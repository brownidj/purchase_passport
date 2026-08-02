import SwiftData
import SwiftUI

struct ReminderEditorView: View {
    enum Mode {
        case create(purchase: Purchase)
        case edit(Reminder)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let mode: Mode
    private let onCommit: (Reminder) -> Void

    @State private var title: String
    @State private var type: ReminderType
    @State private var dueDate: Date
    @State private var hasSpecificTime: Bool
    @State private var advanceWarningDaysText: String
    @State private var recurrence: ReminderRecurrence
    @State private var priority: ReminderPriority
    @State private var notes: String
    @State private var isCompleted: Bool
    @State private var validationMessage: String?

    init(mode: Mode, onCommit: @escaping (Reminder) -> Void) {
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .create:
            _title = State(initialValue: "")
            _type = State(initialValue: .custom)
            _dueDate = State(initialValue: .now)
            _hasSpecificTime = State(initialValue: false)
            _advanceWarningDaysText = State(initialValue: "7")
            _recurrence = State(initialValue: .none)
            _priority = State(initialValue: .normal)
            _notes = State(initialValue: "")
            _isCompleted = State(initialValue: false)
        case .edit(let reminder):
            _title = State(initialValue: reminder.title)
            _type = State(initialValue: reminder.type)
            _dueDate = State(initialValue: reminder.dueDate)
            _hasSpecificTime = State(initialValue: reminder.hasSpecificTime)
            _advanceWarningDaysText = State(initialValue: String(reminder.advanceWarningDays))
            _recurrence = State(initialValue: reminder.recurrence)
            _priority = State(initialValue: reminder.priority)
            _notes = State(initialValue: reminder.notes ?? "")
            _isCompleted = State(initialValue: reminder.isCompleted)
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
                    ForEach(ReminderType.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                Toggle("Specific Time", isOn: $hasSpecificTime)
                DatePicker(
                    "Due",
                    selection: $dueDate,
                    displayedComponents: hasSpecificTime ? [.date, .hourAndMinute] : [.date]
                )
            }

            Section("Schedule") {
                TextField("Advance Warning Days", text: $advanceWarningDaysText)
                Picker("Recurrence", selection: $recurrence) {
                    ForEach(ReminderRecurrence.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                Picker("Priority", selection: $priority) {
                    ForEach(ReminderPriority.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                Toggle("Completed", isOn: $isCompleted)
            }

            Section("Notes") {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
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
            return "New Reminder"
        case .edit:
            return "Edit Reminder"
        }
    }

    private func handleSave() {
        let warningDays = Int(advanceWarningDaysText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        if let message = ReminderService.validate(title: title, advanceWarningDays: warningDays) {
            validationMessage = message
            return
        }

        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        validationMessage = nil

        switch mode {
        case .create(let purchase):
            let reminder = Reminder(
                title: normalizedTitle,
                type: type,
                dueDate: dueDate,
                hasSpecificTime: hasSpecificTime,
                advanceWarningDays: warningDays,
                recurrence: recurrence,
                priority: priority,
                notes: notes.nilIfBlank,
                isCompleted: isCompleted,
                completedAt: isCompleted ? .now : nil,
                updatedAt: .now,
                purchase: purchase
            )
            modelContext.insert(reminder)
            purchase.reminders.append(reminder)
            purchase.updatedAt = .now
            onCommit(reminder)

        case .edit(let reminder):
            reminder.title = normalizedTitle
            reminder.type = type
            reminder.dueDate = dueDate
            reminder.hasSpecificTime = hasSpecificTime
            reminder.advanceWarningDays = warningDays
            reminder.recurrence = recurrence
            reminder.priority = priority
            reminder.notes = notes.nilIfBlank
            reminder.isCompleted = isCompleted
            reminder.completedAt = isCompleted ? (reminder.completedAt ?? .now) : nil
            reminder.updatedAt = .now
            reminder.purchase?.updatedAt = .now
            onCommit(reminder)
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
