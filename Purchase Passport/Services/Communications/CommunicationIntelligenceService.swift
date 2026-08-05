import Foundation
import SwiftData

enum CommunicationIntelligenceService {
    struct EmailEnvelope {
        let messageID: String?
        let threadID: String?
        let sender: String
        let recipients: [String]
        let subject: String
        let body: String
        let sentAt: Date
    }

    struct ExtractedArtifacts {
        let orderNumber: String?
        let trackingNumber: String?
        let rmaNumber: String?
        let warrantyExpiryDate: Date?
        let confidence: Double
    }

    struct ImportResult {
        let correspondence: CorrespondenceRecord
        let linkedPurchase: Purchase?
        let extractedArtifacts: ExtractedArtifacts
    }

    struct ApplyExtractionResult {
        let updatedFields: [String]
        let skippedFields: [String]
    }

    enum EmailFileImportError: LocalizedError {
        case unreadableFile
        case unsupportedFormat

        var errorDescription: String? {
            switch self {
            case .unreadableFile:
                return "The email file could not be read."
            case .unsupportedFormat:
                return "The selected file does not contain a readable email message."
            }
        }
    }

    static func importEmail(
        _ email: EmailEnvelope,
        into purchases: [Purchase],
        updating existingCorrespondence: CorrespondenceRecord? = nil
    ) -> ImportResult {
        let extractedArtifacts = extractArtifacts(from: email)
        let linkResult = linkPurchase(
            for: email,
            extractedArtifacts: extractedArtifacts,
            purchases: purchases
        )

        let correspondence = existingCorrespondence ?? CorrespondenceRecord(
            channel: .email,
            occurredAt: email.sentAt,
            subject: email.subject
        )
        let previousPurchase = correspondence.purchase

        correspondence.channel = .email
        correspondence.occurredAt = email.sentAt
        correspondence.sender = email.sender
        correspondence.recipients = email.recipients.joined(separator: ", ")
        correspondence.subject = email.subject
        correspondence.bodyPreview = previewText(from: email.body)
        correspondence.fullBody = email.body
        correspondence.externalMessageID = email.messageID
        correspondence.threadID = email.threadID
        correspondence.autoLinkConfidence = linkResult.confidence
        correspondence.extractionConfidence = extractedArtifacts.confidence
        correspondence.reviewStatus = linkResult.reviewStatus
        correspondence.extractedOrderNumber = extractedArtifacts.orderNumber
        correspondence.extractedTrackingNumber = extractedArtifacts.trackingNumber
        correspondence.extractedRMANumber = extractedArtifacts.rmaNumber
        correspondence.extractedWarrantyExpiryDate = extractedArtifacts.warrantyExpiryDate
        correspondence.updatedAt = .now
        correspondence.purchase = linkResult.purchase

        if previousPurchase?.persistentModelID != linkResult.purchase?.persistentModelID {
            previousPurchase?.updatedAt = .now
        }

        if let linkedPurchase = linkResult.purchase,
           !linkedPurchase.correspondences.contains(where: { $0.persistentModelID == correspondence.persistentModelID }) {
            linkedPurchase.correspondences.append(correspondence)
            linkedPurchase.updatedAt = .now
        }

        return ImportResult(
            correspondence: correspondence,
            linkedPurchase: linkResult.purchase,
            extractedArtifacts: extractedArtifacts
        )
    }

