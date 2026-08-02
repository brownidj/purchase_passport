import SwiftData
import SwiftUI

struct RepairRecordEditorView: View {
    enum Mode {
        case create(purchase: Purchase)
        case edit(RepairRecord)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FaultRecord.updatedAt, order: .reverse)
    private var faults: [FaultRecord]

    private let mode: Mode
    private let onCommit: (RepairRecord) -> Void

    @State private var repairProvider: String
    @State private var hasBookingDate: Bool
    @State private var bookingDate: Date
    @State private var repairDate: Date
    @State private var diagnosis: String
    @State private var workPerformed: String
    @State private var partsReplaced: String
    @State private var labourCostText: String
    @State private var partsCostText: String
    @State private var totalCostText: String
    @State private var currencyCode: String
    @State private var warrantyCoverage: Bool
    @State private var paymentStatus: RepairPaymentStatus
    @State private var repairWarrantyDetails: String
    @State private var outcome: String
    @State private var unresolvedIssues: String
    @State private var followUpRequired: Bool
    @State private var notes: String
    @State private var selectedFault: FaultRecord?
    @State private var validationMessage: String?

    init(mode: Mode, onCommit: @escaping (RepairRecord) -> Void) {
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .create:
            _repairProvider = State(initialValue: "")
            _hasBookingDate = State(initialValue: false)
            _bookingDate = State(initialValue: .now)
            _repairDate = State(initialValue: .now)
            _diagnosis = State(initialValue: "")
            _workPerformed = State(initialValue: "")
            _partsReplaced = State(initialValue: "")
            _labourCostText = State(initialValue: "")
            _partsCostText = State(initialValue: "")
            _totalCostText = State(initialValue: "")
            _currencyCode = State(initialValue: "")
            _warrantyCoverage = State(initialValue: false)
            _paymentStatus = State(initialValue: .unpaid)
            _repairWarrantyDetails = State(initialValue: "")
            _outcome = State(initialValue: "")
            _unresolvedIssues = State(initialValue: "")
            _followUpRequired = State(initialValue: false)
            _notes = State(initialValue: "")
            _selectedFault = State(initialValue: nil)
        case .edit(let repair):
            _repairProvider = State(initialValue: repair.repairProvider ?? "")
            _hasBookingDate = State(initialValue: repair.bookingDate != nil)
            _bookingDate = State(initialValue: repair.bookingDate ?? .now)
            _repairDate = State(initialValue: repair.repairDate)
            _diagnosis = State(initialValue: repair.diagnosis ?? "")
            _workPerformed = State(initialValue: repair.workPerformed ?? "")
            _partsReplaced = State(initialValue: repair.partsReplaced ?? "")
            _labourCostText = State(initialValue: repair.labourCost.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
            _partsCostText = State(initialValue: repair.partsCost.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
            _totalCostText = State(initialValue: repair.totalCost.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
            _currencyCode = State(initialValue: repair.currencyCode ?? "")
            _warrantyCoverage = State(initialValue: repair.warrantyCoverage)
            _paymentStatus = State(initialValue: repair.paymentStatus)
            _repairWarrantyDetails = State(initialValue: repair.repairWarrantyDetails ?? "")
            _outcome = State(initialValue: repair.outcome ?? "")
            _unresolvedIssues = State(initialValue: repair.unresolvedIssues ?? "")
            _followUpRequired = State(initialValue: repair.followUpRequired)
            _notes = State(initialValue: repair.notes ?? "")
            _selectedFault = State(initialValue: repair.fault)
        }
    }

    var body: some View {
        Form {
            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
            }

            Section("Core") {
                TextField("Repair Provider", text: $repairProvider)
                Toggle("Booking Date", isOn: $hasBookingDate)
                if hasBookingDate {
                    DatePicker("Booking", selection: $bookingDate, displayedComponents: .date)
                }
                DatePicker("Repair Date", selection: $repairDate, displayedComponents: .date)
                Picker("Related Fault", selection: $selectedFault) {
                    Text("None").tag(nil as FaultRecord?)
                    ForEach(faults) { fault in
                        Text(fault.title).tag(fault as FaultRecord?)
                    }
                }
                TextField("Diagnosis", text: $diagnosis, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
            }

            Section("Work") {
                TextField("Work Performed", text: $workPerformed, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                TextField("Parts Replaced", text: $partsReplaced)
                TextField("Outcome", text: $outcome)
                TextField("Unresolved Issues", text: $unresolvedIssues, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                Toggle("Follow-up Required", isOn: $followUpRequired)
            }

            Section("Cost") {
                TextField("Labour Cost", text: $labourCostText)
                TextField("Parts Cost", text: $partsCostText)
                TextField("Total Cost", text: $totalCostText)
                TextField("Currency", text: $currencyCode)
                Toggle("Warranty Coverage", isOn: $warrantyCoverage)
                Picker("Payment Status", selection: $paymentStatus) {
                    ForEach(RepairPaymentStatus.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                TextField("Repair Warranty Details", text: $repairWarrantyDetails)
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
        case .create: return "New Repair"
        case .edit: return "Edit Repair"
        }
    }

    private func handleSave() {
        let labourCost = Decimal(string: labourCostText.trimmingCharacters(in: .whitespacesAndNewlines))
        let partsCost = Decimal(string: partsCostText.trimmingCharacters(in: .whitespacesAndNewlines))
        let manualTotal = Decimal(string: totalCostText.trimmingCharacters(in: .whitespacesAndNewlines))
        let calculatedTotal = RepairCostService.calculateTotal(labour: labourCost, parts: partsCost)
        let finalTotal = manualTotal ?? calculatedTotal

        switch mode {
        case .create(let purchase):
            let repair = RepairRecord(
                repairProvider: repairProvider.nilIfBlank,
                bookingDate: hasBookingDate ? bookingDate : nil,
                repairDate: repairDate,
                diagnosis: diagnosis.nilIfBlank,
                workPerformed: workPerformed.nilIfBlank,
                partsReplaced: partsReplaced.nilIfBlank,
                labourCost: labourCost,
                partsCost: partsCost,
                totalCost: finalTotal,
                currencyCode: currencyCode.nilIfBlank,
                warrantyCoverage: warrantyCoverage,
                paymentStatus: paymentStatus,
                repairWarrantyDetails: repairWarrantyDetails.nilIfBlank,
                outcome: outcome.nilIfBlank,
                unresolvedIssues: unresolvedIssues.nilIfBlank,
                followUpRequired: followUpRequired,
                notes: notes.nilIfBlank,
                purchase: purchase,
                fault: selectedFault
            )
            modelContext.insert(repair)
            purchase.repairRecords.append(repair)
            selectedFault?.relatedRepairs.append(repair)
            purchase.updatedAt = .now
            onCommit(repair)

        case .edit(let repair):
            let previousFault = repair.fault
            repair.repairProvider = repairProvider.nilIfBlank
            repair.bookingDate = hasBookingDate ? bookingDate : nil
            repair.repairDate = repairDate
            repair.diagnosis = diagnosis.nilIfBlank
            repair.workPerformed = workPerformed.nilIfBlank
            repair.partsReplaced = partsReplaced.nilIfBlank
            repair.labourCost = labourCost
            repair.partsCost = partsCost
            repair.totalCost = finalTotal
            repair.currencyCode = currencyCode.nilIfBlank
            repair.warrantyCoverage = warrantyCoverage
            repair.paymentStatus = paymentStatus
            repair.repairWarrantyDetails = repairWarrantyDetails.nilIfBlank
            repair.outcome = outcome.nilIfBlank
            repair.unresolvedIssues = unresolvedIssues.nilIfBlank
            repair.followUpRequired = followUpRequired
            repair.notes = notes.nilIfBlank
            repair.fault = selectedFault
            if previousFault?.persistentModelID != selectedFault?.persistentModelID {
                previousFault?.relatedRepairs.removeAll { $0.persistentModelID == repair.persistentModelID }
                selectedFault?.relatedRepairs.append(repair)
            }
            repair.updatedAt = .now
            repair.purchase?.updatedAt = .now
            onCommit(repair)
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
