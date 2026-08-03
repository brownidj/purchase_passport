import SwiftUI
import SwiftData

struct InteractionListSectionView: View {
    let interactions: [Interaction]
    @Binding var selectedInteractionID: PersistentIdentifier?
    let selectedInteraction: Interaction?
    let formattedDateTime: (Date?, Bool) -> String
    let onEditInteraction: () -> Void

    var body: some View {
        Group {
            if interactions.isEmpty {
                ContentUnavailableView(
                    "No Interactions",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Add an interaction from a purchase detail view.")
                )
            } else {
                List(interactions, selection: $selectedInteractionID) { interaction in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(interaction.subject)
                            .font(.headline)
                        HStack(spacing: 8) {
                            Text(formattedDateTime(interaction.occurredAt, true))
                            Text("•")
                            Text(interaction.purchase?.name ?? "Unlinked Purchase")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .tag(interaction.persistentModelID)
                }
            }
        }
        .navigationTitle("Interactions")
        .toolbar {
            ToolbarItem {
                Button("Edit Interaction", action: onEditInteraction)
                    .disabled(selectedInteraction == nil)
            }
        }
    }
}

struct InteractionDetailSectionView: View {
    let interaction: Interaction?
    let formattedDate: (Date?) -> String
    let formattedDateTime: (Date?, Bool) -> String

    var body: some View {
        Group {
            if let interaction {
                List {
                    Section("Summary") {
                        LabeledContent("Subject", value: interaction.subject)
                        LabeledContent("Type", value: interaction.type.rawValue)
                        LabeledContent("Status", value: interaction.status.rawValue)
                        LabeledContent("Occurred", value: formattedDateTime(interaction.occurredAt, true))
                        LabeledContent("Purchase", value: interaction.purchase?.name ?? "Not set")
                    }

                    Section("Party") {
                        LabeledContent("Party Contacted", value: interaction.partyContacted ?? "Not set")
                        LabeledContent("Contact Person", value: interaction.contactPerson ?? "Not set")
                        LabeledContent("Reference", value: interaction.referenceNumber ?? "Not set")
                    }

                    Section("Details") {
                        LabeledContent("Summary", value: interaction.summary ?? "Not set")
                        LabeledContent("Detailed Notes", value: interaction.detailedNotes ?? "Not set")
                        LabeledContent("Commitments", value: interaction.promisesOrCommitments ?? "Not set")
                        LabeledContent("Next Action", value: interaction.nextAction ?? "Not set")
                        LabeledContent("Follow-up Date", value: formattedDate(interaction.followUpDate))
                    }
                }
                .navigationTitle(interaction.subject)
            } else {
                ContentUnavailableView(
                    "No Interaction Selected",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Select an interaction to view details.")
                )
            }
        }
    }
}
