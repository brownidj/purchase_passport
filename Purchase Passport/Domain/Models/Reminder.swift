import Foundation
import SwiftData

@Model
final class Reminder {
    var title: String
    var type: ReminderType
    var dueDate: Date
    var hasSpecificTime: Bool
    var advanceWarningDays: Int
    var recurrence: ReminderRecurrence
    var priority: ReminderPriority
    var notes: String?
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    var purchase: Purchase?
    var sourceInteraction: Interaction?
    var followUpInteractionType: InteractionType?

    init(
        title: String,
        type: ReminderType = .custom,
        dueDate: Date,
        hasSpecificTime: Bool = false,
        advanceWarningDays: Int = 0,
        recurrence: ReminderRecurrence = .none,
        priority: ReminderPriority = .normal,
        notes: String? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        purchase: Purchase? = nil,
        sourceInteraction: Interaction? = nil,
        followUpInteractionType: InteractionType? = nil
    ) {
        self.title = title
        self.type = type
        self.dueDate = dueDate
        self.hasSpecificTime = hasSpecificTime
        self.advanceWarningDays = advanceWarningDays
        self.recurrence = recurrence
        self.priority = priority
        self.notes = notes
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.purchase = purchase
        self.sourceInteraction = sourceInteraction
        self.followUpInteractionType = followUpInteractionType
    }
}
