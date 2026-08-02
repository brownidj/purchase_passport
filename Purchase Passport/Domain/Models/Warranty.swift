import Foundation
import SwiftData

@Model
final class Warranty {
    var title: String
    var type: WarrantyType
    var provider: String?
    var startDate: Date?
    var endDate: Date?
    var coverageDescription: String?
    var exclusions: String?
    var claimProcedure: String?
    var claimContactDetails: String?
    var warrantyReferenceNumber: String?
    var proofOfPurchaseRequired: Bool
    var isTransferable: Bool?
    var extendedWarrantyDetails: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var purchase: Purchase?

    init(
        title: String,
        type: WarrantyType = .manufacturer,
        provider: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        coverageDescription: String? = nil,
        exclusions: String? = nil,
        claimProcedure: String? = nil,
        claimContactDetails: String? = nil,
        warrantyReferenceNumber: String? = nil,
        proofOfPurchaseRequired: Bool = false,
        isTransferable: Bool? = nil,
        extendedWarrantyDetails: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        purchase: Purchase? = nil
    ) {
        self.title = title
        self.type = type
        self.provider = provider
        self.startDate = startDate
        self.endDate = endDate
        self.coverageDescription = coverageDescription
        self.exclusions = exclusions
        self.claimProcedure = claimProcedure
        self.claimContactDetails = claimContactDetails
        self.warrantyReferenceNumber = warrantyReferenceNumber
        self.proofOfPurchaseRequired = proofOfPurchaseRequired
        self.isTransferable = isTransferable
        self.extendedWarrantyDetails = extendedWarrantyDetails
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.purchase = purchase
    }
}
