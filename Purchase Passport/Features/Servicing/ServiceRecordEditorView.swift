import SwiftData
import SwiftUI

struct ServiceRecordEditorView: View {
    enum Mode {
        case create(purchase: Purchase)
        case edit(ServiceRecord)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let mode: Mode
    private let onCommit: (ServiceRecord) -> Void

    @State private var serviceType: String
    @State private var serviceProvider: String
    @State private var hasBookingDate: Bool
    @State private var bookingDate: Date
    @State private var hasServiceDate: Bool
    @State private var serviceDate: Date
    @State private var hasCompletionDate: Bool
    @State private var completionDate: Date
    @State private var costAmountText: String
    @State private var currencyCode: String
    @State private var usageReading: String
    @State private var workRequested: String
    @State private var workCompleted: String
    @State private var partsReplaced: String
    @State private var technicianNotes: String
    @State private var hasNextServiceDate: Bool
    @State private var nextServiceDate: Date
    @State private var nextServiceIntervalMonthsText: String
    @State private var serviceReferenceNumber: String
    @State private var notes: String
    @State private var validationMessage: String?

    init(mode: Mode, onCommit: @escaping (ServiceRecord) -> Void) {
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .create:
            _serviceType = State(initialValue: "")
            _serviceProvider = State(initialValue: "")
            _hasBookingDate = State(initialValue: false)
            _bookingDate = State(initialValue: .now)
            _hasServiceDate = State(initialValue: true)
            _serviceDate = State(initialValue: .now)
            _hasCompletionDate = State(initialValue: false)
            _completionDate = State(initialValue: .now)
            _costAmountText = State(initialValue: "")
            _currencyCode = State(initialValue: "")
            _usageReading = State(initialValue: "")
            _workRequested = State(initialValue: "")
            _workCompleted = State(initialValue: "")
            _partsReplaced = State(initialValue: "")
            _technicianNotes = State(initialValue: "")
            _hasNextServiceDate = State(initialValue: false)
            _nextServiceDate = State(initialValue: .now)
            _nextServiceIntervalMonthsText = State(initialValue: "")
            _serviceReferenceNumber = State(initialValue: "")
            _notes = State(initialValue: "")
        case .edit(let record):
            _serviceType = State(initialValue: record.serviceType)
            _serviceProvider = State(initialValue: record.serviceProvider ?? "")
            _hasBookingDate = State(initialValue: record.bookingDate != nil)
            _bookingDate = State(initialValue: record.bookingDate ?? .now)
            _hasServiceDate = State(initialValue: record.serviceDate != nil)
            _serviceDate = State(initialValue: record.serviceDate ?? .now)
            _hasCompletionDate = State(initialValue: record.completionDate != nil)
            _completionDate = State(initialValue: record.completionDate ?? .now)
            _costAmountText = State(initialValue: record.costAmount.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
            _currencyCode = State(initialValue: record.currencyCode ?? "")
            _usageReading = State(initialValue: record.usageReading ?? "")
            _workRequested = State(initialValue: record.workRequested ?? "")
            _workCompleted = State(initialValue: record.workCompleted ?? "")
            _partsReplaced = State(initialValue: record.partsReplaced ?? "")
            _technicianNotes = State(initialValue: record.technicianNotes ?? "")
            _hasNextServiceDate = State(initialValue: record.nextServiceDate != nil)
            _nextServiceDate = State(initialValue: record.nextServiceDate ?? .now)
            _nextServiceIntervalMonthsText = State(initialValue: record.nextServiceIntervalMonths.map(String.init) ?? "")
            _serviceReferenceNumber = State(initialValue: record.serviceReferenceNumber ?? "")
            _notes = State(initialValue: record.notes ?? "")
        }
    }

