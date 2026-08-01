import SwiftData
import SwiftUI

struct AppRootView: View {
    @State private var selectedSection: AppSection? = .allPurchases
    @State private var selectedPurchase: Purchase?
    @State private var editorPresentation: PurchaseEditorPresentation?
    @Query(sort: \Purchase.createdAt, order: .reverse)
    private var purchases: [Purchase]

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Purchase Passport")
        } content: {
            switch selectedSection {
            case .allPurchases:
                purchaseListView
            case .some(let section):
                List {
                    Text(section.contentPlaceholder)
                }
                .navigationTitle(section.title)
            case .none:
                ContentUnavailableView(
                    "No Section Selected",
                    systemImage: "sidebar.left"
                )
            }
        } detail: {
            switch selectedSection {
            case .allPurchases:
                purchaseDetailView
            case .some(let section):
                ContentUnavailableView(
                    section.title,
                    systemImage: section.systemImage,
                    description: Text(section.detailPlaceholder)
                )
            case .none:
                ContentUnavailableView(
                    "No Section Selected",
                    systemImage: "sidebar.left"
                )
            }
        }
        .onChange(of: selectedSection) { _, newValue in
            if newValue != .allPurchases {
                selectedPurchase = nil
            }
        }
        .sheet(item: $editorPresentation) { presentation in
            switch presentation {
            case .new:
                PurchaseEditorView(mode: .create) { purchase in
                    selectedPurchase = purchase
                }
                .frame(minWidth: 700, minHeight: 700)
            case .edit(let purchase):
                PurchaseEditorView(mode: .edit(purchase)) { updated in
                    selectedPurchase = updated
                }
                .frame(minWidth: 700, minHeight: 700)
            }
        }
    }

    private var purchaseListView: some View {
        Group {
            if purchases.isEmpty {
                ContentUnavailableView(
                    "No Purchases Yet",
                    systemImage: "cart",
                    description: Text("Create a purchase record to see it listed here.")
                )
            } else {
                List(purchases, selection: $selectedPurchase) { purchase in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(purchase.name)
                            .font(.headline)

                        HStack(spacing: 8) {
                            Text(purchase.status.rawValue)
                            if let categoryName = purchase.category?.name, !categoryName.isEmpty {
                                Text("•")
                                Text(categoryName)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("All Purchases")
        .toolbar {
            ToolbarItemGroup {
                Button("New Purchase") {
                    editorPresentation = .new
                }
                .keyboardShortcut("n")

                Button("Edit Purchase") {
                    guard let selectedPurchase else { return }
                    editorPresentation = .edit(selectedPurchase)
                }
                .disabled(selectedPurchase == nil)
            }
        }
    }

    private var purchaseDetailView: some View {
        Group {
            if let purchase = selectedPurchase {
                List {
                    Section("Summary") {
                        LabeledContent("Name", value: purchase.name)
                        LabeledContent("Status", value: purchase.status.rawValue)
                        LabeledContent("Category", value: purchase.category?.name ?? "Not set")
                        LabeledContent("Description", value: purchase.shortDescription ?? "Not set")
                        LabeledContent("Notes", value: purchase.notes ?? "Not set")
                        LabeledContent("Order Date", value: formattedDate(purchase.orderDate))
                        LabeledContent("Purchase Date", value: formattedDate(purchase.purchaseDate))
                        LabeledContent("Delivery Date", value: formattedDate(purchase.deliveryDate))
                    }

                    Section("Financial") {
                        LabeledContent("Purchase Price", value: formattedPrice(amount: purchase.purchasePrice, currencyCode: purchase.currencyCode))
                        LabeledContent("Currency", value: purchase.currencyCode ?? "Not set")
                    }

                    Section("Details") {
                        LabeledContent("Seller", value: purchase.seller ?? "Not set")
                        LabeledContent("Manufacturer", value: purchase.manufacturer ?? "Not set")
                        LabeledContent("Model", value: purchase.modelName ?? "Not set")
                        LabeledContent("Serial Number", value: purchase.serialNumber ?? "Not set")
                        LabeledContent("Invoice Number", value: purchase.invoiceNumber ?? "Not set")
                        LabeledContent("Order Number", value: purchase.orderNumber ?? "Not set")
                        LabeledContent("Purchase Location", value: purchase.purchaseLocation ?? "Not set")
                        LabeledContent("Storage Location", value: purchase.storageLocation ?? "Not set")
                        LabeledContent("Ownership", value: purchase.ownershipStatus?.rawValue ?? "Not set")
                        LabeledContent("Expected Useful Life", value: formattedUsefulLife(months: purchase.expectedUsefulLifeMonths, notes: purchase.expectedUsefulLifeNotes))
                    }

                    Section("Tags") {
                        LabeledContent("Tags", value: formattedTags(purchase.tags))
                    }
                }
                .navigationTitle(purchase.name)
            } else {
                ContentUnavailableView(
                    "No Purchase Selected",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Select a purchase in the list to view details.")
                )
            }
        }
    }

    private func formattedDate(_ value: Date?) -> String {
        guard let value else { return "Not set" }
        return value.formatted(date: .abbreviated, time: .omitted)
    }

    private func formattedPrice(amount: Decimal?, currencyCode: String?) -> String {
        guard let amount else { return "Not set" }
        if let currencyCode, !currencyCode.isEmpty {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currencyCode
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            if let formatted = formatter.string(from: amount as NSDecimalNumber) {
                return formatted
            }
        }
        return NSDecimalNumber(decimal: amount).stringValue
    }

    private func formattedUsefulLife(months: Int?, notes: String?) -> String {
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        switch (months, trimmedNotes) {
        case let (.some(months), .some(notes)) where !notes.isEmpty:
            return "\(months) months (\(notes))"
        case let (.some(months), _):
            return "\(months) months"
        case let (_, .some(notes)) where !notes.isEmpty:
            return notes
        default:
            return "Not set"
        }
    }

    private func formattedTags(_ tags: [Tag]) -> String {
        if tags.isEmpty { return "Not set" }
        return tags.map(\.name).joined(separator: ", ")
    }
}

private enum PurchaseEditorPresentation: Identifiable {
    case new
    case edit(Purchase)

    var id: String {
        switch self {
        case .new:
            return "new"
        case .edit(let purchase):
            return "edit-\(purchase.persistentModelID)"
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
            "Dashboard content will be implemented in a later task."
        case .allPurchases:
            "Purchase list is available in this section."
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
            "This section is not part of the current task."
        case .allPurchases:
            "Select a purchase to view its details."
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
