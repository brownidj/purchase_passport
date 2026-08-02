import Foundation
import SwiftData

@Model
final class AppBootstrapMetadata {
    @Attribute(.unique) var key: String
    var createdAt: Date

    init(
        key: String,
        createdAt: Date = .now
    ) {
        self.key = key
        self.createdAt = createdAt
    }
}

enum AppBootstrapSeeder {
    private static let seedKey = "seed-PUR-20260802-0001"

    static func seedIfNeeded(in modelContext: ModelContext) throws {
        let existingSeed = try modelContext.fetch(
            FetchDescriptor<AppBootstrapMetadata>(
                predicate: #Predicate { $0.key == seedKey }
            )
        )

        guard existingSeed.isEmpty else {
            return
        }

        let purchaseDate = date(fromISO8601: "2026-08-02")
        let warrantyExpiry = date(fromISO8601: "2028-08-02")

        let category = try findOrCreateCategory(
            named: "Electronics",
            in: modelContext
        )

        let tags = try findOrCreateTags(
            names: ["Laptop", "Work", "Warranty", "Electronics"],
            in: modelContext
        )

        let purchase = Purchase(
            name: "AcmeBook Pro 14",
            shortDescription: "Subcategory: Laptop",
            notes: """
            Purchased during end-of-financial-year sale. Includes protective sleeve and charger.

            Purchase ID: PUR-20260802-0001
            Condition: New
            Seller Details: Tech World Townsville | 123 Flinders Street, Townsville QLD 4810 | +61 7 4771 2345 | sales@techworld.example | https://www.techworld.example
            """,
            status: .active,
            purchaseDate: purchaseDate,
            purchasePrice: Decimal(string: "1000.00"),
            currencyCode: "AUD",
            seller: "Tech World Townsville",
            manufacturer: "Acme Computing",
            modelName: "ABP14-2026",
            serialNumber: "ACM-14P-8F4X92LQ",
            purchaseLocation: "Townsville QLD",
            ownershipStatus: .owned,
            expectedUsefulLifeNotes: "Primary work laptop",
            category: category,
            tags: tags
        )

        let transaction = FinancialTransaction(
            type: .purchase,
            amount: Decimal(string: "1000.00") ?? 1000,
            currencyCode: "AUD",
            transactionDate: purchaseDate,
            notes: "Payment method: Credit Card (last4: 4821)",
            referenceNumber: "TXN-20260802-984731",
            purchase: purchase
        )

        let warranty = Warranty(
            title: "Manufacturer Warranty",
            type: .manufacturer,
            provider: "Acme Computing",
            startDate: purchaseDate,
            endDate: warrantyExpiry,
            coverageDescription: "24 Months",
            proofOfPurchaseRequired: true,
            notes: "Extended warranty: No",
            purchase: purchase
        )

        let reminder = Reminder(
            title: "Manufacturer Warranty Expiry",
            type: .warrantyExpiry,
            dueDate: warrantyExpiry,
            hasSpecificTime: false,
            advanceWarningDays: 30,
            recurrence: .none,
            priority: .high,
            notes: "Review coverage before expiry.",
            purchase: purchase
        )

        let supportInteraction = Interaction(
            occurredAt: date(fromISO8601: "2026-09-15"),
            type: .other,
            status: .resolved,
            partyContacted: "Acme Support",
            subject: "Support enquiry about battery optimisation settings",
            summary: "Asked about battery optimisation settings.",
            detailedNotes: "Settings adjusted as recommended by support.",
            purchase: purchase
        )

        let serviceInteraction = Interaction(
            occurredAt: date(fromISO8601: "2027-03-10"),
            type: .warrantyClaim,
            status: .resolved,
            partyContacted: "Acme Service Centre",
            subject: "Trackpad intermittently unresponsive",
            summary: "Warranty service booking and diagnosis.",
            detailedNotes: "Trackpad assembly replaced under warranty.",
            purchase: purchase
        )

        let complaintCase = ComplaintCase(
            title: "Trackpad fault resolution and response delay",
            issueType: .complaint,
            partyResponsible: "Acme Computing",
            dateOpened: date(fromISO8601: "2027-03-06"),
            status: .resolved,
            desiredResolution: "Warranty repair and confirmation of issue resolution.",
            consumerGuaranteeOrWarranty: "Manufacturer Warranty",
            caseReferenceNumber: "CMP-20270306-ACME",
            chronology: "Fault observed, support contacted, and service arranged.",
            keyEvidence: "Interaction notes and service documentation.",
            correspondence: "Support and service centre responses captured in interactions.",
            responseDeadline: date(fromISO8601: "2027-03-12"),
            commitmentsMade: "Service centre committed to inspect and resolve within one week.",
            outcome: "Fault resolved under warranty.",
            compensationDetails: "No out-of-pocket repair cost.",
            dateClosed: date(fromISO8601: "2027-03-10"),
            purchase: purchase
        )

        let serviceRecord = ServiceRecord(
            serviceType: "Warranty Service",
            serviceProvider: "Acme Service Centre",
            serviceDate: date(fromISO8601: "2027-03-10"),
            completionDate: date(fromISO8601: "2027-03-10"),
            costAmount: 0,
            currencyCode: "AUD",
            workRequested: "Trackpad intermittently unresponsive.",
            workCompleted: "Trackpad assembly replaced under warranty.",
            serviceReferenceNumber: "SRV-20270310-ACME",
            notes: "Completed under manufacturer warranty.",
            purchase: purchase
        )

        let faultRecord = FaultRecord(
            firstNoticedDate: date(fromISO8601: "2027-03-05"),
            title: "Trackpad intermittently unresponsive",
            detailedDescription: "Cursor stops responding intermittently during normal use.",
            severity: .medium,
            status: .resolved,
            sellerOrManufacturerNotified: true,
            notes: "Resolved via warranty service.",
            purchase: purchase
        )

        let repairRecord = RepairRecord(
            repairProvider: "Acme Service Centre",
            bookingDate: date(fromISO8601: "2027-03-08"),
            repairDate: date(fromISO8601: "2027-03-10"),
            diagnosis: "Trackpad hardware issue",
            workPerformed: "Replaced trackpad assembly",
            totalCost: 0,
            currencyCode: "AUD",
            warrantyCoverage: true,
            paymentStatus: .waived,
            outcome: "Resolved",
            followUpRequired: false,
            notes: "No customer charge under warranty.",
            purchase: purchase,
            fault: faultRecord
        )

        let receiptDocument = StoredDocument(
            title: "Receipt",
            category: .receipt,
            notes: "Seed placeholder metadata only.",
            originalFilename: "receipt.pdf",
            storedRelativePath: "seed/receipt.pdf",
            purchase: purchase
        )

        let warrantyDocument = StoredDocument(
            title: "Warranty",
            category: .warranty,
            notes: "Seed placeholder metadata only.",
            originalFilename: "warranty.pdf",
            storedRelativePath: "seed/warranty.pdf",
            purchase: purchase
        )

        let manualDocument = StoredDocument(
            title: "User Manual",
            category: .userManual,
            notes: "Seed placeholder metadata only.",
            originalFilename: "manual.pdf",
            storedRelativePath: "seed/manual.pdf",
            purchase: purchase
        )

        purchase.transactions.append(transaction)
        purchase.warranties.append(warranty)
        purchase.reminders.append(reminder)
        purchase.interactions.append(contentsOf: [
            supportInteraction,
            serviceInteraction
        ])
        purchase.complaintCases.append(complaintCase)
        complaintCase.relatedInteractions.append(contentsOf: [
            supportInteraction,
            serviceInteraction
        ])
        purchase.serviceRecords.append(serviceRecord)
        purchase.faultRecords.append(faultRecord)
        purchase.repairRecords.append(repairRecord)
        complaintCase.relatedFaults.append(faultRecord)
        complaintCase.relatedRepairs.append(repairRecord)
        faultRecord.relatedRepairs.append(repairRecord)
        purchase.documents.append(contentsOf: [
            receiptDocument,
            warrantyDocument,
            manualDocument
        ])
        complaintCase.relatedDocuments.append(contentsOf: [
            warrantyDocument,
            manualDocument
        ])

        modelContext.insert(purchase)
        modelContext.insert(AppBootstrapMetadata(key: seedKey))
        try modelContext.save()
    }

    private static func findOrCreateCategory(
        named name: String,
        in modelContext: ModelContext
    ) throws -> PurchaseCategory {
        if let existing = try modelContext.fetch(
            FetchDescriptor<PurchaseCategory>(
                predicate: #Predicate { $0.name == name }
            )
        ).first {
            return existing
        }

        let category = PurchaseCategory(name: name, isSystemDefined: true)
        modelContext.insert(category)
        return category
    }

    private static func findOrCreateTags(
        names: [String],
        in modelContext: ModelContext
    ) throws -> [Tag] {
        var result: [Tag] = []

        for name in names {
            if let existing = try modelContext.fetch(
                FetchDescriptor<Tag>(
                    predicate: #Predicate { $0.name == name }
                )
            ).first {
                result.append(existing)
            } else {
                let tag = Tag(name: name)
                modelContext.insert(tag)
                result.append(tag)
            }
        }

        return result
    }

    private static func date(fromISO8601 value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? .now
    }
}
