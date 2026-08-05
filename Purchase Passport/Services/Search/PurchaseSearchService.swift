import Foundation

enum PurchaseSearchSortOption: String, CaseIterable, Codable, Identifiable {
    case mostRecent
    case oldest
    case name
    case purchaseValueHighToLow
    case purchaseValueLowToHigh
    case warrantyExpirySoonest
    case nextReminderSoonest
    case category

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mostRecent:
            return "Most Recent"
        case .oldest:
            return "Oldest"
        case .name:
            return "Name"
        case .purchaseValueHighToLow:
            return "Purchase Value (High-Low)"
        case .purchaseValueLowToHigh:
            return "Purchase Value (Low-High)"
        case .warrantyExpirySoonest:
            return "Warranty Expiry"
        case .nextReminderSoonest:
            return "Next Reminder"
        case .category:
            return "Category"
        }
    }
}

enum WarrantySearchFilter: String, CaseIterable, Codable, Identifiable {
    case any
    case active
    case expiringSoon
    case expired

    var id: String { rawValue }

    var title: String {
        switch self {
        case .any:
            return "Any Warranty"
        case .active:
            return "Active Warranty"
        case .expiringSoon:
            return "Warranty Expiring Soon"
        case .expired:
            return "Expired Warranty"
        }
    }
}

struct PurchaseSearchFilters: Codable, Equatable {
    var categoryName: String?
    var status: PurchaseStatus?
    var purchaseDateFrom: Date?
    var purchaseDateTo: Date?
    var warrantyFilter: WarrantySearchFilter
    var unresolvedIssueOnly: Bool
    var upcomingReminderOnly: Bool
    var activeComplaintOnly: Bool
    var serviceDueOnly: Bool
    var includeArchived: Bool

    init(
        categoryName: String? = nil,
        status: PurchaseStatus? = nil,
        purchaseDateFrom: Date? = nil,
        purchaseDateTo: Date? = nil,
        warrantyFilter: WarrantySearchFilter = .any,
        unresolvedIssueOnly: Bool = false,
        upcomingReminderOnly: Bool = false,
        activeComplaintOnly: Bool = false,
        serviceDueOnly: Bool = false,
        includeArchived: Bool = false
    ) {
        self.categoryName = categoryName
        self.status = status
        self.purchaseDateFrom = purchaseDateFrom
        self.purchaseDateTo = purchaseDateTo
        self.warrantyFilter = warrantyFilter
        self.unresolvedIssueOnly = unresolvedIssueOnly
        self.upcomingReminderOnly = upcomingReminderOnly
        self.activeComplaintOnly = activeComplaintOnly
        self.serviceDueOnly = serviceDueOnly
        self.includeArchived = includeArchived
    }

    static let `default` = PurchaseSearchFilters()
}

struct SavedPurchaseSearch: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var query: String
    var filters: PurchaseSearchFilters
    var sortOption: PurchaseSearchSortOption

    init(
        id: UUID = UUID(),
        name: String,
        query: String,
        filters: PurchaseSearchFilters,
        sortOption: PurchaseSearchSortOption
    ) {
        self.id = id
        self.name = name
        self.query = query
        self.filters = filters
        self.sortOption = sortOption
    }
}

enum PurchaseSearchService {
    static func search(
        purchases: [Purchase],
        query: String,
        filters: PurchaseSearchFilters,
        sortOption: PurchaseSearchSortOption,
        referenceDate: Date = .now
    ) -> [Purchase] {
        let tokens = query
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map(String.init)

        let filtered = purchases.filter { purchase in
            matchesArchiveFilter(purchase: purchase, includeArchived: filters.includeArchived)
                && matchesQuery(purchase: purchase, tokens: tokens)
                && matchesCategory(purchase: purchase, categoryName: filters.categoryName)
                && matchesStatus(purchase: purchase, status: filters.status)
                && matchesPurchaseDateRange(
                    purchase: purchase,
                    from: filters.purchaseDateFrom,
                    to: filters.purchaseDateTo
                )
                && matchesWarrantyFilter(
                    purchase: purchase,
                    warrantyFilter: filters.warrantyFilter,
                    referenceDate: referenceDate
                )
                && matchesUnresolvedIssueFilter(
                    purchase: purchase,
                    unresolvedIssueOnly: filters.unresolvedIssueOnly
                )
                && matchesUpcomingReminderFilter(
                    purchase: purchase,
                    upcomingReminderOnly: filters.upcomingReminderOnly,
                    referenceDate: referenceDate
                )
                && matchesActiveComplaintFilter(
                    purchase: purchase,
                    activeComplaintOnly: filters.activeComplaintOnly
                )
                && matchesServiceDueFilter(
                    purchase: purchase,
                    serviceDueOnly: filters.serviceDueOnly,
                    referenceDate: referenceDate
                )
        }

        return sort(filtered, by: sortOption)
    }

