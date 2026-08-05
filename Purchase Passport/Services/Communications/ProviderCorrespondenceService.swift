import Foundation
import SwiftData

enum ProviderCorrespondenceService {
    static func linkedCorrespondences(
        for provider: Organisation,
        correspondences: [CorrespondenceRecord]
    ) -> [CorrespondenceRecord] {
        let providerAddresses = emailAddresses(for: provider)

        return correspondences
            .filter { correspondence in
                if correspondence.purchase?.provider?.persistentModelID == provider.persistentModelID {
                    return true
                }

                guard !providerAddresses.isEmpty else { return false }
                let correspondenceAddresses = addresses(in: correspondence)
                return !providerAddresses.isDisjoint(with: correspondenceAddresses)
            }
            .sorted(by: { $0.occurredAt > $1.occurredAt })
    }

    static func matches(
        _ email: CommunicationIntelligenceService.EmailEnvelope,
        provider: Organisation
    ) -> Bool {
        let providerAddresses = emailAddresses(for: provider)
        let providerDomains = emailDomains(for: provider)
        let corpus = [email.sender, email.recipients.joined(separator: ", "), email.subject, email.body]
            .joined(separator: " ")
            .lowercased()

        if corpus.contains(provider.name.lowercased()) {
            return true
        }

        let messageAddresses = extractedEmails(from: email.sender)
            .union(extractedEmails(from: email.recipients.joined(separator: ", ")))
            .union(extractedEmails(from: email.body))
        if !providerAddresses.isDisjoint(with: messageAddresses) {
            return true
        }

        let messageDomains = Set(messageAddresses.compactMap(domain(from:)))
        return providerDomains.contains { providerDomain in
            messageDomains.contains { messageDomain in
                domainMatches(messageDomain, providerDomain: providerDomain)
            }
        }
    }

    static func emailAddresses(for provider: Organisation) -> Set<String> {
        var addresses = Set<String>()

        if let email = normalizedEmail(provider.emailAddress) {
            addresses.insert(email)
        }

        for contact in provider.contacts {
            if let email = normalizedEmail(contact.emailAddress) {
                addresses.insert(email)
            }
        }

        return addresses
    }

    static func emailDomains(for provider: Organisation) -> Set<String> {
        var domains = Set(emailAddresses(for: provider).compactMap(domain(from:)))

        if let websiteDomain = websiteDomain(from: provider.website) {
            domains.insert(websiteDomain)
        }

        return domains
    }

    static func addresses(in correspondence: CorrespondenceRecord) -> Set<String> {
        var values = Set<String>()

        for address in extractedEmails(from: correspondence.sender) {
            values.insert(address)
        }
        for address in extractedEmails(from: correspondence.recipients) {
            values.insert(address)
        }

        return values
    }

    static func mailMessageURL(for externalMessageID: String?) -> URL? {
        guard var value = externalMessageID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        if !value.hasPrefix("<") { value = "<\(value)" }
        if !value.hasSuffix(">") { value = "\(value)>" }
        guard let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return nil
        }
        return URL(string: "message://\(encoded)")
    }
}

private extension ProviderCorrespondenceService {
    nonisolated static func normalizedEmail(_ value: String?) -> String? {
        guard let value else { return nil }
        let candidate = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard candidate.contains("@") else { return nil }
        return candidate
    }

    nonisolated static func extractedEmails(from text: String?) -> Set<String> {
        guard let text, !text.isEmpty else { return [] }
        let pattern = #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)
        return Set(matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return text[range].lowercased()
        })
    }

    nonisolated static func domain(from email: String) -> String? {
        let components = email.split(separator: "@", omittingEmptySubsequences: false)
        guard components.count == 2 else { return nil }
        let domain = String(components[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        return domain.isEmpty ? nil : domain
    }

    nonisolated static func domainMatches(_ messageDomain: String, providerDomain: String) -> Bool {
        let normalizedMessageDomain = messageDomain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedProviderDomain = providerDomain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedMessageDomain.isEmpty, !normalizedProviderDomain.isEmpty else {
            return false
        }

        return normalizedMessageDomain == normalizedProviderDomain
            || normalizedMessageDomain.hasSuffix("." + normalizedProviderDomain)
    }

    nonisolated static func websiteDomain(from website: String?) -> String? {
        guard let website = website?.trimmingCharacters(in: .whitespacesAndNewlines),
              !website.isEmpty else {
            return nil
        }

        let normalizedWebsite = website.contains("://") ? website : "https://\(website)"
        guard let host = URL(string: normalizedWebsite)?.host?.lowercased() else {
            return nil
        }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
