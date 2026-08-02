import Foundation
import UniformTypeIdentifiers

struct ImportedDocumentFile {
    let originalFilename: String
    let contentType: String?
    let storedRelativePath: String
}

enum DocumentStorageError: LocalizedError {
    case sourceFileMissing
    case copyFailed

    var errorDescription: String? {
        switch self {
        case .sourceFileMissing:
            return "The selected file could not be found."
        case .copyFailed:
            return "The document could not be imported."
        }
    }
}

struct DocumentStorageService {
    private static let folderName = "Attachments"

    static func importFile(from sourceURL: URL) throws -> ImportedDocumentFile {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw DocumentStorageError.sourceFileMissing
        }

        let storageDirectory = try attachmentsDirectoryURL()
        let fileExtension = sourceURL.pathExtension
        let destinationFileName = fileExtension.isEmpty
            ? UUID().uuidString
            : "\(UUID().uuidString).\(fileExtension)"

        let destinationURL = storageDirectory.appendingPathComponent(destinationFileName)

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw DocumentStorageError.copyFailed
        }

        let resourceValues = try? sourceURL.resourceValues(forKeys: [.contentTypeKey])
        let contentType = resourceValues?.contentType?.identifier

        return ImportedDocumentFile(
            originalFilename: sourceURL.lastPathComponent,
            contentType: contentType,
            storedRelativePath: destinationFileName
        )
    }

    static func resolvedURL(for storedRelativePath: String) throws -> URL {
        try attachmentsDirectoryURL().appendingPathComponent(storedRelativePath)
    }

    private static func attachmentsDirectoryURL() throws -> URL {
        let fileManager = FileManager.default
        let appSupportDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let appDirectory = appSupportDirectory.appendingPathComponent("PurchasePassport", isDirectory: true)
        let attachmentsDirectory = appDirectory.appendingPathComponent(folderName, isDirectory: true)

        if !fileManager.fileExists(atPath: attachmentsDirectory.path) {
            try fileManager.createDirectory(at: attachmentsDirectory, withIntermediateDirectories: true)
        }

        return attachmentsDirectory
    }
}
