import Foundation
import AppKit
import CryptoKit

struct PurchaseExportService {
    struct AttachmentManifestEntry: Codable, Equatable {
        let documentIdentifier: UUID
        let title: String
        let category: String
        let originalFilename: String
        let archivedRelativePath: String
        let sha256Hex: String?
    }

    struct PurchaseArchiveManifest: Codable, Equatable {
        let schemaVersion: Int
        let exportedAt: Date
        let purchaseName: String
        let purchaseStatus: String
        let purchaseDateISO8601: String?
        let seller: String?
        let manufacturer: String?
        let currencyCode: String?
        let purchasePrice: String?
        let attachmentCount: Int
        let attachments: [AttachmentManifestEntry]
    }

    enum ExportError: LocalizedError {
        case invalidDestination
        case archiveFolderMissing
        case manifestMissing
        case unsupportedSchemaVersion(Int)
        case invalidManifest
        case missingAttachment(String)
        case invalidAttachmentPath(String)
        case emptyPurchaseName
        case invalidPurchaseStatus(String)
        case invalidPurchaseDate(String)
        case invalidPurchasePrice(String)
        case duplicateAttachmentIdentifier(UUID)
        case duplicateAttachmentPath(String)
        case attachmentChecksumMismatch(String)

        var errorDescription: String? {
            switch self {
            case .invalidDestination:
                return "The selected export destination is invalid."
            case .archiveFolderMissing:
                return "The archive folder could not be found."
            case .manifestMissing:
                return "The archive manifest is missing."
            case .unsupportedSchemaVersion(let version):
                return "The archive schema version \(version) is not supported."
            case .invalidManifest:
                return "The archive manifest is invalid."
            case .missingAttachment(let path):
                return "The archive attachment is missing: \(path)"
            case .invalidAttachmentPath(let path):
                return "The archive contains an invalid attachment path: \(path)"
            case .emptyPurchaseName:
                return "The archive purchase name is empty."
            case .invalidPurchaseStatus(let value):
                return "The archive contains an invalid purchase status: \(value)"
            case .invalidPurchaseDate(let value):
                return "The archive contains an invalid purchase date: \(value)"
            case .invalidPurchasePrice(let value):
                return "The archive contains an invalid purchase price: \(value)"
            case .duplicateAttachmentIdentifier(let identifier):
                return "The archive contains duplicate attachment identifiers: \(identifier.uuidString)"
            case .duplicateAttachmentPath(let value):
                return "The archive contains duplicate attachment paths: \(value)"
            case .attachmentChecksumMismatch(let path):
                return "The archive attachment checksum does not match: \(path)"
            }
        }
    }

    private static let manifestFileName = "manifest.json"
    private static let reportFileName = "purchase-report.txt"
    private static let attachmentsFolderName = "attachments"
    private static let archiveSchemaVersion = 1

    static func purchaseReportText(for purchase: Purchase) -> String {
        let lines: [String] = [
            "Purchase Passport Report",
            "Exported: \(iso8601String(from: .now) ?? "Unknown")",
            "",
            "Purchase Name: \(purchase.name)",
            "Status: \(purchase.status.rawValue)",
            "Category: \(purchase.category?.name ?? "Not set")",
            "Purchase Date: \(iso8601String(from: purchase.purchaseDate) ?? "Not set")",
            "Seller: \(purchase.seller ?? "Not set")",
            "Manufacturer: \(purchase.manufacturer ?? "Not set")",
            "Purchase Price: \(formattedPrice(for: purchase))",
            "",
            "Counts",
            "Documents: \(purchase.documents.count)",
            "Warranties: \(purchase.warranties.count)",
            "Reminders: \(purchase.reminders.count)",
            "Interactions: \(purchase.interactions.count)",
            "Complaints: \(purchase.complaintCases.count)",
            "Service Records: \(purchase.serviceRecords.count)",
            "Fault Records: \(purchase.faultRecords.count)",
            "Repair Records: \(purchase.repairRecords.count)",
            "",
            "Notes:",
            purchase.notes ?? "None"
        ]
        return lines.joined(separator: "\n")
    }

