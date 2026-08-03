import SwiftUI
import SwiftData

enum PurchaseEditorPresentation: Identifiable {
    case new
    case edit(Purchase)

    var id: String {
        switch self {
        case .new:
            return "new"
        case .edit(let purchase):
            return "edit-\(purchase.persistentModelID)"
        }
    }
}

enum ServiceRecordEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(ServiceRecord)

    var id: String {
        switch self {
        case .new(let purchase):
            return "service-new-\(purchase.persistentModelID)"
        case .edit(let record):
            return "service-edit-\(record.persistentModelID)"
        }
    }
}

enum FaultRecordEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(FaultRecord)

    var id: String {
        switch self {
        case .new(let purchase):
            return "fault-new-\(purchase.persistentModelID)"
        case .edit(let fault):
            return "fault-edit-\(fault.persistentModelID)"
        }
    }
}

enum RepairRecordEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(RepairRecord)

    var id: String {
        switch self {
        case .new(let purchase):
            return "repair-new-\(purchase.persistentModelID)"
        case .edit(let repair):
            return "repair-edit-\(repair.persistentModelID)"
        }
    }
}

enum WarrantyEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(Warranty)

    var id: String {
        switch self {
        case .new(let purchase):
            return "warranty-new-\(purchase.persistentModelID)"
        case .edit(let warranty):
            return "warranty-edit-\(warranty.persistentModelID)"
        }
    }
}

enum ReminderEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(Reminder)

    var id: String {
        switch self {
        case .new(let purchase):
            return "reminder-new-\(purchase.persistentModelID)"
        case .edit(let reminder):
            return "reminder-edit-\(reminder.persistentModelID)"
        }
    }
}

enum InteractionEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(Interaction)

    var id: String {
        switch self {
        case .new(let purchase):
            return "interaction-new-\(purchase.persistentModelID)"
        case .edit(let interaction):
            return "interaction-edit-\(interaction.persistentModelID)"
        }
    }
}

enum ComplaintEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(ComplaintCase)

    var id: String {
        switch self {
        case .new(let purchase):
            return "complaint-new-\(purchase.persistentModelID)"
        case .edit(let complaint):
            return "complaint-edit-\(complaint.persistentModelID)"
        }
    }
}

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case search
    case allPurchases
    case servicing
    case interactions
    case complaints
    case warranties
    case reminders
    case documents

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            "Dashboard"
        case .search:
            "Search"
        case .allPurchases:
            "All Purchases"
        case .servicing:
            "Servicing"
        case .interactions:
            "Interactions"
        case .complaints:
            "Complaints"
        case .warranties:
            "Warranties"
        case .reminders:
            "Reminders"
        case .documents:
            "Documents"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            "square.grid.2x2"
        case .search:
            "magnifyingglass"
        case .allPurchases:
            "cart"
        case .servicing:
            "wrench.and.screwdriver"
        case .interactions:
            "bubble.left.and.bubble.right"
        case .complaints:
            "exclamationmark.bubble"
        case .warranties:
            "checkmark.shield"
        case .reminders:
            "bell"
        case .documents:
            "doc.text"
        }
    }

    var contentPlaceholder: String {
        switch self {
        case .dashboard:
            "Dashboard overview and action lists are available in this section."
        case .search:
            "Search and filter purchases from a single list."
        case .allPurchases:
            "Purchase list is available in this section."
        case .servicing:
            "Service, fault and repair records are available in this section."
        case .interactions:
            "Interaction list is available in this section."
        case .complaints:
            "Complaint and dispute records are available in this section."
        case .warranties:
            "Warranty list is available in this section."
        case .reminders:
            "Reminder list is available in this section."
        case .documents:
            "Document import is available from All Purchases."
        }
    }

    var detailPlaceholder: String {
        switch self {
        case .dashboard:
            "Review actionable items and recent activity."
        case .search:
            "Select a search result to view purchase details."
        case .allPurchases:
            "Select a purchase to view its details."
        case .servicing:
            "Select service, fault, or repair records to view details."
        case .interactions:
            "Select an interaction to view details."
        case .complaints:
            "Select a complaint case to view details."
        case .warranties:
            "Select a warranty to view details."
        case .reminders:
            "Select a reminder to view details."
        case .documents:
            "Document detail view will be expanded in a later task."
        }
    }
}
