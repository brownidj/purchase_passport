import Foundation
import SwiftData

@Model
final class AppBootstrapMetadata {
    var createdAt: Date

    init(createdAt: Date = .now) {
        self.createdAt = createdAt
    }
}