    static func decodeSavedSearches(from json: String) -> [SavedPurchaseSearch] {
        guard let data = json.data(using: .utf8) else { return [] }

        do {
            return try JSONDecoder().decode([SavedPurchaseSearch].self, from: data)
        } catch {
            return []
        }
    }

    static func encodeSavedSearches(_ searches: [SavedPurchaseSearch]) -> String {
        do {
            let data = try JSONEncoder().encode(searches)
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            return "[]"
        }
    }

    private static func matchesArchiveFilter(purchase: Purchase, includeArchived: Bool) -> Bool {
        includeArchived || purchase.status != .archived
    }

    private static func matchesQuery(purchase: Purchase, tokens: [String]) -> Bool {
        guard !tokens.isEmpty else { return true }

        let haystack = searchableText(for: purchase)
        return tokens.allSatisfy { haystack.contains($0) }
    }

    private static func searchableText(for purchase: Purchase) -> String {
        var fields: [String] = [purchase.name, purchase.status.rawValue]

        fields.append(contentsOf: [
            purchase.shortDescription,
            purchase.notes,
            purchase.seller,
            purchase.manufacturer,
            purchase.modelName,
            purchase.serialNumber,
            purchase.invoiceNumber,
            purchase.orderNumber,
            purchase.purchaseLocation,
            purchase.storageLocation,
            purchase.category?.name
        ].compactMap { $0 })

        fields.append(purchase.contacts.compactMap { $0.organisation?.name }.joined(separator: " "))
        fields.append(purchase.contacts.map(\.name).joined(separator: " "))
        fields.append(purchase.tags.map(\.name).joined(separator: " "))
        fields.append(purchase.documents.compactMap(\.title).joined(separator: " "))
        fields.append(purchase.documents.compactMap(\.originalFilename).joined(separator: " "))
        fields.append(purchase.warranties.compactMap(\.title).joined(separator: " "))
        fields.append(purchase.warranties.compactMap(\.provider).joined(separator: " "))
        fields.append(purchase.interactions.compactMap(\.subject).joined(separator: " "))
        fields.append(purchase.interactions.compactMap(\.summary).joined(separator: " "))
        fields.append(purchase.correspondences.compactMap(\.sender).joined(separator: " "))
        fields.append(purchase.correspondences.compactMap(\.recipients).joined(separator: " "))
        fields.append(purchase.correspondences.compactMap(\.subject).joined(separator: " "))
        fields.append(purchase.correspondences.compactMap(\.bodyPreview).joined(separator: " "))
        fields.append(purchase.correspondences.compactMap(\.fullBody).joined(separator: " "))
        fields.append(purchase.repairRecords.compactMap(\.diagnosis).joined(separator: " "))
        fields.append(purchase.repairRecords.compactMap(\.workPerformed).joined(separator: " "))
        fields.append(purchase.faultRecords.compactMap(\.title).joined(separator: " "))
        fields.append(purchase.faultRecords.compactMap(\.detailedDescription).joined(separator: " "))

        return fields
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()
    }

    private static func matchesCategory(purchase: Purchase, categoryName: String?) -> Bool {
        guard let categoryName, !categoryName.isEmpty else { return true }
        return purchase.category?.name == categoryName
    }

