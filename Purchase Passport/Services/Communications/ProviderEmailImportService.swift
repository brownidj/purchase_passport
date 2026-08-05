import Foundation
import SwiftData
import UniformTypeIdentifiers

enum ProviderEmailImportService {
    enum ImportMode {
        case importNewOnly
        case overwriteExisting
    }

    struct ImportSummary {
        let providerName: String
        let fileCount: Int
        let matchingCount: Int
        let importedCount: Int
        let overwrittenCount: Int
        let skippedCount: Int
        let linkedCount: Int
        let diagnostics: String
    }

    enum ImportError: LocalizedError {
        case providerNotFound(String)
        case noFilesSelected
        case unsupportedDropPayload
        case unreadableDropPayload

        var errorDescription: String? {
            switch self {
            case .providerNotFound(let providerName):
                return "The provider \(providerName) could not be found for email import."
            case .noFilesSelected:
                return "No email files were provided for import."
            case .unsupportedDropPayload:
                return "The dropped Mail items did not contain readable email files."
            case .unreadableDropPayload:
                return "The dropped Mail items could not be converted into readable email files."
            }
        }
    }

    nonisolated static let supportedContentTypes: [UTType] = [
        .emailMessage,
        UTType(filenameExtension: "eml", conformingTo: .emailMessage),
        UTType(filenameExtension: "emlx", conformingTo: .data)
    ].compactMap { $0 }

    nonisolated static let supportedDropContentTypes: [UTType] = {
        var seen = Set<String>()
        return (supportedContentTypes + [.fileURL, .data]).filter { type in
            seen.insert(type.identifier).inserted
        }
    }()

    @MainActor
    static func importEmailFiles(
        at urls: [URL],
        forProviderNamed providerName: String,
        providers: [Organisation],
        correspondences: [CorrespondenceRecord],
        purchases: [Purchase],
        modelContext: ModelContext,
        mode: ImportMode = .importNewOnly
    ) throws -> ImportSummary {
        guard !urls.isEmpty else {
            throw ImportError.noFilesSelected
        }

        guard let provider = providers.first(where: {
            $0.name.localizedCaseInsensitiveCompare(providerName) == .orderedSame
        }) else {
            throw ImportError.providerNotFound(providerName)
        }

        let emails = try urls.map { try CommunicationIntelligenceService.parseEmailFile(at: $0) }
        let diagnostics = [
            "Imported email files: \(urls.count)",
            "Files: \(urls.map(\.lastPathComponent).joined(separator: ", "))"
        ].joined(separator: "\n")

        let matchingEmails = emails.filter {
            ProviderCorrespondenceService.matches($0, provider: provider)
        }

        var correspondencesByMessageID: [String: CorrespondenceRecord] = [:]
        var correspondencesByFallbackKey: [String: CorrespondenceRecord] = [:]
        for correspondence in correspondences {
            if let messageID = normalizedMessageID(correspondence.externalMessageID),
               correspondencesByMessageID[messageID] == nil {
                correspondencesByMessageID[messageID] = correspondence
            }

            let fallbackKey = correspondenceFallbackKey(correspondence)
            if correspondencesByFallbackKey[fallbackKey] == nil {
                correspondencesByFallbackKey[fallbackKey] = correspondence
            }
        }
        var importedCount = 0
        var overwrittenCount = 0
        var skippedCount = 0
        var linkedCount = 0

        for email in matchingEmails {
            let messageID = normalizedMessageID(email.messageID)
            let fallbackKey = envelopeFallbackKey(email)
            let existingCorrespondence = messageID.flatMap { correspondencesByMessageID[$0] }
                ?? correspondencesByFallbackKey[fallbackKey]

            if existingCorrespondence != nil, mode == .importNewOnly {
                skippedCount += 1
                continue
            }

            let result = CommunicationIntelligenceService.importEmail(
                email,
                into: purchases,
                updating: existingCorrespondence
            )
            result.correspondence.reviewStatus = .accepted

            if existingCorrespondence == nil {
                modelContext.insert(result.correspondence)
                importedCount += 1
            } else {
                overwrittenCount += 1
            }

            if let linkedPurchase = result.linkedPurchase {
                linkedPurchase.updatedAt = .now
                linkedCount += 1
            }

            if let messageID {
                correspondencesByMessageID[messageID] = result.correspondence
            }
            correspondencesByFallbackKey[fallbackKey] = result.correspondence
        }

        if importedCount > 0 || overwrittenCount > 0 {
            try modelContext.save()
        }

        let details = [
            "Provider: \(provider.name)",
            "Provider matches: \(matchingEmails.count)",
            "Imported: \(importedCount)",
            "Overwritten: \(overwrittenCount)",
            "Skipped duplicates: \(skippedCount)",
            "Auto-linked to purchases: \(linkedCount)",
            "",
            diagnostics
        ].joined(separator: "\n")

        return ImportSummary(
            providerName: provider.name,
            fileCount: urls.count,
            matchingCount: matchingEmails.count,
            importedCount: importedCount,
            overwrittenCount: overwrittenCount,
            skippedCount: skippedCount,
            linkedCount: linkedCount,
            diagnostics: details
        )
    }

