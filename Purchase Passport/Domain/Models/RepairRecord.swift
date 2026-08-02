import Foundation
import SwiftData

@Model
final class RepairRecord {
    var repairProvider: String?
    var bookingDate: Date?
    var repairDate: Date
    var diagnosis: String?
    var workPerformed: String?
    var partsReplaced: String?
    var labourCost: Decimal?
    var partsCost: Decimal?
    var totalCost: Decimal?
    var currencyCode: String?
    var warrantyCoverage: Bool
    var paymentStatus: RepairPaymentStatus
    var repairWarrantyDetails: String?
    var outcome: String?
    var unresolvedIssues: String?
    var followUpRequired: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var purchase: Purchase?
    var fault: FaultRecord?

    init(
        repairProvider: String? = nil,
        bookingDate: Date? = nil,
        repairDate: Date,
        diagnosis: String? = nil,
        workPerformed: String? = nil,
        partsReplaced: String? = nil,
        labourCost: Decimal? = nil,
        partsCost: Decimal? = nil,
        totalCost: Decimal? = nil,
        currencyCode: String? = nil,
        warrantyCoverage: Bool = false,
        paymentStatus: RepairPaymentStatus = .unpaid,
        repairWarrantyDetails: String? = nil,
        outcome: String? = nil,
        unresolvedIssues: String? = nil,
        followUpRequired: Bool = false,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        purchase: Purchase? = nil,
        fault: FaultRecord? = nil
    ) {
        self.repairProvider = repairProvider
        self.bookingDate = bookingDate
        self.repairDate = repairDate
        self.diagnosis = diagnosis
        self.workPerformed = workPerformed
        self.partsReplaced = partsReplaced
        self.labourCost = labourCost
        self.partsCost = partsCost
        self.totalCost = totalCost
        self.currencyCode = currencyCode
        self.warrantyCoverage = warrantyCoverage
        self.paymentStatus = paymentStatus
        self.repairWarrantyDetails = repairWarrantyDetails
        self.outcome = outcome
        self.unresolvedIssues = unresolvedIssues
        self.followUpRequired = followUpRequired
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.purchase = purchase
        self.fault = fault
    }
}
