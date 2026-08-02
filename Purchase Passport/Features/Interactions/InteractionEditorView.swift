import SwiftData
import SwiftUI

struct InteractionEditorView: View {
    enum Mode {
        case create(purchase: Purchase)
        case edit(Interaction)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let mode: Mode
    private let onCommit: (Interaction) -> Void

    @State private var occurredAt: Date
    @State private var type: InteractionType
    @State private var status: InteractionStatus
    @State private var partyContacted: String
    @State private var contactPerson: String
    @State private var subject: String
    @State private var summary: String
    @State private var detailedNotes: String
    @State private var promisesOrCommitments: String
    @State private var referenceNumber: String
    @State private var nextAction: String
    @State private var hasFollowUpDate: Bool
    @State private var followUpDate: Date
    @State private var validationMessage: String?

    init(mode: Mode, onCommit: @escaping (Interaction) -> Void) {
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .create:
            _occurredAt = State(initialValue: .now)
            _type = State(initialValue: .phoneCall)
            _status = State(initialValue: .open)
            _partyContacted = State(initialValue: "")
            _contactPerson = State(initialValue: "")
            _subject = State(initialValue: "")
            _summary = State(initialValue: "")
            _detailedNotes = State(initialValue: "")
            _promisesOrCommitments = State(initialValue: "")
            _referenceNumber = State(initialValue: "")
            _nextAction = State(initialValue: "")
            _hasFollowUpDate = State(initialValue: false)
            _followUpDate = State(initialValue: .now)
        case .edit(let interaction):
            _occurredAt = State(initialValue: interaction.occurredAt)
            _type = State(initialValue: interaction.type)
            _status = State(initialValue: interaction.status)
            _partyContacted = State(initialValue: interaction.partyContacted ?? "")
            _contactPerson = State(initialValue: interaction.contactPerson ?? "")
            _subject = State(initialValue: interaction.subject)
            _summary = State(initialValue: interaction.summary ?? "")
            _detailedNotes = State(initialValue: interaction.detailedNotes ?? "")
            _promisesOrCommitments = State(initialValue: interaction.promisesOrCommitments ?? "")
            _referenceNumber = State(initialValue: interaction.referenceNumber ?? "")
            _nextAction = State(initialValue: interaction.nextAction ?? "")
            _hasFollowUpDate = State(initialValue: interaction.followUpDate != nil)
            _followUpDate = State(initialValue: interaction.followUpDate ?? .now)
        }
    }

    var body: some View {
        Form {
            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
            }

            Section("Core") {
                DatePicker("Occurred", selection: $occurredAt)
                Picker("Type", selection: $type) {
                    ForEach(InteractionType.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                Picker("Status", selection: $status) {
                    ForEach(InteractionStatus.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                TextField("Subject", text: $subject)
            }

            Section("Parties") {
                TextField("Party Contacted", text: $partyContacted)
                TextField("Contact Person", text: $contactPerson)
                TextField("Reference Number", text: $referenceNumber)
            }

            Section("Details") {
                TextField("Summary", text: $summary)
                TextField("Detailed Notes", text: $detailedNotes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                TextField("Promises Or Commitments", text: $promisesOrCommitments, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                TextField("Next Action", text: $nextAction)
                Toggle("Follow-up Date", isOn: $hasFollowUpDate)
                if hasFollowUpDate {
                    DatePicker("Follow-up", selection: $followUpDate)
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
            return "New Interaction"
        case .edit:
            return "Edit Interaction"
        }
    }

    private func handleSave() {
        if let message = InteractionEditorValidation.validate(subject: subject) {
            validationMessage = message
            return
        }

        let normalizedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        validationMessage = nil

        switch mode {
        case .create(let purchase):
            let interaction = Interaction(
                occurredAt: occurredAt,
                type: type,
                status: status,
                partyContacted: partyContacted.nilIfBlank,
                contactPerson: contactPerson.nilIfBlank,
                subject: normalizedSubject,
                summary: summary.nilIfBlank,
                detailedNotes: detailedNotes.nilIfBlank,
                promisesOrCommitments: promisesOrCommitments.nilIfBlank,
                referenceNumber: referenceNumber.nilIfBlank,
                nextAction: nextAction.nilIfBlank,
                followUpDate: hasFollowUpDate ? followUpDate : nil,
                updatedAt: .now,
                purchase: purchase
            )

            modelContext.insert(interaction)
            purchase.interactions.append(interaction)
            synchronizeFollowUpReminder(for: interaction, purchase: purchase)
            purchase.updatedAt = .now
            onCommit(interaction)

        case .edit(let interaction):
            let purchase = interaction.purchase
            interaction.occurredAt = occurredAt
            interaction.type = type
            interaction.status = status
            interaction.partyContacted = partyContacted.nilIfBlank
            interaction.contactPerson = contactPerson.nilIfBlank
            interaction.subject = normalizedSubject
            interaction.summary = summary.nilIfBlank
            interaction.detailedNotes = detailedNotes.nilIfBlank
            interaction.promisesOrCommitments = promisesOrCommitments.nilIfBlank
            interaction.referenceNumber = referenceNumber.nilIfBlank
            interaction.nextAction = nextAction.nilIfBlank
            interaction.followUpDate = hasFollowUpDate ? followUpDate : nil
            interaction.updatedAt = .now
            synchronizeFollowUpReminder(for: interaction, purchase: purchase)
            interaction.purchase?.updatedAt = .now
            onCommit(interaction)
        }

        dismiss()
    }

    private func synchronizeFollowUpReminder(for interaction: Interaction, purchase: Purchase?) {
        guard let purchase else { return }

        if hasFollowUpDate {
            let reminderTitle = "Follow-up: \(interaction.subject)"
            let notes = interaction.nextAction ?? interaction.summary ?? "Follow up for interaction."

            if let existingReminder = interaction.followUpReminder {
                existingReminder.title = reminderTitle
                existingReminder.type = .custom
                existingReminder.dueDate = followUpDate
                existingReminder.hasSpecificTime = true
                existingReminder.advanceWarningDays = 1
                existingReminder.recurrence = .none
                existingReminder.priority = .normal
                existingReminder.notes = notes
                existingReminder.isCompleted = false
                existingReminder.completedAt = nil
                existingReminder.updatedAt = .now
                existingReminder.purchase = purchase
            } else {
                let reminder = Reminder(
                    title: reminderTitle,
                    type: .custom,
                    dueDate: followUpDate,
                    hasSpecificTime: true,
                    advanceWarningDays: 1,
                    recurrence: .none,
                    priority: .normal,
                    notes: notes,
                    purchase: purchase
                )
                modelContext.insert(reminder)
                purchase.reminders.append(reminder)
                interaction.followUpReminder = reminder
            }
        } else if let reminder = interaction.followUpReminder {
            purchase.reminders.removeAll { $0.persistentModelID == reminder.persistentModelID }
            interaction.followUpReminder = nil
            modelContext.delete(reminder)
        }
    }
}

enum InteractionEditorValidation {
    static func validate(subject: String) -> String? {
        if subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Interaction subject is required."
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
