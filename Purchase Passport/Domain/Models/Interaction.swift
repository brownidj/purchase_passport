import Foundation
import SwiftData

@Model
final class Interaction {
    var occurredAt: Date
    var type: InteractionType
    var status: InteractionStatus
    var partyContacted: String?
    var contactPerson: String?
    var subject: String
    var summary: String?
    var detailedNotes: String?
    var promisesOrCommitments: String?
    var referenceNumber: String?
    var nextAction: String?
    var followUpDate: Date?
    var createdAt: Date
    var updatedAt: Date

    var purchase: Purchase?
    var followUpReminder: Reminder?

    init(
        occurredAt: Date,
        type: InteractionType,
        status: InteractionStatus = .open,
        partyContacted: String? = nil,
        contactPerson: String? = nil,
        subject: String,
        summary: String? = nil,
        detailedNotes: String? = nil,
        promisesOrCommitments: String? = nil,
        referenceNumber: String? = nil,
        nextAction: String? = nil,
        followUpDate: Date? = nil,
        followUpReminder: Reminder? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        purchase: Purchase? = nil
    ) {
        self.occurredAt = occurredAt
        self.type = type
        self.status = status
        self.partyContacted = partyContacted
        self.contactPerson = contactPerson
        self.subject = subject
        self.summary = summary
        self.detailedNotes = detailedNotes
        self.promisesOrCommitments = promisesOrCommitments
        self.referenceNumber = referenceNumber
        self.nextAction = nextAction
        self.followUpDate = followUpDate
        self.followUpReminder = followUpReminder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.purchase = purchase
    }
}
