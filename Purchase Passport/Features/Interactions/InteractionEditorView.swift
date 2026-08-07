import AppKit
import SwiftData
import SwiftUI

struct InteractionEditorView: View {
    enum Mode {
        case create(purchase: Purchase)
        case createDraft(purchase: Purchase, draft: InteractionDraft)
        case edit(Interaction)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let mode: Mode
    private let onCommit: (Interaction) -> Void
    private let relatedInteraction: Interaction?
    private let relatedCorrespondence: CorrespondenceRecord?

    @State private var occurredAt: Date
    @State private var type: InteractionType
    @State private var status: InteractionStatus
    @State private var partyContacted: String
    @State private var contactPerson: String
    @State private var contactPhoneNumber: String
    @State private var subject: String
    @State private var summary: String
    @State private var detailedNotes: String
    @State private var promisesOrCommitments: String
    @State private var referenceNumber: String
    @State private var durationMinutes: String
    @State private var nextAction: String
    @State private var hasFollowUpDate: Bool
    @State private var followUpDate: Date
    @State private var followUpInteractionType: InteractionType?
    @State private var autoDurationStartDate: Date?
    @State private var validationMessage: String?

    init(mode: Mode, onCommit: @escaping (Interaction) -> Void) {
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .create:
            self.relatedInteraction = nil
            self.relatedCorrespondence = nil
            _occurredAt = State(initialValue: .now)
            _type = State(initialValue: .phoneCall)
            _status = State(initialValue: .open)
            _partyContacted = State(initialValue: "")
            _contactPerson = State(initialValue: "")
            _contactPhoneNumber = State(initialValue: "")
            _subject = State(initialValue: "")
            _summary = State(initialValue: "")
            _detailedNotes = State(initialValue: "")
            _promisesOrCommitments = State(initialValue: "")
            _referenceNumber = State(initialValue: "")
            _durationMinutes = State(initialValue: "")
            _nextAction = State(initialValue: "")
            _hasFollowUpDate = State(initialValue: false)
            _followUpDate = State(initialValue: .now)
            _followUpInteractionType = State(initialValue: nil)
            _autoDurationStartDate = State(initialValue: nil)
        case .createDraft(_, let draft):
            self.relatedInteraction = draft.relatedInteraction
            self.relatedCorrespondence = draft.relatedCorrespondence
            _occurredAt = State(initialValue: draft.occurredAt)
            _type = State(initialValue: draft.type)
            _status = State(initialValue: draft.status)
            _partyContacted = State(initialValue: draft.partyContacted)
            _contactPerson = State(initialValue: draft.contactPerson)
            _contactPhoneNumber = State(initialValue: draft.contactPhoneNumber)
            _subject = State(initialValue: draft.subject)
            _summary = State(initialValue: draft.summary)
            _detailedNotes = State(initialValue: draft.detailedNotes)
            _promisesOrCommitments = State(initialValue: draft.promisesOrCommitments)
            _referenceNumber = State(initialValue: draft.referenceNumber)
            _durationMinutes = State(initialValue: draft.durationMinutes.map(String.init) ?? "")
            _nextAction = State(initialValue: draft.nextAction)
            _hasFollowUpDate = State(initialValue: draft.followUpDate != nil)
            _followUpDate = State(initialValue: draft.followUpDate ?? .now)
            _followUpInteractionType = State(initialValue: nil)
            _autoDurationStartDate = State(initialValue: draft.autoDurationStartDate)
        case .edit(let interaction):
            self.relatedInteraction = interaction.relatedInteraction
            self.relatedCorrespondence = interaction.relatedCorrespondence
            _occurredAt = State(initialValue: interaction.occurredAt)
            _type = State(initialValue: interaction.type)
            _status = State(initialValue: interaction.status)
            _partyContacted = State(initialValue: interaction.partyContacted ?? "")
            _contactPerson = State(initialValue: interaction.contactPerson ?? "")
            _contactPhoneNumber = State(initialValue: interaction.contactPhoneNumber ?? "")
            _subject = State(initialValue: interaction.subject)
            _summary = State(initialValue: interaction.summary ?? "")
            _detailedNotes = State(initialValue: interaction.detailedNotes ?? "")
            _promisesOrCommitments = State(initialValue: interaction.promisesOrCommitments ?? "")
            _referenceNumber = State(initialValue: interaction.referenceNumber ?? "")
            _durationMinutes = State(initialValue: interaction.durationMinutes.map(String.init) ?? "")
            _nextAction = State(initialValue: interaction.nextAction ?? "")
            _hasFollowUpDate = State(initialValue: interaction.followUpDate != nil)
            _followUpDate = State(initialValue: interaction.followUpDate ?? .now)
            _followUpInteractionType = State(initialValue: interaction.followUpReminder?.followUpInteractionType)
            _autoDurationStartDate = State(initialValue: nil)
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
                TextField("Phone Number", text: $contactPhoneNumber)
                TextField("Reference Number", text: $referenceNumber)
            }