    private static func matchesStatus(purchase: Purchase, status: PurchaseStatus?) -> Bool {
        guard let status else { return true }
        return purchase.status == status
    }

    private static func matchesPurchaseDateRange(purchase: Purchase, from: Date?, to: Date?) -> Bool {
        guard from != nil || to != nil else { return true }
        guard let purchaseDate = purchase.purchaseDate else { return false }

        if let from, purchaseDate < from {
            return false
        }

        if let to, purchaseDate > to {
            return false
        }

        return true
    }

    private static func matchesWarrantyFilter(
        purchase: Purchase,
        warrantyFilter: WarrantySearchFilter,
        referenceDate: Date
    ) -> Bool {
        guard warrantyFilter != .any else { return true }

        let statuses = purchase.warranties.map { WarrantyStatusService.status(for: $0, asOf: referenceDate) }

        switch warrantyFilter {
        case .any:
            return true
        case .active:
            return statuses.contains(.active)
        case .expiringSoon:
            return statuses.contains(.expiringSoon)
        case .expired:
            return statuses.contains(.expired)
        }
    }

    private static func matchesUnresolvedIssueFilter(
        purchase: Purchase,
        unresolvedIssueOnly: Bool
    ) -> Bool {
        guard unresolvedIssueOnly else { return true }
        return purchase.faultRecords.contains { $0.status != .resolved && $0.status != .closed }
    }

    private static func matchesUpcomingReminderFilter(
        purchase: Purchase,
        upcomingReminderOnly: Bool,
        referenceDate: Date
    ) -> Bool {
        guard upcomingReminderOnly else { return true }
        guard let upperBound = Calendar.current.date(byAdding: .day, value: 30, to: referenceDate) else {
            return false
        }

        return purchase.reminders.contains {
            !$0.isCompleted && $0.dueDate >= referenceDate && $0.dueDate <= upperBound
        }
    }

    private static func matchesActiveComplaintFilter(
        purchase: Purchase,
        activeComplaintOnly: Bool
    ) -> Bool {
        guard activeComplaintOnly else { return true }

        return purchase.complaintCases.contains {
            $0.status != .resolved && $0.status != .closed
        }
    }

    private static func matchesServiceDueFilter(
        purchase: Purchase,
        serviceDueOnly: Bool,
        referenceDate: Date
    ) -> Bool {
        guard serviceDueOnly else { return true }
        guard let upperBound = Calendar.current.date(byAdding: .day, value: 30, to: referenceDate) else {
            return false
        }

        return purchase.serviceRecords.contains {
            guard let nextServiceDate = $0.nextServiceDate else { return false }
            return nextServiceDate >= referenceDate && nextServiceDate <= upperBound
        }
    }

    private static func sort(_ purchases: [Purchase], by option: PurchaseSearchSortOption) -> [Purchase] {
        switch option {
        case .mostRecent:
            return purchases.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return purchases.sorted { $0.createdAt < $1.createdAt }
        case .name:
            return purchases.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .purchaseValueHighToLow:
            return purchases.sorted { ($0.purchasePrice ?? 0) > ($1.purchasePrice ?? 0) }
        case .purchaseValueLowToHigh:
            return purchases.sorted { ($0.purchasePrice ?? 0) < ($1.purchasePrice ?? 0) }
        case .warrantyExpirySoonest:
            return purchases.sorted {
                earliestWarrantyEndDate(for: $0) < earliestWarrantyEndDate(for: $1)
            }
        case .nextReminderSoonest:
            return purchases.sorted {
                nextReminderDate(for: $0) < nextReminderDate(for: $1)
            }
        case .category:
            return purchases.sorted {
                ($0.category?.name ?? "").localizedCaseInsensitiveCompare($1.category?.name ?? "") == .orderedAscending
            }
        }
    }

    private static func earliestWarrantyEndDate(for purchase: Purchase) -> Date {
        purchase.warranties.compactMap(\.endDate).min() ?? .distantFuture
    }

    private static func nextReminderDate(for purchase: Purchase) -> Date {
        purchase.reminders
            .filter { !$0.isCompleted }
            .map(\.dueDate)
            .min() ?? .distantFuture
    }
}
