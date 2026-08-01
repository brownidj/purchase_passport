import Foundation
import SwiftData

@Model
final class Contact {
    var name: String
    var role: String?
    var emailAddress: String?
    var phoneNumber: String?
    var accountNumber: String?
    var notes: String?

    var organisation: Organisation?
    var purchases: [Purchase]

    init(
        name: String,
        role: String? = nil,
        emailAddress: String? = nil,
        phoneNumber: String? = nil,
        accountNumber: String? = nil,
        notes: String? = nil,
        organisation: Organisation? = nil,
        purchases: [Purchase] = []
    ) {
        self.name = name
        self.role = role
        self.emailAddress = emailAddress
        self.phoneNumber = phoneNumber
        self.accountNumber = accountNumber
        self.notes = notes
        self.organisation = organisation
        self.purchases = purchases
    }
}
