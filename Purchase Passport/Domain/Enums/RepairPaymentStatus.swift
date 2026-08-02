import Foundation

enum RepairPaymentStatus: String, Codable, CaseIterable {
    case unpaid
    case partiallyPaid
    case paid
    case reimbursed
    case waived
}