    @MainActor
    static func cleanupLegacyGeneratedEmailInteractions(in modelContext: ModelContext) throws {
        let correspondences = try modelContext.fetch(FetchDescriptor<CorrespondenceRecord>())
        for correspondence in correspondences {
            removeGeneratedInteractionIfNeeded(for: correspondence, in: modelContext)
        }

        let interactions = try modelContext.fetch(FetchDescriptor<Interaction>())
        for interaction in interactions where interaction.sourceCorrespondence != nil {
            interaction.purchase?.interactions.removeAll {
                $0.persistentModelID == interaction.persistentModelID
            }
            if let followUpReminder = interaction.followUpReminder {
                modelContext.delete(followUpReminder)
            }
            modelContext.delete(interaction)
        }

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    @discardableResult
    static func applyAcceptedExtractions(from correspondence: CorrespondenceRecord) -> ApplyExtractionResult {
        var updatedFields: [String] = []
        var skippedFields: [String] = []

        guard let purchase = correspondence.purchase else {
            skippedFields.append("No linked purchase.")
            correspondence.reviewStatus = .rejected
            correspondence.updatedAt = .now
            return ApplyExtractionResult(updatedFields: updatedFields, skippedFields: skippedFields)
        }

        if let extractedOrderNumber = normalized(correspondence.extractedOrderNumber) {
            if purchase.orderNumber != extractedOrderNumber {
                purchase.orderNumber = extractedOrderNumber
                updatedFields.append("Order Number")
            }
        } else {
            skippedFields.append("Order Number not found in correspondence.")
        }

        if let extractedWarrantyExpiryDate = correspondence.extractedWarrantyExpiryDate {
            if let warranty = purchase.warranties
                .sorted(by: { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) })
                .first {
                if warranty.endDate != extractedWarrantyExpiryDate {
                    warranty.endDate = extractedWarrantyExpiryDate
                    warranty.updatedAt = .now
                    updatedFields.append("Warranty Expiry")
                }
            } else {
                skippedFields.append("No warranty record available to update.")
            }
        } else {
            skippedFields.append("Warranty Expiry not found in correspondence.")
        }

        correspondence.reviewStatus = .accepted
        correspondence.updatedAt = .now
        purchase.updatedAt = .now

        return ApplyExtractionResult(updatedFields: updatedFields, skippedFields: skippedFields)
    }

    static func parseEmailFile(at url: URL) throws -> EmailEnvelope {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let messageData = extractRawMessageData(from: data)
        guard let rawMessage = decodeEmailData(messageData) else {
            throw EmailFileImportError.unreadableFile
        }

        let normalizedMessage = rawMessage.replacingOccurrences(of: "\r\n", with: "\n")
        let separatorRange = normalizedMessage.range(of: "\n\n")
        let headerText = separatorRange.map { String(normalizedMessage[..<$0.lowerBound]) } ?? normalizedMessage
        let bodyText = separatorRange.map { String(normalizedMessage[$0.upperBound...]) } ?? ""
        let headers = parseHeaders(from: headerText)

        guard !headers.isEmpty else {
            throw EmailFileImportError.unsupportedFormat
        }

        return EmailEnvelope(
            messageID: normalized(headers["message-id"]),
            threadID: normalized(headers["thread-index"]) ?? normalized(headers["in-reply-to"]),
            sender: normalized(headers["from"]) ?? "Unknown Sender",
            recipients: recipientList(from: [
                headers["to"],
                headers["cc"],
                headers["bcc"]
            ]),
            subject: normalized(headers["subject"]) ?? "Untitled Email",
            body: bodyText,
            sentAt: parsedDate(from: headers["date"]) ?? .now
        )
    }
}

private extension CommunicationIntelligenceService {
    struct LinkResult {
        let purchase: Purchase?
        let confidence: Double
        let reviewStatus: CorrespondenceReviewStatus
    }

    static func extractArtifacts(from email: EmailEnvelope) -> ExtractedArtifacts {
        let text = [email.subject, email.body].joined(separator: "\n")
        let normalized = text.lowercased()

        let orderNumber = firstCapture(
            in: text,
            pattern: #"(?i)\border(?:\s*(?:number|no\.?|#))?\s*[:#-]?\s*([A-Z0-9-]*\d[A-Z0-9-]{3,})\b"#
        )
        let trackingNumber = firstCapture(
            in: text,
            pattern: #"(?i)\btracking(?:\s*(?:number|no\.?|#))?\s*[:#-]?\s*([A-Z0-9-]*\d[A-Z0-9-]{4,})\b"#
        )
        let rmaNumber = firstCapture(
            in: text,
            pattern: #"(?i)\brma(?:\s*(?:number|no\.?|#))?\s*[:#-]?\s*([A-Z0-9-]*\d[A-Z0-9-]{2,})\b"#
        )

        let warrantyExpiryDate: Date? = {
            guard normalized.contains("warranty"), normalized.contains("expir") else { return nil }
            return firstDetectedDate(in: text)
        }()

        var evidenceCount = 0
        if orderNumber != nil { evidenceCount += 1 }
        if trackingNumber != nil { evidenceCount += 1 }
        if rmaNumber != nil { evidenceCount += 1 }
        if warrantyExpiryDate != nil { evidenceCount += 1 }
        let confidence = min(1.0, Double(evidenceCount) / 3.0)

        return ExtractedArtifacts(
            orderNumber: orderNumber,
            trackingNumber: trackingNumber,
            rmaNumber: rmaNumber,
            warrantyExpiryDate: warrantyExpiryDate,
            confidence: confidence
        )
    }

