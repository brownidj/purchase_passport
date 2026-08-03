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

}
