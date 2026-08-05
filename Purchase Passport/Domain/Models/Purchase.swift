import Foundation
import SwiftData

@Model
final class Purchase {
    var name: String
    var shortDescription: String?
    var notes: String?
    var status: PurchaseStatus

    var purchaseDate: Date?
    var orderDate: Date?
    var deliveryDate: Date?

    var purchasePrice: Decimal?
    var currencyCode: String?

    var seller: String?
    var manufacturer: String?
    var modelName: String?
    var serialNumber: String?
    var invoiceNumber: String?
    var orderNumber: String?

    var purchaseLocation: String?
    var storageLocation: String?

    var ownershipStatus: OwnershipStatus?
    var expectedUsefulLifeNotes: String?
    var expectedUsefulLifeMonths: Int?

    var createdAt: Date
    var updatedAt: Date

    var category: PurchaseCategory?
    var provider: Organisation?

    var transactions: [FinancialTransaction]

    var tags: [Tag]

    var contacts: [Contact]

    var documents: [StoredDocument]

    var warranties: [Warranty]

    var reminders: [Reminder]

    var interactions: [Interaction]

    var correspondences: [CorrespondenceRecord]

    var complaintCases: [ComplaintCase]

    var serviceRecords: [ServiceRecord]

    var faultRecords: [FaultRecord]

    var repairRecords: [RepairRecord]

    init(
        name: String,
        shortDescription: String? = nil,
        notes: String? = nil,
        status: PurchaseStatus = .researching,
        purchaseDate: Date? = nil,
        orderDate: Date? = nil,
        deliveryDate: Date? = nil,
        purchasePrice: Decimal? = nil,
        currencyCode: String? = nil,
        seller: String? = nil,
        manufacturer: String? = nil,
        modelName: String? = nil,
        serialNumber: String? = nil,
        invoiceNumber: String? = nil,
        orderNumber: String? = nil,
        purchaseLocation: String? = nil,
        storageLocation: String? = nil,
        ownershipStatus: OwnershipStatus? = nil,
        expectedUsefulLifeNotes: String? = nil,
        expectedUsefulLifeMonths: Int? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        category: PurchaseCategory? = nil,
        provider: Organisation? = nil,
        transactions: [FinancialTransaction] = [],
        tags: [Tag] = [],
        contacts: [Contact] = [],
        documents: [StoredDocument] = [],
        warranties: [Warranty] = [],
        reminders: [Reminder] = [],
        interactions: [Interaction] = [],
        correspondences: [CorrespondenceRecord] = [],
        complaintCases: [ComplaintCase] = [],
        serviceRecords: [ServiceRecord] = [],
        faultRecords: [FaultRecord] = [],
        repairRecords: [RepairRecord] = []
    ) {
        self.name = name
        self.shortDescription = shortDescription
        self.notes = notes
        self.status = status
        self.purchaseDate = purchaseDate
        self.orderDate = orderDate
        self.deliveryDate = deliveryDate
        self.purchasePrice = purchasePrice
        self.currencyCode = currencyCode
        self.seller = seller
        self.manufacturer = manufacturer
        self.modelName = modelName
        self.serialNumber = serialNumber
        self.invoiceNumber = invoiceNumber
        self.orderNumber = orderNumber
        self.purchaseLocation = purchaseLocation
        self.storageLocation = storageLocation
        self.ownershipStatus = ownershipStatus
        self.expectedUsefulLifeNotes = expectedUsefulLifeNotes
        self.expectedUsefulLifeMonths = expectedUsefulLifeMonths
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.category = category
        self.provider = provider
        self.transactions = transactions
        self.tags = tags
        self.contacts = contacts
        self.documents = documents
        self.warranties = warranties
        self.reminders = reminders
        self.interactions = interactions
        self.correspondences = correspondences
        self.complaintCases = complaintCases
        self.serviceRecords = serviceRecords
        self.faultRecords = faultRecords
        self.repairRecords = repairRecords
    }
}
