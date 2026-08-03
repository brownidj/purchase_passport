import Foundation

enum AppRootFormatting {
    private static let defaultIssuePreviewLimit = 8

    static func formattedDate(_ value: Date?) -> String {
        guard let value else { return "Not set" }
        return value.formatted(date: .abbreviated, time: .omitted)
    }

    static func formattedDateTime(_ value: Date?, includeTime: Bool) -> String {
        guard let value else { return "Not set" }
        if includeTime {
            return value.formatted(date: .abbreviated, time: .shortened)
        }
        return value.formatted(date: .abbreviated, time: .omitted)
    }

    static func formattedPrice(amount: Decimal?, currencyCode: String?) -> String {
        guard let amount else { return "Not set" }
        if let currencyCode, !currencyCode.isEmpty {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currencyCode
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            if let formatted = formatter.string(from: amount as NSDecimalNumber) {
                return formatted
            }
        }
        return NSDecimalNumber(decimal: amount).stringValue
    }

    static func formattedUsefulLife(months: Int?, notes: String?) -> String {
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        switch (months, trimmedNotes) {
        case let (.some(months), .some(notes)) where !notes.isEmpty:
            return "\(months) months (\(notes))"
        case let (.some(months), _):
            return "\(months) months"
        case let (_, .some(notes)) where !notes.isEmpty:
            return notes
        default:
            return "Not set"
        }
    }

    static func formattedTags(_ tags: [Tag]) -> String {
        if tags.isEmpty { return "Not set" }
        return tags.map(\.name).joined(separator: ", ")
    }

    static func formattedWarrantySubtitle(_ warranty: Warranty) -> String {
        let status = WarrantyStatusService.status(for: warranty).rawValue
        let end = formattedDate(warranty.endDate)
        return "\(status) • End: \(end)"
    }

    static func formattedReminderSubtitle(_ reminder: Reminder) -> String {
        let due = formattedDateTime(reminder.dueDate, includeTime: reminder.hasSpecificTime)
        return "\(formattedReminderState(reminder)) • Due: \(due)"
    }

    static func formattedInteractionSubtitle(_ interaction: Interaction) -> String {
        let occurred = formattedDateTime(interaction.occurredAt, includeTime: true)
        return "\(interaction.type.rawValue) • \(interaction.status.rawValue) • \(occurred)"
    }

    static func formattedComplaintSubtitle(_ complaint: ComplaintCase) -> String {
        let opened = formattedDate(complaint.dateOpened)
        let deadlineState = ComplaintService.deadlineState(for: complaint).rawValue
        return "\(complaint.status.rawValue) • \(deadlineState) • Opened: \(opened)"
    }

    static func formattedServiceSubtitle(_ record: ServiceRecord) -> String {
        let date = formattedDate(record.serviceDate ?? record.completionDate ?? record.bookingDate)
        return "\(date) • \(formattedPrice(amount: record.costAmount, currencyCode: record.currencyCode))"
    }

    static func formattedFaultSubtitle(_ fault: FaultRecord) -> String {
        "\(fault.severity.rawValue) • \(fault.status.rawValue)"
    }

    static func formattedRepairSubtitle(_ repair: RepairRecord) -> String {
        let date = formattedDateTime(repair.repairDate, includeTime: false)
        let total = formattedPrice(amount: repair.totalCost, currencyCode: repair.currencyCode)
        return "\(date) • \(total) • \(repair.paymentStatus.rawValue)"
    }

    static func formattedReminderState(_ reminder: Reminder) -> String {
        if reminder.isCompleted { return "completed" }
        if ReminderService.isOverdue(reminder) { return "overdue" }
        if ReminderService.isDueSoon(reminder) { return "due soon" }
        return "scheduled"
    }

    static func convertedFaultNotes(from serviceRecord: ServiceRecord) -> String? {
        var details: [String] = []

        if let notes = nonEmpty(serviceRecord.notes) {
            details.append(notes)
        }
        if let reference = nonEmpty(serviceRecord.serviceReferenceNumber) {
            details.append("Converted from service record reference: \(reference)")
        }
        if let provider = nonEmpty(serviceRecord.serviceProvider) {
            details.append("Original provider: \(provider)")
        }

        return details.isEmpty ? nil : details.joined(separator: "\n\n")
    }

    static func convertedRepairNotes(from faultRecord: FaultRecord) -> String? {
        var details: [String] = []

        if let notes = nonEmpty(faultRecord.notes) {
            details.append(notes)
        }
        if let diagnostics = nonEmpty(faultRecord.diagnosticInformation) {
            details.append("Diagnostic information: \(diagnostics)")
        }
        if let safety = nonEmpty(faultRecord.safetyConcerns) {
            details.append("Safety concerns: \(safety)")
        }

        return details.isEmpty ? nil : details.joined(separator: "\n\n")
    }

    static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func validationIssueSummary(_ issues: [String], maxItems: Int = defaultIssuePreviewLimit) -> String {
        guard !issues.isEmpty else { return "No validation issues found." }

        let preview = issues.prefix(maxItems)
        let lines = preview.map { "• \($0)" }
        let hiddenCount = issues.count - preview.count
        if hiddenCount > 0 {
            return (lines + ["• …and \(hiddenCount) more issue(s)."]).joined(separator: "\n")
        }
        return lines.joined(separator: "\n")
    }
}
