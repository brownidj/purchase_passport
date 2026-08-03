import Foundation

struct BackupService {
    struct BackupManifest: Codable, Equatable {
        let schemaVersion: Int
        let createdAt: Date
        let purchaseCount: Int
        let purchaseArchives: [String]
    }

    enum BackupError: LocalizedError {
        case invalidDestination
        case backupFolderMissing
        case manifestMissing
        case unsupportedSchemaVersion(Int)
        case invalidManifest
        case invalidArchivePath(String)
        case duplicateArchivePath(String)
        case invalidArchive(String, String)

        var errorDescription: String? {
            switch self {
            case .invalidDestination:
                return "The selected backup destination is invalid."
            case .backupFolderMissing:
                return "The backup folder could not be found."
            case .manifestMissing:
                return "The backup manifest is missing."
            case .unsupportedSchemaVersion(let version):
                return "The backup schema version \(version) is not supported."
            case .invalidManifest:
                return "The backup manifest is invalid."
            case .invalidArchivePath(let path):
                return "The backup contains an invalid archive path: \(path)"
            case .duplicateArchivePath(let path):
                return "The backup contains a duplicate archive path: \(path)"
            case .invalidArchive(let path, let issue):
                return "The archive at \(path) is invalid: \(issue)"
            }
        }
    }

    private static let manifestFileName = "backup-manifest.json"
    private static let purchasesFolderName = "purchases"
    private static let backupSchemaVersion = 1

    @discardableResult
    static func exportBackup(for purchases: [Purchase], to backupURL: URL) throws -> BackupManifest {
        guard backupURL.isFileURL else {
            throw BackupError.invalidDestination
        }

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true)

        let purchasesDirectoryURL = backupURL.appendingPathComponent(purchasesFolderName, isDirectory: true)
        try fileManager.createDirectory(at: purchasesDirectoryURL, withIntermediateDirectories: true)

        var archiveRelativePaths: [String] = []
        for (index, purchase) in purchases.enumerated() {
            let safeName = sanitize("\(index + 1)-\(purchase.name)")
            let folderName = "\(safeName).pparchive"
            let relativePath = "\(purchasesFolderName)/\(folderName)"
            let archiveURL = purchasesDirectoryURL.appendingPathComponent(folderName, isDirectory: true)
            try PurchaseExportService.exportArchive(for: purchase, to: archiveURL)
            archiveRelativePaths.append(relativePath)
        }

        let manifest = BackupManifest(
            schemaVersion: backupSchemaVersion,
            createdAt: .now,
            purchaseCount: purchases.count,
            purchaseArchives: archiveRelativePaths
        )

        let manifestURL = backupURL.appendingPathComponent(manifestFileName)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(manifest)
        try data.write(to: manifestURL, options: .atomic)

        return manifest
    }

    static func validateBackup(at backupURL: URL) -> [String] {
        var issues: [String] = []
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: backupURL.path) else {
            return ["Backup folder does not exist."]
        }

        let manifestURL = backupURL.appendingPathComponent(manifestFileName)
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            return ["backup-manifest.json is missing."]
        }

        do {
            let data = try Data(contentsOf: manifestURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let manifest = try decoder.decode(BackupManifest.self, from: data)

            if manifest.schemaVersion != backupSchemaVersion {
                issues.append("Unsupported backup schema version: \(manifest.schemaVersion).")
            }

            if manifest.purchaseCount != manifest.purchaseArchives.count {
                issues.append("Purchase count mismatch in backup manifest.")
            }

            var seenArchivePaths = Set<String>()
            for relativePath in manifest.purchaseArchives {
                if !seenArchivePaths.insert(relativePath).inserted {
                    issues.append("Duplicate archive path in backup manifest: \(relativePath)")
                    continue
                }
                if !isSafeArchiveRelativePath(relativePath) {
                    issues.append("Invalid archive path in backup manifest: \(relativePath)")
                    continue
                }
                let archiveURL = backupURL.appendingPathComponent(relativePath)
                let archiveIssues = PurchaseExportService.validateArchive(at: archiveURL)
                if !archiveIssues.isEmpty {
                    issues.append("Archive \(relativePath) has issues:")
                    issues.append(contentsOf: archiveIssues.map { "  - \($0)" })
                }
            }
        } catch {
            issues.append("backup-manifest.json could not be decoded.")
        }

        return issues
    }

    static func restoreBackup(at backupURL: URL) throws -> [Purchase] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: backupURL.path) else {
            throw BackupError.backupFolderMissing
        }

        let manifestURL = backupURL.appendingPathComponent(manifestFileName)
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            throw BackupError.manifestMissing
        }

        let manifestData = try Data(contentsOf: manifestURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest: BackupManifest
        do {
            manifest = try decoder.decode(BackupManifest.self, from: manifestData)
        } catch {
            throw BackupError.invalidManifest
        }

        guard manifest.schemaVersion == backupSchemaVersion else {
            throw BackupError.unsupportedSchemaVersion(manifest.schemaVersion)
        }

        guard manifest.purchaseCount == manifest.purchaseArchives.count else {
            throw BackupError.invalidManifest
        }

        var seenArchivePaths = Set<String>()
        for relativePath in manifest.purchaseArchives {
            guard seenArchivePaths.insert(relativePath).inserted else {
                throw BackupError.duplicateArchivePath(relativePath)
            }
            guard isSafeArchiveRelativePath(relativePath) else {
                throw BackupError.invalidArchivePath(relativePath)
            }
        }

        var purchases: [Purchase] = []
        purchases.reserveCapacity(manifest.purchaseArchives.count)
        for relativePath in manifest.purchaseArchives {
            let archiveURL = backupURL.appendingPathComponent(relativePath)
            let archiveIssues = PurchaseExportService.validateArchive(at: archiveURL)
            if let firstIssue = archiveIssues.first {
                throw BackupError.invalidArchive(relativePath, firstIssue)
            }
            let purchase = try PurchaseExportService.importArchive(at: archiveURL)
            purchases.append(purchase)
        }

        return purchases
    }

    private static func sanitize(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = value.components(separatedBy: invalid).joined(separator: "_")
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "purchase" : trimmed
    }

    private static func isSafeArchiveRelativePath(_ value: String) -> Bool {
        guard value.hasPrefix("\(purchasesFolderName)/"),
              value.hasSuffix(".pparchive"),
              !value.contains("..") else {
            return false
        }

        let path = NSString(string: value)
        return !path.isAbsolutePath
    }
}