    nonisolated static func loadDroppedEmailFiles(
        from itemProviders: [NSItemProvider],
        completion: @escaping (Result<[URL], Error>) -> Void
    ) {
        let relevantProviders = itemProviders.filter { provider in
            supportedDropContentTypes.contains { type in
                provider.hasItemConformingToTypeIdentifier(type.identifier)
            }
        }

        guard !relevantProviders.isEmpty else {
            completion(.failure(ImportError.unsupportedDropPayload))
            return
        }

        let group = DispatchGroup()
        let lock = NSLock()
        var urls: [URL] = []
        var firstError: Error?

        for provider in relevantProviders {
            group.enter()
            loadDroppedEmailFile(from: provider) { result in
                lock.lock()
                defer { lock.unlock() }
                switch result {
                case .success(let url):
                    urls.append(url)
                case .failure(let error):
                    if firstError == nil {
                        firstError = error
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if !urls.isEmpty {
                completion(.success(urls))
            } else {
                completion(.failure(firstError ?? ImportError.unreadableDropPayload))
            }
        }
    }
}

extension ProviderEmailImportService {
    nonisolated static func loadDroppedEmailFile(
        from itemProvider: NSItemProvider,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let suggestedName = itemProvider.suggestedName

        if itemProvider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let url = item as? URL {
                    completeWithStagedCopy(from: url, contentType: detectedContentType(for: url), suggestedName: suggestedName, completion: completion)
                    return
                }
                if let url = item as? NSURL {
                    completeWithStagedCopy(from: url as URL, contentType: detectedContentType(for: url as URL), suggestedName: suggestedName, completion: completion)
                    return
                }
                if let error {
                    loadFileOrDataRepresentation(from: itemProvider, completion: completion, fallbackError: error)
                    return
                }
                loadFileOrDataRepresentation(from: itemProvider, completion: completion, fallbackError: ImportError.unreadableDropPayload)
            }
            return
        }

        loadFileOrDataRepresentation(from: itemProvider, completion: completion, fallbackError: ImportError.unreadableDropPayload)
    }

    nonisolated static func loadFileOrDataRepresentation(
        from itemProvider: NSItemProvider,
        completion: @escaping (Result<URL, Error>) -> Void,
        fallbackError: Error
    ) {
        let suggestedName = itemProvider.suggestedName
        let candidateTypes = supportedContentTypes.filter {
            itemProvider.hasItemConformingToTypeIdentifier($0.identifier)
        }

        guard let contentType = candidateTypes.first else {
            completion(.failure(fallbackError))
            return
        }

        itemProvider.loadFileRepresentation(forTypeIdentifier: contentType.identifier) { url, error in
            if let url {
                completeWithStagedCopy(from: url, contentType: contentType, suggestedName: suggestedName, completion: completion)
                return
            }

            itemProvider.loadDataRepresentation(forTypeIdentifier: contentType.identifier) { data, dataError in
                guard let data else {
                    completion(.failure(dataError ?? error ?? fallbackError))
                    return
                }

                do {
                    let stagedURL = try stagedDropURL(
                        suggestedName: suggestedName,
                        contentType: contentType
                    )
                    try data.write(to: stagedURL, options: .atomic)
                    completion(.success(stagedURL))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    nonisolated static func completeWithStagedCopy(
        from sourceURL: URL,
        contentType: UTType?,
        suggestedName: String?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        do {
            let stagedURL = try stagedDropURL(
                suggestedName: suggestedName ?? sourceURL.lastPathComponent,
                contentType: contentType ?? detectedContentType(for: sourceURL)
            )
            if FileManager.default.fileExists(atPath: stagedURL.path) {
                try FileManager.default.removeItem(at: stagedURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: stagedURL)
            completion(.success(stagedURL))
        } catch {
            completion(.failure(error))
        }
    }

    nonisolated static func stagedDropURL(suggestedName: String?, contentType: UTType?) throws -> URL {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let baseName = {
            let candidate = (suggestedName as NSString?)?.deletingPathExtension ?? ""
            return candidate.isEmpty ? UUID().uuidString : candidate
        }()
        let providedExtension = {
            let candidate = (suggestedName as NSString?)?.pathExtension ?? ""
            return candidate.isEmpty ? nil : candidate
        }()
        let pathExtension = providedExtension ?? contentType?.preferredFilenameExtension ?? "eml"
        return temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "-" + baseName)
            .appendingPathExtension(pathExtension)
    }

    nonisolated static func detectedContentType(for url: URL) -> UTType? {
        UTType(filenameExtension: url.pathExtension)
    }

    static func normalizedMessageID(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
            .lowercased()
        return trimmed.isEmpty ? nil : trimmed
    }

    static func correspondenceFallbackKey(_ correspondence: CorrespondenceRecord) -> String {
        [
            correspondence.sender?.lowercased() ?? "",
            normalizedRecipients(correspondence.recipients),
            correspondence.subject.lowercased(),
            correspondence.bodyPreview?.lowercased() ?? "",
            correspondence.threadID?.lowercased() ?? ""
        ].joined(separator: "|")
    }

    static func envelopeFallbackKey(_ email: CommunicationIntelligenceService.EmailEnvelope) -> String {
        [
            email.sender.lowercased(),
            normalizedRecipients(email.recipients.joined(separator: ", ")),
            email.subject.lowercased(),
            duplicatePreviewText(from: email.body).lowercased(),
            email.threadID?.lowercased() ?? ""
        ].joined(separator: "|")
    }

    static func normalizedRecipients(_ rawRecipients: String?) -> String {
        guard let rawRecipients else { return "" }
        let recipients = rawRecipients
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .sorted()
        return recipients.joined(separator: ",")
    }

    static func duplicatePreviewText(from body: String, maxLength: Int = 240) -> String {
        let flattened = body
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard flattened.count > maxLength else { return flattened }
        let endIndex = flattened.index(flattened.startIndex, offsetBy: maxLength)
        return String(flattened[..<endIndex]) + "…"
    }
}