            Section("Details") {
                TextField("Summary", text: $summary)
                TextField("Detailed Notes", text: $detailedNotes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                TextField("Promises Or Commitments", text: $promisesOrCommitments, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                TextField("Duration (minutes)", text: $durationMinutes)
                Toggle("Follow-up Date", isOn: $hasFollowUpDate)
                if hasFollowUpDate {
                    DatePicker("Follow-up", selection: $followUpDate)
                    Picker("Follow-up Action", selection: $followUpInteractionType) {
                        Text("None").tag(Optional<InteractionType>.none)
                        ForEach(followUpActionTypes, id: \.self) { value in
                            Text(value.rawValue).tag(Optional(value))
                        }
                    }
                    TextField("Follow-up Notes", text: $nextAction, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }

            if relatedInteraction != nil || relatedCorrespondence != nil {
                Section("Linked Context") {
                    if let relatedCorrespondence {
                        LabeledContent("Linked Email", value: relatedCorrespondence.subject)
                        LabeledContent(
                            "Occurred",
                            value: relatedCorrespondence.occurredAt.formatted(date: .abbreviated, time: .shortened)
                        )
                        LabeledContent("From", value: relatedCorrespondence.sender ?? "Not set")
                        if relatedCorrespondence.externalMessageID != nil {
                            Button("Open in Mail") {
                                openRelatedCorrespondenceInMail(relatedCorrespondence)
                            }
                        }
                        if let contextPreview = correspondenceContextPreview {
                            Text(contextPreview)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let relatedInteraction {
                        LabeledContent("Linked Interaction", value: relatedInteraction.subject)
                        LabeledContent("Type", value: relatedInteraction.type.rawValue)
                        LabeledContent(
                            "Occurred",
                            value: relatedInteraction.occurredAt.formatted(date: .abbreviated, time: .shortened)
                        )
                        if let contextSummary = interactionContextSummary {
                            Text(contextSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if type == .phoneCall, phoneNumberForDialing != nil {
                Section("Call") {
                    LabeledContent("Dial Number", value: phoneNumberForDialing ?? "Not set")
                    Button(autoDurationStartDate == nil ? "Start" : "Restart Start Time") {
                        startCallTiming()
                    }
                    Button("Dial Number") {
                        dialPhoneNumber()
                    }
                    if autoDurationStartDate != nil {
                        Button("Use Elapsed Duration") {
                            applyElapsedDuration()
                        }
                        LabeledContent("Call Started", value: formattedCallStartedAt)
                    } else {
                        Text("Use Start to stamp the call start time, or Dial Number to start the call and stamp the time together.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if showsInlineActionRow {
                Section {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)

                        Spacer()

                        Button("Save") {
                            handleSave()
                        }
                        .keyboardShortcut(.defaultAction)
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
            return "New Interaction"
        case .createDraft:
            return "Log Phone Call"
        case .edit:
            return "Edit Interaction"
        }
    }

    private var showsInlineActionRow: Bool {
        switch mode {
        case .createDraft, .edit:
            return true
        case .create:
            return false
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
                contactPhoneNumber: contactPhoneNumber.nilIfBlank,
                subject: normalizedSubject,
                summary: summary.nilIfBlank,
                detailedNotes: detailedNotes.nilIfBlank,
                promisesOrCommitments: promisesOrCommitments.nilIfBlank,
                referenceNumber: referenceNumber.nilIfBlank,
                durationMinutes: durationMinutes.nilIfBlankInt,
                nextAction: nextAction.nilIfBlank,
                followUpDate: hasFollowUpDate ? followUpDate : nil,
                updatedAt: .now,
                purchase: purchase,
                relatedInteraction: relatedInteraction,
                relatedCorrespondence: relatedCorrespondence
            )

            modelContext.insert(interaction)
            purchase.interactions.append(interaction)
            synchronizeFollowUpReminder(for: interaction, purchase: purchase)
            purchase.updatedAt = .now
            if !saveModelContext() { return }
            onCommit(interaction)

        case .createDraft(let purchase, _):
            let interaction = Interaction(
                occurredAt: occurredAt,
                type: type,
                status: status,
                partyContacted: partyContacted.nilIfBlank,
                contactPerson: contactPerson.nilIfBlank,
                contactPhoneNumber: contactPhoneNumber.nilIfBlank,
                subject: normalizedSubject,
                summary: summary.nilIfBlank,
                detailedNotes: detailedNotes.nilIfBlank,
                promisesOrCommitments: promisesOrCommitments.nilIfBlank,
                referenceNumber: referenceNumber.nilIfBlank,
                durationMinutes: durationMinutes.nilIfBlankInt,
                nextAction: nextAction.nilIfBlank,
                followUpDate: hasFollowUpDate ? followUpDate : nil,
                updatedAt: .now,
                purchase: purchase,
                relatedInteraction: relatedInteraction,
                relatedCorrespondence: relatedCorrespondence
            )

            modelContext.insert(interaction)
            purchase.interactions.append(interaction)
            synchronizeFollowUpReminder(for: interaction, purchase: purchase)
            purchase.updatedAt = .now
            if !saveModelContext() { return }
            onCommit(interaction)

        case .edit(let interaction):
            let purchase = interaction.purchase
            interaction.occurredAt = occurredAt
            interaction.type = type
            interaction.status = status
            interaction.partyContacted = partyContacted.nilIfBlank
            interaction.contactPerson = contactPerson.nilIfBlank
            interaction.contactPhoneNumber = contactPhoneNumber.nilIfBlank
            interaction.subject = normalizedSubject
            interaction.summary = summary.nilIfBlank
            interaction.detailedNotes = detailedNotes.nilIfBlank
            interaction.promisesOrCommitments = promisesOrCommitments.nilIfBlank
            interaction.referenceNumber = referenceNumber.nilIfBlank
            interaction.durationMinutes = durationMinutes.nilIfBlankInt
            interaction.nextAction = nextAction.nilIfBlank
            interaction.followUpDate = hasFollowUpDate ? followUpDate : nil
            interaction.updatedAt = .now
            interaction.relatedInteraction = relatedInteraction
            interaction.relatedCorrespondence = relatedCorrespondence
            synchronizeFollowUpReminder(for: interaction, purchase: purchase)
            interaction.purchase?.updatedAt = .now
            if !saveModelContext() { return }
            onCommit(interaction)
        }

        dismiss()
    }

    private var phoneNumberForDialing: String? {
        contactPhoneNumber.nilIfBlank
    }

    private var correspondenceContextPreview: String? {
        let value = relatedCorrespondence?.fullBody?.nilIfBlank ?? relatedCorrespondence?.bodyPreview?.nilIfBlank
        guard let value else { return nil }
        return String(value.prefix(500))
    }

    private var interactionContextSummary: String? {
        let value = relatedInteraction?.detailedNotes?.nilIfBlank
            ?? relatedInteraction?.summary?.nilIfBlank
        guard let value else { return nil }
        return String(value.prefix(500))
    }

    private var formattedCallStartedAt: String {
        guard let autoDurationStartDate else { return "Not set" }
        return autoDurationStartDate.formatted(date: .abbreviated, time: .shortened)
    }

    private var followUpActionTypes: [InteractionType] {
        InteractionType.allCases.filter { $0 != .other }
    }

    private func dialPhoneNumber() {
        guard let phoneNumber = phoneNumberForDialing,
              let url = dialingURL(for: phoneNumber) else {
            validationMessage = "A valid phone number is required to start the call."
            return
        }

        startCallTiming()

        if !NSWorkspace.shared.open(url) {
            validationMessage = "The call could not be started from this Mac."
        }
    }

    private func startCallTiming() {
        let startDate = Date.now
        occurredAt = startDate
        autoDurationStartDate = startDate
        validationMessage = nil
    }

    private func openRelatedCorrespondenceInMail(_ correspondence: CorrespondenceRecord) {
        guard let url = ProviderCorrespondenceService.mailMessageURL(for: correspondence.externalMessageID) else {
            validationMessage = "This email does not have a Mail link."
            return
        }
        validationMessage = nil
        if !NSWorkspace.shared.open(url) {
            validationMessage = "The email could not be opened in Mail."
        }
    }

    private func applyElapsedDuration() {
        guard let autoDurationStartDate else { return }
        let elapsed = max(Date.now.timeIntervalSince(autoDurationStartDate), 0)
        let minutes = max(Int((elapsed / 60).rounded(.up)), 1)
        durationMinutes = String(minutes)
    }

    private func dialingURL(for phoneNumber: String) -> URL? {
        let allowedScalars = CharacterSet(charactersIn: "+0123456789")
        let sanitized = String(phoneNumber.unicodeScalars.filter { allowedScalars.contains($0) })
        guard !sanitized.isEmpty else { return nil }
        return URL(string: "tel://\(sanitized)")
    }

    private func saveModelContext() -> Bool {
        do {
            try modelContext.save()
            validationMessage = nil
            return true
        } catch {
            validationMessage = error.localizedDescription
            return false
        }
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
                existingReminder.sourceInteraction = interaction
                existingReminder.followUpInteractionType = followUpInteractionType
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
                    purchase: purchase,
                    sourceInteraction: interaction,
                    followUpInteractionType: followUpInteractionType
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

    var nilIfBlankInt: Int? {
        guard let value = nilIfBlank else { return nil }
        return Int(value)
    }
}