    static func linkPurchase(
        for email: EmailEnvelope,
        extractedArtifacts: ExtractedArtifacts,
        purchases: [Purchase]
    ) -> LinkResult {
        let normalizedCorpus = [email.subject, email.body, email.sender, email.recipients.joined(separator: " ")]
            .joined(separator: " ")
            .lowercased()
        let messageAddresses = structuredMessageAddresses(for: email)
        let messageDomains = Set(messageAddresses.compactMap(domain(from:)))
        let providerPurchaseCounts = Dictionary(
            grouping: purchases.compactMap { purchase in
                purchase.provider.map { ($0.persistentModelID, purchase) }
            },
            by: \.0
        ).mapValues(\.count)

        var bestPurchase: Purchase?
        var bestScore = 0
        var hasTieForBestScore = false

        for purchase in purchases {
            var score = 0

            if normalizedCorpus.contains(purchase.name.lowercased()) {
                score += 3
            }

            if let modelName = purchase.modelName?.lowercased(), !modelName.isEmpty, normalizedCorpus.contains(modelName) {
                score += 2
            }

            if let orderNumber = purchase.orderNumber?.lowercased(), !orderNumber.isEmpty, normalizedCorpus.contains(orderNumber) {
                score += 4
            }

            if let invoiceNumber = purchase.invoiceNumber?.lowercased(), !invoiceNumber.isEmpty, normalizedCorpus.contains(invoiceNumber) {
                score += 3
            }

            if let extractedOrder = extractedArtifacts.orderNumber?.lowercased(),
               let purchaseOrder = purchase.orderNumber?.lowercased(),
               extractedOrder == purchaseOrder {
                score += 5
            }

            if let provider = purchase.provider {
                if normalizedCorpus.contains(provider.name.lowercased()) {
                    score += 2
                }

                let providerAddressCount = providerPurchaseCounts[provider.persistentModelID] ?? 0
                let providerAddresses = ProviderCorrespondenceService.emailAddresses(for: provider)
                let providerDomains = ProviderCorrespondenceService.emailDomains(for: provider)
                let hasExactProviderAddressMatch = !providerAddresses.isDisjoint(with: messageAddresses)
                let hasProviderDomainMatch = providerDomains.contains { providerDomain in
                    messageDomains.contains { messageDomain in
                        domainMatches(messageDomain, providerDomain: providerDomain)
                    }
                }

                if hasExactProviderAddressMatch {
                    score += providerAddressCount == 1 ? 6 : 4
                } else if hasProviderDomainMatch {
                    score += providerAddressCount == 1 ? 4 : 2
                }
            }

            if score > bestScore {
                bestScore = score
                bestPurchase = purchase
                hasTieForBestScore = false
            } else if score == bestScore, score > 0 {
                hasTieForBestScore = true
            }
        }

        guard let bestPurchase else {
            return LinkResult(
                purchase: nil,
                confidence: 0,
                reviewStatus: .pendingReview
            )
        }

        let confidence = min(1.0, Double(bestScore) / 10.0)
        let isAutoLink = bestScore >= 6 && !hasTieForBestScore
        return LinkResult(
            purchase: isAutoLink ? bestPurchase : nil,
            confidence: confidence,
            reviewStatus: isAutoLink ? .autoLinked : .pendingReview
        )
    }

    nonisolated static func previewText(from body: String, maxLength: Int = 240) -> String {
        let flattened = body
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard flattened.count > maxLength else { return flattened }
        let endIndex = flattened.index(flattened.startIndex, offsetBy: maxLength)
        return String(flattened[..<endIndex]) + "…"
    }

