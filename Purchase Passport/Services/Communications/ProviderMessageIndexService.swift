import AppKit
import Foundation
import SwiftData

struct ProviderMessageEntry: Identifiable, Equatable {
    let id: String
    let occurredAt: Date
    let type: String
    let contact: String
    let text: String
    let attachments: [String]
}

struct ProviderMessageConversation: Identifiable, Equatable {
    let id: String
    let fileName: String
    let conversationLabel: String
    let conversationIdentifier: String?
    let matchReasons: [String]
    let messages: [ProviderMessageEntry]

    nonisolated var latestMessageAt: Date? {
        messages.map(\.occurredAt).max()
    }

    nonisolated var messageCount: Int {
        messages.count
    }
}

struct ProviderMessageProviderRecord: Equatable {
    let providerKey: String
    let providerName: String
    let conversations: [ProviderMessageConversation]
}

struct ProviderMessageSearchTerm: Identifiable, Equatable {
    let id: String
    let category: String
    let label: String
    let rawValue: String
    let normalizedValue: String
}

struct ProviderMessageSearchDebug: Equatable {
    let providerName: String
    let terms: [ProviderMessageSearchTerm]
}

struct ProviderMessageRefreshResult: Equatable {
    let outputURL: URL
    let providerRecords: [ProviderMessageProviderRecord]

    func record(for provider: Organisation) -> ProviderMessageProviderRecord? {
        let key = ProviderMessageIndexService.providerKey(for: provider)
        return providerRecords.first { $0.providerKey == key }
    }
}

enum ProviderMessageIndexService {
    private struct ProviderMatchDescriptor {
        struct ValueMatcher {
            let category: String
            let rawValue: String
            let normalizedValue: String
            let reason: String
        }

        let providerKey: String
        let providerName: String
        let phoneMatchers: [ValueMatcher]
        let emailMatchers: [ValueMatcher]
        let nameMatchers: [ValueMatcher]
    }

    private struct ConversationCandidate {
        let fileName: String
        let conversationLabel: String
        let conversationIdentifier: String?
        let phoneCandidates: Set<String>
        let emailCandidates: Set<String>
        let nameCandidates: Set<String>
        let messages: [ProviderMessageEntry]

        func matchedConversation(for descriptor: ProviderMatchDescriptor) -> ProviderMessageConversation? {
            var reasons: [String] = []

            for matcher in descriptor.phoneMatchers where phoneCandidates.contains(matcher.normalizedValue) {
                if !reasons.contains(matcher.reason) {
                    reasons.append(matcher.reason)
                }
            }

            for matcher in descriptor.emailMatchers where emailCandidates.contains(matcher.normalizedValue) {
                if !reasons.contains(matcher.reason) {
                    reasons.append(matcher.reason)
                }
            }

            for matcher in descriptor.nameMatchers where nameCandidates.contains(matcher.normalizedValue) {
                if !reasons.contains(matcher.reason) {
                    reasons.append(matcher.reason)
                }
            }

            guard !reasons.isEmpty else { return nil }

            return ProviderMessageConversation(
                id: fileName,
                fileName: fileName,
                conversationLabel: conversationLabel,
                conversationIdentifier: conversationIdentifier,
                matchReasons: reasons,
                messages: messages
            )
        }
    }

    enum IndexError: LocalizedError, Equatable {
        case sourceDirectoryMissing
        case sourceDirectoryAccessDenied
        case invalidMessagesDirectory
        case directorySelectionCancelled
        case noMessageFilesFound

        var errorDescription: String? {
            switch self {
            case .sourceDirectoryMissing:
                return "The Messages export directory could not be found."
            case .sourceDirectoryAccessDenied:
                return "Select the exported Messages folder to allow linked message access."
            case .invalidMessagesDirectory:
                return "Select the Messages folder in `data/` that contains the `.txt` conversation files."
            case .directorySelectionCancelled:
                return nil
            case .noMessageFilesFound:
                return "No exported message text files were found."
            }
        }
    }

    static func linkedConversations(for provider: Organisation) throws -> [ProviderMessageConversation] {
        let descriptor = descriptor(for: provider)
        let candidates = try loadConversationCandidates()

        return candidates
            .compactMap { $0.matchedConversation(for: descriptor) }
            .sorted { lhs, rhs in
                switch (lhs.latestMessageAt, rhs.latestMessageAt) {
                case let (lhsDate?, rhsDate?):
                    return lhsDate > rhsDate
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.conversationLabel.localizedCaseInsensitiveCompare(rhs.conversationLabel) == .orderedAscending
                }
            }
    }

