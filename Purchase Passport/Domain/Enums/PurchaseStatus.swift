import Foundation

enum PurchaseStatus: String, Codable, CaseIterable {
    case researching
    case ordered
    case awaitingDelivery
    case active
    case underWarranty
    case underRepair
    case returned
    case refunded
    case replaced
    case sold
    case donated
    case disposed
    case cancelled
    case archived
}