    var body: some View {
        Form {
            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
            }

            Section("Core") {
                TextField("Service Type", text: $serviceType)
                TextField("Service Provider", text: $serviceProvider)
                Toggle("Booking Date", isOn: $hasBookingDate)
                if hasBookingDate { DatePicker("Booking", selection: $bookingDate, displayedComponents: .date) }
                Toggle("Service Date", isOn: $hasServiceDate)
                if hasServiceDate { DatePicker("Service", selection: $serviceDate, displayedComponents: .date) }
                Toggle("Completion Date", isOn: $hasCompletionDate)
                if hasCompletionDate { DatePicker("Completion", selection: $completionDate, displayedComponents: .date) }
            }

            Section("Cost") {
                TextField("Cost", text: $costAmountText)
                TextField("Currency", text: $currencyCode)
                TextField("Usage Reading", text: $usageReading)
                TextField("Reference Number", text: $serviceReferenceNumber)
            }

            Section("Work") {
                TextField("Work Requested", text: $workRequested, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                TextField("Work Completed", text: $workCompleted, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                TextField("Parts Replaced", text: $partsReplaced)
                TextField("Technician Notes", text: $technicianNotes, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
            }

            Section("Next Service") {
                Toggle("Next Service Date", isOn: $hasNextServiceDate)
                if hasNextServiceDate { DatePicker("Next Service", selection: $nextServiceDate, displayedComponents: .date) }
                TextField("Next Service Interval (months)", text: $nextServiceIntervalMonthsText)
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
        case .create: return "New Service Record"
        case .edit: return "Edit Service Record"
        }
    }

    private func handleSave() {
        let normalizedType = serviceType.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedType.isEmpty {
            validationMessage = "Service type is required."
            return
        }

        validationMessage = nil
        let costAmount = Decimal(string: costAmountText.trimmingCharacters(in: .whitespacesAndNewlines))
        let nextServiceInterval = Int(nextServiceIntervalMonthsText.trimmingCharacters(in: .whitespacesAndNewlines))

        switch mode {
        case .create(let purchase):
            let record = ServiceRecord(
                serviceType: normalizedType,
                serviceProvider: serviceProvider.nilIfBlank,
                bookingDate: hasBookingDate ? bookingDate : nil,
                serviceDate: hasServiceDate ? serviceDate : nil,
                completionDate: hasCompletionDate ? completionDate : nil,
                costAmount: costAmount,
                currencyCode: currencyCode.nilIfBlank,
                usageReading: usageReading.nilIfBlank,
                workRequested: workRequested.nilIfBlank,
                workCompleted: workCompleted.nilIfBlank,
                partsReplaced: partsReplaced.nilIfBlank,
                technicianNotes: technicianNotes.nilIfBlank,
                nextServiceDate: hasNextServiceDate ? nextServiceDate : nil,
                nextServiceIntervalMonths: nextServiceInterval,
                serviceReferenceNumber: serviceReferenceNumber.nilIfBlank,
                notes: notes.nilIfBlank,
                purchase: purchase
            )
            modelContext.insert(record)
            purchase.serviceRecords.append(record)
            purchase.updatedAt = .now
            onCommit(record)

        case .edit(let record):
            record.serviceType = normalizedType
            record.serviceProvider = serviceProvider.nilIfBlank
            record.bookingDate = hasBookingDate ? bookingDate : nil
            record.serviceDate = hasServiceDate ? serviceDate : nil
            record.completionDate = hasCompletionDate ? completionDate : nil
            record.costAmount = costAmount
            record.currencyCode = currencyCode.nilIfBlank
            record.usageReading = usageReading.nilIfBlank
            record.workRequested = workRequested.nilIfBlank
            record.workCompleted = workCompleted.nilIfBlank
            record.partsReplaced = partsReplaced.nilIfBlank
            record.technicianNotes = technicianNotes.nilIfBlank
            record.nextServiceDate = hasNextServiceDate ? nextServiceDate : nil
            record.nextServiceIntervalMonths = nextServiceInterval
            record.serviceReferenceNumber = serviceReferenceNumber.nilIfBlank
            record.notes = notes.nilIfBlank
            record.updatedAt = .now
            record.purchase?.updatedAt = .now
            onCommit(record)
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
