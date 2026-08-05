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
    private static let seedKey = "seed-PUR-20260805-0002"
    private static let cleanupKey = "cleanup-PUR-20260805-0003"
    private static let legacyDemoPurchaseNames = [
        "AcmeBook Pro 14",
        "AcmePro 14"
    ]
    private static let legacyDemoOrganisationNames = [
        "Tech World Townsville",
        "Townsville Tech"
    ]

    static func seedIfNeeded(in modelContext: ModelContext) throws {
        try cleanLegacyDemoRecordsIfNeeded(in: modelContext)

        let existingSeed = try modelContext.fetch(
            FetchDescriptor<AppBootstrapMetadata>(
                predicate: #Predicate { $0.key == seedKey }
            )
        )

        guard existingSeed.isEmpty else {
            return
        }

        modelContext.insert(AppBootstrapMetadata(key: seedKey))
        try modelContext.save()
    }

    private static func cleanLegacyDemoRecordsIfNeeded(in modelContext: ModelContext) throws {
        let existingCleanup = try modelContext.fetch(
            FetchDescriptor<AppBootstrapMetadata>(
                predicate: #Predicate { $0.key == cleanupKey }
            )
        )

        guard existingCleanup.isEmpty else {
            return
        }

        let purchases = try modelContext.fetch(FetchDescriptor<Purchase>())
        let demoPurchases = purchases.filter { purchase in
            isLegacyDemoPurchase(purchase)
        }

        for purchase in demoPurchases {
            deletePurchaseGraph(purchase, in: modelContext)
        }

        try deleteLegacyDemoOrganisations(in: modelContext)

        modelContext.insert(AppBootstrapMetadata(key: cleanupKey))
        try modelContext.save()
    }

    private static func isLegacyDemoPurchase(_ purchase: Purchase) -> Bool {
        if legacyDemoPurchaseNames.contains(where: {
            purchase.name.localizedCaseInsensitiveCompare($0) == .orderedSame
        }) {
            return true
        }

        if let seller = purchase.seller?.trimmingCharacters(in: .whitespacesAndNewlines),
           legacyDemoOrganisationNames.contains(where: {
               seller.localizedCaseInsensitiveCompare($0) == .orderedSame
           }) {
            return true
        }

        if let providerName = purchase.provider?.name.trimmingCharacters(in: .whitespacesAndNewlines),
           legacyDemoOrganisationNames.contains(where: {
               providerName.localizedCaseInsensitiveCompare($0) == .orderedSame
           }) {
            return true
        }

        return false
    }

    private static func deletePurchaseGraph(_ purchase: Purchase, in modelContext: ModelContext) {
        let transactions = purchase.transactions
        let documents = purchase.documents
        let reminders = purchase.reminders
        let warranties = purchase.warranties
        let interactions = purchase.interactions
        let correspondences = purchase.correspondences
        let serviceRecords = purchase.serviceRecords
        let repairRecords = purchase.repairRecords
        let faultRecords = purchase.faultRecords
        let complaintCases = purchase.complaintCases

        for complaintCase in complaintCases {
            complaintCase.relatedInteractions.removeAll()
            complaintCase.relatedFaults.removeAll()
            complaintCase.relatedRepairs.removeAll()
            complaintCase.relatedDocuments.removeAll()
            complaintCase.purchase = nil
        }

        for faultRecord in faultRecords {
            faultRecord.relatedRepairs.removeAll()
            faultRecord.purchase = nil
        }

        for repairRecord in repairRecords {
            repairRecord.fault = nil
            repairRecord.purchase = nil
        }

        for serviceRecord in serviceRecords {
            serviceRecord.purchase = nil
        }

        for correspondence in correspondences {
            correspondence.complaintCase = nil
            correspondence.purchase = nil
        }

        for interaction in interactions {
            interaction.purchase = nil
        }

        for warranty in warranties {
            warranty.purchase = nil
        }

        for reminder in reminders {
            reminder.purchase = nil
        }

        for document in documents {
            document.purchase = nil
        }

        for transaction in transactions {
            transaction.purchase = nil
        }

        purchase.transactions.removeAll()
        purchase.documents.removeAll()
        purchase.reminders.removeAll()
        purchase.warranties.removeAll()
        purchase.interactions.removeAll()
        purchase.correspondences.removeAll()
        purchase.serviceRecords.removeAll()
        purchase.repairRecords.removeAll()
        purchase.faultRecords.removeAll()
        purchase.complaintCases.removeAll()
        purchase.tags.removeAll()
        purchase.contacts.removeAll()
        purchase.provider = nil
        purchase.category = nil

        for complaintCase in complaintCases {
            modelContext.delete(complaintCase)
        }
        for faultRecord in faultRecords {
            modelContext.delete(faultRecord)
        }
        for repairRecord in repairRecords {
            modelContext.delete(repairRecord)
        }
        for serviceRecord in serviceRecords {
            modelContext.delete(serviceRecord)
        }
        for correspondence in correspondences {
            modelContext.delete(correspondence)
        }
        for interaction in interactions {
            modelContext.delete(interaction)
        }
        for warranty in warranties {
            modelContext.delete(warranty)
        }
        for reminder in reminders {
            modelContext.delete(reminder)
        }
        for document in documents {
            modelContext.delete(document)
        }
        for transaction in transactions {
            modelContext.delete(transaction)
        }

        modelContext.delete(purchase)
    }

    private static func deleteLegacyDemoOrganisations(in modelContext: ModelContext) throws {
        let organisations = try modelContext.fetch(FetchDescriptor<Organisation>())
        let legacyOrganisations = organisations.filter { organisation in
            legacyDemoOrganisationNames.contains {
                organisation.name.localizedCaseInsensitiveCompare($0) == .orderedSame
            }
        }

        for organisation in legacyOrganisations {
            let contacts = organisation.contacts

            for contact in contacts {
                contact.organisation = nil
                if contact.purchases.isEmpty {
                    modelContext.delete(contact)
                }
            }

            organisation.contacts.removeAll()
            modelContext.delete(organisation)
        }
    }
}
