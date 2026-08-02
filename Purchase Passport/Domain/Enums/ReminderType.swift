import Foundation

enum ReminderType: String, Codable, CaseIterable {
    case warrantyExpiry
    case guaranteeExpiry
    case returnPeriodExpiry
    case paymentDue
    case financePayment
    case serviceDue
    case maintenanceDue
    case registrationRenewal
    case insuranceRenewal
    case subscriptionRenewal
    case travelPaymentDeadline
    case cancellationDeadline
    case contractorFollowUp
    case defectInspection
    case complaintResponseDeadline
    case repairFollowUp
    case documentExpiry
    case custom
}
