import Foundation
import SwiftData

@Model
final class Organisation {
    @Attribute(.unique) var name: String
    var website: String?
    var postalAddress: String?
    var physicalAddress: String?
    var customerServiceNumber: String?
    var notes: String?

    var contacts: [Contact]

    init(
        name: String,
        website: String? = nil,
        postalAddress: String? = nil,
        physicalAddress: String? = nil,
        customerServiceNumber: String? = nil,
        notes: String? = nil,
        contacts: [Contact] = []
    ) {
        self.name = name
        self.website = website
        self.postalAddress = postalAddress
        self.physicalAddress = physicalAddress
        self.customerServiceNumber = customerServiceNumber
        self.notes = notes
        self.contacts = contacts
    }
}
