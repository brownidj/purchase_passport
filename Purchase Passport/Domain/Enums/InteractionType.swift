import Foundation

enum InteractionType: String, Codable, CaseIterable {
    case phoneCall
    case email
    case letter
    case inPersonVisit
    case onlineChat
    case serviceAppointment
    case repairBooking
    case complaint
    case warrantyClaim
    case refundRequest
    case replacementRequest
    case inspection
    case quotation
    case followUp
    case other
}
