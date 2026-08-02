import SwiftData
import SwiftUI

struct FaultRecordEditorView: View {
    enum Mode {
        case create(purchase: Purchase)
        case edit(FaultRecord)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FaultRecord.updatedAt, order: .reverse)
    private var allFaults: [FaultRecord]

    private let mode: Mode
    private let onCommit: (FaultRecord) -> Void

    @State private var firstNoticedDate: Date
    @State private var title: String
    @State private var detailedDescription: String
    @State private var severity: FaultSeverity
    @State private var status: FaultStatus
    @State private var diagnosticInformation: String
    @State private var effectOnUse: String
    @State private var safetyConcerns: String
    @State private var sellerOrManufacturerNotified: Bool
    @State private var notes: String
    @State private var validationMessage: String?

    init(mode: Mode, onCommit: @escaping (FaultRecord) -> Void) {
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .create:
            _firstNoticedDate = State(initialValue: .now)
            _title = State(initialValue: "")
            _detailedDescription = State(initialValue: "")
            _severity = State(initialValue: .medium)
            _status = State(initialValue: .open)
            _diagnosticInformation = State(initialValue: "")
            _effectOnUse = State(initialValue: "")
            _safetyConcerns = State(initialValue: "")
            _sellerOrManufacturerNotified = State(initialValue: false)
            _notes = State(initialValue: "")
        case .edit(let fault):
            _firstNoticedDate = State(initialValue: fault.firstNoticedDate)
            _title = State(initialValue: fault.title)
            _detailedDescription = State(initialValue: fault.detailedDescription ?? "")
            _severity = State(initialValue: fault.severity)
            _status = State(initialValue: fault.status)
            _diagnosticInformation = State(initialValue: fault.diagnosticInformation ?? "")
            _effectOnUse = State(initialValue: fault.effectOnUse ?? "")
            _safetyConcerns = State(initialValue: fault.safetyConcerns ?? "")
            _sellerOrManufacturerNotified = State(initialValue: fault.sellerOrManufacturerNotified)
            _notes = State(initialValue: fault.notes ?? "")
        }
    }

    var body: some View {
        Form {
            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
            }

            Section("Core") {
                DatePicker("First Noticed", selection: $firstNoticedDate, displayedComponents: .date)
                TextField("Fault Title", text: $title)
                Picker("Severity", selection: $severity) {
                    ForEach(FaultSeverity.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                Picker("Status", selection: $status) {
                    ForEach(FaultStatus.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
            }

            Section("Details") {
                TextField("Description", text: $detailedDescription, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                TextField("Diagnostic Information", text: $diagnosticInformation, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                TextField("Effect On Use", text: $effectOnUse)
                TextField("Safety Concerns", text: $safetyConcerns)
                Toggle("Seller or Manufacturer Notified", isOn: $sellerOrManufacturerNotified)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(editorTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { handleSave() }
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var editorTitle: String {
        switch mode {
        case .create: return "New Fault"
        case .edit: return "Edit Fault"
        }
    }

    private func handleSave() {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedTitle.isEmpty {
            validationMessage = "Fault title is required."
            return
        }

        validationMessage = nil

        switch mode {
        case .create(let purchase):
            let fault = FaultRecord(
                firstNoticedDate: firstNoticedDate,
                title: normalizedTitle,
                detailedDescription: detailedDescription.nilIfBlank,
                severity: severity,
                status: status,
                diagnosticInformation: diagnosticInformation.nilIfBlank,
                effectOnUse: effectOnUse.nilIfBlank,
                safetyConcerns: safetyConcerns.nilIfBlank,
                sellerOrManufacturerNotified: sellerOrManufacturerNotified,
                notes: notes.nilIfBlank,
                purchase: purchase
            )
            modelContext.insert(fault)
            purchase.faultRecords.append(fault)
            purchase.updatedAt = .now
            onCommit(fault)

        case .edit(let fault):
            fault.firstNoticedDate = firstNoticedDate
            fault.title = normalizedTitle
            fault.detailedDescription = detailedDescription.nilIfBlank
            fault.severity = severity
            fault.status = status
            fault.diagnosticInformation = diagnosticInformation.nilIfBlank
            fault.effectOnUse = effectOnUse.nilIfBlank
            fault.safetyConcerns = safetyConcerns.nilIfBlank
            fault.sellerOrManufacturerNotified = sellerOrManufacturerNotified
            fault.notes = notes.nilIfBlank
            fault.updatedAt = .now
            fault.purchase?.updatedAt = .now
            onCommit(fault)
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
