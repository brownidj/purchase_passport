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

}
