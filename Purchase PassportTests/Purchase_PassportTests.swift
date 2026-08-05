//
//  Purchase_PassportTests.swift
//  Purchase PassportTests
//
//  Created by David Browning on 1/8/2026.
//

import Testing
import Foundation
import SwiftData
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

    @Test func purchaseEditorValidationFailsForBlankProviderName() {
        let result = PurchaseEditorValidation.validate(
            name: "MacBook Pro",
            providerBusinessName: "   "
        )
        #expect(result == "Provider business name is required.")
    }

    @Test func purchaseEditorValidationPassesForProviderName() {
        let result = PurchaseEditorValidation.validate(
            name: "MacBook Pro",
            providerBusinessName: "Tech World Townsville"
        )
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

    @Test func communicationIntelligenceExtractsOrderTrackingAndRMA() {
        let email = CommunicationIntelligenceService.EmailEnvelope(
            messageID: "<msg-001@example.com>",
            threadID: "thread-001",
            sender: "orders@techworld.example",
            recipients: ["david@example.com"],
            subject: "Order update ORD-778899",
            body: """
            Thanks for your order.
            Order Number: ORD-778899
            Tracking Number: TRK-1234567
            RMA Number: RMA-2222
            """,
            sentAt: .now
        )

        let result = CommunicationIntelligenceService.importEmail(email, into: [])

        #expect(result.extractedArtifacts.orderNumber == "ORD-778899")
        #expect(result.extractedArtifacts.trackingNumber == "TRK-1234567")
        #expect(result.extractedArtifacts.rmaNumber == "RMA-2222")
        #expect(result.correspondence.channel == .email)
        #expect(result.correspondence.fullBody?.contains("Tracking Number: TRK-1234567") == true)
    }

    @Test func communicationIntelligenceAutoLinksWhenSignalsAreStrong() {
        let provider = Organisation(
            name: "Tech World Townsville",
            emailAddress: "sales@techworld.example",
            website: "https://www.techworld.example"
        )
        let purchase = Purchase(
            name: "AcmeBook Pro 14",
            orderNumber: "ORD-778899",
            provider: provider
        )
        let email = CommunicationIntelligenceService.EmailEnvelope(
            messageID: "<msg-002@example.com>",
            threadID: "thread-002",
            sender: "support@techworld.example",
            recipients: ["david@example.com"],
            subject: "AcmeBook Pro 14 - warranty update",
            body: "Order Number ORD-778899 has now shipped.",
            sentAt: .now
        )

        let result = CommunicationIntelligenceService.importEmail(email, into: [purchase])

        #expect(result.linkedPurchase?.persistentModelID == purchase.persistentModelID)
        #expect(result.correspondence.reviewStatus == .autoLinked)
        #expect(purchase.correspondences.count == 1)
    }

    @Test func communicationIntelligenceAutoLinksOutgoingEmailToUniqueProviderPurchase() {
        let provider = Organisation(
            name: "Townsville Windows & Screens",
            emailAddress: "admin@twscreens.com.au",
            website: "https://www.twscreens.com.au"
        )
        let purchase = Purchase(
            name: "Security Screens",
            provider: provider
        )
        let email = CommunicationIntelligenceService.EmailEnvelope(
            messageID: "<msg-security-screens-002@example.com>",
            threadID: "thread-security-screens-002",
            sender: "david@example.com",
            recipients: ["accounts@twscreens.com.au"],
            subject: "Screen access concern",
            body: "Please confirm the next steps for the Townsville Windows & Screens installation.",
            sentAt: .now
        )

        let result = CommunicationIntelligenceService.importEmail(email, into: [purchase])

        #expect(result.linkedPurchase?.persistentModelID == purchase.persistentModelID)
        #expect(result.correspondence.reviewStatus == .autoLinked)
    }

    @Test func communicationIntelligenceReimportUpdatesExistingCorrespondenceInPlace() {
        let provider = Organisation(
            name: "Townsville Windows & Screens",
            emailAddress: "admin@twscreens.com.au",
            website: "https://www.twscreens.com.au"
        )
        let purchase = Purchase(name: "Security Screens", provider: provider)
        let correspondence = CorrespondenceRecord(
            occurredAt: .now.addingTimeInterval(-86_400),
            sender: "david@example.com",
            recipients: "admin@twscreens.com.au",
            subject: "Old subject",
            bodyPreview: "Old preview",
            fullBody: "Old body",
            externalMessageID: "<old-message@example.com>"
        )
        let originalID = correspondence.persistentModelID
        let email = CommunicationIntelligenceService.EmailEnvelope(
            messageID: "<new-message@example.com>",
            threadID: "thread-reimport-001",
            sender: "david@example.com",
            recipients: ["accounts@twscreens.com.au"],
            subject: "Updated screen access complaint",
            body: "Crimsafe maintenance access remains impossible in the rear bedrooms.",
            sentAt: .now
        )

        let result = CommunicationIntelligenceService.importEmail(
            email,
            into: [purchase],
            updating: correspondence
        )

        #expect(result.correspondence.persistentModelID == originalID)
        #expect(result.correspondence.subject == "Updated screen access complaint")
        #expect(result.correspondence.fullBody == "Crimsafe maintenance access remains impossible in the rear bedrooms.")
        #expect(result.correspondence.externalMessageID == "<new-message@example.com>")
        #expect(result.linkedPurchase?.persistentModelID == purchase.persistentModelID)
    }

    @Test func communicationIntelligenceApplyAcceptedExtractionsUpdatesPurchaseAndWarranty() {
        let purchase = Purchase(name: "Extraction Apply Test", orderNumber: "OLD-123")
        let warranty = Warranty(title: "Manufacturer", endDate: nil, purchase: purchase)
        purchase.warranties = [warranty]
        let extractedDate = Calendar(identifier: .gregorian).date(
            from: DateComponents(year: 2028, month: 8, day: 2)
        )!
        let correspondence = CorrespondenceRecord(
            occurredAt: .now,
            subject: "Warranty confirmation",
            extractedOrderNumber: "ORD-NEW-778899",
            extractedWarrantyExpiryDate: extractedDate,
            purchase: purchase
        )

        let result = CommunicationIntelligenceService.applyAcceptedExtractions(from: correspondence)

        #expect(purchase.orderNumber == "ORD-NEW-778899")
        #expect(warranty.endDate == extractedDate)
        #expect(correspondence.reviewStatus == .accepted)
        #expect(result.updatedFields.contains("Order Number"))
        #expect(result.updatedFields.contains("Warranty Expiry"))
    }

    @Test func communicationIntelligenceApplyAcceptedExtractionsSkipsWhenNoWarrantyExists() {
        let purchase = Purchase(name: "Extraction Skip Test")
        let correspondence = CorrespondenceRecord(
            occurredAt: .now,
            subject: "Warranty notice",
            extractedWarrantyExpiryDate: .now,
            purchase: purchase
        )

        let result = CommunicationIntelligenceService.applyAcceptedExtractions(from: correspondence)
        #expect(result.skippedFields.contains("No warranty record available to update."))
    }

    @Test func providerCorrespondenceServiceMatchesProviderAndContactEmails() {
        let provider = Organisation(name: "Tech World", emailAddress: "sales@techworld.example")
        let contact = Contact(
            name: "Accounts",
            emailAddress: "accounts@techworld.example",
            organisation: provider
        )
        provider.contacts = [contact]

        let purchase = Purchase(name: "Laptop", provider: provider)
        let matchBySender = CorrespondenceRecord(
            occurredAt: .now,
            sender: "sales@techworld.example",
            subject: "Order update"
        )
        let matchByRecipient = CorrespondenceRecord(
            occurredAt: .now,
            recipients: "Customer <accounts@techworld.example>",
            subject: "Invoice copy"
        )
        let matchByLinkedPurchase = CorrespondenceRecord(
            occurredAt: .now,
            sender: "other@example.com",
            subject: "General note",
            purchase: purchase
        )
        let nonMatch = CorrespondenceRecord(
            occurredAt: .now,
            sender: "someone@another.example",
            subject: "Unrelated"
        )

        let result = ProviderCorrespondenceService.linkedCorrespondences(
            for: provider,
            correspondences: [nonMatch, matchBySender, matchByRecipient, matchByLinkedPurchase]
        )

        #expect(result.count == 3)
        #expect(result.contains(where: { $0.persistentModelID == matchBySender.persistentModelID }))
        #expect(result.contains(where: { $0.persistentModelID == matchByRecipient.persistentModelID }))
        #expect(result.contains(where: { $0.persistentModelID == matchByLinkedPurchase.persistentModelID }))
    }

    @Test func providerCorrespondenceServiceExtractsEmailDomains() {
        let provider = Organisation(name: "Townsville Windows", emailAddress: "admin@twscreens.com.au")
        let contact = Contact(
            name: "Accounts",
            emailAddress: "accounts@twscreens.com.au",
            organisation: provider
        )
        let secondContact = Contact(
            name: "Support",
            emailAddress: "support@service.example",
            organisation: provider
        )
        provider.contacts = [contact, secondContact]

        let domains = ProviderCorrespondenceService.emailDomains(for: provider)

        #expect(domains.contains("twscreens.com.au"))
        #expect(domains.contains("service.example"))
        #expect(domains.count == 2)
    }

    @Test func providerCorrespondenceServiceMatchesByWebsiteDomainWhenContactIsMissing() {
        let provider = Organisation(
            name: "Townsville Windows & Screens",
            website: "https://www.twscreens.com.au"
        )
        let email = CommunicationIntelligenceService.EmailEnvelope(
            messageID: "<msg-website-001@example.com>",
            threadID: nil,
            sender: "windows@twscreens.com.au",
            recipients: ["david@example.com"],
            subject: "Installation update",
            body: "Your install is booked in.",
            sentAt: .now
        )

        #expect(ProviderCorrespondenceService.matches(email, provider: provider))
    }

    @Test func providerCorrespondenceServiceMatchesSubdomainRecipientForDraftStyleEmail() {
        let provider = Organisation(
            name: "Townsville Windows & Screens",
            emailAddress: "admin@twscreens.com.au"
        )
        let email = CommunicationIntelligenceService.EmailEnvelope(
            messageID: nil,
            threadID: nil,
            sender: "david@example.com",
            recipients: ["quotes@north.twscreens.com.au"],
            subject: "Draft quote request",
            body: "Please confirm the revised scope.",
            sentAt: .now
        )

        #expect(ProviderCorrespondenceService.matches(email, provider: provider))
    }

    @Test func providerCorrespondenceServiceMatchesSelectedEmailToProviderByDomain() {
        let provider = Organisation(name: "Townsville Windows & Screens", emailAddress: "admin@twscreens.com.au")
        let email = CommunicationIntelligenceService.EmailEnvelope(
            messageID: "<msg-003@example.com>",
            threadID: nil,
            sender: "windows@twscreens.com.au",
            recipients: ["david@example.com"],
            subject: "Quote follow-up",
            body: "Thanks for contacting Townsville Windows & Screens.",
            sentAt: .now
        )

        #expect(ProviderCorrespondenceService.matches(email, provider: provider))
    }

    @Test func communicationIntelligenceParsesEmailFile() throws {
        let emailFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("eml")
        let rawMessage = """
        From: windows@twscreens.com.au
        To: david@example.com
        Cc: quotes@north.twscreens.com.au
        Bcc: archive@twscreens.com.au
        Subject: Quote follow-up
        Date: Tue, 24 Dec 2024 10:15:00 +1000
        Message-ID: <msg-quote-001@twscreens.com.au>

        Hello David,
        Here is the follow-up quote.
        """
        try rawMessage.write(to: emailFileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: emailFileURL) }

        let envelope = try CommunicationIntelligenceService.parseEmailFile(at: emailFileURL)

        #expect(envelope.sender == "windows@twscreens.com.au")
        #expect(envelope.recipients.contains("david@example.com"))
        #expect(envelope.recipients.contains("quotes@north.twscreens.com.au"))
        #expect(envelope.recipients.contains("archive@twscreens.com.au"))
        #expect(envelope.subject == "Quote follow-up")
        #expect(envelope.messageID == "<msg-quote-001@twscreens.com.au>")
        #expect(envelope.body.contains("follow-up quote"))
    }

    @Test func providerEmailImportServiceFallbackKeysRejectDuplicateImportedDraft() {
        let correspondence = CorrespondenceRecord(
            occurredAt: .now,
            sender: "david@example.com",
            recipients: "archive@twscreens.com.au, quotes@north.twscreens.com.au",
            subject: "Draft quote request",
            bodyPreview: "Please confirm the revised scope.",
            threadID: nil
        )
        let envelope = CommunicationIntelligenceService.EmailEnvelope(
            messageID: nil,
            threadID: nil,
            sender: "david@example.com",
            recipients: ["quotes@north.twscreens.com.au", "archive@twscreens.com.au"],
            subject: "Draft quote request",
            body: "Please confirm the revised scope.",
            sentAt: .now
        )

        #expect(
            ProviderEmailImportService.correspondenceFallbackKey(correspondence)
                == ProviderEmailImportService.envelopeFallbackKey(envelope)
        )
    }

    @Test func communicationIntelligenceParsesEMLXEmailFile() throws {
        let emailFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("emlx")
        let rawMessage = """
        From: windows@twscreens.com.au
        To: david@example.com
        Subject: Mail drag export
        Date: Tue, 24 Dec 2024 10:15:00 +1000
        Message-ID: <msg-quote-002@twscreens.com.au>

        Hello David,
        This came from a Mail export.
        """
        let messageData = rawMessage.data(using: .utf8)!
        let emlxData = Data("\(messageData.count)\n".utf8)
            + messageData
            + Data("\n<plist version=\"1.0\"></plist>".utf8)
        try emlxData.write(to: emailFileURL)
        defer { try? FileManager.default.removeItem(at: emailFileURL) }

        let envelope = try CommunicationIntelligenceService.parseEmailFile(at: emailFileURL)

        #expect(envelope.subject == "Mail drag export")
        #expect(envelope.messageID == "<msg-quote-002@twscreens.com.au>")
        #expect(envelope.body.contains("Mail export"))
    }

    @Test func providerCorrespondenceServiceBuildsMailMessageURL() {
        let url = ProviderCorrespondenceService.mailMessageURL(for: "rma-88421@acme.example")
        #expect(url?.absoluteString.contains("message://") == true)
        #expect(url?.absoluteString.contains("%3Crma-88421%40acme.example%3E") == true)
    }

    @MainActor
    @Test func communicationIntelligenceCleansUpLegacyGeneratedEmailInteractions() throws {
        let container = try makeTestModelContainer()
        let modelContext = container.mainContext
        let occurredAt = Calendar(identifier: .gregorian).date(
            from: DateComponents(year: 2024, month: 12, day: 24, hour: 10, minute: 15)
        )!

        let purchase = Purchase(name: "Security Screens", status: .active)
        let correspondence = CorrespondenceRecord(
            occurredAt: occurredAt,
            sender: "admin@twscreens.com.au",
            recipients: "david@example.com",
            subject: "Warranty update",
            bodyPreview: "Crimsafe confirmed the next inspection step.",
            externalMessageID: "<security-screens-001@twscreens.com.au>",
            reviewStatus: .accepted,
            extractedRMANumber: "RMA-4455",
            purchase: purchase
        )
        let interaction = Interaction(
            occurredAt: occurredAt,
            type: .email,
            status: .resolved,
            subject: "Warranty update",
            summary: "Crimsafe confirmed the next inspection step.",
            referenceNumber: "RMA-4455",
            purchase: purchase,
            sourceCorrespondence: correspondence
        )

        purchase.correspondences = [correspondence]
        purchase.interactions = [interaction]
        correspondence.generatedInteraction = interaction
        modelContext.insert(purchase)
        modelContext.insert(correspondence)
        modelContext.insert(interaction)

        try CommunicationIntelligenceService.cleanupLegacyGeneratedEmailInteractions(in: modelContext)

        let remainingInteractions = try modelContext.fetch(FetchDescriptor<Interaction>())
        #expect(purchase.interactions.isEmpty)
        #expect(correspondence.generatedInteraction == nil)
        #expect(remainingInteractions.isEmpty)
    }

    @Test func timelineServiceIncludesCorrespondenceAndComplaintEvents() {
        let purchase = Purchase(name: "Timeline Test")
        let correspondenceDate = Calendar(identifier: .gregorian).date(
            from: DateComponents(year: 2026, month: 8, day: 6)
        )!
        let complaintDate = Calendar(identifier: .gregorian).date(
            from: DateComponents(year: 2026, month: 8, day: 7)
        )!

        let correspondence = CorrespondenceRecord(
            occurredAt: correspondenceDate,
            subject: "Delivery delay acknowledgement",
            purchase: purchase
        )
        let complaint = ComplaintCase(
            title: "Delayed delivery",
            dateOpened: complaintDate,
            purchase: purchase
        )

        purchase.correspondences = [correspondence]
        purchase.complaintCases = [complaint]

        let entries = TimelineService.entries(for: purchase, filter: .interactions)
        #expect(entries.contains(where: { $0.title == "Email Correspondence" }))
        #expect(entries.contains(where: { $0.title == "Complaint Opened" }))
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

    @Test func dashboardServiceReturnsOnlyUnresolvedFaults() {
        let purchase = Purchase(name: "Fault Dashboard Test")
        let openFault = FaultRecord(firstNoticedDate: .now, title: "Open Fault", status: .open, purchase: purchase)
        let closedFault = FaultRecord(firstNoticedDate: .now, title: "Closed Fault", status: .closed, purchase: purchase)
        let resolvedFault = FaultRecord(firstNoticedDate: .now, title: "Resolved Fault", status: .resolved, purchase: purchase)

        let unresolved = DashboardService.unresolvedFaults(from: [openFault, closedFault, resolvedFault], limit: 10)

        #expect(unresolved.count == 1)
        #expect(unresolved.first?.title == "Open Fault")
    }

    @Test func dashboardServiceFlagsOnlyActiveComplaints() {
        let active = ComplaintCase(title: "Open case", status: .open)
        let escalated = ComplaintCase(title: "Escalated case", status: .escalated)
        let resolved = ComplaintCase(title: "Resolved case", status: .resolved)

        let result = DashboardService.activeComplaints(from: [active, escalated, resolved], limit: 10)

        #expect(result.count == 2)
        #expect(result.contains(where: { $0.title == "Open case" }))
        #expect(result.contains(where: { $0.title == "Escalated case" }))
    }

    @Test func dashboardServiceFindsServiceDueWithinWindow() {
        let calendar = Calendar(identifier: .gregorian)
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let inWindow = calendar.date(byAdding: .day, value: 10, to: referenceDate)!
        let outWindow = calendar.date(byAdding: .day, value: 45, to: referenceDate)!

        let dueSoon = ServiceRecord(serviceType: "Due soon", nextServiceDate: inWindow)
        let dueLater = ServiceRecord(serviceType: "Due later", nextServiceDate: outWindow)

        let result = DashboardService.serviceDueDates(
            from: [dueSoon, dueLater],
            asOf: referenceDate,
            dueWithinDays: 30,
            limit: 10
        )

        #expect(result.count == 1)
        #expect(result.first?.serviceType == "Due soon")
    }

    @Test func appRootWorkflowAutoselectReturnsNilForEmptyItems() {
        let selected = AppRootWorkflowCoordinator.autoselectID(
            in: [Purchase](),
            lastSelectedID: nil
        )
        #expect(selected == nil)
    }

    @Test func appRootWorkflowAutoselectPrefersLastSelectionWhenPresent() {
        let first = Purchase(name: "First")
        let second = Purchase(name: "Second")

        let selected = AppRootWorkflowCoordinator.autoselectID(
            in: [first, second],
            lastSelectedID: second.persistentModelID
        )

        #expect(selected == second.persistentModelID)
    }

    @Test func appRootWorkflowAutoselectFallsBackToFirstWhenLastMissing() {
        let first = Purchase(name: "First")
        let second = Purchase(name: "Second")
        let missing = Purchase(name: "Missing")

        let selected = AppRootWorkflowCoordinator.autoselectID(
            in: [first, second],
            lastSelectedID: missing.persistentModelID
        )

        #expect(selected == first.persistentModelID)
    }

    @Test func appRootSelectionApplySectionChangeTriggersExpectedActions() {
        var clearPurchaseAndDocumentCalls = 0
        var autoselectPurchaseCalls = 0
        var autoselectProvidersCalls = 0
        var autoselectSearchCalls = 0
        var autoselectServicingCalls = 0
        var autoselectInteractionsCalls = 0
        var autoselectComplaintsCalls = 0
        var autoselectWarrantiesCalls = 0
        var autoselectRemindersCalls = 0
        var clearAllCalls = 0

        AppRootSelectionCoordinator.applySectionChange(
            .servicing,
            clearPurchaseAndDocument: { clearPurchaseAndDocumentCalls += 1 },
            autoselectPurchase: { autoselectPurchaseCalls += 1 },
            autoselectProviders: { autoselectProvidersCalls += 1 },
            autoselectSearch: { autoselectSearchCalls += 1 },
            autoselectServicing: { autoselectServicingCalls += 1 },
            autoselectInteractions: { autoselectInteractionsCalls += 1 },
            autoselectComplaints: { autoselectComplaintsCalls += 1 },
            autoselectWarranties: { autoselectWarrantiesCalls += 1 },
            autoselectReminders: { autoselectRemindersCalls += 1 },
            clearAll: { clearAllCalls += 1 }
        )

        #expect(clearPurchaseAndDocumentCalls == 1)
        #expect(autoselectServicingCalls == 1)
        #expect(autoselectPurchaseCalls == 0)
        #expect(autoselectProvidersCalls == 0)
        #expect(autoselectSearchCalls == 0)
        #expect(autoselectInteractionsCalls == 0)
        #expect(autoselectComplaintsCalls == 0)
        #expect(autoselectWarrantiesCalls == 0)
        #expect(autoselectRemindersCalls == 0)
        #expect(clearAllCalls == 0)
    }

    @Test func appRootSelectionLinkedSelectionsChoosesSortedDefaults() {
        let calendar = Calendar(identifier: .gregorian)
        let purchase = Purchase(name: "Selection Test")

        let oldDocument = StoredDocument(
            title: "Old",
            originalFilename: "old.pdf",
            storedRelativePath: "seed/old.pdf",
            dateAdded: calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!,
            purchase: purchase
        )
        let newDocument = StoredDocument(
            title: "New",
            originalFilename: "new.pdf",
            storedRelativePath: "seed/new.pdf",
            dateAdded: calendar.date(from: DateComponents(year: 2026, month: 8, day: 2))!,
            purchase: purchase
        )

        let openReminder = Reminder(
            title: "Later",
            dueDate: calendar.date(from: DateComponents(year: 2026, month: 8, day: 10))!,
            purchase: purchase
        )
        let soonerReminder = Reminder(
            title: "Sooner",
            dueDate: calendar.date(from: DateComponents(year: 2026, month: 8, day: 5))!,
            purchase: purchase
        )

        let interactionEarlier = Interaction(
            occurredAt: calendar.date(from: DateComponents(year: 2026, month: 8, day: 3))!,
            type: .email,
            subject: "Earlier",
            purchase: purchase
        )
        let interactionLater = Interaction(
            occurredAt: calendar.date(from: DateComponents(year: 2026, month: 8, day: 6))!,
            type: .email,
            subject: "Later",
            purchase: purchase
        )

        purchase.documents = [oldDocument, newDocument]
        purchase.reminders = [openReminder, soonerReminder]
        purchase.interactions = [interactionEarlier, interactionLater]

        let selections = AppRootSelectionCoordinator.linkedSelections(for: purchase)

        #expect(selections.document?.title == "New")
        #expect(selections.reminder?.title == "Sooner")
        #expect(selections.interaction?.subject == "Later")
    }

    @Test func appRootWorkflowConvertsServiceToFaultUsingMappedFields() {
        let purchase = Purchase(name: "Mapping Test")
        let serviceDate = Calendar(identifier: .gregorian).date(
            from: DateComponents(year: 2026, month: 9, day: 10)
        )!
        let service = ServiceRecord(
            serviceType: "Inspection",
            serviceDate: serviceDate,
            workRequested: "Screen flicker during use",
            workCompleted: "Checked ribbon cable",
            technicianNotes: "Intermittent after prolonged use",
            purchase: purchase
        )

        let fault = AppRootWorkflowCoordinator.convertServiceRecordToFault(service)

        #expect(fault.title == "Inspection")
        #expect(fault.firstNoticedDate == serviceDate)
        #expect(fault.detailedDescription == "Screen flicker during use")
        #expect(fault.diagnosticInformation == "Checked ribbon cable")
        #expect(fault.effectOnUse == "Intermittent after prolonged use")
        #expect(fault.severity == .medium)
        #expect(fault.status == .open)
    }

    @Test func appRootWorkflowConvertsFaultToRepairUsingMappedFields() {
        let purchase = Purchase(name: "Repair Mapping Test")
        let fault = FaultRecord(
            firstNoticedDate: .now,
            title: "Trackpad issue",
            detailedDescription: "Trackpad does not click intermittently",
            status: .resolved,
            effectOnUse: "Cannot reliably select items",
            sellerOrManufacturerNotified: true,
            purchase: purchase
        )

        let repair = AppRootWorkflowCoordinator.convertFaultToRepair(fault)

        #expect(repair.diagnosis == "Trackpad issue")
        #expect(repair.workPerformed == "Trackpad does not click intermittently")
        #expect(repair.warrantyCoverage == true)
        #expect(repair.paymentStatus == RepairPaymentStatus.unpaid)
        #expect(repair.outcome == "Resolved")
        #expect(repair.followUpRequired == false)
        #expect(repair.unresolvedIssues == "Cannot reliably select items")
    }

    @Test func purchaseSearchServiceMatchesAcrossTagsAndDocuments() {
        let workTag = Tag(name: "Work")
        let purchase = Purchase(
            name: "AcmeBook Pro 14",
            seller: "Tech World",
            tags: [workTag]
        )
        let receipt = StoredDocument(
            title: "Tax Invoice",
            originalFilename: "invoice.pdf",
            storedRelativePath: "seed/invoice.pdf",
            purchase: purchase
        )
        purchase.documents = [receipt]

        let results = PurchaseSearchService.search(
            purchases: [purchase],
            query: "work invoice",
            filters: .default,
            sortOption: .mostRecent
        )

        #expect(results.count == 1)
        #expect(results.first?.name == "AcmeBook Pro 14")
    }

    @Test func purchaseSearchServiceMatchesCorrespondenceFullBody() {
        let purchase = Purchase(name: "Security Screens")
        let correspondence = CorrespondenceRecord(
            occurredAt: .now,
            sender: "david@example.com",
            recipients: "accounts@twscreens.com.au",
            subject: "Maintenance access issue",
            bodyPreview: "The inaccessible bedroom screens remain a problem.",
            fullBody: """
            The inaccessible bedroom screens remain a problem.
            Crimsafe maintenance requirements cannot be performed on the rear bedrooms.
            """,
            purchase: purchase
        )
        purchase.correspondences = [correspondence]

        let results = PurchaseSearchService.search(
            purchases: [purchase],
            query: "crimsafe rear bedrooms",
            filters: .default,
            sortOption: .mostRecent
        )

        #expect(results.count == 1)
        #expect(results.first?.name == "Security Screens")
    }

    @Test func purchaseSearchServiceAppliesAdvancedFilters() {
        let calendar = Calendar(identifier: .gregorian)
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let upcomingReminderDate = calendar.date(byAdding: .day, value: 7, to: referenceDate)!

        let electronicsCategory = PurchaseCategory(name: "Electronics")

        let matching = Purchase(
            name: "Laptop",
            status: .active,
            purchaseDate: referenceDate,
            category: electronicsCategory
        )
        matching.reminders = [
            Reminder(title: "Warranty follow-up", dueDate: upcomingReminderDate, purchase: matching)
        ]
        matching.complaintCases = [ComplaintCase(title: "Open case", status: .open, purchase: matching)]

        let nonMatching = Purchase(
            name: "Archived Phone",
            status: .archived,
            purchaseDate: referenceDate,
            category: electronicsCategory
        )

        let filters = PurchaseSearchFilters(
            categoryName: "Electronics",
            status: .active,
            upcomingReminderOnly: true,
            activeComplaintOnly: true,
            includeArchived: false
        )

        let results = PurchaseSearchService.search(
            purchases: [matching, nonMatching],
            query: "",
            filters: filters,
            sortOption: .mostRecent,
            referenceDate: referenceDate
        )

        #expect(results.count == 1)
        #expect(results.first?.name == "Laptop")
    }

    @Test func purchaseSearchServiceSavedSearchesRoundTrip() {
        let saved = SavedPurchaseSearch(
            name: "Warranty Focus",
            query: "laptop",
            filters: PurchaseSearchFilters(status: .active, warrantyFilter: .active),
            sortOption: .warrantyExpirySoonest
        )

        let encoded = PurchaseSearchService.encodeSavedSearches([saved])
        let decoded = PurchaseSearchService.decodeSavedSearches(from: encoded)

        #expect(decoded.count == 1)
        #expect(decoded.first?.name == "Warranty Focus")
        #expect(decoded.first?.filters.status == .active)
        #expect(decoded.first?.sortOption == .warrantyExpirySoonest)
    }

    @Test func purchaseExportServiceReportContainsKeySummaryFields() {
        let purchase = Purchase(
            name: "AcmeBook Pro 14",
            status: .active,
            purchasePrice: Decimal(string: "2999.99"),
            currencyCode: "AUD",
            seller: "Tech World",
            manufacturer: "Acme"
        )

        let report = PurchaseExportService.purchaseReportText(for: purchase)
        #expect(report.contains("Purchase Name: AcmeBook Pro 14"))
        #expect(report.contains("Status: \(PurchaseStatus.active.rawValue)"))
        #expect(report.contains("Purchase Price: AUD 2999.99"))
    }

    @Test func purchaseExportArchiveValidationPassesForFreshExport() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let purchase = Purchase(name: "Archive Test Purchase", status: .active)
        try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        let archiveURL = tempRoot.appendingPathComponent("archive.pparchive", isDirectory: true)

        try PurchaseExportService.exportArchive(for: purchase, to: archiveURL)
        let issues = PurchaseExportService.validateArchive(at: archiveURL)

        #expect(issues.isEmpty)
    }

    @Test func purchaseExportPDFReportWritesNonEmptyFile() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let purchase = Purchase(name: "PDF Test Purchase", status: .active)
        try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        let destinationURL = tempRoot.appendingPathComponent("purchase-report.pdf")

        try PurchaseExportService.exportPDFReport(for: purchase, to: destinationURL)
        #expect(fileManager.fileExists(atPath: destinationURL.path))

        let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
        let size = attributes[.size] as? NSNumber
        #expect((size?.intValue ?? 0) > 0)
    }

    @Test func backupValidationPassesForFreshExport() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let purchases = [
            Purchase(name: "Backup One", status: .active),
            Purchase(name: "Backup Two", status: .ordered)
        ]

        try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        let backupURL = tempRoot.appendingPathComponent("backup.ppbackup", isDirectory: true)
        try BackupService.exportBackup(for: purchases, to: backupURL)

        let issues = BackupService.validateBackup(at: backupURL)
        #expect(issues.isEmpty)
    }

    @Test func purchaseArchiveImportRestoresPurchaseFields() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let purchase = Purchase(
            name: "Imported Purchase",
            status: .active,
            purchaseDate: Date(timeIntervalSince1970: 1_700_000_000),
            purchasePrice: Decimal(string: "1499.95"),
            currencyCode: "AUD",
            seller: "Retailer",
            manufacturer: "Maker"
        )

        try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        let archiveURL = tempRoot.appendingPathComponent("import.pparchive", isDirectory: true)
        try PurchaseExportService.exportArchive(for: purchase, to: archiveURL)

        let restored = try PurchaseExportService.importArchive(at: archiveURL)
        #expect(restored.name == "Imported Purchase")
        #expect(restored.status == .active)
        #expect(restored.currencyCode == "AUD")
        #expect(restored.purchasePrice == Decimal(string: "1499.95"))
        #expect(restored.seller == "Retailer")
        #expect(restored.manufacturer == "Maker")
    }

    @Test func purchaseArchiveImportFailsWhenManifestReferencesMissingAttachment() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let archiveURL = tempRoot.appendingPathComponent("broken.pparchive", isDirectory: true)
        try fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)
        let attachmentsURL = archiveURL.appendingPathComponent("attachments", isDirectory: true)
        try fileManager.createDirectory(at: attachmentsURL, withIntermediateDirectories: true)

        let manifestURL = archiveURL.appendingPathComponent("manifest.json")
        let manifestObject: [String: Any] = [
            "schemaVersion": 1,
            "exportedAt": ISO8601DateFormatter().string(from: .now),
            "purchaseName": "Broken Import",
            "purchaseStatus": PurchaseStatus.active.rawValue,
            "attachmentCount": 1,
            "attachments": [
                [
                    "documentIdentifier": UUID().uuidString,
                    "title": "Missing Receipt",
                    "category": DocumentCategory.receipt.rawValue,
                    "originalFilename": "receipt.pdf",
                    "archivedRelativePath": "attachments/missing-receipt.pdf"
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: manifestObject, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: manifestURL, options: .atomic)

        do {
            _ = try PurchaseExportService.importArchive(at: archiveURL)
            Issue.record("Expected missing attachment error.")
        } catch let error as PurchaseExportService.ExportError {
            switch error {
            case .missingAttachment(let relativePath):
                #expect(relativePath == "attachments/missing-receipt.pdf")
            default:
                Issue.record("Unexpected export error: \(error.localizedDescription)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error.localizedDescription)")
        }
    }

    @Test func backupRestoreReturnsAllPurchasesFromBackup() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let purchases = [
            Purchase(name: "Restore One", status: .active),
            Purchase(name: "Restore Two", status: .ordered)
        ]

        try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        let backupURL = tempRoot.appendingPathComponent("restore.ppbackup", isDirectory: true)
        try BackupService.exportBackup(for: purchases, to: backupURL)

        let restored = try BackupService.restoreBackup(at: backupURL)
        #expect(restored.count == 2)
        #expect(restored.contains(where: { $0.name == "Restore One" }))
        #expect(restored.contains(where: { $0.name == "Restore Two" }))
    }

    @Test func purchaseArchiveImportRejectsUnsafeAttachmentPath() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let archiveURL = tempRoot.appendingPathComponent("unsafe.pparchive", isDirectory: true)
        try fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)
        let attachmentsURL = archiveURL.appendingPathComponent("attachments", isDirectory: true)
        try fileManager.createDirectory(at: attachmentsURL, withIntermediateDirectories: true)

        let manifestObject: [String: Any] = [
            "schemaVersion": 1,
            "exportedAt": ISO8601DateFormatter().string(from: .now),
            "purchaseName": "Unsafe Import",
            "purchaseStatus": PurchaseStatus.active.rawValue,
            "attachmentCount": 1,
            "attachments": [
                [
                    "documentIdentifier": UUID().uuidString,
                    "title": "Unsafe",
                    "category": DocumentCategory.receipt.rawValue,
                    "originalFilename": "receipt.pdf",
                    "archivedRelativePath": "../escape.pdf"
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: manifestObject, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: archiveURL.appendingPathComponent("manifest.json"), options: .atomic)

        do {
            _ = try PurchaseExportService.importArchive(at: archiveURL)
            Issue.record("Expected invalid attachment path error.")
        } catch let error as PurchaseExportService.ExportError {
            switch error {
            case .invalidAttachmentPath(let path):
                #expect(path == "../escape.pdf")
            default:
                Issue.record("Unexpected export error: \(error.localizedDescription)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error.localizedDescription)")
        }
    }

    @Test func appRootWorkflowResolvePurchaseNameConflictsRenamesDuplicates() {
        let existingPurchases = [Purchase(name: "MacBook"), Purchase(name: "iPhone")]
        let importedPurchases = [Purchase(name: "MacBook"), Purchase(name: "MacBook"), Purchase(name: "Watch")]

        let resolutions = AppRootWorkflowCoordinator.resolvePurchaseNameConflicts(
            importedPurchases: importedPurchases,
            existingPurchases: existingPurchases
        )

        #expect(importedPurchases[0].name == "MacBook (Imported 2)")
        #expect(importedPurchases[1].name == "MacBook (Imported 3)")
        #expect(importedPurchases[2].name == "Watch")
        #expect(resolutions.count == 2)
    }

    @Test func purchaseArchiveImportRejectsInvalidPurchaseStatus() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let archiveURL = tempRoot.appendingPathComponent("invalid-status.pparchive", isDirectory: true)
        try fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(
            at: archiveURL.appendingPathComponent("attachments", isDirectory: true),
            withIntermediateDirectories: true
        )

        let manifestObject: [String: Any] = [
            "schemaVersion": 1,
            "exportedAt": ISO8601DateFormatter().string(from: .now),
            "purchaseName": "Invalid Status Purchase",
            "purchaseStatus": "not-a-real-status",
            "attachmentCount": 0,
            "attachments": []
        ]
        let data = try JSONSerialization.data(withJSONObject: manifestObject, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: archiveURL.appendingPathComponent("manifest.json"), options: .atomic)

        do {
            _ = try PurchaseExportService.importArchive(at: archiveURL)
            Issue.record("Expected invalid purchase status error.")
        } catch let error as PurchaseExportService.ExportError {
            switch error {
            case .invalidPurchaseStatus(let value):
                #expect(value == "not-a-real-status")
            default:
                Issue.record("Unexpected export error: \(error.localizedDescription)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error.localizedDescription)")
        }
    }

    @Test func backupRestoreRejectsInvalidArchivePathInManifest() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let backupURL = tempRoot.appendingPathComponent("invalid-path.ppbackup", isDirectory: true)
        try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true)

        let manifestObject: [String: Any] = [
            "schemaVersion": 1,
            "createdAt": ISO8601DateFormatter().string(from: .now),
            "purchaseCount": 1,
            "purchaseArchives": ["../outside.pparchive"]
        ]
        let data = try JSONSerialization.data(withJSONObject: manifestObject, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: backupURL.appendingPathComponent("backup-manifest.json"), options: .atomic)

        do {
            _ = try BackupService.restoreBackup(at: backupURL)
            Issue.record("Expected invalid archive path error.")
        } catch let error as BackupService.BackupError {
            switch error {
            case .invalidArchivePath(let value):
                #expect(value == "../outside.pparchive")
            default:
                Issue.record("Unexpected backup error: \(error.localizedDescription)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error.localizedDescription)")
        }
    }

    @Test func purchaseArchiveValidationReportsInvalidPurchaseStatusIssue() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let archiveURL = tempRoot.appendingPathComponent("invalid-status-validation.pparchive", isDirectory: true)
        try fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(
            at: archiveURL.appendingPathComponent("attachments", isDirectory: true),
            withIntermediateDirectories: true
        )

        let manifestObject: [String: Any] = [
            "schemaVersion": 1,
            "exportedAt": ISO8601DateFormatter().string(from: .now),
            "purchaseName": "Validation Purchase",
            "purchaseStatus": "broken-status",
            "attachmentCount": 0,
            "attachments": []
        ]
        let data = try JSONSerialization.data(withJSONObject: manifestObject, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: archiveURL.appendingPathComponent("manifest.json"), options: .atomic)

        let issues = PurchaseExportService.validateArchive(at: archiveURL)
        #expect(issues.contains(where: { $0.contains("Purchase status is invalid") }))
    }

    @Test func backupValidationReportsInvalidArchivePathIssue() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let backupURL = tempRoot.appendingPathComponent("invalid-path-validation.ppbackup", isDirectory: true)
        try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true)

        let manifestObject: [String: Any] = [
            "schemaVersion": 1,
            "createdAt": ISO8601DateFormatter().string(from: .now),
            "purchaseCount": 1,
            "purchaseArchives": ["../bad.pparchive"]
        ]
        let data = try JSONSerialization.data(withJSONObject: manifestObject, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: backupURL.appendingPathComponent("backup-manifest.json"), options: .atomic)

        let issues = BackupService.validateBackup(at: backupURL)
        #expect(issues.contains(where: { $0.contains("Invalid archive path in backup manifest") }))
    }

    @Test func appRootWorkflowResolveDocumentIdentifierConflictsReassignsDuplicates() {
        let duplicateIdentifier = UUID()

        let existingPurchase = Purchase(name: "Existing")
        let existingDocument = StoredDocument(
            identifier: duplicateIdentifier,
            title: "Existing Receipt",
            originalFilename: "existing.pdf",
            storedRelativePath: "existing.pdf",
            purchase: existingPurchase
        )
        existingPurchase.documents = [existingDocument]

        let importedPurchase = Purchase(name: "Imported")
        let importedDocument = StoredDocument(
            identifier: duplicateIdentifier,
            title: "Imported Receipt",
            originalFilename: "imported.pdf",
            storedRelativePath: "imported.pdf",
            purchase: importedPurchase
        )
        importedPurchase.documents = [importedDocument]

        let resolutions = AppRootWorkflowCoordinator.resolveDocumentIdentifierConflicts(
            importedPurchases: [importedPurchase],
            existingPurchases: [existingPurchase]
        )

        #expect(resolutions.count == 1)
        #expect(resolutions.first?.originalIdentifier == duplicateIdentifier)
        #expect(importedDocument.identifier != duplicateIdentifier)
        #expect(importedDocument.identifier == resolutions.first?.resolvedIdentifier)
    }

    @Test func appRootFormattingValidationIssueSummaryTruncatesOutput() {
        let issues = (1...10).map { "Issue \($0)" }
        let summary = AppRootFormatting.validationIssueSummary(issues)

        #expect(summary.contains("• Issue 1"))
        #expect(summary.contains("• Issue 8"))
        #expect(!summary.contains("• Issue 9"))
        #expect(summary.contains("…and 2 more issue(s)."))
    }

    @Test func purchaseArchiveValidationReportsChecksumMismatchAfterTamper() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let sourceURL = tempRoot.appendingPathComponent("receipt.txt")
        try "original".write(to: sourceURL, atomically: true, encoding: .utf8)
        let imported = try DocumentStorageService.importFile(from: sourceURL)

        let purchase = Purchase(name: "Checksum Validation Test", status: .active)
        let document = StoredDocument(
            title: "Receipt",
            category: .receipt,
            originalFilename: imported.originalFilename,
            contentType: imported.contentType,
            storedRelativePath: imported.storedRelativePath,
            purchase: purchase
        )
        purchase.documents = [document]

        let archiveURL = tempRoot.appendingPathComponent("checksum-validate.pparchive", isDirectory: true)
        try PurchaseExportService.exportArchive(for: purchase, to: archiveURL)

        let archivedAttachmentURL = archiveURL
            .appendingPathComponent("attachments", isDirectory: true)
            .appendingPathComponent("\(document.identifier.uuidString)-receipt.txt")
        try "tampered".write(to: archivedAttachmentURL, atomically: true, encoding: .utf8)

        let issues = PurchaseExportService.validateArchive(at: archiveURL)
        #expect(issues.contains(where: { $0.contains("Checksum mismatch for attachment") }))
    }

    @Test func purchaseArchiveImportFailsWhenAttachmentChecksumMismatches() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let sourceURL = tempRoot.appendingPathComponent("invoice.txt")
        try "original-invoice".write(to: sourceURL, atomically: true, encoding: .utf8)
        let imported = try DocumentStorageService.importFile(from: sourceURL)

        let purchase = Purchase(name: "Checksum Import Test", status: .active)
        let document = StoredDocument(
            title: "Invoice",
            category: .invoice,
            originalFilename: imported.originalFilename,
            contentType: imported.contentType,
            storedRelativePath: imported.storedRelativePath,
            purchase: purchase
        )
        purchase.documents = [document]

        let archiveURL = tempRoot.appendingPathComponent("checksum-import.pparchive", isDirectory: true)
        try PurchaseExportService.exportArchive(for: purchase, to: archiveURL)

        let archivedAttachmentURL = archiveURL
            .appendingPathComponent("attachments", isDirectory: true)
            .appendingPathComponent("\(document.identifier.uuidString)-invoice.txt")
        try "tampered-invoice".write(to: archivedAttachmentURL, atomically: true, encoding: .utf8)

        do {
            _ = try PurchaseExportService.importArchive(at: archiveURL)
            Issue.record("Expected attachment checksum mismatch error.")
        } catch let error as PurchaseExportService.ExportError {
            switch error {
            case .attachmentChecksumMismatch(let relativePath):
                #expect(relativePath == "attachments/\(document.identifier.uuidString)-invoice.txt")
            default:
                Issue.record("Unexpected export error: \(error.localizedDescription)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error.localizedDescription)")
        }
    }

    @Test func backupRestoreWithReportRestoresValidArchivesAndSkipsInvalidOnes() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }

        let purchases = [
            Purchase(name: "Valid One", status: .active),
            Purchase(name: "Will Become Invalid", status: .ordered)
        ]

        try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        let backupURL = tempRoot.appendingPathComponent("partial-restore.ppbackup", isDirectory: true)
        try BackupService.exportBackup(for: purchases, to: backupURL)

        let purchasesDirectory = backupURL.appendingPathComponent("purchases", isDirectory: true)
        let archiveDirectories = try fileManager.contentsOfDirectory(
            at: purchasesDirectory,
            includingPropertiesForKeys: nil
        )
        let targetArchive = archiveDirectories.first { $0.lastPathComponent.contains("Will Become Invalid") }
        if let targetArchive {
            try fileManager.removeItem(at: targetArchive.appendingPathComponent("manifest.json"))
        } else {
            Issue.record("Expected to find exported archive to tamper with.")
        }

        let report = try BackupService.restoreBackupWithReport(at: backupURL)
        #expect(report.restoredPurchases.count == 1)
        #expect(report.restoredPurchases.first?.name == "Valid One")
        #expect(report.issues.count == 1)
        #expect(report.issues.first?.contains("Skipped purchases/") == true)
    }

    @Test func backupWriteRestoreReportCreatesReadableLogFile() throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempRoot) }
        try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)

        let report = BackupService.RestoreReport(
            restoredPurchases: [Purchase(name: "Restored Purchase", status: .active)],
            issues: ["Skipped purchases/broken.pparchive: manifest.json is missing."]
        )

        let logURL = try BackupService.writeRestoreReport(for: tempRoot, report: report)
        #expect(fileManager.fileExists(atPath: logURL.path))

        let text = try String(contentsOf: logURL, encoding: .utf8)
        #expect(text.contains("Purchase Passport Restore Report"))
        #expect(text.contains("Restored Purchases: 1"))
        #expect(text.contains("Skipped Archives: 1"))
        #expect(text.contains("Restored Purchase"))
        #expect(text.contains("broken.pparchive"))
    }

    @MainActor
    private func makeTestModelContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Purchase.self,
            PurchaseCategory.self,
            FinancialTransaction.self,
            Tag.self,
            Contact.self,
            Organisation.self,
            StoredDocument.self,
            Warranty.self,
            Reminder.self,
            Interaction.self,
            CorrespondenceRecord.self,
            ComplaintCase.self,
            ServiceRecord.self,
            FaultRecord.self,
            RepairRecord.self,
            AppBootstrapMetadata.self,
            configurations: configuration
        )
    }

}
