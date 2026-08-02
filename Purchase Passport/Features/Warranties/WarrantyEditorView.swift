import SwiftData
import SwiftUI

struct WarrantyEditorView: View {
    enum Mode {
        case create(purchase: Purchase)
        case edit(Warranty)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let mode: Mode
    private let onCommit: (Warranty) -> Void

    @State private var title: String
    @State private var type: WarrantyType
    @State private var provider: String
    @State private var startDate: Date
    @State private var hasStartDate: Bool
    @State private var endDate: Date
    @State private var hasEndDate: Bool
    @State private var warrantyReferenceNumber: String
    @State private var coverageDescription: String
    @State private var claimProcedure: String
    @State private var notes: String
    @State private var proofOfPurchaseRequired: Bool
    @State private var isTransferable: Bool?
    @State private var validationMessage: String?

    init(mode: Mode, onCommit: @escaping (Warranty) -> Void) {
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .create:
            _title = State(initialValue: "")
            _type = State(initialValue: .manufacturer)
            _provider = State(initialValue: "")
            _startDate = State(initialValue: .now)
            _hasStartDate = State(initialValue: false)
            _endDate = State(initialValue: .now)
            _hasEndDate = State(initialValue: false)
            _warrantyReferenceNumber = State(initialValue: "")
            _coverageDescription = State(initialValue: "")
            _claimProcedure = State(initialValue: "")
            _notes = State(initialValue: "")
            _proofOfPurchaseRequired = State(initialValue: true)
            _isTransferable = State(initialValue: nil)
        case .edit(let warranty):
            _title = State(initialValue: warranty.title)
            _type = State(initialValue: warranty.type)
            _provider = State(initialValue: warranty.provider ?? "")
            _startDate = State(initialValue: warranty.startDate ?? .now)
            _hasStartDate = State(initialValue: warranty.startDate != nil)
            _endDate = State(initialValue: warranty.endDate ?? .now)
            _hasEndDate = State(initialValue: warranty.endDate != nil)
            _warrantyReferenceNumber = State(initialValue: warranty.warrantyReferenceNumber ?? "")
            _coverageDescription = State(initialValue: warranty.coverageDescription ?? "")
            _claimProcedure = State(initialValue: warranty.claimProcedure ?? "")
            _notes = State(initialValue: warranty.notes ?? "")
            _proofOfPurchaseRequired = State(initialValue: warranty.proofOfPurchaseRequired)
            _isTransferable = State(initialValue: warranty.isTransferable)
        }
    }

    var body: some View {
        Form {
            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
            }

            Section("Core") {
                TextField("Title", text: $title)
                Picker("Type", selection: $type) {
                    ForEach(WarrantyType.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                TextField("Provider", text: $provider)
                TextField("Reference Number", text: $warrantyReferenceNumber)
            }

            Section("Coverage") {
                Toggle("Start Date", isOn: $hasStartDate)
                if hasStartDate {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
                Toggle("End Date", isOn: $hasEndDate)
                if hasEndDate {
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                TextField("Coverage Description", text: $coverageDescription, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                TextField("Claim Procedure", text: $claimProcedure, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
            }

            Section("Options") {
                Toggle("Proof Of Purchase Required", isOn: $proofOfPurchaseRequired)
                Picker("Transferable", selection: $isTransferable) {
                    Text("Not set").tag(nil as Bool?)
                    Text("Yes").tag(true as Bool?)
                    Text("No").tag(false as Bool?)
                }
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(editorTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
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
    }

    private var editorTitle: String {
        switch mode {
        case .create:
            return "New Warranty"
        case .edit:
            return "Edit Warranty"
        }
    }

    private func handleSave() {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedTitle.isEmpty {
            validationMessage = "Warranty title is required."
            return
        }

        if hasStartDate && hasEndDate && endDate < startDate {
            validationMessage = "End date cannot be before start date."
            return
        }

        validationMessage = nil

        switch mode {
        case .create(let purchase):
            let warranty = Warranty(
                title: normalizedTitle,
                type: type,
                provider: provider.nilIfBlank,
                startDate: hasStartDate ? startDate : nil,
                endDate: hasEndDate ? endDate : nil,
                coverageDescription: coverageDescription.nilIfBlank,
                claimProcedure: claimProcedure.nilIfBlank,
                warrantyReferenceNumber: warrantyReferenceNumber.nilIfBlank,
                proofOfPurchaseRequired: proofOfPurchaseRequired,
                isTransferable: isTransferable,
                notes: notes.nilIfBlank,
                updatedAt: .now,
                purchase: purchase
            )
            modelContext.insert(warranty)
            purchase.warranties.append(warranty)
            purchase.updatedAt = .now
            onCommit(warranty)

        case .edit(let warranty):
            warranty.title = normalizedTitle
            warranty.type = type
            warranty.provider = provider.nilIfBlank
            warranty.startDate = hasStartDate ? startDate : nil
            warranty.endDate = hasEndDate ? endDate : nil
            warranty.coverageDescription = coverageDescription.nilIfBlank
            warranty.claimProcedure = claimProcedure.nilIfBlank
            warranty.warrantyReferenceNumber = warrantyReferenceNumber.nilIfBlank
            warranty.proofOfPurchaseRequired = proofOfPurchaseRequired
            warranty.isTransferable = isTransferable
            warranty.notes = notes.nilIfBlank
            warranty.updatedAt = .now
            warranty.purchase?.updatedAt = .now
            onCommit(warranty)
        }

        dismiss()
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
