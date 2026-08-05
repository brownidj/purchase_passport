import SwiftData
import SwiftUI

struct SearchListSectionView: View {
    let results: [Purchase]
    let availableCategoryNames: [String]
    let savedSearches: [SavedPurchaseSearch]

    @Binding var selectedPurchaseID: PersistentIdentifier?
    @Binding var searchQuery: String
    @Binding var filters: PurchaseSearchFilters
    @Binding var sortOption: PurchaseSearchSortOption

    let onSaveCurrentSearch: () -> Void
    let onApplySavedSearch: (SavedPurchaseSearch) -> Void
    let onDeleteSavedSearch: (SavedPurchaseSearch) -> Void

    var body: some View {
        List(selection: $selectedPurchaseID) {
            controlsSection
            savedSearchesSection
            resultsSection
        }
        .navigationTitle("Search")
        .toolbar {
            ToolbarItemGroup {
                Button("Save Search", action: onSaveCurrentSearch)
                Button("Clear Filters", action: clearFilters)
            }
        }
    }

    private var controlsSection: some View {
        Section("Search") {
            TextField("Search purchases, contacts, documents, notes…", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("search.query")

            Picker("Sort", selection: $sortOption) {
                ForEach(PurchaseSearchSortOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }

            Picker("Category", selection: $filters.categoryName) {
                Text("Any Category").tag(Optional<String>.none)
                ForEach(availableCategoryNames, id: \.self) { categoryName in
                    Text(categoryName).tag(Optional(categoryName))
                }
            }

            Picker("Status", selection: $filters.status) {
                Text("Any Status").tag(Optional<PurchaseStatus>.none)
                ForEach(PurchaseStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(Optional(status))
                }
            }

            Picker("Warranty", selection: $filters.warrantyFilter) {
                ForEach(WarrantySearchFilter.allCases) { option in
                    Text(option.title).tag(option)
                }
            }

            DatePicker("Purchase Date From", selection: purchaseDateFromBinding, displayedComponents: .date)
            DatePicker("Purchase Date To", selection: purchaseDateToBinding, displayedComponents: .date)

            Toggle("Unresolved Issue", isOn: $filters.unresolvedIssueOnly)
            Toggle("Upcoming Reminder", isOn: $filters.upcomingReminderOnly)
            Toggle("Active Complaint", isOn: $filters.activeComplaintOnly)
            Toggle("Service Due", isOn: $filters.serviceDueOnly)
            Toggle("Include Archived", isOn: $filters.includeArchived)
        }
    }

    @ViewBuilder
    private var savedSearchesSection: some View {
        if !savedSearches.isEmpty {
            Section("Saved Searches") {
                ForEach(savedSearches) { search in
                    HStack {
                        Button(search.name) {
                            onApplySavedSearch(search)
                        }
                        .buttonStyle(.link)

                        Spacer()

                        Button(role: .destructive) {
                            onDeleteSavedSearch(search)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }

    private var resultsSection: some View {
        Section("Results (\(results.count))") {
            if results.isEmpty {
                ContentUnavailableView(
                    "No Matching Purchases",
                    systemImage: "magnifyingglass",
                    description: Text("Adjust your search text or filters.")
                )
            } else {
                ForEach(results, id: \.persistentModelID) { purchase in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(purchase.name)
                            .font(.headline)

                        HStack(spacing: 8) {
                            Text(purchase.status.rawValue)
                            if let categoryName = purchase.category?.name, !categoryName.isEmpty {
                                Text("•")
                                Text(categoryName)
                            }
                            if let seller = purchase.seller, !seller.isEmpty {
                                Text("•")
                                Text(seller)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .accessibilityIdentifier("searchResultRow.\(purchase.name)")
                    .tag(purchase.persistentModelID)
                }
            }
        }
    }

    private var purchaseDateFromBinding: Binding<Date> {
        Binding(
            get: { filters.purchaseDateFrom ?? .now },
            set: { filters.purchaseDateFrom = $0 }
        )
    }

    private var purchaseDateToBinding: Binding<Date> {
        Binding(
            get: { filters.purchaseDateTo ?? .now },
            set: { filters.purchaseDateTo = $0 }
        )
    }

    private func clearFilters() {
        searchQuery = ""
        filters = .default
        sortOption = .mostRecent
    }
}
