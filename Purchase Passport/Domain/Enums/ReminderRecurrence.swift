import Foundation

enum ReminderRecurrence: String, Codable, CaseIterable {
    case none
    case daily
    case weekly
    case monthly
    case yearly
}