    static func refreshIndex(for providers: [Organisation]) throws -> ProviderMessageRefreshResult {
        let candidates = try loadConversationCandidates()
        let providerRecords = providers
            .map { provider -> ProviderMessageProviderRecord in
                let descriptor = descriptor(for: provider)
                let conversations = candidates
                    .compactMap { $0.matchedConversation(for: descriptor) }
                    .sorted { lhs, rhs in
                        switch (lhs.latestMessageAt, rhs.latestMessageAt) {
                        case let (lhsDate?, rhsDate?):
                            return lhsDate > rhsDate
                        case (.some, .none):
                            return true
                        case (.none, .some):
                            return false
                        case (.none, .none):
                            return lhs.conversationLabel.localizedCaseInsensitiveCompare(rhs.conversationLabel) == .orderedAscending
                        }
                    }

                return ProviderMessageProviderRecord(
                    providerKey: descriptor.providerKey,
                    providerName: descriptor.providerName,
                    conversations: conversations
                )
            }

        let outputURL = try yamlOutputURL()
        let yaml = yamlString(for: providerRecords)
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try yaml.write(to: outputURL, atomically: true, encoding: .utf8)

        return ProviderMessageRefreshResult(outputURL: outputURL, providerRecords: providerRecords)
    }

    nonisolated static func providerKey(for provider: Organisation) -> String {
        String(describing: provider.persistentModelID)
    }

    static func debugSearch(for provider: Organisation) -> ProviderMessageSearchDebug {
        let descriptor = descriptor(for: provider)
        let terms =
            descriptor.phoneMatchers.map {
                ProviderMessageSearchTerm(
                    id: "\($0.category)-\($0.reason)-\($0.normalizedValue)",
                    category: $0.category,
                    label: $0.reason,
                    rawValue: $0.rawValue,
                    normalizedValue: $0.normalizedValue
                )
            } +
            descriptor.emailMatchers.map {
                ProviderMessageSearchTerm(
                    id: "\($0.category)-\($0.reason)-\($0.normalizedValue)",
                    category: $0.category,
                    label: $0.reason,
                    rawValue: $0.rawValue,
                    normalizedValue: $0.normalizedValue
                )
            } +
            descriptor.nameMatchers.map {
                ProviderMessageSearchTerm(
                    id: "\($0.category)-\($0.reason)-\($0.normalizedValue)",
                    category: $0.category,
                    label: $0.reason,
                    rawValue: $0.rawValue,
                    normalizedValue: $0.normalizedValue
                )
            }

        return ProviderMessageSearchDebug(
            providerName: descriptor.providerName,
            terms: terms.sorted {
                if $0.category == $1.category {
                    return $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending
                }
                return $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending
            }
        )
    }

    @MainActor
    static func chooseMessagesDirectory() throws -> URL {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Messages Folder"
        panel.message = "Select the Messages folder in `data/` that contains the conversation `.txt` files."
        panel.directoryURL = legacyMessagesSourceRootURL()

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            throw IndexError.directorySelectionCancelled
        }

        guard directoryLooksLikeMessagesExport(selectedURL) else {
            throw IndexError.invalidMessagesDirectory
        }

        let bookmark = try selectedURL.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmark, forKey: messagesDirectoryBookmarkKey)

        return selectedURL
    }
}

private extension ProviderMessageIndexService {
    struct ResolvedMessagesSourceRoot {
        let url: URL
        let requiresSecurityScope: Bool
    }

    nonisolated static let messagesDirectoryBookmarkKey = "ProviderMessageIndexService.messagesDirectoryBookmark"

