import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct AppRootView: View {
    @State private var selectedSection: AppSection? = .allPurchases
    @State private var selectedPurchaseID: PersistentIdentifier?
    @State private var selectedWarrantyID: PersistentIdentifier?
    @State private var selectedReminderID: PersistentIdentifier?
    @State private var lastSelectedPurchaseID: PersistentIdentifier?
    @State private var lastSelectedWarrantyID: PersistentIdentifier?
    @State private var lastSelectedReminderID: PersistentIdentifier?
    @State private var selectedPurchase: Purchase?
    @State private var selectedDocument: StoredDocument?
    @State private var selectedWarranty: Warranty?
    @State private var selectedReminder: Reminder?

    @State private var purchaseEditorPresentation: PurchaseEditorPresentation?
    @State private var warrantyEditorPresentation: WarrantyEditorPresentation?
    @State private var reminderEditorPresentation: ReminderEditorPresentation?

    @State private var isShowingDocumentImporter = false
    @State private var documentErrorMessage: String?

    @Query(sort: \Purchase.createdAt, order: .reverse)
    private var purchases: [Purchase]

    @Query(sort: \Warranty.updatedAt, order: .reverse)
    private var warranties: [Warranty]

    @Query(sort: \Reminder.dueDate)
    private var reminders: [Reminder]

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
            case .warranties:
                warrantyListView
            case .reminders:
                reminderListView
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
            case .warranties:
                warrantyDetailView
            case .reminders:
                reminderDetailView
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
            switch newValue {
            case .allPurchases:
                autoselectPurchase()
            case .warranties:
                selectedPurchase = nil
                selectedDocument = nil
                autoselectWarranty()
            case .reminders:
                selectedPurchase = nil
                selectedDocument = nil
                autoselectReminder()
            case .some, .none:
                selectedPurchase = nil
                selectedWarranty = nil
                selectedReminder = nil
                selectedDocument = nil
            }
        }
        .onChange(of: selectedPurchaseID) { _, newValue in
            guard let newValue else {
                selectedPurchase = nil
                return
            }
            lastSelectedPurchaseID = newValue
            selectedPurchase = purchases.first { $0.persistentModelID == newValue }
        }
        .onChange(of: selectedPurchase) { _, newValue in
            selectedPurchaseID = newValue?.persistentModelID
            guard let purchase = newValue else {
                selectedDocument = nil
                selectedWarranty = nil
                selectedReminder = nil
                selectedWarrantyID = nil
                selectedReminderID = nil
                return
            }
            selectedDocument = purchase.documents.sorted(by: { $0.dateAdded > $1.dateAdded }).first
            selectedWarranty = purchase.warranties.sorted(by: { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) }).first
            selectedReminder = purchase.reminders.sorted(by: { $0.dueDate < $1.dueDate }).first
            selectedWarrantyID = selectedWarranty?.persistentModelID
            selectedReminderID = selectedReminder?.persistentModelID
        }
        .onChange(of: selectedWarranty) { _, newValue in
            selectedWarrantyID = newValue?.persistentModelID
        }
        .onChange(of: selectedReminder) { _, newValue in
            selectedReminderID = newValue?.persistentModelID
        }
        .onChange(of: selectedWarrantyID) { _, newValue in
            guard let newValue else {
                selectedWarranty = nil
                return
            }
            lastSelectedWarrantyID = newValue
            selectedWarranty = warranties.first { $0.persistentModelID == newValue }
        }
        .onChange(of: selectedReminderID) { _, newValue in
            guard let newValue else {
                selectedReminder = nil
                return
            }
            lastSelectedReminderID = newValue
            selectedReminder = reminders.first { $0.persistentModelID == newValue }
        }
        .onAppear {
            switch selectedSection {
            case .allPurchases:
                autoselectPurchase()
            case .warranties:
                autoselectWarranty()
            case .reminders:
                autoselectReminder()
            default:
                break
            }
        }
        .sheet(item: $purchaseEditorPresentation) { presentation in
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
        .sheet(item: $warrantyEditorPresentation) { presentation in
            switch presentation {
            case .new(let purchase):
                WarrantyEditorView(mode: .create(purchase: purchase)) { warranty in
                    selectedWarranty = warranty
                }
                .frame(minWidth: 650, minHeight: 620)
            case .edit(let warranty):
                WarrantyEditorView(mode: .edit(warranty)) { updated in
                    selectedWarranty = updated
                }
                .frame(minWidth: 650, minHeight: 620)
            }
        }
        .sheet(item: $reminderEditorPresentation) { presentation in
            switch presentation {
            case .new(let purchase):
                ReminderEditorView(mode: .create(purchase: purchase)) { reminder in
                    selectedReminder = reminder
                }
                .frame(minWidth: 650, minHeight: 560)
            case .edit(let reminder):
                ReminderEditorView(mode: .edit(reminder)) { updated in
                    selectedReminder = updated
                }
                .frame(minWidth: 650, minHeight: 560)
            }
        }
        .fileImporter(
            isPresented: $isShowingDocumentImporter,
            allowedContentTypes: [.data, .pdf, .image, .plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleDocumentImport(result: result)
        }
        .alert("Document Import Error", isPresented: .constant(documentErrorMessage != nil), actions: {
            Button("OK") {
                documentErrorMessage = nil
            }
        }, message: {
            Text(documentErrorMessage ?? "Unknown error.")
        })
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
                List(purchases, selection: $selectedPurchaseID) { purchase in
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
                    .tag(purchase.persistentModelID)
                }
            }
        }
        .navigationTitle("All Purchases")
        .toolbar {
            ToolbarItemGroup {
                Button("New Purchase") {
                    purchaseEditorPresentation = .new
                }
                .keyboardShortcut("n")

                Button("Edit Purchase") {
                    guard let selectedPurchase else { return }
                    purchaseEditorPresentation = .edit(selectedPurchase)
                }
                .disabled(selectedPurchase == nil)

                Button("Import Document") {
                    isShowingDocumentImporter = true
                }
                .keyboardShortcut("i")
                .disabled(selectedPurchase == nil)
            }
        }
    }

    private var warrantyListView: some View {
        Group {
            if warranties.isEmpty {
                ContentUnavailableView(
                    "No Warranties",
                    systemImage: "checkmark.shield",
                    description: Text("Add a warranty from a purchase detail view.")
                )
            } else {
                List(warranties, selection: $selectedWarrantyID) { warranty in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(warranty.title)
                            .font(.headline)
                        Text(warranty.purchase?.name ?? "Unlinked Purchase")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .tag(warranty.persistentModelID)
                }
            }
        }
        .navigationTitle("Warranties")
        .toolbar {
            ToolbarItem {
                Button("Edit Warranty") {
                    guard let selectedWarranty else { return }
                    warrantyEditorPresentation = .edit(selectedWarranty)
                }
                .disabled(selectedWarranty == nil)
            }
        }
    }

    private var reminderListView: some View {
        Group {
            if reminders.isEmpty {
                ContentUnavailableView(
                    "No Reminders",
                    systemImage: "bell",
                    description: Text("Add a reminder from a purchase detail view.")
                )
            } else {
                List(reminders, selection: $selectedReminderID) { reminder in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reminder.title)
                            .font(.headline)
                        HStack(spacing: 8) {
                            Text(formattedDateTime(reminder.dueDate, includeTime: reminder.hasSpecificTime))
                            Text("•")
                            Text(reminder.purchase?.name ?? "Unlinked Purchase")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .tag(reminder.persistentModelID)
                }
            }
        }
        .navigationTitle("Reminders")
        .toolbar {
            ToolbarItem {
                Button("Edit Reminder") {
                    guard let selectedReminder else { return }
                    reminderEditorPresentation = .edit(selectedReminder)
                }
                .disabled(selectedReminder == nil)
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

                    Section("Warranties") {
                        if purchase.warranties.isEmpty {
                            Text("No warranties attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.warranties.sorted(by: { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) })
                            ForEach(items) { warranty in
                                Button {
                                    selectedWarranty = warranty
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(warranty.title)
                                                .font(.body)
                                            Text(formattedWarrantySubtitle(warranty))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedWarranty?.persistentModelID == warranty.persistentModelID {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Section("Reminders") {
                        if purchase.reminders.isEmpty {
                            Text("No reminders attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.reminders.sorted(by: { $0.dueDate < $1.dueDate })
                            ForEach(items) { reminder in
                                Button {
                                    selectedReminder = reminder
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(reminder.title)
                                                .font(.body)
                                            Text(formattedReminderSubtitle(reminder))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedReminder?.persistentModelID == reminder.persistentModelID {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Section("Documents") {
                        if purchase.documents.isEmpty {
                            Text("No documents attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let documents = purchase.documents.sorted(by: { $0.dateAdded > $1.dateAdded })
                            ForEach(documents) { document in
                                Button {
                                    selectedDocument = document
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(document.title)
                                                .font(.body)
                                            Text(document.category.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedDocument?.identifier == document.identifier {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .navigationTitle(purchase.name)
                .toolbar {
                    ToolbarItemGroup {
                        Button("Add Warranty") {
                            warrantyEditorPresentation = .new(purchase)
                        }

                        Button("Edit Warranty") {
                            guard let selectedWarranty else { return }
                            warrantyEditorPresentation = .edit(selectedWarranty)
                        }
                        .disabled(selectedWarranty == nil)

                        Button("Add Reminder") {
                            reminderEditorPresentation = .new(purchase)
                        }

                        Button("Edit Reminder") {
                            guard let selectedReminder else { return }
                            reminderEditorPresentation = .edit(selectedReminder)
                        }
                        .disabled(selectedReminder == nil)

                        Button("Open Document") {
                            openSelectedDocument()
                        }
                        .disabled(selectedDocument == nil)
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Purchase Selected",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Select a purchase in the list to view details.")
                )
            }
        }
    }

    private var warrantyDetailView: some View {
        Group {
            if let warranty = selectedWarranty {
                List {
                    Section("Summary") {
                        LabeledContent("Title", value: warranty.title)
                        LabeledContent("Type", value: warranty.type.rawValue)
                        LabeledContent("Provider", value: warranty.provider ?? "Not set")
                        LabeledContent("Purchase", value: warranty.purchase?.name ?? "Not set")
                        LabeledContent("Status", value: WarrantyStatusService.status(for: warranty).rawValue)
                    }

                    Section("Dates") {
                        LabeledContent("Start Date", value: formattedDate(warranty.startDate))
                        LabeledContent("End Date", value: formattedDate(warranty.endDate))
                    }

                    Section("Claim") {
                        LabeledContent("Reference", value: warranty.warrantyReferenceNumber ?? "Not set")
                        LabeledContent("Claim Procedure", value: warranty.claimProcedure ?? "Not set")
                        LabeledContent("Proof Of Purchase", value: warranty.proofOfPurchaseRequired ? "Required" : "Not required")
                    }

                    Section("Notes") {
                        LabeledContent("Coverage", value: warranty.coverageDescription ?? "Not set")
                        LabeledContent("Notes", value: warranty.notes ?? "Not set")
                    }
                }
                .navigationTitle(warranty.title)
            } else {
                ContentUnavailableView(
                    "No Warranty Selected",
                    systemImage: "checkmark.shield",
                    description: Text("Select a warranty to view details.")
                )
            }
        }
    }

    private var reminderDetailView: some View {
        Group {
            if let reminder = selectedReminder {
                List {
                    Section("Summary") {
                        LabeledContent("Title", value: reminder.title)
                        LabeledContent("Type", value: reminder.type.rawValue)
                        LabeledContent("Due", value: formattedDateTime(reminder.dueDate, includeTime: reminder.hasSpecificTime))
                        LabeledContent("Purchase", value: reminder.purchase?.name ?? "Not set")
                        LabeledContent("Priority", value: reminder.priority.rawValue)
                        LabeledContent("Recurrence", value: reminder.recurrence.rawValue)
                    }

                    Section("Tracking") {
                        LabeledContent("Advance Warning", value: "\(reminder.advanceWarningDays) day(s)")
                        LabeledContent("State", value: formattedReminderState(reminder))
                        LabeledContent("Completed", value: reminder.isCompleted ? "Yes" : "No")
                        LabeledContent("Next Due", value: formattedDateTime(ReminderService.nextDueDate(for: reminder), includeTime: reminder.hasSpecificTime))
                    }

                    Section("Notes") {
                        LabeledContent("Notes", value: reminder.notes ?? "Not set")
                    }
                }
                .navigationTitle(reminder.title)
            } else {
                ContentUnavailableView(
                    "No Reminder Selected",
                    systemImage: "bell",
                    description: Text("Select a reminder to view details.")
                )
            }
        }
    }

    private func formattedDate(_ value: Date?) -> String {
        guard let value else { return "Not set" }
        return value.formatted(date: .abbreviated, time: .omitted)
    }

    private func formattedDateTime(_ value: Date?, includeTime: Bool) -> String {
        guard let value else { return "Not set" }
        if includeTime {
            return value.formatted(date: .abbreviated, time: .shortened)
        }
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

    private func formattedWarrantySubtitle(_ warranty: Warranty) -> String {
        let status = WarrantyStatusService.status(for: warranty).rawValue
        let end = formattedDate(warranty.endDate)
        return "\(status) • End: \(end)"
    }

    private func formattedReminderSubtitle(_ reminder: Reminder) -> String {
        let due = formattedDateTime(reminder.dueDate, includeTime: reminder.hasSpecificTime)
        return "\(formattedReminderState(reminder)) • Due: \(due)"
    }

    private func formattedReminderState(_ reminder: Reminder) -> String {
        if reminder.isCompleted { return "completed" }
        if ReminderService.isOverdue(reminder) { return "overdue" }
        if ReminderService.isDueSoon(reminder) { return "due soon" }
        return "scheduled"
    }

    private func autoselectPurchase() {
        guard !purchases.isEmpty else {
            selectedPurchaseID = nil
            selectedPurchase = nil
            return
        }

        if let lastSelectedPurchaseID,
           purchases.contains(where: { $0.persistentModelID == lastSelectedPurchaseID }) {
            selectedPurchaseID = lastSelectedPurchaseID
        } else {
            selectedPurchaseID = purchases[0].persistentModelID
        }
    }

    private func autoselectWarranty() {
        guard !warranties.isEmpty else {
            selectedWarrantyID = nil
            selectedWarranty = nil
            return
        }

        if let lastSelectedWarrantyID,
           warranties.contains(where: { $0.persistentModelID == lastSelectedWarrantyID }) {
            selectedWarrantyID = lastSelectedWarrantyID
        } else {
            selectedWarrantyID = warranties[0].persistentModelID
        }
    }

    private func autoselectReminder() {
        guard !reminders.isEmpty else {
            selectedReminderID = nil
            selectedReminder = nil
            return
        }

        if let lastSelectedReminderID,
           reminders.contains(where: { $0.persistentModelID == lastSelectedReminderID }) {
            selectedReminderID = lastSelectedReminderID
        } else {
            selectedReminderID = reminders[0].persistentModelID
        }
    }

    private func handleDocumentImport(result: Result<[URL], Error>) {
        guard let purchase = selectedPurchase else { return }

        do {
            let urls = try result.get()
            guard let sourceURL = urls.first else { return }

            let imported = try DocumentStorageService.importFile(from: sourceURL)
            let title = sourceURL.deletingPathExtension().lastPathComponent
            let document = StoredDocument(
                title: title.isEmpty ? imported.originalFilename : title,
                category: .other,
                originalFilename: imported.originalFilename,
                contentType: imported.contentType,
                storedRelativePath: imported.storedRelativePath,
                purchase: purchase
            )

            purchase.documents.append(document)
            purchase.updatedAt = .now
            selectedDocument = document
        } catch {
            documentErrorMessage = error.localizedDescription
        }
    }

    private func openSelectedDocument() {
        guard let selectedDocument else { return }

        do {
            let url = try DocumentStorageService.resolvedURL(for: selectedDocument.storedRelativePath)
            NSWorkspace.shared.open(url)
        } catch {
            documentErrorMessage = error.localizedDescription
        }
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

private enum WarrantyEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(Warranty)

    var id: String {
        switch self {
        case .new(let purchase):
            return "warranty-new-\(purchase.persistentModelID)"
        case .edit(let warranty):
            return "warranty-edit-\(warranty.persistentModelID)"
        }
    }
}

private enum ReminderEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(Reminder)

    var id: String {
        switch self {
        case .new(let purchase):
            return "reminder-new-\(purchase.persistentModelID)"
        case .edit(let reminder):
            return "reminder-edit-\(reminder.persistentModelID)"
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
            "Warranty list is available in this section."
        case .reminders:
            "Reminder list is available in this section."
        case .documents:
            "Document import is available from All Purchases."
        }
    }

    var detailPlaceholder: String {
        switch self {
        case .dashboard:
            "This section is not part of the current task."
        case .allPurchases:
            "Select a purchase to view its details."
        case .warranties:
            "Select a warranty to view details."
        case .reminders:
            "Select a reminder to view details."
        case .documents:
            "Document detail view will be expanded in a later task."
        }
    }
}

#Preview {
    AppRootView()
}
