import Foundation

enum TimelineFilter: String, Codable, CaseIterable {
    case all
    case core
    case financial
    case warrantyReminder
    case interactions
    case servicing
}
