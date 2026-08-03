import Foundation
import AppKit

struct PurchaseExportService {
    struct AttachmentManifestEntry: Codable, Equatable {
        let documentIdentifier: UUID
        let title: String
        let category: String
        let originalFilename: String
        let archivedRelativePath: String
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
                    archivedRelativePath: relativePath
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

            for attachment in manifest.attachments {
                let attachmentURL = archiveURL.appendingPathComponent(attachment.archivedRelativePath)
                if !fileManager.fileExists(atPath: attachmentURL.path) {
                    issues.append("Missing attachment file: \(attachment.archivedRelativePath)")
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

        guard manifest.attachmentCount == manifest.attachments.count else {
            throw ExportError.invalidManifest
        }

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
            let sourceURL = archiveURL.appendingPathComponent(attachment.archivedRelativePath)
            guard fileManager.fileExists(atPath: sourceURL.path) else {
                throw ExportError.missingAttachment(attachment.archivedRelativePath)
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
}
