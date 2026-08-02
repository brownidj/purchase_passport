import Foundation

enum InteractionStatus: String, Codable, CaseIterable {
    case open
    case pending
    case resolved
    case cancelled
}
