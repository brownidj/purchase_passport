import AppKit
import EventKit
import Foundation

enum ProviderCalendarAuthorizationState: Equatable {
    case notDetermined
    case denied
    case restricted
    case writeOnly
    case fullAccess

    var canReadEvents: Bool {
        switch self {
        case .fullAccess:
            return true
        case .notDetermined, .denied, .restricted, .writeOnly:
            return false
        }
    }
}

struct ProviderCalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarTitle: String
    let location: String?
    let notesExcerpt: String?
    let matchReason: String
}

struct ProviderCalendarDebugEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarTitle: String
    let didMatch: Bool
    let matchedReasons: [String]
    let matchedTokenCount: Int
    let overlappingTokens: [String]
    let titleField: String?
    let locationField: String?
    let notesField: String?
    let organizerField: String?
    let attendeeFields: [String]
    let urlField: String?
}

@MainActor
final class ProviderCalendarService {
    static let shared = ProviderCalendarService()
    static let lookbackYears = 3
    static let lookaheadYears = 1

    private let eventStore = EKEventStore()

    private init() {}

    static func currentAuthorizationState() -> ProviderCalendarAuthorizationState {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14.0, *) {
            switch status {
            case .notDetermined:
                return .notDetermined
            case .restricted:
                return .restricted
            case .denied:
                return .denied
            case .writeOnly:
                return .writeOnly
            case .fullAccess:
                return .fullAccess
            @unknown default:
                return .denied
            }
        } else {
            switch status {
            case .notDetermined:
                return .notDetermined
            case .restricted:
                return .restricted
            case .denied:
                return .denied
            case .writeOnly:
                return .writeOnly
            case .fullAccess:
                return .fullAccess
            case .authorized:
                return .fullAccess
            @unknown default:
                return .denied
            }
        }
    }

    func requestFullAccess() async throws -> Bool {
        if #available(macOS 14.0, *) {
            return try await eventStore.requestFullAccessToEvents()
        } else {
            return try await eventStore.requestAccess(to: .event)
        }
    }

    func relatedEvents(
        for provider: Organisation,
        linkedPurchases: [Purchase],
        referenceDate: Date = .now
    ) -> [ProviderCalendarEvent] {
        guard Self.currentAuthorizationState().canReadEvents else { return [] }

        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -Self.lookbackYears, to: referenceDate) ?? referenceDate
        let end = calendar.date(byAdding: .year, value: Self.lookaheadYears, to: referenceDate) ?? referenceDate
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let matcher = ProviderCalendarMatcher(provider: provider, linkedPurchases: linkedPurchases)

        return eventStore.events(matching: predicate)
            .compactMap { matcher.match(for: $0) }
            .sorted { lhs, rhs in
                Self.sortEvents(lhs, rhs, referenceDate: referenceDate)
            }
    }

    func debugEvents(
        for provider: Organisation,
        linkedPurchases: [Purchase],
        referenceDate: Date = .now
    ) -> [ProviderCalendarDebugEvent] {
        guard Self.currentAuthorizationState().canReadEvents else { return [] }

        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -Self.lookbackYears, to: referenceDate) ?? referenceDate
        let end = calendar.date(byAdding: .year, value: Self.lookaheadYears, to: referenceDate) ?? referenceDate
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let matcher = ProviderCalendarMatcher(provider: provider, linkedPurchases: linkedPurchases)

        return eventStore.events(matching: predicate)
            .compactMap { matcher.debugEvent(for: $0) }
            .sorted { lhs, rhs in
                Self.sortDebugEvents(lhs, rhs, referenceDate: referenceDate)
            }
    }

    func openCalendarApp() -> Bool {
        guard let calendarAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") else {
            return false
        }
        return NSWorkspace.shared.open(calendarAppURL)
    }

    private static func sortEvents(
        _ lhs: ProviderCalendarEvent,
        _ rhs: ProviderCalendarEvent,
        referenceDate: Date
    ) -> Bool {
        let lhsIsUpcoming = lhs.endDate >= referenceDate
        let rhsIsUpcoming = rhs.endDate >= referenceDate

        switch (lhsIsUpcoming, rhsIsUpcoming) {
        case (true, false):
            return true
        case (false, true):
            return false
        case (true, true):
            return lhs.startDate < rhs.startDate
        case (false, false):
            return lhs.startDate > rhs.startDate
        }
    }

    private static func sortDebugEvents(
        _ lhs: ProviderCalendarDebugEvent,
        _ rhs: ProviderCalendarDebugEvent,
        referenceDate: Date
    ) -> Bool {
        let lhsIsUpcoming = lhs.endDate >= referenceDate
        let rhsIsUpcoming = rhs.endDate >= referenceDate

        switch (lhsIsUpcoming, rhsIsUpcoming) {
        case (true, false):
            return true
        case (false, true):
            return false
        case (true, true):
            if lhs.didMatch != rhs.didMatch {
                return lhs.didMatch && !rhs.didMatch
            }
            return lhs.startDate < rhs.startDate
        case (false, false):
            if lhs.didMatch != rhs.didMatch {
                return lhs.didMatch && !rhs.didMatch
            }
            return lhs.startDate > rhs.startDate
        }
    }

    static var searchWindowDescription: String {
        "last \(lookbackYears) years and next \(lookaheadYears * 12) months"
    }
}

