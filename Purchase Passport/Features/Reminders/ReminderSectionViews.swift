import SwiftUI
import SwiftData

struct ReminderListSectionView: View {
    let reminders: [Reminder]
    @Binding var selectedReminderID: PersistentIdentifier?
    let selectedReminder: Reminder?
    let formattedDateTime: (Date?, Bool) -> String
    let onEditReminder: () -> Void

    var body: some View {
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
                            Text(formattedDateTime(reminder.dueDate, reminder.hasSpecificTime))
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
                Button("Edit Reminder", action: onEditReminder)
                    .disabled(selectedReminder == nil)
            }
        }
    }
}

struct ReminderDetailSectionView: View {
    let reminder: Reminder?
    let formattedDateTime: (Date?, Bool) -> String
    let formattedReminderState: (Reminder) -> String

    var body: some View {
        Group {
            if let reminder {
                List {
                    Section("Summary") {
                        LabeledContent("Title", value: reminder.title)
                        LabeledContent("Type", value: reminder.type.rawValue)
                        LabeledContent("Due", value: formattedDateTime(reminder.dueDate, reminder.hasSpecificTime))
                        LabeledContent("Purchase", value: reminder.purchase?.name ?? "Not set")
                        LabeledContent("Priority", value: reminder.priority.rawValue)
                        LabeledContent("Recurrence", value: reminder.recurrence.rawValue)
                    }

                    Section("Tracking") {
                        LabeledContent("Advance Warning", value: "\(reminder.advanceWarningDays) day(s)")
                        LabeledContent("State", value: formattedReminderState(reminder))
                        LabeledContent("Completed", value: reminder.isCompleted ? "Yes" : "No")
                        LabeledContent("Next Due", value: formattedDateTime(ReminderService.nextDueDate(for: reminder), reminder.hasSpecificTime))
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
}
