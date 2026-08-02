import SwiftData
import SwiftUI

struct ComplaintCaseEditorView: View {
    enum Mode {
        case create(purchase: Purchase)
        case edit(ComplaintCase)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let mode: Mode
    private let onCommit: (ComplaintCase) -> Void

    @State private var title: String
    @State private var issueType: ComplaintIssueType
    @State private var partyResponsible: String
    @State private var dateOpened: Date
    @State private var status: ComplaintStatus
    @State private var desiredResolution: String
    @State private var consumerGuaranteeOrWarranty: String
    @State private var caseReferenceNumber: String
    @State private var chronology: String
    @State private var keyEvidence: String
    @State private var correspondence: String
    @State private var hasResponseDeadline: Bool
    @State private var responseDeadline: Date
    @State private var commitmentsMade: String
    @State private var outcome: String
    @State private var compensationDetails: String
    @State private var hasClosedDate: Bool
    @State private var dateClosed: Date
    @State private var selectedInteractionIDs: Set<PersistentIdentifier>
    @State private var selectedFaultIDs: Set<PersistentIdentifier>
    @State private var selectedRepairIDs: Set<PersistentIdentifier>
    @State private var selectedDocumentIDs: Set<UUID>
    @State private var validationMessage: String?

    init(mode: Mode, onCommit: @escaping (ComplaintCase) -> Void) {
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .create:
            _title = State(initialValue: "")
            _issueType = State(initialValue: .complaint)
            _partyResponsible = State(initialValue: "")
            _dateOpened = State(initialValue: .now)
            _status = State(initialValue: .open)
            _desiredResolution = State(initialValue: "")
            _consumerGuaranteeOrWarranty = State(initialValue: "")
            _caseReferenceNumber = State(initialValue: "")
            _chronology = State(initialValue: "")
            _keyEvidence = State(initialValue: "")
            _correspondence = State(initialValue: "")
            _hasResponseDeadline = State(initialValue: false)
            _responseDeadline = State(initialValue: .now)
            _commitmentsMade = State(initialValue: "")
            _outcome = State(initialValue: "")
            _compensationDetails = State(initialValue: "")
            _hasClosedDate = State(initialValue: false)
            _dateClosed = State(initialValue: .now)
            _selectedInteractionIDs = State(initialValue: [])
            _selectedFaultIDs = State(initialValue: [])
            _selectedRepairIDs = State(initialValue: [])
            _selectedDocumentIDs = State(initialValue: [])

        case .edit(let complaint):
            _title = State(initialValue: complaint.title)
            _issueType = State(initialValue: complaint.issueType)
            _partyResponsible = State(initialValue: complaint.partyResponsible ?? "")
            _dateOpened = State(initialValue: complaint.dateOpened)
            _status = State(initialValue: complaint.status)
            _desiredResolution = State(initialValue: complaint.desiredResolution ?? "")
            _consumerGuaranteeOrWarranty = State(initialValue: complaint.consumerGuaranteeOrWarranty ?? "")
            _caseReferenceNumber = State(initialValue: complaint.caseReferenceNumber ?? "")
            _chronology = State(initialValue: complaint.chronology ?? "")
            _keyEvidence = State(initialValue: complaint.keyEvidence ?? "")
            _correspondence = State(initialValue: complaint.correspondence ?? "")
            _hasResponseDeadline = State(initialValue: complaint.responseDeadline != nil)
            _responseDeadline = State(initialValue: complaint.responseDeadline ?? .now)
            _commitmentsMade = State(initialValue: complaint.commitmentsMade ?? "")
            _outcome = State(initialValue: complaint.outcome ?? "")
            _compensationDetails = State(initialValue: complaint.compensationDetails ?? "")
            _hasClosedDate = State(initialValue: complaint.dateClosed != nil)
            _dateClosed = State(initialValue: complaint.dateClosed ?? .now)
            _selectedInteractionIDs = State(initialValue: Set(complaint.relatedInteractions.map(\.persistentModelID)))
            _selectedFaultIDs = State(initialValue: Set(complaint.relatedFaults.map(\.persistentModelID)))
            _selectedRepairIDs = State(initialValue: Set(complaint.relatedRepairs.map(\.persistentModelID)))
            _selectedDocumentIDs = State(initialValue: Set(complaint.relatedDocuments.map(\.identifier)))
        }
    }

