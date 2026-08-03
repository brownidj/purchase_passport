import SwiftData
import Foundation

struct AppRootLinkedSelections {
    let document: StoredDocument?
    let serviceRecord: ServiceRecord?
    let faultRecord: FaultRecord?
    let repairRecord: RepairRecord?
    let warranty: Warranty?
    let reminder: Reminder?
    let interaction: Interaction?
    let complaint: ComplaintCase?

    var serviceRecordID: PersistentIdentifier? { serviceRecord?.persistentModelID }
    var faultRecordID: PersistentIdentifier? { faultRecord?.persistentModelID }
    var repairRecordID: PersistentIdentifier? { repairRecord?.persistentModelID }
    var warrantyID: PersistentIdentifier? { warranty?.persistentModelID }
    var reminderID: PersistentIdentifier? { reminder?.persistentModelID }
    var interactionID: PersistentIdentifier? { interaction?.persistentModelID }
    var complaintID: PersistentIdentifier? { complaint?.persistentModelID }
}

enum AppRootSelectionCoordinator {
    static func applySectionChange(
        _ newValue: AppSection?,
        clearPurchaseAndDocument: () -> Void,
        autoselectPurchase: () -> Void,
        autoselectSearch: () -> Void,
        autoselectServicing: () -> Void,
        autoselectInteractions: () -> Void,
        autoselectComplaints: () -> Void,
        autoselectWarranties: () -> Void,
        autoselectReminders: () -> Void,
        clearAll: () -> Void
    ) {
        switch newValue {
        case .dashboard:
            clearPurchaseAndDocument()
        case .allPurchases:
            autoselectPurchase()
        case .search:
            clearPurchaseAndDocument()
            autoselectSearch()
        case .servicing:
            clearPurchaseAndDocument()
            autoselectServicing()
        case .interactions:
            clearPurchaseAndDocument()
            autoselectInteractions()
        case .complaints:
            clearPurchaseAndDocument()
            autoselectComplaints()
        case .warranties:
            clearPurchaseAndDocument()
            autoselectWarranties()
        case .reminders:
            clearPurchaseAndDocument()
            autoselectReminders()
        case .some, .none:
            clearAll()
        }
    }

    static func linkedSelections(for purchase: Purchase) -> AppRootLinkedSelections {
        let document = purchase.documents.sorted(by: { $0.dateAdded > $1.dateAdded }).first
        let serviceRecord = purchase.serviceRecords.sorted(by: { ($0.serviceDate ?? .distantPast) > ($1.serviceDate ?? .distantPast) }).first
        let faultRecord = purchase.faultRecords.sorted(by: { $0.firstNoticedDate > $1.firstNoticedDate }).first
        let repairRecord = purchase.repairRecords.sorted(by: { $0.repairDate > $1.repairDate }).first
        let warranty = purchase.warranties.sorted(by: { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) }).first
        let reminder = purchase.reminders.sorted(by: { $0.dueDate < $1.dueDate }).first
        let interaction = purchase.interactions.sorted(by: { $0.occurredAt > $1.occurredAt }).first
        let complaint = purchase.complaintCases.sorted(by: { $0.dateOpened > $1.dateOpened }).first

        return AppRootLinkedSelections(
            document: document,
            serviceRecord: serviceRecord,
            faultRecord: faultRecord,
            repairRecord: repairRecord,
            warranty: warranty,
            reminder: reminder,
            interaction: interaction,
            complaint: complaint
        )
    }
}
