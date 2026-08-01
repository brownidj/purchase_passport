import SwiftUI

struct AppRootView: View {
    @State private var selectedSection: AppSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Purchase Passport")
        } content: {
            if let section = selectedSection {
                List {
                    Text(section.contentPlaceholder)
                }
                .navigationTitle(section.title)
            } else {
                Text("Select a section")
                    .foregroundStyle(.secondary)
            }
        } detail: {
            if let section = selectedSection {
                ContentUnavailableView(
                    section.title,
                    systemImage: section.systemImage,
                    description: Text(section.detailPlaceholder)
                )
            } else {
                ContentUnavailableView(
                    "No Section Selected",
                    systemImage: "sidebar.left"
                )
            }
        }
    }
}

private enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case allPurchases
    case warranties
    case reminders
    case documents

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            "Dashboard"
        case .allPurchases:
            "All Purchases"
        case .warranties:
            "Warranties"
        case .reminders:
            "Reminders"
        case .documents:
            "Documents"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            "square.grid.2x2"
        case .allPurchases:
            "cart"
        case .warranties:
            "checkmark.shield"
        case .reminders:
            "bell"
        case .documents:
            "doc.text"
        }
    }

    var contentPlaceholder: String {
        switch self {
        case .dashboard:
            "Phase 1 foundation: dashboard scaffolding is in place."
        case .allPurchases:
            "Purchase list will be implemented in Phase 2."
        case .warranties:
            "Warranty records will be implemented in Phase 5."
        case .reminders:
            "Reminder support will be implemented in later phases."
        case .documents:
            "Document import and organization will be implemented in Phase 4."
        }
    }

    var detailPlaceholder: String {
        switch self {
        case .dashboard:
            "This is a placeholder detail view for project foundation."
        case .allPurchases:
            "No purchase model is created yet."
        case .warranties:
            "No warranty model is created yet."
        case .reminders:
            "No reminder model is created yet."
        case .documents:
            "No document model is created yet."
        }
    }
}

#Preview {
    AppRootView()
}
