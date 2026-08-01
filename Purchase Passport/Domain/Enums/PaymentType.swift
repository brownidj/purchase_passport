import Foundation

enum PaymentType: String, Codable, CaseIterable {
    case purchase
    case deposit
    case balance
    case fee
    case tax
    case delivery
    case instalment
    case refund
    case rebate
    case other
}
