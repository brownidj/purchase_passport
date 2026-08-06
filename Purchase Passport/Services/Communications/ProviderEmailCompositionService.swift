import Foundation

enum ProviderEmailCompositionService {
    static func composeMailURL(to recipient: String, subject: String, body: String) -> URL? {
        let trimmedRecipient = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRecipient.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = trimmedRecipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }

    static func replyRecipient(for correspondence: CorrespondenceRecord, provider: Organisation) -> String? {
        let providerAddresses = ProviderCorrespondenceService.emailAddresses(for: provider)
        let senderAddresses = ProviderCorrespondenceService.emailAddresses(in: correspondence.sender)
        let recipientAddresses = ProviderCorrespondenceService.emailAddresses(in: correspondence.recipients)

        if !providerAddresses.isDisjoint(with: senderAddresses) {
            return recipientAddresses.first
        }

        if let matchingRecipient = recipientAddresses.first(where: { providerAddresses.contains($0) }) {
            return matchingRecipient
        }

        return senderAddresses.first ?? recipientAddresses.first
    }

    static func replySubject(for subject: String) -> String {
        let trimmedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSubject.isEmpty else { return "Re:" }

        let lowercaseSubject = trimmedSubject.lowercased()
        if lowercaseSubject.hasPrefix("re:") || lowercaseSubject.hasPrefix("fw:") || lowercaseSubject.hasPrefix("fwd:") {
            return trimmedSubject
        }
        return "Re: \(trimmedSubject)"
    }
}