private struct ProviderCalendarMatcher {
    private struct TextNeedle {
        let value: String
        let reason: String
        let tokens: [String]
        let exactOnly: Bool
        let minimumTokenOverlap: Int
    }

    private struct DigitNeedle {
        let value: String
        let reason: String
    }

    private let textNeedles: [TextNeedle]
    private let digitNeedles: [DigitNeedle]

    private struct MatchEvaluation {
        let matchedReasons: [String]
        let overlappingTokens: [String]
        let searchableFields: SearchableFields

        var didMatch: Bool {
            !matchedReasons.isEmpty
        }

        var hasCandidateSignal: Bool {
            didMatch || !overlappingTokens.isEmpty
        }
    }

    private struct SearchableFields {
        let title: String?
        let location: String?
        let notes: String?
        let calendarTitle: String
        let url: String?
        let organizer: String?
        let attendees: [String]

        var all: [String] {
            ([title, location, notes, calendarTitle, url, organizer] + attendees)
                .compactMap { $0?.trimmedNilIfEmpty }
        }
    }

    init(provider: Organisation, linkedPurchases: [Purchase]) {
        var textNeedles: [TextNeedle] = []
        var digitNeedles: [DigitNeedle] = []

        Self.appendTextNeedle(provider.name, reason: "Provider name", to: &textNeedles)
        Self.appendTextNeedle(provider.emailAddress, reason: "Provider email", to: &textNeedles)
        Self.appendDigitNeedle(provider.phoneNumber, reason: "Provider phone", to: &digitNeedles)
        Self.appendDigitNeedle(provider.customerServiceNumber, reason: "Customer service number", to: &digitNeedles)

        for contact in provider.contacts {
            Self.appendTextNeedle(contact.name, reason: "Contact name", to: &textNeedles)
            Self.appendTextNeedle(contact.emailAddress, reason: "Contact email", to: &textNeedles)
            Self.appendDigitNeedle(contact.phoneNumber, reason: "Contact phone", to: &digitNeedles)
        }

        for purchase in linkedPurchases {
            Self.appendTextNeedle(purchase.name, reason: "Linked purchase", to: &textNeedles)
        }

        self.textNeedles = textNeedles
        self.digitNeedles = digitNeedles
    }

    func match(for event: EKEvent) -> ProviderCalendarEvent? {
        let evaluation = evaluate(event)
        guard evaluation.didMatch else { return nil }

        return ProviderCalendarEvent(
            id: event.eventIdentifier ?? "\(event.calendarItemIdentifier)-\(event.startDate.timeIntervalSinceReferenceDate)",
            title: event.title?.trimmedNilIfEmpty ?? "Untitled Event",
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay,
            calendarTitle: event.calendar.title,
            location: event.location?.trimmedNilIfEmpty,
            notesExcerpt: boundedExcerpt(event.notes?.trimmedNilIfEmpty, limit: 500),
            matchReason: evaluation.matchedReasons.joined(separator: ", ")
        )
    }

    func debugEvent(for event: EKEvent) -> ProviderCalendarDebugEvent? {
        let evaluation = evaluate(event)
        guard evaluation.hasCandidateSignal else { return nil }

        return ProviderCalendarDebugEvent(
            id: event.eventIdentifier ?? "\(event.calendarItemIdentifier)-\(event.startDate.timeIntervalSinceReferenceDate)",
            title: event.title?.trimmedNilIfEmpty ?? "Untitled Event",
            startDate: event.startDate,
            endDate: event.endDate,
            calendarTitle: event.calendar.title,
            didMatch: evaluation.didMatch,
            matchedReasons: evaluation.matchedReasons,
            matchedTokenCount: evaluation.overlappingTokens.count,
            overlappingTokens: evaluation.overlappingTokens,
            titleField: evaluation.searchableFields.title,
            locationField: evaluation.searchableFields.location,
            notesField: evaluation.searchableFields.notes,
            organizerField: evaluation.searchableFields.organizer,
            attendeeFields: evaluation.searchableFields.attendees,
            urlField: evaluation.searchableFields.url
        )
    }

