import SwiftUI

struct AppRootCompositionView: View {
    @Binding var selectedSection: AppSection?
    let contentViewForSection: (AppSection) -> AnyView
    let detailViewForSection: (AppSection) -> AnyView

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .accessibilityIdentifier("sidebar.\(section.rawValue)")
                    .tag(section)
            }
            .navigationTitle("Purchase Passport")
        } content: {
            if let section = selectedSection {
                contentViewForSection(section)
            } else {
                ContentUnavailableView(
                    "No Section Selected",
                    systemImage: "sidebar.left"
                )
            }
        } detail: {
            if let section = selectedSection {
                detailViewForSection(section)
            } else {
                ContentUnavailableView(
                    "No Section Selected",
                    systemImage: "sidebar.left"
                )
            }
        }
    }
}