    var body: some View {
        Form {
            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
            }

            Section("Core") {
                TextField("Case Title", text: $title)
                Picker("Issue Type", selection: $issueType) {
                    ForEach(ComplaintIssueType.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                TextField("Party Responsible", text: $partyResponsible)
                DatePicker("Date Opened", selection: $dateOpened, displayedComponents: .date)
                Picker("Status", selection: $status) {
                    ForEach(ComplaintStatus.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                TextField("Case or Reference Number", text: $caseReferenceNumber)
            }

            Section("Resolution") {
                TextField("Desired Resolution", text: $desiredResolution, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                TextField("Consumer Guarantee or Warranty", text: $consumerGuaranteeOrWarranty)
                TextField("Commitments Made", text: $commitmentsMade, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                TextField("Outcome", text: $outcome)
                TextField("Compensation / Replacement / Refund Details", text: $compensationDetails, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
            }

            Section("Chronology and Evidence") {
                TextField("Chronology", text: $chronology, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
                TextField("Key Evidence", text: $keyEvidence, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                TextField("Correspondence", text: $correspondence, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section("Deadlines") {
                Toggle("Has Response Deadline", isOn: $hasResponseDeadline)
                if hasResponseDeadline {
                    DatePicker("Response Deadline", selection: $responseDeadline)
                }
                Toggle("Case Closed", isOn: $hasClosedDate)
                if hasClosedDate {
                    DatePicker("Date Closed", selection: $dateClosed, displayedComponents: .date)
                }
            }

            if let purchase = editablePurchase {
                Section("Related Interactions") {
                    if purchase.interactions.isEmpty {
                        Text("No interactions available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(purchase.interactions.sorted(by: { $0.occurredAt > $1.occurredAt })) { interaction in
                            Toggle(interaction.subject, isOn: interactionBinding(for: interaction))
                        }
                    }
                }

                Section("Related Faults") {
                    if purchase.faultRecords.isEmpty {
                        Text("No faults available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(purchase.faultRecords.sorted(by: { $0.firstNoticedDate > $1.firstNoticedDate })) { fault in
                            Toggle(fault.title, isOn: faultBinding(for: fault))
                        }
                    }
                }

                Section("Related Repairs") {
                    if purchase.repairRecords.isEmpty {
                        Text("No repairs available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(purchase.repairRecords.sorted(by: { $0.repairDate > $1.repairDate })) { repair in
                            Toggle(repair.diagnosis ?? "Repair", isOn: repairBinding(for: repair))
                        }
                    }
                }

                Section("Related Documents") {
                    if purchase.documents.isEmpty {
                        Text("No documents available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(purchase.documents.sorted(by: { $0.dateAdded > $1.dateAdded })) { document in
                            Toggle(document.title, isOn: documentBinding(for: document))
                        }
                    }
                }
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
            return "New Complaint Case"
        case .edit:
            return "Edit Complaint Case"
        }
    }

    private var editablePurchase: Purchase? {
        switch mode {
        case .create(let purchase):
            return purchase
        case .edit(let complaint):
            return complaint.purchase
        }
    }

    private func handleSave() {
        if let message = ComplaintCaseEditorValidation.validate(title: title) {
            validationMessage = message
            return
        }

        guard let purchase = editablePurchase else {
            validationMessage = "Complaint must be linked to a purchase."
            return
        }

        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        validationMessage = nil

        let selectedInteractions = purchase.interactions.filter { selectedInteractionIDs.contains($0.persistentModelID) }
        let selectedFaults = purchase.faultRecords.filter { selectedFaultIDs.contains($0.persistentModelID) }
        let selectedRepairs = purchase.repairRecords.filter { selectedRepairIDs.contains($0.persistentModelID) }
        let selectedDocuments = purchase.documents.filter { selectedDocumentIDs.contains($0.identifier) }

        switch mode {
        case .create:
            let complaint = ComplaintCase(
                title: normalizedTitle,
                issueType: issueType,
                partyResponsible: partyResponsible.nilIfBlank,
                dateOpened: dateOpened,
                status: status,
                desiredResolution: desiredResolution.nilIfBlank,
                consumerGuaranteeOrWarranty: consumerGuaranteeOrWarranty.nilIfBlank,
                caseReferenceNumber: caseReferenceNumber.nilIfBlank,
                chronology: chronology.nilIfBlank,
                keyEvidence: keyEvidence.nilIfBlank,
                correspondence: correspondence.nilIfBlank,
                responseDeadline: hasResponseDeadline ? responseDeadline : nil,
                commitmentsMade: commitmentsMade.nilIfBlank,
                outcome: outcome.nilIfBlank,
                compensationDetails: compensationDetails.nilIfBlank,
                dateClosed: hasClosedDate ? dateClosed : nil,
                updatedAt: .now,
                purchase: purchase,
                warranty: nil,
                relatedDocuments: selectedDocuments,
                relatedInteractions: selectedInteractions,
                relatedFaults: selectedFaults,
                relatedRepairs: selectedRepairs
            )
            modelContext.insert(complaint)
            purchase.complaintCases.append(complaint)
            purchase.updatedAt = .now
            onCommit(complaint)

        case .edit(let complaint):
            complaint.title = normalizedTitle
            complaint.issueType = issueType
            complaint.partyResponsible = partyResponsible.nilIfBlank
            complaint.dateOpened = dateOpened
            complaint.status = status
            complaint.desiredResolution = desiredResolution.nilIfBlank
            complaint.consumerGuaranteeOrWarranty = consumerGuaranteeOrWarranty.nilIfBlank
            complaint.caseReferenceNumber = caseReferenceNumber.nilIfBlank
            complaint.chronology = chronology.nilIfBlank
            complaint.keyEvidence = keyEvidence.nilIfBlank
            complaint.correspondence = correspondence.nilIfBlank
            complaint.responseDeadline = hasResponseDeadline ? responseDeadline : nil
            complaint.commitmentsMade = commitmentsMade.nilIfBlank
            complaint.outcome = outcome.nilIfBlank
            complaint.compensationDetails = compensationDetails.nilIfBlank
            complaint.dateClosed = hasClosedDate ? dateClosed : nil
            complaint.relatedDocuments = selectedDocuments
            complaint.relatedInteractions = selectedInteractions
            complaint.relatedFaults = selectedFaults
            complaint.relatedRepairs = selectedRepairs
            complaint.updatedAt = .now
            complaint.purchase?.updatedAt = .now
            onCommit(complaint)
        }

        dismiss()
    }

    private func interactionBinding(for interaction: Interaction) -> Binding<Bool> {
        Binding(
            get: { selectedInteractionIDs.contains(interaction.persistentModelID) },
            set: { isSelected in
                if isSelected {
                    selectedInteractionIDs.insert(interaction.persistentModelID)
                } else {
                    selectedInteractionIDs.remove(interaction.persistentModelID)
                }
            }
        )
    }

    private func faultBinding(for fault: FaultRecord) -> Binding<Bool> {
        Binding(
            get: { selectedFaultIDs.contains(fault.persistentModelID) },
            set: { isSelected in
                if isSelected {
                    selectedFaultIDs.insert(fault.persistentModelID)
                } else {
                    selectedFaultIDs.remove(fault.persistentModelID)
                }
            }
        )
    }

    private func repairBinding(for repair: RepairRecord) -> Binding<Bool> {
        Binding(
            get: { selectedRepairIDs.contains(repair.persistentModelID) },
            set: { isSelected in
                if isSelected {
                    selectedRepairIDs.insert(repair.persistentModelID)
                } else {
                    selectedRepairIDs.remove(repair.persistentModelID)
                }
            }
        )
    }

    private func documentBinding(for document: StoredDocument) -> Binding<Bool> {
        Binding(
            get: { selectedDocumentIDs.contains(document.identifier) },
            set: { isSelected in
                if isSelected {
                    selectedDocumentIDs.insert(document.identifier)
                } else {
                    selectedDocumentIDs.remove(document.identifier)
                }
            }
        )
    }
}

enum ComplaintCaseEditorValidation {
    static func validate(title: String) -> String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Complaint case title is required."
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