    private func evaluate(_ event: EKEvent) -> MatchEvaluation {
        let fields = searchableFields(for: event)
        let normalizedFieldTexts = fields.all.compactMap(Self.normalizeText)
        let normalizedText = normalizedFieldTexts.joined(separator: "\n").trimmedNilIfEmpty
        let normalizedDigits = Self.normalizeDigits(fields.all.joined(separator: " "))
        let normalizedTokens = normalizedText.map(Self.tokenize(normalizedText:)) ?? []
        let tokenSet = Set(normalizedTokens)

        var reasons: [String] = []
        var overlappingTokens: [String] = []

        for needle in textNeedles {
            if matches(
                needle,
                normalizedFieldTexts: normalizedFieldTexts,
                normalizedTokens: normalizedTokens
            ) {
                if !reasons.contains(needle.reason) {
                    reasons.append(needle.reason)
                }
            }

            for token in needle.tokens where tokenSet.contains(token) {
                if !overlappingTokens.contains(token) {
                    overlappingTokens.append(token)
                }
            }
        }

        for needle in digitNeedles where normalizedDigits?.contains(needle.value) == true {
            if !reasons.contains(needle.reason) {
                reasons.append(needle.reason)
            }
        }

        return MatchEvaluation(
            matchedReasons: reasons,
            overlappingTokens: overlappingTokens,
            searchableFields: fields
        )
    }

    private func searchableFields(for event: EKEvent) -> SearchableFields {
        let attendeeNames = (event.attendees ?? [])
            .compactMap { $0.name?.trimmedNilIfEmpty }
        let attendeeURLs = (event.attendees ?? [])
            .compactMap { $0.url.absoluteString.trimmedNilIfEmpty }

        return SearchableFields(
            title: event.title?.trimmedNilIfEmpty,
            location: event.location?.trimmedNilIfEmpty,
            notes: event.notes?.trimmedNilIfEmpty,
            calendarTitle: event.calendar.title,
            url: event.url?.absoluteString.trimmedNilIfEmpty,
            organizer: event.organizer.map {
                [$0.name?.trimmedNilIfEmpty, $0.url.absoluteString.trimmedNilIfEmpty]
                    .compactMap { $0 }
                    .joined(separator: " • ")
                    .trimmedNilIfEmpty
            } ?? nil,
            attendees: attendeeNames + attendeeURLs
        )
    }

    private static func appendTextNeedle(
        _ source: String?,
        reason: String,
        to collection: inout [TextNeedle]
    ) {
        guard let value = Self.normalizeText(source), value.count >= 3 else { return }
        let tokens = Self.tokenize(normalizedText: value)
        guard collection.contains(where: { $0.value == value }) == false else { return }
        guard tokens.isEmpty == false else { return }
        let exactOnly = source?.contains("@") == true
        collection.append(
            TextNeedle(
                value: value,
                reason: reason,
                tokens: tokens,
                exactOnly: exactOnly,
                minimumTokenOverlap: minimumTokenOverlap(for: tokens)
            )
        )
    }

    private static func appendDigitNeedle(
        _ source: String?,
        reason: String,
        to collection: inout [DigitNeedle]
    ) {
        guard let value = Self.normalizeDigits(source), value.count >= 6 else { return }
        guard collection.contains(where: { $0.value == value }) == false else { return }
        collection.append(DigitNeedle(value: value, reason: reason))
    }

    nonisolated private static func normalizeText(_ value: String?) -> String? {
        guard let value = value?.trimmedNilIfEmpty else { return nil }

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

        return normalized.isEmpty ? nil : normalized.lowercased()
    }

    nonisolated private static func tokenize(normalizedText: String) -> [String] {
        normalizedText
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count >= 3 }
    }

    private func matches(
        _ needle: TextNeedle,
        normalizedFieldTexts: [String],
        normalizedTokens: [String]
    ) -> Bool {
        if normalizedFieldTexts.contains(where: { $0.contains(needle.value) }) {
            return true
        }
        guard needle.exactOnly == false, needle.tokens.isEmpty == false else {
            return false
        }

        let tokenSet = Set(normalizedTokens)
        let overlapCount = needle.tokens.filter { tokenSet.contains($0) }.count
        return overlapCount >= needle.minimumTokenOverlap
    }

    nonisolated private static func minimumTokenOverlap(for tokens: [String]) -> Int {
        tokens.count <= 1 ? 1 : 2
    }

    nonisolated private static func normalizeDigits(_ value: String?) -> String? {
        guard let value = value?.trimmedNilIfEmpty else { return nil }
        let digits = value.filter(\.isNumber)
        return digits.isEmpty ? nil : digits
    }

    private func boundedExcerpt(_ value: String?, limit: Int) -> String? {
        guard let value else { return nil }
        let normalized = value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let prefix = String(normalized.prefix(limit))
        if normalized.count > limit {
            return prefix + "\n\n[More in Calendar]"
        }
        return prefix
    }
}

private extension String {
    nonisolated var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
