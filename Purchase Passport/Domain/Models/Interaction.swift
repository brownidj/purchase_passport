import Foundation
import SwiftData

@Model
final class Interaction {
    var occurredAt: Date
    var type: InteractionType
    var status: InteractionStatus
    var partyContacted: String?
    var contactPerson: String?
    var contactPhoneNumber: String?
    var subject: String
    var summary: String?
    var detailedNotes: String?
    var promisesOrCommitments: String?
    var referenceNumber: String?
    var durationMinutes: Int?
    var nextAction: String?
    var followUpDate: Date?
    var createdAt: Date
    var updatedAt: Date

    var purchase: Purchase?
    var followUpReminder: Reminder?
    var sourceCorrespondence: CorrespondenceRecord?
    var relatedInteraction: Interaction?
    var relatedCorrespondence: CorrespondenceRecord?

    init(
        occurredAt: Date,
        type: InteractionType,
        status: InteractionStatus = .open,
        partyContacted: String? = nil,
        contactPerson: String? = nil,
        contactPhoneNumber: String? = nil,
        subject: String,
        summary: String? = nil,
        detailedNotes: String? = nil,
        promisesOrCommitments: String? = nil,
        referenceNumber: String? = nil,
        durationMinutes: Int? = nil,
        nextAction: String? = nil,
        followUpDate: Date? = nil,
        followUpReminder: Reminder? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        purchase: Purchase? = nil,
        sourceCorrespondence: CorrespondenceRecord? = nil,
        relatedInteraction: Interaction? = nil,
        relatedCorrespondence: CorrespondenceRecord? = nil
    ) {
        self.occurredAt = occurredAt
        self.type = type
        self.status = status
        self.partyContacted = partyContacted
        self.contactPerson = contactPerson
        self.contactPhoneNumber = contactPhoneNumber
        self.subject = subject
        self.summary = summary
        self.detailedNotes = detailedNotes
        self.promisesOrCommitments = promisesOrCommitments
        self.referenceNumber = referenceNumber
        self.durationMinutes = durationMinutes
        self.nextAction = nextAction
        self.followUpDate = followUpDate
        self.followUpReminder = followUpReminder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.purchase = purchase
        self.sourceCorrespondence = sourceCorrespondence
        self.relatedInteraction = relatedInteraction
        self.relatedCorrespondence = relatedCorrespondence
    }
}

extension Interaction {
    var isReadOnlyGenerated: Bool {
        sourceCorrespondence != nil
    }
}