    nonisolated private static func makeMessageDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }

    nonisolated private static func makeYAMLDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    nonisolated private static func descriptor(for provider: Organisation) -> ProviderMatchDescriptor {
        var phoneMatchers: [ProviderMatchDescriptor.ValueMatcher] = []
        var emailMatchers: [ProviderMatchDescriptor.ValueMatcher] = []
        var nameMatchers: [ProviderMatchDescriptor.ValueMatcher] = []

        appendPhoneMatcher(provider.phoneNumber, reason: "Provider phone", to: &phoneMatchers)
        appendPhoneMatcher(provider.customerServiceNumber, reason: "Customer service number", to: &phoneMatchers)
        appendEmailMatcher(provider.emailAddress, reason: "Provider email", to: &emailMatchers)
        appendNameMatcher(provider.name, reason: "Provider name", to: &nameMatchers)

        for contact in provider.contacts {
            appendPhoneMatcher(contact.phoneNumber, reason: "Contact phone: \(contact.name)", to: &phoneMatchers)
            appendEmailMatcher(contact.emailAddress, reason: "Contact email: \(contact.name)", to: &emailMatchers)
            appendNameMatcher(contact.name, reason: "Contact name: \(contact.name)", to: &nameMatchers)
        }

        return ProviderMatchDescriptor(
            providerKey: providerKey(for: provider),
            providerName: provider.name,
            phoneMatchers: phoneMatchers,
            emailMatchers: emailMatchers,
            nameMatchers: nameMatchers
        )
    }

    nonisolated private static func appendPhoneMatcher(
        _ source: String?,
        reason: String,
        to collection: inout [ProviderMatchDescriptor.ValueMatcher]
    ) {
        guard
            let rawValue = source?.trimmingCharacters(in: .whitespacesAndNewlines),
            !rawValue.isEmpty,
            let normalizedValue = normalizePhoneNumber(rawValue),
            normalizedValue.count >= 6
        else { return }
        guard !collection.contains(where: { $0.normalizedValue == normalizedValue }) else { return }
        collection.append(
            .init(
                category: "Phone",
                rawValue: rawValue,
                normalizedValue: normalizedValue,
                reason: reason
            )
        )
    }

    nonisolated private static func appendEmailMatcher(
        _ source: String?,
        reason: String,
        to collection: inout [ProviderMatchDescriptor.ValueMatcher]
    ) {
        guard
            let rawValue = source?.trimmingCharacters(in: .whitespacesAndNewlines),
            !rawValue.isEmpty,
            let normalizedValue = normalizeEmail(rawValue)
        else { return }
        guard !collection.contains(where: { $0.normalizedValue == normalizedValue }) else { return }
        collection.append(
            .init(
                category: "Email",
                rawValue: rawValue,
                normalizedValue: normalizedValue,
                reason: reason
            )
        )
    }

    nonisolated private static func appendNameMatcher(
        _ source: String?,
        reason: String,
        to collection: inout [ProviderMatchDescriptor.ValueMatcher]
    ) {
        guard
            let rawValue = source?.trimmingCharacters(in: .whitespacesAndNewlines),
            !rawValue.isEmpty,
            let normalizedValue = normalizeName(rawValue)
        else { return }
        guard !collection.contains(where: { $0.normalizedValue == normalizedValue }) else { return }
        collection.append(
            .init(
                category: "Name",
                rawValue: rawValue,
                normalizedValue: normalizedValue,
                reason: reason
            )
        )
    }

    nonisolated private static func loadConversationCandidates() throws -> [ConversationCandidate] {
        try withMessagesSourceRootURL { sourceRoot in
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: sourceRoot,
                includingPropertiesForKeys: nil
            )
            .filter { $0.pathExtension.lowercased() == "txt" }
            .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }

            guard !fileURLs.isEmpty else { throw IndexError.noMessageFilesFound }

            return try fileURLs.map(parseConversationFile(at:))
        }
    }

    nonisolated private static func parseConversationFile(at fileURL: URL) throws -> ConversationCandidate {
        let messageDateFormatter = makeMessageDateFormatter()
        let data = try Data(contentsOf: fileURL)
        let rawContents = String(decoding: data, as: UTF8.self)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let lines = rawContents.components(separatedBy: "\n")
        let header = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? fileURL.deletingPathExtension().lastPathComponent
        let (conversationLabel, conversationIdentifier) = parseHeader(header)

        let stem = sanitizedConversationStem(fileURL.deletingPathExtension().lastPathComponent)
        var messages: [ProviderMessageEntry] = []

        var index = lines.firstIndex(where: { $0.contains("Date") && $0.contains("Messages") }) ?? 2
        index += 1

        while index < lines.count {
            let line = lines[index]
            guard let row = parseRowPrefix(from: line, using: messageDateFormatter) else {
                index += 1
                continue
            }

            index += 1
            var blockLines = [row.remainder]
            while index < lines.count, parseRowPrefix(from: lines[index], using: messageDateFormatter) == nil {
                blockLines.append(lines[index])
                index += 1
            }

            let (messageText, attachments) = parseMessagePayload(blockLines.joined(separator: "\n"))
            messages.append(
                ProviderMessageEntry(
                    id: "\(fileURL.lastPathComponent)-\(messages.count)",
                    occurredAt: row.date,
                    type: row.type,
                    contact: row.contact,
                    text: messageText,
                    attachments: attachments
                )
            )
        }

        let candidatePhones = Set(
            [conversationLabel, conversationIdentifier, stem]
                .compactMap(normalizePhoneNumber)
        )
        let candidateEmails = Set(
            [conversationLabel, conversationIdentifier, stem]
                .compactMap(normalizeEmail)
        )
        let candidateNames = Set(
            [conversationLabel, conversationIdentifier, stem]
                .compactMap(normalizeName)
        )

        return ConversationCandidate(
            fileName: fileURL.lastPathComponent,
            conversationLabel: conversationLabel,
            conversationIdentifier: conversationIdentifier,
            phoneCandidates: candidatePhones,
            emailCandidates: candidateEmails,
            nameCandidates: candidateNames,
            messages: messages
        )
    }

    nonisolated private static func parseHeader(_ rawHeader: String) -> (String, String?) {
        let parts = rawHeader.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        let label = parts.first.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let identifier = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : nil
        return (label?.isEmpty == false ? label! : rawHeader, identifier?.isEmpty == false ? identifier : nil)
    }

    nonisolated private static func parseRowPrefix(
        from line: String,
        using messageDateFormatter: DateFormatter
    ) -> (date: Date, type: String, contact: String, remainder: String)? {
        let parts = line.components(separatedBy: "\t")
        guard parts.count >= 4 else { return nil }

        let dateString = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        guard let date = messageDateFormatter.date(from: dateString) else { return nil }

        let type = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let contact = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let remainder = parts.dropFirst(3).joined(separator: "\t")
        return (date, type, contact, remainder)
    }

    nonisolated private static func parseMessagePayload(_ payload: String) -> (String, [String]) {
        let normalized = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return ("", []) }

        if let tabIndex = normalized.lastIndex(of: "\t") {
            let textPart = String(normalized[..<tabIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            let attachmentPart = String(normalized[normalized.index(after: tabIndex)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let cleanedText = textPart == "-" ? "" : textPart
            let attachments = attachmentPart == "-" || attachmentPart.isEmpty ? [] : [attachmentPart]
            return (cleanedText, attachments)
        }

        return (normalized == "-" ? "" : normalized, [])
    }

    nonisolated private static func withMessagesSourceRootURL<T>(
        _ body: (URL) throws -> T
    ) throws -> T {
        let resolvedRoot = try resolveMessagesSourceRoot()

        if resolvedRoot.requiresSecurityScope {
            guard resolvedRoot.url.startAccessingSecurityScopedResource() else {
                throw IndexError.sourceDirectoryAccessDenied
            }
            do {
                defer { resolvedRoot.url.stopAccessingSecurityScopedResource() }
                return try body(resolvedRoot.url)
            } catch {
                if isPermissionError(error) {
                    throw IndexError.sourceDirectoryAccessDenied
                }
                throw error
            }
        }

        do {
            return try body(resolvedRoot.url)
        } catch {
            if isPermissionError(error) {
                throw IndexError.sourceDirectoryAccessDenied
            }
            throw error
        }
    }

    nonisolated private static func resolveMessagesSourceRoot() throws -> ResolvedMessagesSourceRoot {
        if let bookmarkedURL = bookmarkedMessagesSourceRootURL() {
            return ResolvedMessagesSourceRoot(url: bookmarkedURL, requiresSecurityScope: true)
        }

        if let bundledURL = bundledMessagesSourceRootURL() {
            return ResolvedMessagesSourceRoot(url: bundledURL, requiresSecurityScope: false)
        }

        if let legacyURL = legacyMessagesSourceRootURL() {
            return ResolvedMessagesSourceRoot(url: legacyURL, requiresSecurityScope: false)
        }

        throw IndexError.sourceDirectoryMissing
    }

    nonisolated private static func yamlOutputURL() throws -> URL {
        let applicationSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return applicationSupportURL
            .appendingPathComponent("Purchase Passport", isDirectory: true)
            .appendingPathComponent("provider_messages.yaml")
    }

    nonisolated private static func yamlString(for records: [ProviderMessageProviderRecord]) -> String {
        let yamlDateFormatter = makeYAMLDateFormatter()
        var lines: [String] = []
        lines.append("generated_at: \(yamlQuoted(yamlDateFormatter.string(from: .now)))")
        lines.append("source_root: \(yamlQuoted("data/Messages"))")
        lines.append("providers:")

        for record in records {
            lines.append("  - provider_key: \(yamlQuoted(record.providerKey))")
            lines.append("    provider_name: \(yamlQuoted(record.providerName))")
            lines.append("    conversation_count: \(record.conversations.count)")
            lines.append("    conversations:")

            if record.conversations.isEmpty {
                lines.append("      []")
                continue
            }

            for conversation in record.conversations {
                lines.append("      - file_name: \(yamlQuoted(conversation.fileName))")
                lines.append("        conversation_label: \(yamlQuoted(conversation.conversationLabel))")
                lines.append("        conversation_identifier: \(yamlQuoted(conversation.conversationIdentifier ?? ""))")
                lines.append("        matched_by:")
                for reason in conversation.matchReasons {
                    lines.append("          - \(yamlQuoted(reason))")
                }
                lines.append("        message_count: \(conversation.messageCount)")
                lines.append("        latest_message_at: \(yamlQuoted(conversation.latestMessageAt.map { yamlDateFormatter.string(from: $0) } ?? ""))")
                lines.append("        messages:")

                if conversation.messages.isEmpty {
                    lines.append("          []")
                    continue
                }

                for message in conversation.messages {
                    lines.append("          - occurred_at: \(yamlQuoted(yamlDateFormatter.string(from: message.occurredAt)))")
                    lines.append("            type: \(yamlQuoted(message.type))")
                    lines.append("            contact: \(yamlQuoted(message.contact))")
                    lines.append("            text: \(yamlQuoted(message.text))")
                    lines.append("            attachments:")
                    if message.attachments.isEmpty {
                        lines.append("              []")
                    } else {
                        for attachment in message.attachments {
                            lines.append("              - \(yamlQuoted(attachment))")
                        }
                    }
                }
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }

    nonisolated private static func yamlQuoted(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(escaped)\""
    }

    nonisolated private static func sanitizedConversationStem(_ stem: String) -> String {
        stem.replacingOccurrences(
            of: #"\(\d+\)$"#,
            with: "",
            options: .regularExpression
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func normalizePhoneNumber(_ value: String?) -> String? {
        guard let value else { return nil }
        let digits = value.filter(\.isNumber)
        return digits.isEmpty ? nil : digits
    }

    nonisolated private static func normalizeEmail(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.contains("@") ? trimmed : nil
    }

    nonisolated private static func normalizeName(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }

        let folded = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let scalarView = folded.unicodeScalars.map { scalar -> Character in
            if scalar == "&" {
                return " "
            }
            if CharacterSet.alphanumerics.contains(scalar) || scalar == "@" || scalar == "." {
                return Character(scalar)
            }
            return " "
        }

        let normalized = String(scalarView)
            .replacingOccurrences(of: "\\band\\b", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return normalized.isEmpty ? nil : normalized
    }

    nonisolated private static func bundledMessagesSourceRootURL() -> URL? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let bundledURL = resourceURL
            .appendingPathComponent("data", isDirectory: true)
            .appendingPathComponent("Messages", isDirectory: true)
        return directoryExists(at: bundledURL) ? bundledURL : nil
    }

    nonisolated private static func legacyMessagesSourceRootURL() -> URL? {
        let servicesDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceRoot = servicesDirectory
            .appendingPathComponent("data", isDirectory: true)
            .appendingPathComponent("Messages", isDirectory: true)
        return directoryExists(at: sourceRoot) ? sourceRoot : nil
    }

    nonisolated private static func bookmarkedMessagesSourceRootURL() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: messagesDirectoryBookmarkKey) else {
            return nil
        }

        var isStale = false
        guard let resolvedURL = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        if isStale,
           let refreshedBookmark = try? resolvedURL.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
           ) {
            UserDefaults.standard.set(refreshedBookmark, forKey: messagesDirectoryBookmarkKey)
        }

        return resolvedURL
    }

    nonisolated private static func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    nonisolated private static func directoryLooksLikeMessagesExport(_ url: URL) -> Bool {
        guard directoryExists(at: url) else { return false }
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return false
        }
        return fileURLs.contains { $0.pathExtension.lowercased() == "txt" }
    }

    nonisolated private static func isPermissionError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain, nsError.code == NSFileReadNoPermissionError {
            return true
        }
        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlyingError.domain == NSPOSIXErrorDomain,
           underlyingError.code == EPERM {
            return true
        }
        return false
    }
}
