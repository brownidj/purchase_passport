import Foundation

enum OwnershipStatus: String, Codable, CaseIterable {
    case owned
    case financed
    case leased
    case shared
    case disposed
}
