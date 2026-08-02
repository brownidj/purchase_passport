import Foundation
import SwiftData

enum TimelineService {
    enum EventCategory: String {
        case core
        case financial
        case warrantyReminder
        case interactions
        case servicing
    }

    struct TimelineEntry: Identifiable, Equatable {
        let id: String
        let date: Date
        let title: String
        let details: String
        let category: EventCategory
    }

    static func entries(for purchase: Purchase, filter: TimelineFilter = .all) -> [TimelineEntry] {
        var allEntries: [TimelineEntry] = []

        if let orderDate = purchase.orderDate {
            allEntries.append(TimelineEntry(
                id: "order-\(purchase.persistentModelID)",
                date: orderDate,
                title: "Order Placed",
                details: purchase.name,
                category: .core
            ))
        }

        if let purchaseDate = purchase.purchaseDate {
            allEntries.append(TimelineEntry(
                id: "purchase-\(purchase.persistentModelID)",
                date: purchaseDate,
                title: "Purchased",
                details: purchase.name,
                category: .core
            ))
        }

        if let deliveryDate = purchase.deliveryDate {
            allEntries.append(TimelineEntry(
                id: "delivery-\(purchase.persistentModelID)",
                date: deliveryDate,
                title: "Delivered",
                details: purchase.name,
                category: .core
            ))
        }

        for transaction in purchase.transactions {
            guard let transactionDate = transaction.transactionDate else { continue }
            allEntries.append(TimelineEntry(
                id: "transaction-\(transaction.persistentModelID)",
                date: transactionDate,
                title: "Financial Transaction",
                details: "\(transaction.type.rawValue) • \(transaction.currencyCode) \(NSDecimalNumber(decimal: transaction.amount).stringValue)",
                category: .financial
            ))
        }

        for warranty in purchase.warranties {
            if let startDate = warranty.startDate {
                allEntries.append(TimelineEntry(
                    id: "warranty-start-\(warranty.persistentModelID)",
                    date: startDate,
                    title: "Warranty Started",
                    details: warranty.title,
                    category: .warrantyReminder
                ))
            }
            if let endDate = warranty.endDate {
                allEntries.append(TimelineEntry(
                    id: "warranty-end-\(warranty.persistentModelID)",
                    date: endDate,
                    title: "Warranty Expires",
                    details: warranty.title,
                    category: .warrantyReminder
                ))
            }
        }

        for reminder in purchase.reminders {
            allEntries.append(TimelineEntry(
                id: "reminder-\(reminder.persistentModelID)",
                date: reminder.dueDate,
                title: "Reminder Due",
                details: reminder.title,
                category: .warrantyReminder
            ))
        }

        for interaction in purchase.interactions {
            allEntries.append(TimelineEntry(
                id: "interaction-\(interaction.persistentModelID)",
                date: interaction.occurredAt,
                title: "Interaction",
                details: interaction.subject,
                category: .interactions
            ))
        }

        for service in purchase.serviceRecords {
            guard let serviceDate = service.serviceDate ?? service.completionDate ?? service.bookingDate else { continue }
            allEntries.append(TimelineEntry(
                id: "service-\(service.persistentModelID)",
                date: serviceDate,
                title: "Service Record",
                details: service.serviceType,
                category: .servicing
            ))
        }

        for fault in purchase.faultRecords {
            allEntries.append(TimelineEntry(
                id: "fault-\(fault.persistentModelID)",
                date: fault.firstNoticedDate,
                title: "Fault Recorded",
                details: fault.title,
                category: .servicing
            ))
        }

        for repair in purchase.repairRecords {
            allEntries.append(TimelineEntry(
                id: "repair-\(repair.persistentModelID)",
                date: repair.repairDate,
                title: "Repair Record",
                details: repair.diagnosis ?? "Repair",
                category: .servicing
            ))
        }

        let filtered = allEntries.filter {
            switch filter {
            case .all:
                return true
            case .core:
                return $0.category == .core
            case .financial:
                return $0.category == .financial
            case .warrantyReminder:
                return $0.category == .warrantyReminder
            case .interactions:
                return $0.category == .interactions
            case .servicing:
                return $0.category == .servicing
            }
        }

        return filtered.sorted { $0.date > $1.date }
    }
}
