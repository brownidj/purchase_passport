import Foundation
import SwiftData

@Model
final class FaultRecord {
    var firstNoticedDate: Date
    var title: String
    var detailedDescription: String?
    var severity: FaultSeverity
    var status: FaultStatus
    var diagnosticInformation: String?
    var effectOnUse: String?
    var safetyConcerns: String?
    var sellerOrManufacturerNotified: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var purchase: Purchase?
    var relatedRepairs: [RepairRecord]

    init(
        firstNoticedDate: Date,
        title: String,
        detailedDescription: String? = nil,
        severity: FaultSeverity = .medium,
        status: FaultStatus = .open,
        diagnosticInformation: String? = nil,
        effectOnUse: String? = nil,
        safetyConcerns: String? = nil,
        sellerOrManufacturerNotified: Bool = false,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        purchase: Purchase? = nil,
        relatedRepairs: [RepairRecord] = []
    ) {
        self.firstNoticedDate = firstNoticedDate
        self.title = title
        self.detailedDescription = detailedDescription
        self.severity = severity
        self.status = status
        self.diagnosticInformation = diagnosticInformation
        self.effectOnUse = effectOnUse
        self.safetyConcerns = safetyConcerns
        self.sellerOrManufacturerNotified = sellerOrManufacturerNotified
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.purchase = purchase
        self.relatedRepairs = relatedRepairs
    }
}
