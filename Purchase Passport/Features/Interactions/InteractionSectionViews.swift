import SwiftUI
import SwiftData

struct InteractionListSectionView: View {
    let providers: [Organisation]
    let purchases: [Purchase]
    let interactions: [Interaction]
    let correspondences: [CorrespondenceRecord]
    @Binding var selectedInteractionID: PersistentIdentifier?
    let selectedInteraction: Interaction?
    let selectedCorrespondence: CorrespondenceRecord?
    let selectedPurchase: Purchase?
    let formattedDateTime: (Date?, Bool) -> String
    let formattedCorrespondenceSubtitle: (CorrespondenceRecord) -> String
    let onEditInteraction: () -> Void
    let onSelectCorrespondence: (CorrespondenceRecord) -> Void
    let onSetCorrespondenceStatus: (CorrespondenceRecord, CorrespondenceReviewStatus) -> Void
    let onApplyCorrespondenceExtraction: (CorrespondenceRecord) -> Void
    let onLinkCorrespondenceToPurchase: (CorrespondenceRecord, Purchase) -> Void
    let onOpenLinkedPurchase: (Purchase) -> Void
    let onOpenCorrespondenceInMail: (CorrespondenceRecord) -> Void
    let onDeleteSelectedCorrespondence: () -> Void

    @State private var selectedProviderFilterID: PersistentIdentifier?
    @State private var selectedPurchaseFilterID: PersistentIdentifier?
    @State private var correspondencePendingDeletion: CorrespondenceRecord?

