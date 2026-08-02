import Foundation

enum ComplaintIssueType: String, Codable, CaseIterable {
    case complaint
    case warrantyClaim
    case refundRequest
    case replacementRequest
    case dispute
    case other
}
