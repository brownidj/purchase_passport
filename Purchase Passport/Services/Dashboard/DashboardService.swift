import Foundation
import SwiftData

enum DashboardService {
    struct ActivityEntry: Identifiable, Equatable {
        let id: String
        let date: Date
        let title: String
        let details: String
        let purchaseName: String
    }

    static func recentPurchases(from purchases: [Purchase], limit: Int = 5) -> [Purchase] {
        purchases
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }

    static func upcomingReminders(from reminders: [Reminder], asOf referenceDate: Date = .now, limit: Int = 8) -> [Reminder] {
        reminders
            .filter { !$0.isCompleted && $0.dueDate >= referenceDate }
            .sorted { $0.dueDate < $1.dueDate }
            .prefix(limit)
            .map { $0 }
    }

    static func warrantiesNearingExpiry(from warranties: [Warranty], asOf referenceDate: Date = .now, limit: Int = 8) -> [Warranty] {
        warranties
            .filter { WarrantyStatusService.status(for: $0, asOf: referenceDate) == .expiringSoon }
            .sorted { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) }
            .prefix(limit)
            .map { $0 }
    }

    static func overdueFollowUps(from interactions: [Interaction], asOf referenceDate: Date = .now, limit: Int = 8) -> [Interaction] {
        interactions
            .filter {
                guard let followUpDate = $0.followUpDate else { return false }
                guard $0.status != .resolved && $0.status != .cancelled else { return false }
                return followUpDate < referenceDate
            }
            .sorted { ($0.followUpDate ?? .distantFuture) < ($1.followUpDate ?? .distantFuture) }
            .prefix(limit)
            .map { $0 }
    }

    static func serviceDueDates(from serviceRecords: [ServiceRecord], asOf referenceDate: Date = .now, dueWithinDays: Int = 30, limit: Int = 8) -> [ServiceRecord] {
        guard let upperBound = Calendar.current.date(byAdding: .day, value: dueWithinDays, to: referenceDate) else {
            return []
        }

        return serviceRecords
            .filter {
                guard let nextServiceDate = $0.nextServiceDate else { return false }
                return nextServiceDate >= referenceDate && nextServiceDate <= upperBound
            }
            .sorted { ($0.nextServiceDate ?? .distantFuture) < ($1.nextServiceDate ?? .distantFuture) }
            .prefix(limit)
            .map { $0 }
    }

    static func unresolvedFaults(from faultRecords: [FaultRecord], limit: Int = 8) -> [FaultRecord] {
        faultRecords
            .filter { $0.status != .resolved && $0.status != .closed }
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(limit)
            .map { $0 }
    }

    static func activeRepairs(from repairRecords: [RepairRecord], limit: Int = 8) -> [RepairRecord] {
        repairRecords
            .filter {
                if $0.followUpRequired { return true }
                let outcome = $0.outcome?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return outcome.isEmpty
            }
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(limit)
            .map { $0 }
    }

    static func activeComplaints(from complaints: [ComplaintCase], limit: Int = 8) -> [ComplaintCase] {
        complaints
            .filter { $0.status != .resolved && $0.status != .closed }
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(limit)
            .map { $0 }
    }

    static func recentInteractions(from interactions: [Interaction], limit: Int = 8) -> [Interaction] {
        interactions
            .sorted { $0.occurredAt > $1.occurredAt }
            .prefix(limit)
            .map { $0 }
    }

    static func recentlyAddedDocuments(from purchases: [Purchase], limit: Int = 8) -> [StoredDocument] {
        purchases
            .flatMap(\.documents)
            .sorted { $0.dateAdded > $1.dateAdded }
            .prefix(limit)
            .map { $0 }
    }

    static func recentActivity(from purchases: [Purchase], limit: Int = 12) -> [ActivityEntry] {
        purchases
            .flatMap { purchase in
                TimelineService.entries(for: purchase).map { entry in
                    ActivityEntry(
                        id: "\(purchase.persistentModelID)-\(entry.id)",
                        date: entry.date,
                        title: entry.title,
                        details: entry.details,
                        purchaseName: purchase.name
                    )
                }
            }
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }
}
