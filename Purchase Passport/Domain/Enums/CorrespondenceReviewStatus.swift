import Foundation

enum CorrespondenceReviewStatus: String, Codable, CaseIterable {
    case autoLinked
    case pendingReview
    case accepted
    case rejected
}
