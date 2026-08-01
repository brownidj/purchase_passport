import SwiftData
import SwiftUI

@main
struct Purchase_PassportApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [AppBootstrapMetadata.self])
    }
}
