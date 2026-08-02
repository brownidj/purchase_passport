import Foundation

enum ComplaintStatus: String, Codable, CaseIterable {
    case draft
    case open
    case awaitingResponse
    case escalated
    case resolved
    case closed
}
