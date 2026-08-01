import Foundation
import SwiftData

@Model
final class Tag {
    @Attribute(.unique) var name: String

    var purchases: [Purchase]

    init(
        name: String,
        purchases: [Purchase] = []
    ) {
        self.name = name
        self.purchases = purchases
    }
}
