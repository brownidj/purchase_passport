import Foundation
import SwiftData

@Model
final class StoredDocument {
    @Attribute(.unique) var identifier: UUID

    var title: String
    var category: DocumentCategory

    var issueDate: Date?
    var expiryDate: Date?
    var issuingOrganisation: String?
    var referenceNumber: String?
    var notes: String?

    var originalFilename: String
    var contentType: String?
    var storedRelativePath: String

    var versionNumber: Int
    var supersededAt: Date?
    var dateAdded: Date

    var purchase: Purchase?

    init(
        identifier: UUID = UUID(),
        title: String,
        category: DocumentCategory = .other,
        issueDate: Date? = nil,
        expiryDate: Date? = nil,
        issuingOrganisation: String? = nil,
        referenceNumber: String? = nil,
        notes: String? = nil,
        originalFilename: String,
        contentType: String? = nil,
        storedRelativePath: String,
        versionNumber: Int = 1,
        supersededAt: Date? = nil,
        dateAdded: Date = .now,
        purchase: Purchase? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.category = category
        self.issueDate = issueDate
        self.expiryDate = expiryDate
        self.issuingOrganisation = issuingOrganisation
        self.referenceNumber = referenceNumber
        self.notes = notes
        self.originalFilename = originalFilename
        self.contentType = contentType
        self.storedRelativePath = storedRelativePath
        self.versionNumber = versionNumber
        self.supersededAt = supersededAt
        self.dateAdded = dateAdded
        self.purchase = purchase
    }
}
