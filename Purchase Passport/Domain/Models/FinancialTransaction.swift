import Foundation
import SwiftData

@Model
final class FinancialTransaction {
    var type: PaymentType
    var amount: Decimal
    var currencyCode: String
    var transactionDate: Date?
    var notes: String?
    var referenceNumber: String?

    var purchase: Purchase?

    init(
        type: PaymentType,
        amount: Decimal,
        currencyCode: String,
        transactionDate: Date? = nil,
        notes: String? = nil,
        referenceNumber: String? = nil,
        purchase: Purchase? = nil
    ) {
        self.type = type
        self.amount = amount
        self.currencyCode = currencyCode
        self.transactionDate = transactionDate
        self.notes = notes
        self.referenceNumber = referenceNumber
        self.purchase = purchase
    }
}
