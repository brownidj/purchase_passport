//
//  Purchase_PassportTests.swift
//  Purchase PassportTests
//
//  Created by David Browning on 1/8/2026.
//

import Testing
import Foundation
@testable import Purchase_Passport

struct Purchase_PassportTests {

    @Test func purchaseEditorValidationFailsForBlankName() {
        let result = PurchaseEditorValidation.validate(name: "   ")
        #expect(result == "Purchase name is required.")
    }

    @Test func purchaseEditorValidationPassesForNonBlankName() {
        let result = PurchaseEditorValidation.validate(name: "MacBook Pro")
        #expect(result == nil)
    }

    @Test func reminderServiceCalculatesNextMonthlyDueDate() {
        let calendar = Calendar(identifier: .gregorian)
        let dueDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 20))!
        let reminder = Reminder(
            title: "Service Due",
            dueDate: dueDate,
            recurrence: .monthly
        )

        let nextDate = ReminderService.nextDueDate(for: reminder, from: referenceDate)
        let expectedDate = calendar.date(from: DateComponents(year: 2026, month: 4, day: 15))
        #expect(nextDate == expectedDate)
    }

    @Test func reminderServiceFlagsOverdueReminder() {
        let calendar = Calendar(identifier: .gregorian)
        let dueDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 10))!
        let reminder = Reminder(title: "Pay Bill", dueDate: dueDate)

        #expect(ReminderService.isOverdue(reminder, asOf: referenceDate))
    }

    @Test func warrantyStatusServiceReturnsExpiringSoon() {
        let calendar = Calendar(identifier: .gregorian)
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 20))!
        let warranty = Warranty(title: "Laptop Warranty", endDate: endDate)

        let status = WarrantyStatusService.status(for: warranty, asOf: referenceDate, expiringSoonDays: 30)
        #expect(status == .expiringSoon)
    }

    @Test func interactionEditorValidationFailsForBlankSubject() {
        let result = InteractionEditorValidation.validate(subject: " ")
        #expect(result == "Interaction subject is required.")
    }

    @Test func timelineServiceFiltersInteractionEvents() {
        let purchaseDate = Calendar(identifier: .gregorian).date(
            from: DateComponents(year: 2026, month: 8, day: 2)
        )!
        let interactionDate = Calendar(identifier: .gregorian).date(
            from: DateComponents(year: 2026, month: 8, day: 5)
        )!

        let purchase = Purchase(
            name: "Test Purchase",
            purchaseDate: purchaseDate
        )
        let interaction = Interaction(
            occurredAt: interactionDate,
            type: .email,
            subject: "Support Follow-up",
            purchase: purchase
        )
        purchase.interactions = [interaction]

        let filtered = TimelineService.entries(for: purchase, filter: .interactions)
        #expect(filtered.count == 1)
        #expect(filtered.first?.title == "Interaction")
    }

    @Test func repairCostServiceCalculatesTotalFromLabourAndParts() {
        let total = RepairCostService.calculateTotal(labour: Decimal(string: "120.50"), parts: Decimal(string: "80.25"))
        #expect(total == Decimal(string: "200.75"))
    }

    @Test func timelineServiceFiltersServicingEvents() {
        let purchase = Purchase(name: "Service Test")
        let serviceDate = Calendar(identifier: .gregorian).date(
            from: DateComponents(year: 2026, month: 9, day: 1)
        )!
        let service = ServiceRecord(serviceType: "Inspection", serviceDate: serviceDate, purchase: purchase)
        purchase.serviceRecords = [service]

        let filtered = TimelineService.entries(for: purchase, filter: .servicing)
        #expect(filtered.count == 1)
        #expect(filtered.first?.title == "Service Record")
    }

    @Test func complaintValidationFailsForBlankTitle() {
        let result = ComplaintCaseEditorValidation.validate(title: "   ")
        #expect(result == "Complaint case title is required.")
    }

    @Test func complaintServiceReturnsDueSoonForNearDeadline() {
        let calendar = Calendar(identifier: .gregorian)
        let opened = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let deadline = calendar.date(from: DateComponents(year: 2026, month: 8, day: 5))!
        let reference = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!

        let complaint = ComplaintCase(
            title: "Delivery dispute",
            dateOpened: opened,
            responseDeadline: deadline
        )

        let state = ComplaintService.deadlineState(for: complaint, asOf: reference, dueSoonDays: 7)
        #expect(state == .dueSoon)
    }

    @Test func complaintServiceChronologyIncludesLinkedEntities() {
        let calendar = Calendar(identifier: .gregorian)
        let purchase = Purchase(name: "Complaint Test")
        let opened = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let interactionDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 3))!
        let faultDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 2))!
        let repairDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 4))!

        let interaction = Interaction(
            occurredAt: interactionDate,
            type: .email,
            subject: "Supplier follow-up",
            purchase: purchase
        )
        let fault = FaultRecord(
            firstNoticedDate: faultDate,
            title: "Screen flicker",
            purchase: purchase
        )
        let repair = RepairRecord(
            repairDate: repairDate,
            diagnosis: "Loose cable",
            purchase: purchase,
            fault: fault
        )
        let document = StoredDocument(
            title: "Complaint Email",
            originalFilename: "complaint.eml",
            storedRelativePath: "seed/complaint.eml",
            purchase: purchase
        )

        let complaint = ComplaintCase(
            title: "Major display issue",
            dateOpened: opened,
            purchase: purchase,
            relatedDocuments: [document],
            relatedInteractions: [interaction],
            relatedFaults: [fault],
            relatedRepairs: [repair]
        )

        let chronology = ComplaintService.chronology(for: complaint)
        #expect(chronology.count == 5)
        #expect(chronology.contains { $0.title == "Interaction" })
        #expect(chronology.contains { $0.title == "Fault" })
        #expect(chronology.contains { $0.title == "Repair" })
        #expect(chronology.contains { $0.title == "Evidence Document" })
    }

}
