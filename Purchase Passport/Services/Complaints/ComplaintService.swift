import Foundation
import SwiftData

enum ComplaintService {
    enum DeadlineState: String {
        case noDeadline
        case overdue
        case dueSoon
        case scheduled
    }

    struct ChronologyEntry: Identifiable, Equatable {
        let id: String
        let date: Date
        let title: String
        let details: String
    }

    static func deadlineState(
        for complaint: ComplaintCase,
        asOf referenceDate: Date = .now,
        dueSoonDays: Int = 7
    ) -> DeadlineState {
        guard let deadline = complaint.responseDeadline else {
            return .noDeadline
        }

        if deadline < referenceDate {
            return .overdue
        }

        guard let threshold = Calendar.current.date(byAdding: .day, value: dueSoonDays, to: referenceDate) else {
            return .scheduled
        }

        if deadline <= threshold {
            return .dueSoon
        }

        return .scheduled
    }

    static func chronology(for complaint: ComplaintCase) -> [ChronologyEntry] {
        var entries: [ChronologyEntry] = [
            ChronologyEntry(
                id: "complaint-opened-\(complaint.persistentModelID)",
                date: complaint.dateOpened,
                title: "Case Opened",
                details: complaint.title
            )
        ]

        for interaction in complaint.relatedInteractions {
            entries.append(ChronologyEntry(
                id: "interaction-\(interaction.persistentModelID)",
                date: interaction.occurredAt,
                title: "Interaction",
                details: interaction.subject
            ))
        }

        for fault in complaint.relatedFaults {
            entries.append(ChronologyEntry(
                id: "fault-\(fault.persistentModelID)",
                date: fault.firstNoticedDate,
                title: "Fault",
                details: fault.title
            ))
        }

        for repair in complaint.relatedRepairs {
            entries.append(ChronologyEntry(
                id: "repair-\(repair.persistentModelID)",
                date: repair.repairDate,
                title: "Repair",
                details: repair.diagnosis ?? "Repair"
            ))
        }

        for document in complaint.relatedDocuments {
            entries.append(ChronologyEntry(
                id: "document-\(document.identifier.uuidString)",
                date: document.dateAdded,
                title: "Evidence Document",
                details: document.title
            ))
        }

        if let closedDate = complaint.dateClosed {
            entries.append(ChronologyEntry(
                id: "complaint-closed-\(complaint.persistentModelID)",
                date: closedDate,
                title: "Case Closed",
                details: complaint.outcome ?? complaint.status.rawValue
            ))
        }

        return entries.sorted { $0.date > $1.date }
    }
}
