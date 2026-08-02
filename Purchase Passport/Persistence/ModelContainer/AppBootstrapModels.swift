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
            Service History (captured as notes until interaction/service models are implemented):
            - 2026-09-15: Support Enquiry — Asked about battery optimisation settings. Outcome: Settings adjusted as recommended by support.
            - 2027-03-10: Warranty Service — Trackpad intermittently unresponsive. Outcome: Trackpad assembly replaced under warranty.
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
        purchase.documents.append(contentsOf: [
            receiptDocument,
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
