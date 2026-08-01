import Foundation
import SwiftData
import SwiftUI

struct PurchaseEditorView: View {
    enum Mode {
        case create
        case edit(Purchase)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PurchaseCategory.name) private var categories: [PurchaseCategory]
    @Query(sort: \Tag.name) private var tags: [Tag]

    private let mode: Mode
    private let onCommit: (Purchase) -> Void

    @State private var name: String
    @State private var shortDescription: String
    @State private var notes: String
    @State private var status: PurchaseStatus

    @State private var hasOrderDate: Bool
    @State private var orderDate: Date
    @State private var hasPurchaseDate: Bool
    @State private var purchaseDate: Date
    @State private var hasDeliveryDate: Bool
    @State private var deliveryDate: Date

    @State private var purchasePriceText: String
    @State private var currencyCode: String

    @State private var seller: String
    @State private var manufacturer: String
    @State private var modelName: String
    @State private var serialNumber: String
    @State private var invoiceNumber: String
    @State private var orderNumber: String
    @State private var purchaseLocation: String
    @State private var storageLocation: String

    @State private var ownershipStatus: OwnershipStatus?
    @State private var expectedUsefulLifeNotes: String
    @State private var expectedUsefulLifeMonthsText: String

    @State private var categoryName: String
    @State private var tagsText: String

    @State private var showDiscardConfirmation = false
    @State private var validationMessage: String?

    init(mode: Mode, onCommit: @escaping (Purchase) -> Void) {
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _shortDescription = State(initialValue: "")
            _notes = State(initialValue: "")
            _status = State(initialValue: .researching)
            _hasOrderDate = State(initialValue: false)
            _orderDate = State(initialValue: .now)
            _hasPurchaseDate = State(initialValue: false)
            _purchaseDate = State(initialValue: .now)
            _hasDeliveryDate = State(initialValue: false)
            _deliveryDate = State(initialValue: .now)
            _purchasePriceText = State(initialValue: "")
            _currencyCode = State(initialValue: "")
            _seller = State(initialValue: "")
            _manufacturer = State(initialValue: "")
            _modelName = State(initialValue: "")
            _serialNumber = State(initialValue: "")
            _invoiceNumber = State(initialValue: "")
            _orderNumber = State(initialValue: "")
            _purchaseLocation = State(initialValue: "")
            _storageLocation = State(initialValue: "")
            _ownershipStatus = State(initialValue: nil)
            _expectedUsefulLifeNotes = State(initialValue: "")
            _expectedUsefulLifeMonthsText = State(initialValue: "")
            _categoryName = State(initialValue: "")
            _tagsText = State(initialValue: "")
        case .edit(let purchase):
            _name = State(initialValue: purchase.name)
            _shortDescription = State(initialValue: purchase.shortDescription ?? "")
            _notes = State(initialValue: purchase.notes ?? "")
            _status = State(initialValue: purchase.status)
            _hasOrderDate = State(initialValue: purchase.orderDate != nil)
            _orderDate = State(initialValue: purchase.orderDate ?? .now)
            _hasPurchaseDate = State(initialValue: purchase.purchaseDate != nil)
            _purchaseDate = State(initialValue: purchase.purchaseDate ?? .now)
            _hasDeliveryDate = State(initialValue: purchase.deliveryDate != nil)
            _deliveryDate = State(initialValue: purchase.deliveryDate ?? .now)
            _purchasePriceText = State(initialValue: purchase.purchasePrice.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
            _currencyCode = State(initialValue: purchase.currencyCode ?? "")
            _seller = State(initialValue: purchase.seller ?? "")
            _manufacturer = State(initialValue: purchase.manufacturer ?? "")
            _modelName = State(initialValue: purchase.modelName ?? "")
            _serialNumber = State(initialValue: purchase.serialNumber ?? "")
            _invoiceNumber = State(initialValue: purchase.invoiceNumber ?? "")
            _orderNumber = State(initialValue: purchase.orderNumber ?? "")
            _purchaseLocation = State(initialValue: purchase.purchaseLocation ?? "")
            _storageLocation = State(initialValue: purchase.storageLocation ?? "")
            _ownershipStatus = State(initialValue: purchase.ownershipStatus)
            _expectedUsefulLifeNotes = State(initialValue: purchase.expectedUsefulLifeNotes ?? "")
            _expectedUsefulLifeMonthsText = State(initialValue: purchase.expectedUsefulLifeMonths.map(String.init) ?? "")
            _categoryName = State(initialValue: purchase.category?.name ?? "")
            _tagsText = State(initialValue: purchase.tags.map(\ .name).joined(separator: ", "))
        }
    }

