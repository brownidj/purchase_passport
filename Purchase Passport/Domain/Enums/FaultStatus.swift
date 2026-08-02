import Foundation

enum FaultStatus: String, Codable, CaseIterable {
    case open
    case monitoring
    case inRepair
    case resolved
    case closed
}
