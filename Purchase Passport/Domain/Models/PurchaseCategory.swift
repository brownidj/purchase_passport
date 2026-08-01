import Foundation
import SwiftData

@Model
final class PurchaseCategory {
    @Attribute(.unique) var name: String
    var isSystemDefined: Bool

    var purchases: [Purchase]

    init(
        name: String,
        isSystemDefined: Bool = false,
        purchases: [Purchase] = []
    ) {
        self.name = name
        self.isSystemDefined = isSystemDefined
        self.purchases = purchases
    }
}
