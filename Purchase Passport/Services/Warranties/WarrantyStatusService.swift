import Foundation

enum WarrantyStatusService {
    static func status(
        for warranty: Warranty,
        asOf referenceDate: Date = .now,
        expiringSoonDays: Int = 30
    ) -> WarrantyStatus {
        guard let endDate = warranty.endDate else {
            return .unknown
        }

        if endDate < referenceDate {
            return .expired
        }

        guard let soonThreshold = Calendar.current.date(byAdding: .day, value: expiringSoonDays, to: referenceDate) else {
            return .active
        }

        if endDate <= soonThreshold {
            return .expiringSoon
        }

        return .active
    }
}