    var body: some View {
        VStack(spacing: 0) {
            filterBar

            Group {
                if filteredInteractions.isEmpty && filteredCorrespondences.isEmpty {
                    ContentUnavailableView(
                        "No Interactions",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Change the provider or purchase filter, add an interaction, or import email.")
                    )
                } else {
                    List(selection: $selectedInteractionID) {
                        if !filteredCorrespondences.isEmpty || !emailInteractions.isEmpty {
                            Section("Emails") {
                                ForEach(sortedCorrespondences) { correspondence in
                                    HStack(alignment: .top, spacing: 8) {
                                        Button {
                                            onSelectCorrespondence(correspondence)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(correspondence.subject)
                                                    .font(.headline)
                                                Text(formattedCorrespondenceSubtitle(correspondence))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                Text(correspondence.purchase?.name ?? "All provider emails")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .buttonStyle(.plain)

                                        Spacer()

                                        if selectedCorrespondence?.persistentModelID == correspondence.persistentModelID {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                        }

                                        Menu("Email Actions") {
                                            if correspondence.purchase == nil,
                                               let selectedPurchaseFilter {
                                                Button("Link to Selected Purchase") {
                                                    onLinkCorrespondenceToPurchase(correspondence, selectedPurchaseFilter)
                                                }
                                            }
                                            if let linkedPurchase = correspondence.purchase {
                                                Button("Open Linked Purchase") {
                                                    onOpenLinkedPurchase(linkedPurchase)
                                                }
                                            }
                                            Button("Open in Mail") {
                                                onOpenCorrespondenceInMail(correspondence)
                                            }
                                            Divider()
                                            Button("Delete", role: .destructive) {
                                                correspondencePendingDeletion = correspondence
                                            }
                                        }
                                        .menuStyle(.button)
                                    }
                                    .padding(.vertical, 2)
                                }

                                ForEach(emailInteractions) { interaction in
                                    interactionRow(interaction)
                                }
                            }
                        }

                        if !filteredInteractions.isEmpty {
                            if !phoneCallInteractions.isEmpty {
                                Section("Phone Calls") {
                                    ForEach(phoneCallInteractions) { interaction in
                                        interactionRow(interaction)
                                    }
                                }
                            }

                            if !letterInteractions.isEmpty {
                                Section("Letters") {
                                    ForEach(letterInteractions) { interaction in
                                        interactionRow(interaction)
                                    }
                                }
                            }

                            if !onlineChatInteractions.isEmpty {
                                Section("Online Chat") {
                                    ForEach(onlineChatInteractions) { interaction in
                                        interactionRow(interaction)
                                    }
                                }
                            }

                            if !inPersonInteractions.isEmpty {
                                Section("In-Person") {
                                    ForEach(inPersonInteractions) { interaction in
                                        interactionRow(interaction)
                                    }
                                }
                            }

                            if !serviceAppointmentInteractions.isEmpty {
                                Section("Service Appointments") {
                                    ForEach(serviceAppointmentInteractions) { interaction in
                                        interactionRow(interaction)
                                    }
                                }
                            }

                            if !otherInteractions.isEmpty {
                                Section("Other Interactions") {
                                    ForEach(otherInteractions) { interaction in
                                        interactionRow(interaction)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Interactions")
        .onAppear(perform: syncFiltersFromSelectionIfNeeded)
        .onChange(of: selectedProviderFilterID) { _, _ in
            guard let selectedPurchaseFilter,
                  availablePurchasesForSelectedProvider.contains(where: { $0.persistentModelID == selectedPurchaseFilter.persistentModelID }) else {
                selectedPurchaseFilterID = nil
                return
            }
        }
        .confirmationDialog(
            "Delete imported email?",
            isPresented: Binding(
                get: { correspondencePendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        correspondencePendingDeletion = nil
                    }
                }
            ),
            presenting: correspondencePendingDeletion
        ) { correspondence in
            Button("Delete Email", role: .destructive) {
                onSelectCorrespondence(correspondence)
                onDeleteSelectedCorrespondence()
                correspondencePendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                correspondencePendingDeletion = nil
            }
        } message: { correspondence in
            Text("This will permanently remove \"\(correspondence.subject)\" and unlink it from any attached purchase.")
        }
        .toolbar {
            ToolbarItem {
                Button("Edit Interaction", action: onEditInteraction)
                    .disabled(selectedInteraction == nil)
            }
            ToolbarItem {
                Button("Delete Email", role: .destructive, action: onDeleteSelectedCorrespondence)
                    .disabled(selectedCorrespondence == nil)
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 12) {
            Picker("Provider", selection: $selectedProviderFilterID) {
                Text("All Providers").tag(Optional<PersistentIdentifier>.none)
                ForEach(providers) { provider in
                    Text(provider.name).tag(Optional(provider.persistentModelID))
                }
            }
            .pickerStyle(.menu)

            Picker("Purchase", selection: $selectedPurchaseFilterID) {
                Text("All").tag(Optional<PersistentIdentifier>.none)
                ForEach(availablePurchasesForSelectedProvider) { purchase in
                    Text(purchase.name).tag(Optional(purchase.persistentModelID))
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var selectedProviderFilter: Organisation? {
        guard let selectedProviderFilterID else { return nil }
        return providers.first { $0.persistentModelID == selectedProviderFilterID }
    }

    private var selectedPurchaseFilter: Purchase? {
        guard let selectedPurchaseFilterID else { return nil }
        return purchases.first { $0.persistentModelID == selectedPurchaseFilterID }
    }

    private var availablePurchasesForSelectedProvider: [Purchase] {
        let basePurchases: [Purchase]
        if let provider = selectedProviderFilter {
            basePurchases = purchases.filter { $0.provider?.persistentModelID == provider.persistentModelID }
        } else {
            basePurchases = purchases
        }

        return basePurchases.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var filteredCorrespondences: [CorrespondenceRecord] {
        correspondences.filter { correspondence in
            matchesSelectedProvider(correspondence) && matchesSelectedPurchase(correspondence)
        }
    }

    private var filteredInteractions: [Interaction] {
        interactions.filter { interaction in
            matchesSelectedProvider(interaction) && matchesSelectedPurchase(interaction)
        }
    }

    private var sortedCorrespondences: [CorrespondenceRecord] {
        filteredCorrespondences.sorted(by: { $0.occurredAt > $1.occurredAt })
    }

    private var sortedInteractions: [Interaction] {
        filteredInteractions.sorted(by: { $0.occurredAt > $1.occurredAt })
    }

    private var phoneCallInteractions: [Interaction] {
        sortedInteractions.filter { $0.type == .phoneCall }
    }

    private var emailInteractions: [Interaction] {
        sortedInteractions.filter { $0.type == .email }
    }

    private var letterInteractions: [Interaction] {
        sortedInteractions.filter { $0.type == .letter }
    }

    private var onlineChatInteractions: [Interaction] {
        sortedInteractions.filter { $0.type == .onlineChat }
    }

    private var inPersonInteractions: [Interaction] {
        sortedInteractions.filter { $0.type == .inPersonVisit }
    }

    private var serviceAppointmentInteractions: [Interaction] {
        sortedInteractions.filter { $0.type == .serviceAppointment }
    }

    private var otherInteractions: [Interaction] {
        sortedInteractions.filter {
            $0.type != .email &&
            $0.type != .phoneCall &&
            $0.type != .letter &&
            $0.type != .onlineChat &&
            $0.type != .inPersonVisit &&
            $0.type != .serviceAppointment
        }
    }

    @ViewBuilder
    private func interactionRow(_ interaction: Interaction) -> some View {
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

    private func syncFiltersFromSelectionIfNeeded() {
        if let selectedPurchase, selectedPurchaseFilterID == nil, selectedProviderFilterID == nil {
            selectedProviderFilterID = selectedPurchase.provider?.persistentModelID
            selectedPurchaseFilterID = selectedPurchase.persistentModelID
            return
        }

        if let selectedPurchaseFilter,
           !availablePurchasesForSelectedProvider.contains(where: { $0.persistentModelID == selectedPurchaseFilter.persistentModelID }) {
            selectedPurchaseFilterID = nil
        }
    }

    private func matchesSelectedProvider(_ correspondence: CorrespondenceRecord) -> Bool {
        guard let provider = selectedProviderFilter else { return true }
        if correspondence.purchase?.provider?.persistentModelID == provider.persistentModelID {
            return true
        }
        return !ProviderCorrespondenceService
            .linkedCorrespondences(for: provider, correspondences: [correspondence])
            .isEmpty
    }

    private func matchesSelectedPurchase(_ correspondence: CorrespondenceRecord) -> Bool {
        guard let purchase = selectedPurchaseFilter else { return true }
        return correspondence.purchase?.persistentModelID == purchase.persistentModelID
    }

    private func matchesSelectedProvider(_ interaction: Interaction) -> Bool {
        guard let provider = selectedProviderFilter else { return true }
        return interaction.purchase?.provider?.persistentModelID == provider.persistentModelID
    }

    private func matchesSelectedPurchase(_ interaction: Interaction) -> Bool {
        guard let purchase = selectedPurchaseFilter else { return true }
        return interaction.purchase?.persistentModelID == purchase.persistentModelID
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
                        LabeledContent("Source", value: "Manual Interaction")
                    }

                    Section("Party") {
                        LabeledContent("Party Contacted", value: interaction.partyContacted ?? "Not set")
                        LabeledContent("Contact Person", value: interaction.contactPerson ?? "Not set")
                        LabeledContent("Phone Number", value: interaction.contactPhoneNumber ?? "Not set")
                        LabeledContent("Reference", value: interaction.referenceNumber ?? "Not set")
                    }

                    Section("Details") {
                        LabeledContent("Summary", value: interaction.summary ?? "Not set")
                        LabeledContent("Detailed Notes", value: interaction.detailedNotes ?? "Not set")
                        LabeledContent("Commitments", value: interaction.promisesOrCommitments ?? "Not set")
                        LabeledContent("Duration", value: interaction.durationMinutes.map { "\($0) min" } ?? "Not set")
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
