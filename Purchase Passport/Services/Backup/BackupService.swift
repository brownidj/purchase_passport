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

        var errorDescription: String? {
            switch self {
            case .invalidDestination:
                return "The selected backup destination is invalid."
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

            for relativePath in manifest.purchaseArchives {
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

    private static func sanitize(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = value.components(separatedBy: invalid).joined(separator: "_")
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "purchase" : trimmed
    }
}
