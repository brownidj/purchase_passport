import Foundation

enum WarrantyStatus: String, Codable, CaseIterable {
    case active
    case expiringSoon
    case expired
    case unknown
}
