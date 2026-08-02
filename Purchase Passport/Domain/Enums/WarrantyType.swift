import Foundation

enum WarrantyType: String, Codable, CaseIterable {
    case manufacturer
    case retailer
    case extended
    case insurance
    case serviceContract
    case other
}
