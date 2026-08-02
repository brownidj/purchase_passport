import SwiftData
import SwiftUI

@main
struct Purchase_PassportApp: App {
    private let sharedModelContainer: ModelContainer

    init() {
        do {
            sharedModelContainer = try ModelContainer(
                for: Purchase.self,
                PurchaseCategory.self,
                FinancialTransaction.self,
                Tag.self,
                Contact.self,
                Organisation.self,
                StoredDocument.self,
                Warranty.self,
                Reminder.self,
                AppBootstrapMetadata.self
            )
            try AppBootstrapSeeder.seedIfNeeded(in: sharedModelContainer.mainContext)
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