    nonisolated static func firstCapture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1 else {
            return nil
        }
        guard let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[captureRange])
    }

    nonisolated static func firstDetectedDate(in text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector.matches(in: text, range: range).first?.date
    }

    nonisolated static func domain(from emailAddress: String) -> String? {
        let parts = emailAddress.lowercased().split(separator: "@")
        guard parts.count == 2 else { return nil }
        return String(parts[1])
    }

    nonisolated static func structuredMessageAddresses(for email: EmailEnvelope) -> Set<String> {
        extractedEmails(from: [email.sender, email.recipients.joined(separator: ", ")].joined(separator: " "))
    }

    nonisolated static func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    nonisolated static func extractedEmails(from text: String) -> Set<String> {
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

    nonisolated static func domainMatches(_ messageDomain: String, providerDomain: String) -> Bool {
        let normalizedMessageDomain = messageDomain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedProviderDomain = providerDomain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedMessageDomain.isEmpty, !normalizedProviderDomain.isEmpty else {
            return false
        }

        return normalizedMessageDomain == normalizedProviderDomain
            || normalizedMessageDomain.hasSuffix("." + normalizedProviderDomain)
    }

    static func decodeEmailData(_ data: Data) -> String? {
        let encodings: [String.Encoding] = [.utf8, .ascii, .isoLatin1, .utf16]
        for encoding in encodings {
            if let value = String(data: data, encoding: encoding) {
                return value
            }
        }
        return nil
    }

    static func extractRawMessageData(from data: Data) -> Data {
        guard let newlineIndex = data.firstIndex(of: 0x0A) else {
            return data
        }

        let firstLineData = data[..<newlineIndex]
        guard let byteCountString = String(data: firstLineData, encoding: .ascii)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !byteCountString.isEmpty,
              byteCountString.allSatisfy(\.isNumber),
              let byteCount = Int(byteCountString) else {
            return data
        }

        let contentStart = data.index(after: newlineIndex)
        guard byteCount > 0, data.distance(from: contentStart, to: data.endIndex) >= byteCount else {
            return data
        }

        let messageEnd = data.index(contentStart, offsetBy: byteCount)
        return Data(data[contentStart..<messageEnd])
    }

    static func parseHeaders(from headerText: String) -> [String: String] {
        let lines = headerText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var unfoldedLines: [String] = []

        for line in lines {
            if let last = unfoldedLines.last, line.hasPrefix(" ") || line.hasPrefix("\t") {
                unfoldedLines[unfoldedLines.count - 1] = last + " " + line.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                unfoldedLines.append(line)
            }
        }

        var headers: [String: String] = [:]
        for line in unfoldedLines {
            guard let separatorIndex = line.firstIndex(of: ":") else { continue }
            let key = line[..<separatorIndex].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = line[line.index(after: separatorIndex)...].trimmingCharacters(in: .whitespacesAndNewlines)
            headers[key] = value
        }

        return headers
    }

    static func recipientList(from rawValues: [String?]) -> [String] {
        let values = rawValues.compactMap { value -> String? in
            guard let value else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        guard !values.isEmpty else { return [] }

        let combined = values.joined(separator: ", ")
        let pattern = #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return values
        }
        let range = NSRange(combined.startIndex..<combined.endIndex, in: combined)
        let matches = regex.matches(in: combined, options: [], range: range)
        let recipients = matches.compactMap { match -> String? in
            guard let matchRange = Range(match.range, in: combined) else { return nil }
            return String(combined[matchRange])
        }
        return recipients.isEmpty ? values : Array(Set(recipients.map { $0.lowercased() })).sorted()
    }

    static func parsedDate(from rawValue: String?) -> Date? {
        guard let rawValue, !rawValue.isEmpty else { return nil }
        let candidate = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        let formatters = [
            makeDateFormatter("EEE, d MMM yyyy HH:mm:ss Z"),
            makeDateFormatter("EEE, dd MMM yyyy HH:mm:ss Z"),
            makeDateFormatter("d MMM yyyy HH:mm:ss Z"),
            makeDateFormatter("dd MMM yyyy HH:mm:ss Z")
        ]

        for formatter in formatters {
            if let date = formatter.date(from: candidate) {
                return date
            }
        }

        return nil
    }

    static func makeDateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }

    @MainActor
    static func removeGeneratedInteractionIfNeeded(
        for correspondence: CorrespondenceRecord,
        in modelContext: ModelContext
    ) {
        guard let interaction = correspondence.generatedInteraction else { return }

        interaction.purchase?.interactions.removeAll {
            $0.persistentModelID == interaction.persistentModelID
        }

        if let followUpReminder = interaction.followUpReminder {
            modelContext.delete(followUpReminder)
        }

        correspondence.generatedInteraction = nil
        modelContext.delete(interaction)
    }

}
