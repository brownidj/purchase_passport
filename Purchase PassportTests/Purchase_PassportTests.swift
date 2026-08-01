//
//  Purchase_PassportTests.swift
//  Purchase PassportTests
//
//  Created by David Browning on 1/8/2026.
//

import Testing
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

}