    var body: some View {
        Form {
            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
            }

            Section("Core") {
                TextField("Purchase Name", text: $name)
                TextField("Category", text: $categoryName)
                Picker("Status", selection: $status) {
                    ForEach(PurchaseStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                TextField("Description", text: $shortDescription)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section("Dates") {
                dateFieldToggle("Order Date", isOn: $hasOrderDate, selection: $orderDate)
                dateFieldToggle("Purchase Date", isOn: $hasPurchaseDate, selection: $purchaseDate)
                dateFieldToggle("Delivery Date", isOn: $hasDeliveryDate, selection: $deliveryDate)
            }

            Section("Financial") {
                TextField("Purchase Price", text: $purchasePriceText)
                TextField("Currency (e.g. AUD)", text: $currencyCode)
            }

            Section("Vendor") {
                TextField("Seller", text: $seller)
                TextField("Manufacturer", text: $manufacturer)
                TextField("Model", text: $modelName)
                TextField("Serial Number", text: $serialNumber)
                TextField("Invoice Number", text: $invoiceNumber)
                TextField("Order Number", text: $orderNumber)
            }

            Section("Location and Ownership") {
                TextField("Purchase Location", text: $purchaseLocation)
                TextField("Storage Location", text: $storageLocation)
                Picker("Ownership Status", selection: $ownershipStatus) {
                    Text("Not set").tag(nil as OwnershipStatus?)
                    ForEach(OwnershipStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status as OwnershipStatus?)
                    }
                }
                TextField("Expected Useful Life (months)", text: $expectedUsefulLifeMonthsText)
                TextField("Expected Useful Life Notes", text: $expectedUsefulLifeNotes)
            }

            Section("Tags") {
                TextField("Comma-separated tags", text: $tagsText)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(editorTitle)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    handleCancel()
                }
                .keyboardShortcut(.cancelAction)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    handleSave()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .alert("Discard Changes?", isPresented: $showDiscardConfirmation) {
            Button("Keep Editing", role: .cancel) {}
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("You have unsaved changes. Discard them?")
        }
    }

    private var editorTitle: String {
        switch mode {
        case .create:
            return "New Purchase"
        case .edit:
            return "Edit Purchase"
        }
    }

    private var hasUnsavedChanges: Bool {
        true
    }

    @ViewBuilder
    private func dateFieldToggle(_ title: String, isOn: Binding<Bool>, selection: Binding<Date>) -> some View {
        Toggle(title, isOn: isOn)
        if isOn.wrappedValue {
            DatePicker(title, selection: selection, displayedComponents: .date)
        }
    }

    private func handleCancel() {
        showDiscardConfirmation = true
    }

    private func handleSave() {
        if let message = PurchaseEditorValidation.validate(name: name) {
            validationMessage = message
            return
        }

        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCategoryName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCurrencyCode = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines)

        let category = findOrCreateCategory(named: normalizedCategoryName)
        let tags = findOrCreateTags(from: tagsText)

        let expectedUsefulLifeMonths = Int(expectedUsefulLifeMonthsText.trimmingCharacters(in: .whitespacesAndNewlines))
        let purchasePrice = Decimal(string: purchasePriceText.trimmingCharacters(in: .whitespacesAndNewlines))

        switch mode {
        case .create:
            let purchase = Purchase(
                name: normalizedName,
                shortDescription: shortDescription.nilIfBlank,
                notes: notes.nilIfBlank,
                status: status,
                purchaseDate: hasPurchaseDate ? purchaseDate : nil,
                orderDate: hasOrderDate ? orderDate : nil,
                deliveryDate: hasDeliveryDate ? deliveryDate : nil,
                purchasePrice: purchasePrice,
                currencyCode: normalizedCurrencyCode.nilIfBlank,
                seller: seller.nilIfBlank,
                manufacturer: manufacturer.nilIfBlank,
                modelName: modelName.nilIfBlank,
                serialNumber: serialNumber.nilIfBlank,
                invoiceNumber: invoiceNumber.nilIfBlank,
                orderNumber: orderNumber.nilIfBlank,
                purchaseLocation: purchaseLocation.nilIfBlank,
                storageLocation: storageLocation.nilIfBlank,
                ownershipStatus: ownershipStatus,
                expectedUsefulLifeNotes: expectedUsefulLifeNotes.nilIfBlank,
                expectedUsefulLifeMonths: expectedUsefulLifeMonths,
                updatedAt: .now,
                category: category,
                tags: tags
            )

            modelContext.insert(purchase)
            onCommit(purchase)

        case .edit(let purchase):
            purchase.name = normalizedName
            purchase.shortDescription = shortDescription.nilIfBlank
            purchase.notes = notes.nilIfBlank
            purchase.status = status
            purchase.purchaseDate = hasPurchaseDate ? purchaseDate : nil
            purchase.orderDate = hasOrderDate ? orderDate : nil
            purchase.deliveryDate = hasDeliveryDate ? deliveryDate : nil
            purchase.purchasePrice = purchasePrice
            purchase.currencyCode = normalizedCurrencyCode.nilIfBlank
            purchase.seller = seller.nilIfBlank
            purchase.manufacturer = manufacturer.nilIfBlank
            purchase.modelName = modelName.nilIfBlank
            purchase.serialNumber = serialNumber.nilIfBlank
            purchase.invoiceNumber = invoiceNumber.nilIfBlank
            purchase.orderNumber = orderNumber.nilIfBlank
            purchase.purchaseLocation = purchaseLocation.nilIfBlank
            purchase.storageLocation = storageLocation.nilIfBlank
            purchase.ownershipStatus = ownershipStatus
            purchase.expectedUsefulLifeNotes = expectedUsefulLifeNotes.nilIfBlank
            purchase.expectedUsefulLifeMonths = expectedUsefulLifeMonths
            purchase.category = category
            purchase.tags = tags
            purchase.updatedAt = .now
            onCommit(purchase)
        }

        dismiss()
    }

    private func findOrCreateCategory(named name: String) -> PurchaseCategory? {
        guard !name.isEmpty else { return nil }
        if let existing = categories.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return existing
        }

        let newCategory = PurchaseCategory(name: name)
        modelContext.insert(newCategory)
        return newCategory
    }

    private func findOrCreateTags(from rawValue: String) -> [Tag] {
        let tagNames = rawValue
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var result: [Tag] = []
        for tagName in tagNames {
            if let existing = tags.first(where: { $0.name.caseInsensitiveCompare(tagName) == .orderedSame }) {
                result.append(existing)
            } else {
                let newTag = Tag(name: tagName)
                modelContext.insert(newTag)
                result.append(newTag)
            }
        }

        return result
    }
}

enum PurchaseEditorValidation {
    static func validate(name: String) -> String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Purchase name is required."
        }
        return nil
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
