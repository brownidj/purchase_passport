import Foundation

enum ReminderService {
    static func validate(title: String, advanceWarningDays: Int) -> String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Reminder title is required."
        }
        if advanceWarningDays < 0 {
            return "Advance warning days cannot be negative."
        }
        return nil
    }

    static func nextDueDate(for reminder: Reminder, from referenceDate: Date = .now) -> Date? {
        guard reminder.recurrence != .none else { return nil }

        var candidate = reminder.dueDate
        while candidate <= referenceDate {
            guard let advanced = advance(candidate, by: reminder.recurrence) else {
                return nil
            }
            candidate = advanced
        }
        return candidate
    }

    static func isDueSoon(_ reminder: Reminder, asOf referenceDate: Date = .now) -> Bool {
        guard !reminder.isCompleted else { return false }
        guard reminder.dueDate >= referenceDate else { return false }

        guard let warnDate = Calendar.current.date(byAdding: .day, value: -reminder.advanceWarningDays, to: reminder.dueDate) else {
            return false
        }
        return referenceDate >= warnDate
    }

    static func isOverdue(_ reminder: Reminder, asOf referenceDate: Date = .now) -> Bool {
        !reminder.isCompleted && reminder.dueDate < referenceDate
    }

    private static func advance(_ date: Date, by recurrence: ReminderRecurrence) -> Date? {
        let calendar = Calendar.current
        switch recurrence {
        case .none:
            return date
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }
}