    static func exportReport(for purchase: Purchase, to destinationURL: URL) throws {
        guard destinationURL.isFileURL else {
            throw ExportError.invalidDestination
        }
        try purchaseReportText(for: purchase).write(to: destinationURL, atomically: true, encoding: .utf8)
    }

    static func exportPDFReport(for purchase: Purchase, to destinationURL: URL) throws {
        guard destinationURL.isFileURL else {
            throw ExportError.invalidDestination
        }

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 595, height: 842))
        textView.isEditable = false
        textView.isSelectable = false
        textView.textContainerInset = NSSize(width: 36, height: 36)
        textView.string = purchaseReportText(for: purchase)
        textView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)

        let data = textView.dataWithPDF(inside: textView.bounds)
        try data.write(to: destinationURL, options: .atomic)
    }

    @discardableResult
    static func exportArchive(for purchase: Purchase, to archiveURL: URL) throws -> PurchaseArchiveManifest {
        guard archiveURL.isFileURL else {
            throw ExportError.invalidDestination
        }

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: archiveURL.path) {
            try fileManager.removeItem(at: archiveURL)
        }
        try fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)

        let attachmentsDirectoryURL = archiveURL.appendingPathComponent(attachmentsFolderName, isDirectory: true)
        try fileManager.createDirectory(at: attachmentsDirectoryURL, withIntermediateDirectories: true)

        var attachmentEntries: [AttachmentManifestEntry] = []
        for document in purchase.documents.sorted(by: { $0.dateAdded > $1.dateAdded }) {
            let sourceURL = try? DocumentStorageService.resolvedURL(for: document.storedRelativePath)
            guard
                let sourceURL,
                fileManager.fileExists(atPath: sourceURL.path)
            else {
                continue
            }

            let safeFileName = "\(document.identifier.uuidString)-\(sanitizeFileName(document.originalFilename))"
            let relativePath = "\(attachmentsFolderName)/\(safeFileName)"
            let destinationURL = attachmentsDirectoryURL.appendingPathComponent(safeFileName)
            try fileManager.copyItem(at: sourceURL, to: destinationURL)

            attachmentEntries.append(
                AttachmentManifestEntry(
                    documentIdentifier: document.identifier,
                    title: document.title,
                    category: document.category.rawValue,
                    originalFilename: document.originalFilename,
                    archivedRelativePath: relativePath,
                    sha256Hex: checksumHex(forFileAt: destinationURL)
                )
            )
        }

        let manifest = PurchaseArchiveManifest(
            schemaVersion: archiveSchemaVersion,
            exportedAt: .now,
            purchaseName: purchase.name,
            purchaseStatus: purchase.status.rawValue,
            purchaseDateISO8601: iso8601String(from: purchase.purchaseDate),
            seller: purchase.seller,
            manufacturer: purchase.manufacturer,
            currencyCode: purchase.currencyCode,
            purchasePrice: purchase.purchasePrice.map { NSDecimalNumber(decimal: $0).stringValue },
            attachmentCount: attachmentEntries.count,
            attachments: attachmentEntries
        )

        let reportURL = archiveURL.appendingPathComponent(reportFileName)
        try purchaseReportText(for: purchase).write(to: reportURL, atomically: true, encoding: .utf8)

        let manifestURL = archiveURL.appendingPathComponent(manifestFileName)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(manifest)
        try data.write(to: manifestURL, options: .atomic)

        return manifest
    }

    static func validateArchive(at archiveURL: URL) -> [String] {
        var issues: [String] = []
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: archiveURL.path) else {
            return ["Archive folder does not exist."]
        }

        let manifestURL = archiveURL.appendingPathComponent(manifestFileName)
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            return ["manifest.json is missing."]
        }

        let reportURL = archiveURL.appendingPathComponent(reportFileName)
        if !fileManager.fileExists(atPath: reportURL.path) {
            issues.append("purchase-report.txt is missing.")
        }

        do {
            let data = try Data(contentsOf: manifestURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let manifest = try decoder.decode(PurchaseArchiveManifest.self, from: data)

            if manifest.schemaVersion != archiveSchemaVersion {
                issues.append("Unsupported schema version: \(manifest.schemaVersion).")
            }

            if manifest.attachmentCount != manifest.attachments.count {
                issues.append("Attachment count mismatch in manifest.")
            }

            if manifest.purchaseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append("Purchase name is empty.")
            }

            if PurchaseStatus(rawValue: manifest.purchaseStatus) == nil {
                issues.append("Purchase status is invalid: \(manifest.purchaseStatus)")
            }

            if let purchaseDateISO8601 = manifest.purchaseDateISO8601,
               parseISO8601Date(purchaseDateISO8601) == nil {
                issues.append("Purchase date is invalid: \(purchaseDateISO8601)")
            }

            if let purchasePrice = manifest.purchasePrice,
               parseDecimal(purchasePrice) == nil {
                issues.append("Purchase price is invalid: \(purchasePrice)")
            }

            var seenAttachmentIdentifiers = Set<UUID>()
            var seenAttachmentPaths = Set<String>()

            for attachment in manifest.attachments {
                if !seenAttachmentIdentifiers.insert(attachment.documentIdentifier).inserted {
                    issues.append("Duplicate attachment identifier: \(attachment.documentIdentifier.uuidString)")
                }
                if !seenAttachmentPaths.insert(attachment.archivedRelativePath).inserted {
                    issues.append("Duplicate attachment path: \(attachment.archivedRelativePath)")
                }
                if !isSafeAttachmentRelativePath(attachment.archivedRelativePath) {
                    issues.append("Invalid attachment path: \(attachment.archivedRelativePath)")
                    continue
                }
                let attachmentURL = archiveURL.appendingPathComponent(attachment.archivedRelativePath)
                if !fileManager.fileExists(atPath: attachmentURL.path) {
                    issues.append("Missing attachment file: \(attachment.archivedRelativePath)")
                    continue
                }

                if let expectedChecksum = attachment.sha256Hex,
                   let actualChecksum = checksumHex(forFileAt: attachmentURL),
                   expectedChecksum != actualChecksum {
                    issues.append("Checksum mismatch for attachment: \(attachment.archivedRelativePath)")
                }
            }
        } catch {
            issues.append("manifest.json could not be decoded.")
        }

        return issues
    }

    static func importArchive(at archiveURL: URL) throws -> Purchase {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: archiveURL.path) else {
            throw ExportError.archiveFolderMissing
        }

        let manifestURL = archiveURL.appendingPathComponent(manifestFileName)
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            throw ExportError.manifestMissing
        }

        let manifestData = try Data(contentsOf: manifestURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest: PurchaseArchiveManifest
        do {
            manifest = try decoder.decode(PurchaseArchiveManifest.self, from: manifestData)
        } catch {
            throw ExportError.invalidManifest
        }

        guard manifest.schemaVersion == archiveSchemaVersion else {
            throw ExportError.unsupportedSchemaVersion(manifest.schemaVersion)
        }

        try validateManifestForImport(manifest)

        let purchase = Purchase(
            name: manifest.purchaseName,
            status: PurchaseStatus(rawValue: manifest.purchaseStatus) ?? .researching,
            purchaseDate: parseISO8601Date(manifest.purchaseDateISO8601),
            purchasePrice: parseDecimal(manifest.purchasePrice),
            currencyCode: manifest.currencyCode,
            seller: manifest.seller,
            manufacturer: manifest.manufacturer
        )

        for attachment in manifest.attachments {
            guard isSafeAttachmentRelativePath(attachment.archivedRelativePath) else {
                throw ExportError.invalidAttachmentPath(attachment.archivedRelativePath)
            }
            let sourceURL = archiveURL.appendingPathComponent(attachment.archivedRelativePath)
            guard fileManager.fileExists(atPath: sourceURL.path) else {
                throw ExportError.missingAttachment(attachment.archivedRelativePath)
            }
            if let expectedChecksum = attachment.sha256Hex {
                let actualChecksum = checksumHex(forFileAt: sourceURL)
                guard actualChecksum == expectedChecksum else {
                    throw ExportError.attachmentChecksumMismatch(attachment.archivedRelativePath)
                }
            }

            let imported = try DocumentStorageService.importFile(from: sourceURL)
            let document = StoredDocument(
                identifier: attachment.documentIdentifier,
                title: attachment.title,
                category: DocumentCategory(rawValue: attachment.category) ?? .other,
                originalFilename: attachment.originalFilename,
                contentType: imported.contentType,
                storedRelativePath: imported.storedRelativePath,
                purchase: purchase
            )
            purchase.documents.append(document)
        }

        return purchase
    }

    private static func formattedPrice(for purchase: Purchase) -> String {
        guard let amount = purchase.purchasePrice else { return "Not set" }
        let value = NSDecimalNumber(decimal: amount).stringValue
        if let currencyCode = purchase.currencyCode, !currencyCode.isEmpty {
            return "\(currencyCode) \(value)"
        }
        return value
    }

    private static func iso8601String(from date: Date?) -> String? {
        guard let date else { return nil }
        return ISO8601DateFormatter().string(from: date)
    }

    private static func parseISO8601Date(_ value: String?) -> Date? {
        guard let value else { return nil }
        return ISO8601DateFormatter().date(from: value)
    }

    private static func parseDecimal(_ value: String?) -> Decimal? {
        guard let value else { return nil }
        return Decimal(string: value)
    }

    private static func sanitizeFileName(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = value.components(separatedBy: invalid).joined(separator: "_")
        return cleaned.isEmpty ? "attachment" : cleaned
    }

    private static func isSafeAttachmentRelativePath(_ value: String) -> Bool {
        guard value.hasPrefix("\(attachmentsFolderName)/"), !value.contains("..") else {
            return false
        }
        let path = NSString(string: value)
        return !path.isAbsolutePath
    }

    private static func checksumHex(forFileAt fileURL: URL) -> String? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func validateManifestForImport(_ manifest: PurchaseArchiveManifest) throws {
        guard manifest.attachmentCount == manifest.attachments.count else {
            throw ExportError.invalidManifest
        }

        guard !manifest.purchaseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExportError.emptyPurchaseName
        }

        guard PurchaseStatus(rawValue: manifest.purchaseStatus) != nil else {
            throw ExportError.invalidPurchaseStatus(manifest.purchaseStatus)
        }

        if let purchaseDateISO8601 = manifest.purchaseDateISO8601,
           parseISO8601Date(purchaseDateISO8601) == nil {
            throw ExportError.invalidPurchaseDate(purchaseDateISO8601)
        }

        if let purchasePrice = manifest.purchasePrice,
           parseDecimal(purchasePrice) == nil {
            throw ExportError.invalidPurchasePrice(purchasePrice)
        }

        var seenAttachmentIdentifiers = Set<UUID>()
        var seenAttachmentPaths = Set<String>()
        for attachment in manifest.attachments {
            guard seenAttachmentIdentifiers.insert(attachment.documentIdentifier).inserted else {
                throw ExportError.duplicateAttachmentIdentifier(attachment.documentIdentifier)
            }

            guard seenAttachmentPaths.insert(attachment.archivedRelativePath).inserted else {
                throw ExportError.duplicateAttachmentPath(attachment.archivedRelativePath)
            }

            guard isSafeAttachmentRelativePath(attachment.archivedRelativePath) else {
                throw ExportError.invalidAttachmentPath(attachment.archivedRelativePath)
            }
        }
    }
}
