import Foundation
import SwiftData

@Model
final class ServiceRecord {
    var serviceType: String
    var serviceProvider: String?
    var bookingDate: Date?
    var serviceDate: Date?
    var completionDate: Date?
    var costAmount: Decimal?
    var currencyCode: String?
    var usageReading: String?
    var workRequested: String?
    var workCompleted: String?
    var partsReplaced: String?
    var technicianNotes: String?
    var nextServiceDate: Date?
    var nextServiceIntervalMonths: Int?
    var serviceReferenceNumber: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var purchase: Purchase?

    init(
        serviceType: String,
        serviceProvider: String? = nil,
        bookingDate: Date? = nil,
        serviceDate: Date? = nil,
        completionDate: Date? = nil,
        costAmount: Decimal? = nil,
        currencyCode: String? = nil,
        usageReading: String? = nil,
        workRequested: String? = nil,
        workCompleted: String? = nil,
        partsReplaced: String? = nil,
        technicianNotes: String? = nil,
        nextServiceDate: Date? = nil,
        nextServiceIntervalMonths: Int? = nil,
        serviceReferenceNumber: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        purchase: Purchase? = nil
    ) {
        self.serviceType = serviceType
        self.serviceProvider = serviceProvider
        self.bookingDate = bookingDate
        self.serviceDate = serviceDate
        self.completionDate = completionDate
        self.costAmount = costAmount
        self.currencyCode = currencyCode
        self.usageReading = usageReading
        self.workRequested = workRequested
        self.workCompleted = workCompleted
        self.partsReplaced = partsReplaced
        self.technicianNotes = technicianNotes
        self.nextServiceDate = nextServiceDate
        self.nextServiceIntervalMonths = nextServiceIntervalMonths
        self.serviceReferenceNumber = serviceReferenceNumber
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.purchase = purchase
    }
}
