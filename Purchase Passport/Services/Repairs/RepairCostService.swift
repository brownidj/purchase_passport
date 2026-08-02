import Foundation

enum RepairCostService {
    static func calculateTotal(labour: Decimal?, parts: Decimal?) -> Decimal? {
        switch (labour, parts) {
        case let (.some(labour), .some(parts)):
            return labour + parts
        case let (.some(labour), .none):
            return labour
        case let (.none, .some(parts)):
            return parts
        case (.none, .none):
            return nil
        }
    }
}
