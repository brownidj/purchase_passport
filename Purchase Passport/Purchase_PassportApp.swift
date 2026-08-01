import SwiftData
import SwiftUI

@main
struct Purchase_PassportApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: [
                Purchase.self,
                PurchaseCategory.self,
                FinancialTransaction.self,
                Tag.self,
                Contact.self,
                Organisation.self
            ]
        )
    }
}
