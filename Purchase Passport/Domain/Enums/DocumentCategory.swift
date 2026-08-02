import Foundation

enum DocumentCategory: String, Codable, CaseIterable {
    case receipt
    case invoice
    case quotation
    case purchaseOrder
    case contract
    case financeAgreement
    case warranty
    case guarantee
    case insurancePolicy
    case userManual
    case serviceReport
    case repairReport
    case photograph
    case screenshot
    case email
    case letter
    case complaint
    case refundRecord
    case certificate
    case permit
    case other
}
