import Foundation
import SwiftData

@Model
final class ComplaintCase {
    var title: String
    var issueType: ComplaintIssueType
    var partyResponsible: String?
    var dateOpened: Date
    var status: ComplaintStatus
    var desiredResolution: String?
    var consumerGuaranteeOrWarranty: String?
    var caseReferenceNumber: String?
    var chronology: String?
    var keyEvidence: String?
    var correspondence: String?
    var responseDeadline: Date?
    var commitmentsMade: String?
    var outcome: String?
    var compensationDetails: String?
    var dateClosed: Date?
    var createdAt: Date
    var updatedAt: Date

    var purchase: Purchase?
    var warranty: Warranty?
    var relatedDocuments: [StoredDocument]
    var relatedInteractions: [Interaction]
    var relatedFaults: [FaultRecord]
    var relatedRepairs: [RepairRecord]

    init(
        title: String,
        issueType: ComplaintIssueType = .complaint,
        partyResponsible: String? = nil,
        dateOpened: Date = .now,
        status: ComplaintStatus = .open,
        desiredResolution: String? = nil,
        consumerGuaranteeOrWarranty: String? = nil,
        caseReferenceNumber: String? = nil,
        chronology: String? = nil,
        keyEvidence: String? = nil,
        correspondence: String? = nil,
        responseDeadline: Date? = nil,
        commitmentsMade: String? = nil,
        outcome: String? = nil,
        compensationDetails: String? = nil,
        dateClosed: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        purchase: Purchase? = nil,
        warranty: Warranty? = nil,
        relatedDocuments: [StoredDocument] = [],
        relatedInteractions: [Interaction] = [],
        relatedFaults: [FaultRecord] = [],
        relatedRepairs: [RepairRecord] = []
    ) {
        self.title = title
        self.issueType = issueType
        self.partyResponsible = partyResponsible
        self.dateOpened = dateOpened
        self.status = status
        self.desiredResolution = desiredResolution
        self.consumerGuaranteeOrWarranty = consumerGuaranteeOrWarranty
        self.caseReferenceNumber = caseReferenceNumber
        self.chronology = chronology
        self.keyEvidence = keyEvidence
        self.correspondence = correspondence
        self.responseDeadline = responseDeadline
        self.commitmentsMade = commitmentsMade
        self.outcome = outcome
        self.compensationDetails = compensationDetails
        self.dateClosed = dateClosed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.purchase = purchase
        self.warranty = warranty
        self.relatedDocuments = relatedDocuments
        self.relatedInteractions = relatedInteractions
        self.relatedFaults = relatedFaults
        self.relatedRepairs = relatedRepairs
    }
}
