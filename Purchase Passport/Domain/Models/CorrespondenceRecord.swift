import Foundation
import SwiftData

@Model
final class CorrespondenceRecord {
    var channel: InteractionType
    var occurredAt: Date
    var sender: String?
    var recipients: String?
    var subject: String
    var bodyPreview: String?
    var fullBody: String?
    var externalMessageID: String?
    var threadID: String?
    var autoLinkConfidence: Double?
    var extractionConfidence: Double?
    var reviewStatus: CorrespondenceReviewStatus
    var extractedOrderNumber: String?
    var extractedTrackingNumber: String?
    var extractedRMANumber: String?
    var extractedWarrantyExpiryDate: Date?
    var createdAt: Date
    var updatedAt: Date

    var purchase: Purchase?
    var complaintCase: ComplaintCase?
    var generatedInteraction: Interaction?

    init(
        channel: InteractionType = .email,
        occurredAt: Date,
        sender: String? = nil,
        recipients: String? = nil,
        subject: String,
        bodyPreview: String? = nil,
        fullBody: String? = nil,
        externalMessageID: String? = nil,
        threadID: String? = nil,
        autoLinkConfidence: Double? = nil,
        extractionConfidence: Double? = nil,
        reviewStatus: CorrespondenceReviewStatus = .pendingReview,
        extractedOrderNumber: String? = nil,
        extractedTrackingNumber: String? = nil,
        extractedRMANumber: String? = nil,
        extractedWarrantyExpiryDate: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        purchase: Purchase? = nil,
        complaintCase: ComplaintCase? = nil,
        generatedInteraction: Interaction? = nil
    ) {
        self.channel = channel
        self.occurredAt = occurredAt
        self.sender = sender
        self.recipients = recipients
        self.subject = subject
        self.bodyPreview = bodyPreview
        self.fullBody = fullBody
        self.externalMessageID = externalMessageID
        self.threadID = threadID
        self.autoLinkConfidence = autoLinkConfidence
        self.extractionConfidence = extractionConfidence
        self.reviewStatus = reviewStatus
        self.extractedOrderNumber = extractedOrderNumber
        self.extractedTrackingNumber = extractedTrackingNumber
        self.extractedRMANumber = extractedRMANumber
        self.extractedWarrantyExpiryDate = extractedWarrantyExpiryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.purchase = purchase
        self.complaintCase = complaintCase
        self.generatedInteraction = generatedInteraction
    }
}
