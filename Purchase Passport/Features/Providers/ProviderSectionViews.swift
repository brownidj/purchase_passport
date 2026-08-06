import AppKit
import SwiftData
import SwiftUI

private struct ProviderContactDraft: Identifiable {
    let id: UUID
    let existingContactID: PersistentIdentifier?
    var name: String
    var role: String
    var emailAddress: String
    var phoneNumber: String
    var accountNumber: String
    var notes: String

    init(contact: Contact) {
        id = UUID()
        existingContactID = contact.persistentModelID
        name = contact.name
        role = contact.role ?? ""
        emailAddress = contact.emailAddress ?? ""
        phoneNumber = contact.phoneNumber ?? ""
        accountNumber = contact.accountNumber ?? ""
        notes = contact.notes ?? ""
    }

    init() {
        id = UUID()
        existingContactID = nil
        name = ""
        role = ""
        emailAddress = ""
        phoneNumber = ""
        accountNumber = ""
        notes = ""
    }
}

enum ProviderEditorPresentation: Identifiable {
    case new
    case edit(Organisation)

    var id: String {
        switch self {
        case .new:
            return "provider-new"
        case .edit(let organisation):
            return "provider-edit-\(organisation.persistentModelID)"
        }
    }
}

struct ProviderListSectionView: View {
    let providers: [Organisation]
    let selectedProvider: Organisation?
    @Binding var selectedProviderID: PersistentIdentifier?
    let linkedPurchaseCount: (Organisation) -> Int
    let onNewProvider: () -> Void
    let onEditProvider: () -> Void
    let onDeleteProvider: () -> Void

    var body: some View {
        Group {
            if providers.isEmpty {
                ContentUnavailableView(
                    "No Providers",
                    systemImage: "building.2",
                    description: Text("Create providers to manage supplier details and contacts.")
                )
            } else {
                List(providers, selection: $selectedProviderID) { provider in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(provider.name)
                            .font(.headline)
                        Text("\(provider.contacts.count) contact(s) • \(linkedPurchaseCount(provider)) linked purchase(s)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .tag(provider.persistentModelID)
                }
            }
        }
        .navigationTitle("Providers")
        .toolbar {
            ToolbarItemGroup {
                Button("New Provider", action: onNewProvider)
                Button("Edit Provider", action: onEditProvider)
                    .disabled(selectedProvider == nil)
                Button("Delete Provider", role: .destructive, action: onDeleteProvider)
                    .disabled(selectedProvider == nil)
            }
        }
    }
}

struct ProviderDetailSectionView: View {
    let provider: Organisation?
    let linkedPurchases: [Purchase]
    let linkedCorrespondences: [CorrespondenceRecord]
    let linkedPurchaseCount: Int
    let onOpenPurchase: (Purchase) -> Void
    let onOpenCorrespondenceInMail: (CorrespondenceRecord) -> Void
    let onOpenEmailImport: () -> Void
    let onComposeEmail: (Purchase?) -> Void
    let onReplyToCorrespondence: (CorrespondenceRecord) -> Void
    let onLogPhoneCall: (Purchase, InteractionDraft) -> Void

    @State private var isShowingPhoneCallSheet = false
    @State private var isLinkedPurchasesExpanded = true
    @State private var isPhoneCallsExpanded = false
    @State private var isCalendarExpanded = false
    @State private var isLinkedEmailsExpanded = false
    @State private var isContactDetailsExpanded = false
    @State private var isAddressesExpanded = false
    @State private var isNotesExpanded = false
    @State private var isAssociatedContactsExpanded = false

    var body: some View {
        Group {
            if let provider {
                List {
                    Section("Summary") {
                        LabeledContent("Business Name", value: provider.name)
                    }

                    collapsibleSection("Linked Purchases", isExpanded: $isLinkedPurchasesExpanded) {
                        LabeledContent("Linked Purchases", value: "\(linkedPurchaseCount)")

                        if linkedPurchases.isEmpty {
                            Text("No linked purchases")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(linkedPurchases, id: \.persistentModelID) { purchase in
                                Button {
                                    onOpenPurchase(purchase)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(purchase.name)
                                        Text(purchase.status.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    collapsibleSection("Phone Calls", isExpanded: $isPhoneCallsExpanded) {
                        Button("Log Phone Call") {
                            isShowingPhoneCallSheet = true
                        }
                        .disabled(!canLogPhoneCall(for: provider))

                        if linkedPurchases.isEmpty {
                            Text("Link at least one purchase to this provider before logging provider calls.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if availablePhoneCallTargets(for: provider).isEmpty {
                            Text("Add a company or contact phone number before logging provider calls.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("The call will be saved as an interaction against the selected linked purchase.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    collapsibleSection("Calendar", isExpanded: $isCalendarExpanded) {
                        ProviderCalendarSectionView(
                            provider: provider,
                            linkedPurchases: linkedPurchases
                        )
                    }

                    collapsibleSection("Linked Emails", isExpanded: $isLinkedEmailsExpanded) {
                        Button("Compose Email") {
                            onComposeEmail(linkedPurchases.first)
                        }
                        .disabled(!canComposeEmail(for: provider))

                        Button("Open Email Import Window") {
                            onOpenEmailImport()
                        }

                        Text("Open the import window, then drag exported `.eml` or `.emlx` email files onto it for this provider.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if !canComposeEmail(for: provider) {
                            Text("Add a linked purchase and at least one provider or contact email address before composing email from Purchase Passport.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Open a draft in Mail from here. Purchase Passport will log the outgoing email as an interaction when the draft is launched.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if linkedCorrespondences.isEmpty {
                            Text("No linked emails")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(linkedCorrespondences) { correspondence in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(correspondence.subject)
                                        Text(correspondence.occurredAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button("Reply") {
                                        onReplyToCorrespondence(correspondence)
                                    }
                                    .disabled(!canComposeEmail(for: provider))
                                    if correspondence.externalMessageID != nil {
                                        Button("Open in Mail") {
                                            onOpenCorrespondenceInMail(correspondence)
                                        }
                                    } else {
                                        Text("No Mail link")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    collapsibleSection("Contact Details", isExpanded: $isContactDetailsExpanded) {
                        LabeledContent("Email", value: provider.emailAddress ?? "Not set")
                        LabeledContent("Phone", value: provider.phoneNumber ?? "Not set")
                        LabeledContent("Website", value: provider.website ?? "Not set")
                        LabeledContent("Customer Service", value: provider.customerServiceNumber ?? "Not set")
                    }

                    collapsibleSection("Addresses", isExpanded: $isAddressesExpanded) {
                        LabeledContent("Postal", value: provider.postalAddress ?? "Not set")
                        LabeledContent("Physical", value: provider.physicalAddress ?? "Not set")
                    }

                    collapsibleSection("Notes", isExpanded: $isNotesExpanded) {
                        Text(provider.notes ?? "Not set")
                            .foregroundStyle(provider.notes == nil ? .secondary : .primary)
                    }

                    collapsibleSection("Associated Contacts", isExpanded: $isAssociatedContactsExpanded) {
                        if provider.contacts.isEmpty {
                            Text("No contacts on record")
                                .foregroundStyle(.secondary)
                        } else {
                            let contacts = provider.contacts
                                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                            ForEach(contacts) { contact in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                    Text(contactSummary(contact))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(provider.name)
                .sheet(isPresented: $isShowingPhoneCallSheet) {
                    ProviderPhoneCallDraftSheet(
                        provider: provider,
                        linkedPurchases: linkedPurchases,
                        onLogPhoneCall: onLogPhoneCall
                    )
                    .presentationDetents([.medium])
                }
            } else {
                ContentUnavailableView(
                    "No Provider Selected",
                    systemImage: "building.2",
                    description: Text("Select a provider to view details.")
                )
            }
        }
    }

    private func contactSummary(_ contact: Contact) -> String {
        let values = [
            contact.role?.trimmedNilIfEmpty,
            contact.emailAddress?.trimmedNilIfEmpty,
            contact.phoneNumber?.trimmedNilIfEmpty
        ].compactMap { $0 }

        return values.isEmpty ? "No details" : values.joined(separator: " • ")
    }

    private func canLogPhoneCall(for provider: Organisation) -> Bool {
        !linkedPurchases.isEmpty && !availablePhoneCallTargets(for: provider).isEmpty
    }

    private func canComposeEmail(for provider: Organisation) -> Bool {
        !linkedPurchases.isEmpty && !ProviderEmailRecipientTarget.targets(for: provider).isEmpty
    }

    private func availablePhoneCallTargets(for provider: Organisation) -> [ProviderPhoneCallTarget] {
        ProviderPhoneCallTarget.targets(for: provider)
    }

    private func collapsibleSection<Content: View>(
        _ title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Section {
            DisclosureGroup(isExpanded: isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
                .padding(.top, 8)
            } label: {
                Text(title)
                    .font(.headline)
            }
        }
    }
}

private struct ProviderCalendarSectionView: View {
    let provider: Organisation
    let linkedPurchases: [Purchase]

    @State private var authorizationState = ProviderCalendarAuthorizationState.notDetermined
    @State private var events: [ProviderCalendarEvent] = []
    @State private var debugEvents: [ProviderCalendarDebugEvent] = []
    @State private var isShowingDebugEvents = false
    @State private var isLoading = false
    @State private var statusMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            actionRow

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content
        }
        .task(id: provider.persistentModelID) {
            await refreshCalendarEvents(promptIfNeeded: false)
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        HStack {
            switch authorizationState {
            case .notDetermined:
                Button("Allow Calendar Access") {
                    Task {
                        await requestCalendarAccess()
                    }
                }
            case .denied, .restricted, .writeOnly, .fullAccess:
                Button("Refresh Calendar Events") {
                    Task {
                        await refreshCalendarEvents(promptIfNeeded: false)
                    }
                }
            }

            Button("Open Calendar") {
                openCalendarApp()
            }

            if authorizationState.canReadEvents {
                Button(isShowingDebugEvents ? "Hide Debug Fields" : "Show Debug Fields") {
                    isShowingDebugEvents.toggle()
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch authorizationState {
        case .notDetermined:
            Text("Grant Calendar access to let Purchase Passport look for events that mention this provider, its contacts, or linked purchases.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .denied:
            Text("Calendar access is denied. Allow access in System Settings, then refresh.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .restricted:
            Text("Calendar access is restricted on this Mac.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .writeOnly:
            Text("Calendar access is write-only. Purchase Passport needs full access to read existing events.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .fullAccess:
            if isLoading {
                ProgressView("Checking Calendar…")
                    .controlSize(.small)
            } else if events.isEmpty {
                Text("No related calendar events were found for the \(ProviderCalendarService.searchWindowDescription).")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isShowingDebugEvents {
                    debugEventContent
                }
            } else {
                ForEach(events) { event in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            Text(event.title)
                                .font(.headline)
                            Spacer()
                            Text(formattedDateRange(for: event))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }

                        Text("\(event.calendarTitle) • matched by \(event.matchReason)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let location = event.location {
                            Text("Location: \(location)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let notesExcerpt = event.notesExcerpt {
                            Text(notesExcerpt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if isShowingDebugEvents {
                    Divider()
                    debugEventContent
                }
            }
        }
    }

    @ViewBuilder
    private var debugEventContent: some View {
        if debugEvents.isEmpty {
            Text("No candidate EventKit items exposed nearby for this provider.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("Debug candidates")
                .font(.headline)

            ForEach(debugEvents.prefix(20)) { event in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(event.title)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(event.didMatch ? "Matched" : "Candidate only")
                            .font(.caption)
                            .foregroundStyle(event.didMatch ? .green : .secondary)
                    }

                    Text("\(event.calendarTitle) • \(event.startDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !event.matchedReasons.isEmpty {
                        Text("Reasons: \(event.matchedReasons.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Matched token count: \(event.matchedTokenCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !event.overlappingTokens.isEmpty {
                        Text("Tokens: \(event.overlappingTokens.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    debugField("Title", value: event.titleField)
                    debugField("Location", value: event.locationField)
                    debugField("Organizer", value: event.organizerField)
                    if !event.attendeeFields.isEmpty {
                        debugField("Attendees", value: event.attendeeFields.joined(separator: " | "))
                    }
                    debugField("URL", value: event.urlField)
                    debugField("Notes", value: event.notesField)
                }
                .padding(.vertical, 6)
            }
        }
    }

    @ViewBuilder
    private func debugField(_ label: String, value: String?) -> some View {
        if let value, !value.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func formattedDateRange(for event: ProviderCalendarEvent) -> String {
        formattedDateRange(startDate: event.startDate, endDate: event.endDate, isAllDay: event.isAllDay)
    }

    private func formattedDateRange(startDate: Date, endDate: Date, isAllDay: Bool) -> String {
        if isAllDay {
            return startDate.formatted(date: .abbreviated, time: .omitted)
        }

        let start = startDate.formatted(date: .abbreviated, time: .shortened)
        let end = endDate.formatted(date: .abbreviated, time: .shortened)
        return "\(start)\n\(end)"
    }

    private func requestCalendarAccess() async {
        do {
            let granted = try await ProviderCalendarService.shared.requestFullAccess()
            authorizationState = ProviderCalendarService.currentAuthorizationState()
            if granted {
                await refreshCalendarEvents(promptIfNeeded: false)
            } else {
                events = []
                statusMessage = "Calendar access was not granted."
            }
        } catch {
            authorizationState = ProviderCalendarService.currentAuthorizationState()
            events = []
            statusMessage = error.localizedDescription
        }
    }

    private func refreshCalendarEvents(promptIfNeeded: Bool) async {
        let currentState = ProviderCalendarService.currentAuthorizationState()
        authorizationState = currentState

        guard currentState.canReadEvents else {
            events = []
            debugEvents = []
            if promptIfNeeded, currentState == .notDetermined {
                await requestCalendarAccess()
            } else {
                statusMessage = nil
            }
            isLoading = false
            return
        }

        isLoading = true
        statusMessage = nil
        events = ProviderCalendarService.shared.relatedEvents(
            for: provider,
            linkedPurchases: linkedPurchases
        )
        debugEvents = ProviderCalendarService.shared.debugEvents(
            for: provider,
            linkedPurchases: linkedPurchases
        )
        isLoading = false
    }

    private func openCalendarApp() {
        let opened = ProviderCalendarService.shared.openCalendarApp()
        if !opened {
            statusMessage = "Calendar could not be opened on this Mac."
        }
    }
}

private struct ProviderPhoneCallDraftSheet: View {
    @Environment(\.dismiss) private var dismiss

    let provider: Organisation
    let linkedPurchases: [Purchase]
    let onLogPhoneCall: (Purchase, InteractionDraft) -> Void

    @State private var selectedPurchaseID: PersistentIdentifier?
    @State private var selectedPhoneTargetID: String = ""
    @State private var selectedContextItemID: String = ProviderRelatedContextSelection.noneID
    @State private var validationMessage: String?

    init(
        provider: Organisation,
        linkedPurchases: [Purchase],
        onLogPhoneCall: @escaping (Purchase, InteractionDraft) -> Void
    ) {
        self.provider = provider
        self.linkedPurchases = linkedPurchases
        self.onLogPhoneCall = onLogPhoneCall

        let sortedPurchases = linkedPurchases.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        let phoneTargets = ProviderPhoneCallTarget.targets(for: provider)
        _selectedPurchaseID = State(initialValue: sortedPurchases.first?.persistentModelID)
        _selectedPhoneTargetID = State(initialValue: phoneTargets.first?.id ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }

                Section("Purchase") {
                    Picker("Linked Purchase", selection: $selectedPurchaseID) {
                        ForEach(sortedPurchases, id: \.persistentModelID) { purchase in
                            Text(purchase.name).tag(Optional(purchase.persistentModelID))
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Phone Number") {
                    Picker("Call Number", selection: $selectedPhoneTargetID) {
                        ForEach(phoneTargets) { target in
                            Text(target.pickerTitle).tag(target.id)
                        }
                    }
                    .pickerStyle(.menu)

                    if let selectedPhoneTarget {
                        LabeledContent("Number", value: selectedPhoneTarget.phoneNumber)
                        LabeledContent("Contact", value: selectedPhoneTarget.contactName ?? "Company")
                    }
                }

                Section("Related Context") {
                    Picker("Prior Email or Interaction", selection: $selectedContextItemID) {
                        Text("None").tag(ProviderRelatedContextSelection.noneID)
                        ForEach(availableContextItems) { item in
                            Text(item.pickerTitle).tag(item.id)
                        }
                    }
                    .pickerStyle(.menu)

                    if let selectedContextItem {
                        LabeledContent("Type", value: selectedContextItem.typeLabel)
                        LabeledContent(
                            "Occurred",
                            value: selectedContextItem.occurredAt.formatted(date: .abbreviated, time: .shortened)
                        )
                        LabeledContent("Subject", value: selectedContextItem.subject)
                        if let secondary = selectedContextItem.secondaryLabel {
                            LabeledContent("Party", value: secondary)
                        }
                        if let correspondence = selectedContextItem.correspondence,
                           correspondence.externalMessageID != nil {
                            Button("Open in Mail") {
                                openCorrespondenceInMail(correspondence)
                            }
                        }
                        if let details = selectedContextItem.details {
                            Text(details)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                    } else {
                        Text("Select an earlier email or interaction if this call is a follow-up.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)

                        Spacer()

                        Button("Continue") {
                            continueToInteractionEditor()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Log Provider Call")
            .onChange(of: selectedPurchaseID) { _, _ in
                guard availableContextItems.contains(where: { $0.id == selectedContextItemID }) else {
                    selectedContextItemID = ProviderRelatedContextSelection.noneID
                    return
                }
            }
        }
    }

    private var sortedPurchases: [Purchase] {
        linkedPurchases.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var phoneTargets: [ProviderPhoneCallTarget] {
        ProviderPhoneCallTarget.targets(for: provider)
    }

    private var selectedPurchase: Purchase? {
        guard let selectedPurchaseID else { return nil }
        return sortedPurchases.first { $0.persistentModelID == selectedPurchaseID }
    }

    private var selectedPhoneTarget: ProviderPhoneCallTarget? {
        phoneTargets.first { $0.id == selectedPhoneTargetID }
    }

    private var availableContextItems: [ProviderRelatedContextItem] {
        guard let selectedPurchase else { return [] }

        let correspondenceItems = selectedPurchase.correspondences.map(ProviderRelatedContextItem.correspondence)
        let interactionItems = selectedPurchase.interactions
            .filter { $0.type != .email }
            .filter { $0.relatedInteraction == nil || $0.relatedInteraction?.persistentModelID != $0.persistentModelID }
            .map(ProviderRelatedContextItem.interaction)

        return (correspondenceItems + interactionItems)
            .sorted { $0.occurredAt > $1.occurredAt }
    }

    private var selectedContextItem: ProviderRelatedContextItem? {
        availableContextItems.first { $0.id == selectedContextItemID }
    }

    private func continueToInteractionEditor() {
        guard let selectedPurchase else {
            validationMessage = "Select a linked purchase before logging the call."
            return
        }
        guard let selectedPhoneTarget else {
            validationMessage = "Select a phone number before logging the call."
            return
        }

        validationMessage = nil
        let draft = InteractionDraft(
            occurredAt: .now,
            type: .phoneCall,
            status: .open,
            partyContacted: provider.name,
            contactPerson: selectedPhoneTarget.contactName ?? "",
            contactPhoneNumber: selectedPhoneTarget.phoneNumber,
            subject: "Phone call to \(provider.name)",
            summary: "Dialed \(selectedPhoneTarget.phoneNumber)",
            autoDurationStartDate: nil,
            relatedInteraction: selectedContextItem?.interaction,
            relatedCorrespondence: selectedContextItem?.correspondence
        )
        onLogPhoneCall(selectedPurchase, draft)
        dismiss()
    }

    private func openCorrespondenceInMail(_ correspondence: CorrespondenceRecord) {
        guard let url = ProviderCorrespondenceService.mailMessageURL(for: correspondence.externalMessageID) else {
            validationMessage = "This email does not have a Mail link."
            return
        }
        validationMessage = nil
        if !NSWorkspace.shared.open(url) {
            validationMessage = "The email could not be opened in Mail."
        }
    }
}

struct ProviderEmailComposerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let provider: Organisation
    let linkedPurchases: [Purchase]
    let initialPurchase: Purchase?
    let initialCorrespondence: CorrespondenceRecord?
    let onCommit: (Interaction) -> Void

    @State private var selectedPurchaseID: PersistentIdentifier?
    @State private var selectedRecipientTargetID: String = ""
    @State private var selectedContextItemID: String = ProviderRelatedContextSelection.noneID
    @State private var subject: String
    @State private var bodyText: String
    @State private var validationMessage: String?

    init(
        provider: Organisation,
        linkedPurchases: [Purchase],
        initialPurchase: Purchase? = nil,
        initialCorrespondence: CorrespondenceRecord? = nil,
        onCommit: @escaping (Interaction) -> Void
    ) {
        self.provider = provider
        self.linkedPurchases = linkedPurchases
        self.initialPurchase = initialPurchase
        self.initialCorrespondence = initialCorrespondence
        self.onCommit = onCommit

        let sortedPurchases = linkedPurchases.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        let recipients = ProviderEmailRecipientTarget.targets(for: provider)

        let resolvedPurchaseID = initialPurchase?.persistentModelID
            ?? initialCorrespondence?.purchase?.persistentModelID
            ?? sortedPurchases.first?.persistentModelID
        let relatedContextID = initialCorrespondence.map {
            "correspondence-\($0.persistentModelID)"
        } ?? ProviderRelatedContextSelection.noneID
        let preferredRecipient = initialCorrespondence.flatMap {
            ProviderEmailCompositionService.replyRecipient(for: $0, provider: provider)
        }
        let resolvedRecipientID = recipients.first(where: { $0.emailAddress == preferredRecipient })?.id
            ?? recipients.first?.id
            ?? ""
        let purchaseName = sortedPurchases.first(where: { $0.persistentModelID == resolvedPurchaseID })?.name
        let recipientName = recipients.first(where: { $0.id == resolvedRecipientID })?.displayName
            ?? provider.name

        _selectedPurchaseID = State(initialValue: resolvedPurchaseID)
        _selectedRecipientTargetID = State(initialValue: resolvedRecipientID)
        _selectedContextItemID = State(initialValue: relatedContextID)
        _subject = State(
            initialValue: ProviderEmailComposerSheet.defaultSubject(
                initialCorrespondence: initialCorrespondence,
                purchaseName: purchaseName
            )
        )
        _bodyText = State(
            initialValue: ProviderEmailComposerSheet.defaultBody(
                recipientName: recipientName,
                purchaseName: purchaseName,
                contextItem: initialCorrespondence.map(ProviderRelatedContextItem.correspondence)
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }

                Section("Purchase") {
                    Picker("Linked Purchase", selection: $selectedPurchaseID) {
                        ForEach(sortedPurchases, id: \.persistentModelID) { purchase in
                            Text(purchase.name).tag(Optional(purchase.persistentModelID))
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Recipient") {
                    Picker("Send To", selection: $selectedRecipientTargetID) {
                        ForEach(recipientTargets) { target in
                            Text(target.pickerTitle).tag(target.id)
                        }
                    }
                    .pickerStyle(.menu)

                    if let selectedRecipientTarget {
                        LabeledContent("Email", value: selectedRecipientTarget.emailAddress)
                        LabeledContent("Contact", value: selectedRecipientTarget.contactName ?? "Company")
                    }
                }

                Section("Compose") {
                    TextField("Subject", text: $subject)
                    Button("Use Template") {
                        applyTemplate()
                    }
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 220)
                        .font(.body)
                }

                Section("Related Context") {
                    Picker("Prior Email or Interaction", selection: $selectedContextItemID) {
                        Text("None").tag(ProviderRelatedContextSelection.noneID)
                        ForEach(availableContextItems) { item in
                            Text(item.pickerTitle).tag(item.id)
                        }
                    }
                    .pickerStyle(.menu)

                    if let selectedContextItem {
                        LabeledContent("Type", value: selectedContextItem.typeLabel)
                        LabeledContent(
                            "Occurred",
                            value: selectedContextItem.occurredAt.formatted(date: .abbreviated, time: .shortened)
                        )
                        LabeledContent("Subject", value: selectedContextItem.subject)
                        if let secondary = selectedContextItem.secondaryLabel {
                            LabeledContent("Party", value: secondary)
                        }
                        if let correspondence = selectedContextItem.correspondence,
                           correspondence.externalMessageID != nil {
                            Button("Open in Mail") {
                                openCorrespondenceInMail(correspondence)
                            }
                        }
                        if let details = selectedContextItem.details {
                            Text(details)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                    } else {
                        Text("Select an earlier email or interaction if this draft is a reply or follow-up.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("Opening the draft in Mail logs the outgoing email as an interaction immediately.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)

                        Spacer()

                        Button("Open Draft in Mail") {
                            openDraftInMail()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Compose Provider Email")
            .onChange(of: selectedPurchaseID) { _, _ in
                guard availableContextItems.contains(where: { $0.id == selectedContextItemID }) else {
                    selectedContextItemID = ProviderRelatedContextSelection.noneID
                    return
                }
            }
        }
    }

    private var sortedPurchases: [Purchase] {
        linkedPurchases.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var recipientTargets: [ProviderEmailRecipientTarget] {
        ProviderEmailRecipientTarget.targets(for: provider)
    }

    private var selectedPurchase: Purchase? {
        guard let selectedPurchaseID else { return nil }
        return sortedPurchases.first { $0.persistentModelID == selectedPurchaseID }
    }

    private var selectedRecipientTarget: ProviderEmailRecipientTarget? {
        recipientTargets.first { $0.id == selectedRecipientTargetID }
    }

    private var availableContextItems: [ProviderRelatedContextItem] {
        guard let selectedPurchase else { return [] }

        let correspondenceItems = selectedPurchase.correspondences.map(ProviderRelatedContextItem.correspondence)
        let interactionItems = selectedPurchase.interactions
            .filter { $0.relatedInteraction == nil || $0.relatedInteraction?.persistentModelID != $0.persistentModelID }
            .map(ProviderRelatedContextItem.interaction)

        return (correspondenceItems + interactionItems)
            .sorted { $0.occurredAt > $1.occurredAt }
    }

    private var selectedContextItem: ProviderRelatedContextItem? {
        availableContextItems.first { $0.id == selectedContextItemID }
    }

    private func applyTemplate() {
        subject = Self.defaultSubject(
            initialCorrespondence: selectedContextItem?.correspondence,
            purchaseName: selectedPurchase?.name
        )
        bodyText = Self.defaultBody(
            recipientName: selectedRecipientTarget?.displayName ?? provider.name,
            purchaseName: selectedPurchase?.name,
            contextItem: selectedContextItem
        )
    }

    private func openDraftInMail() {
        guard let selectedPurchase else {
            validationMessage = "Select a linked purchase before composing email."
            return
        }
        guard let selectedRecipientTarget else {
            validationMessage = "Select an email recipient before composing."
            return
        }

        let normalizedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSubject.isEmpty else {
            validationMessage = "Email subject is required."
            return
        }

        let normalizedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = ProviderEmailCompositionService.composeMailURL(
            to: selectedRecipientTarget.emailAddress,
            subject: normalizedSubject,
            body: bodyText
        ) else {
            validationMessage = "The email draft could not be prepared."
            return
        }

        validationMessage = nil
        guard NSWorkspace.shared.open(url) else {
            validationMessage = "Mail could not open a draft for this email."
            return
        }

        let interaction = Interaction(
            occurredAt: .now,
            type: .email,
            status: .pending,
            partyContacted: provider.name,
            contactPerson: selectedRecipientTarget.contactName?.trimmedNilIfEmpty,
            subject: normalizedSubject,
            summary: "Draft opened in Mail to \(selectedRecipientTarget.emailAddress)",
            detailedNotes: normalizedBody.isEmpty ? nil : normalizedBody,
            updatedAt: .now,
            purchase: selectedPurchase,
            relatedInteraction: selectedContextItem?.interaction,
            relatedCorrespondence: selectedContextItem?.correspondence
        )

        modelContext.insert(interaction)
        selectedPurchase.interactions.append(interaction)
        selectedPurchase.updatedAt = .now
        onCommit(interaction)
        dismiss()
    }

    private func openCorrespondenceInMail(_ correspondence: CorrespondenceRecord) {
        guard let url = ProviderCorrespondenceService.mailMessageURL(for: correspondence.externalMessageID) else {
            validationMessage = "This email does not have a Mail link."
            return
        }
        validationMessage = nil
        if !NSWorkspace.shared.open(url) {
            validationMessage = "The email could not be opened in Mail."
        }
    }

    private static func defaultSubject(
        initialCorrespondence: CorrespondenceRecord?,
        purchaseName: String?
    ) -> String {
        if let initialCorrespondence {
            return ProviderEmailCompositionService.replySubject(for: initialCorrespondence.subject)
        }
        if let purchaseName, !purchaseName.isEmpty {
            return "Regarding \(purchaseName)"
        }
        return "Email to Provider"
    }

    private static func defaultBody(
        recipientName: String,
        purchaseName: String?,
        contextItem: ProviderRelatedContextItem?
    ) -> String {
        let greeting = "Hi \(recipientName),"

        if let correspondence = contextItem?.correspondence {
            let occurred = correspondence.occurredAt.formatted(date: .abbreviated, time: .omitted)
            return """
            \(greeting)

            Regarding your email of \(occurred) about "\(correspondence.subject)":



            Kind regards,
            """
        }

        if let interaction = contextItem?.interaction {
            return """
            \(greeting)

            Following up regarding \(interaction.subject):



            Kind regards,
            """
        }

        if let purchaseName, !purchaseName.isEmpty {
            return """
            \(greeting)

            Regarding \(purchaseName):



            Kind regards,
            """
        }

        return """
        \(greeting)



        Kind regards,
        """
    }
}

private struct ProviderEmailRecipientTarget: Identifiable {
    let id: String
    let label: String
    let emailAddress: String
    let contactName: String?

    var pickerTitle: String {
        "\(label) • \(emailAddress)"
    }

    var displayName: String {
        contactName ?? label
    }

    static func targets(for provider: Organisation) -> [ProviderEmailRecipientTarget] {
        var targets: [ProviderEmailRecipientTarget] = []

        if let emailAddress = provider.emailAddress?.trimmedNilIfEmpty {
            targets.append(
                ProviderEmailRecipientTarget(
                    id: "company-\(emailAddress)",
                    label: "Company",
                    emailAddress: emailAddress,
                    contactName: nil
                )
            )
        }

        let contacts = provider.contacts
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        for contact in contacts {
            guard let emailAddress = contact.emailAddress?.trimmedNilIfEmpty else { continue }
            targets.append(
                ProviderEmailRecipientTarget(
                    id: "contact-\(contact.persistentModelID)-\(emailAddress)",
                    label: contact.name,
                    emailAddress: emailAddress,
                    contactName: contact.name
                )
            )
        }

        return targets
    }
}

private struct ProviderPhoneCallTarget: Identifiable {
    let id: String
    let label: String
    let phoneNumber: String
    let contactName: String?

    var pickerTitle: String {
        "\(label) • \(phoneNumber)"
    }

    static func targets(for provider: Organisation) -> [ProviderPhoneCallTarget] {
        var targets: [ProviderPhoneCallTarget] = []

        if let phoneNumber = provider.phoneNumber?.trimmedNilIfEmpty {
            targets.append(
                ProviderPhoneCallTarget(
                    id: "company-\(phoneNumber)",
                    label: "Company",
                    phoneNumber: phoneNumber,
                    contactName: nil
                )
            )
        }

        if let customerServiceNumber = provider.customerServiceNumber?.trimmedNilIfEmpty {
            targets.append(
                ProviderPhoneCallTarget(
                    id: "customer-service-\(customerServiceNumber)",
                    label: "Customer Service",
                    phoneNumber: customerServiceNumber,
                    contactName: "Customer Service"
                )
            )
        }

        let contacts = provider.contacts
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        for contact in contacts {
            guard let phoneNumber = contact.phoneNumber?.trimmedNilIfEmpty else { continue }
            targets.append(
                ProviderPhoneCallTarget(
                    id: "contact-\(contact.persistentModelID)-\(phoneNumber)",
                    label: contact.name,
                    phoneNumber: phoneNumber,
                    contactName: contact.name
                )
            )
        }

        return targets
    }
}

private enum ProviderRelatedContextSelection {
    static let noneID = "none"
}

private enum ProviderRelatedContextItem: Identifiable {
    case correspondence(CorrespondenceRecord)
    case interaction(Interaction)

    var id: String {
        switch self {
        case .correspondence(let correspondence):
            return "correspondence-\(correspondence.persistentModelID)"
        case .interaction(let interaction):
            return "interaction-\(interaction.persistentModelID)"
        }
    }

    var occurredAt: Date {
        switch self {
        case .correspondence(let correspondence):
            return correspondence.occurredAt
        case .interaction(let interaction):
            return interaction.occurredAt
        }
    }

    var subject: String {
        switch self {
        case .correspondence(let correspondence):
            return correspondence.subject
        case .interaction(let interaction):
            return interaction.subject
        }
    }

    var typeLabel: String {
        switch self {
        case .correspondence:
            return "Email"
        case .interaction(let interaction):
            return interaction.type.rawValue
        }
    }

    var secondaryLabel: String? {
        switch self {
        case .correspondence(let correspondence):
            return correspondence.sender?.trimmedNilIfEmpty
        case .interaction(let interaction):
            return interaction.partyContacted?.trimmedNilIfEmpty
        }
    }

    var details: String? {
        switch self {
        case .correspondence(let correspondence):
            return emailDetailsExcerpt(for: correspondence)
        case .interaction(let interaction):
            return boundedExcerpt(
                interaction.detailedNotes?.trimmedNilIfEmpty
                    ?? interaction.summary?.trimmedNilIfEmpty,
                limit: 1200
            )
        }
    }

    var pickerTitle: String {
        "\(typeLabel) • \(subject)"
    }

    var interaction: Interaction? {
        guard case .interaction(let interaction) = self else { return nil }
        return interaction
    }

    var correspondence: CorrespondenceRecord? {
        guard case .correspondence(let correspondence) = self else { return nil }
        return correspondence
    }

    private func emailDetailsExcerpt(for correspondence: CorrespondenceRecord) -> String? {
        let preferred = correspondence.fullBody?.trimmedNilIfEmpty
            ?? correspondence.bodyPreview?.trimmedNilIfEmpty
        return boundedExcerpt(preferred, limit: 1600)
    }

    private func boundedExcerpt(_ value: String?, limit: Int) -> String? {
        guard let value else { return nil }
        let normalized = value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let prefix = String(normalized.prefix(limit))
        if normalized.count > limit {
            return prefix + "\n\n[Open in Mail to read the rest]"
        }
        return prefix
    }
}

@MainActor
struct ProviderEditorView: View {
    enum Mode {
        case create
        case edit(Organisation)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Organisation.name) private var organisations: [Organisation]

    private let mode: Mode
    private let onCommit: (Organisation) -> Void

    @State private var businessName: String
    @State private var emailAddress: String
    @State private var phoneNumber: String
    @State private var website: String
    @State private var postalAddress: String
    @State private var physicalAddress: String
    @State private var customerServiceNumber: String
    @State private var notes: String
    @State private var contactDrafts: [ProviderContactDraft]
    @State private var validationMessage: String?

    init(mode: Mode, onCommit: @escaping (Organisation) -> Void) {
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .create:
            _businessName = State(initialValue: "")
            _emailAddress = State(initialValue: "")
            _phoneNumber = State(initialValue: "")
            _website = State(initialValue: "")
            _postalAddress = State(initialValue: "")
            _physicalAddress = State(initialValue: "")
            _customerServiceNumber = State(initialValue: "")
            _notes = State(initialValue: "")
            _contactDrafts = State(initialValue: [])
        case .edit(let provider):
            _businessName = State(initialValue: provider.name)
            _emailAddress = State(initialValue: provider.emailAddress ?? "")
            _phoneNumber = State(initialValue: provider.phoneNumber ?? "")
            _website = State(initialValue: provider.website ?? "")
            _postalAddress = State(initialValue: provider.postalAddress ?? "")
            _physicalAddress = State(initialValue: provider.physicalAddress ?? "")
            _customerServiceNumber = State(initialValue: provider.customerServiceNumber ?? "")
            _notes = State(initialValue: provider.notes ?? "")
            _contactDrafts = State(
                initialValue: provider.contacts
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    .map(ProviderContactDraft.init(contact:))
            )
        }
    }

    var body: some View {
        Form {
            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
            }

            Section("Provider") {
                TextField("Business Name", text: $businessName)
                TextField("Email Address", text: $emailAddress)
                TextField("Phone Number", text: $phoneNumber)
                TextField("Website", text: $website)
                TextField("Customer Service Number", text: $customerServiceNumber)
                TextField("Postal Address", text: $postalAddress)
                TextField("Physical Address", text: $physicalAddress)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
            }

            Section("Associated Contacts") {
                if contactDrafts.isEmpty {
                    Text("No contacts added")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach($contactDrafts) { $draft in
                        VStack(alignment: .leading) {
                            TextField("Contact Name", text: $draft.name)
                            TextField("Role", text: $draft.role)
                            TextField("Email", text: $draft.emailAddress)
                            TextField("Phone", text: $draft.phoneNumber)
                            TextField("Account Number", text: $draft.accountNumber)
                            TextField("Notes", text: $draft.notes)
                        }
                    }
                    .onDelete { offsets in
                        contactDrafts.remove(atOffsets: offsets)
                    }
                }

                Button("Add Contact") {
                    contactDrafts.append(ProviderContactDraft())
                }
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

    private func handleSave() {
        let normalizedName = businessName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else {
            validationMessage = "Provider business name is required."
            return
        }

        let duplicate = organisations.first { organisation in
            let sameName = organisation.name.localizedCaseInsensitiveCompare(normalizedName) == .orderedSame
            if !sameName { return false }
            switch mode {
            case .create:
                return true
            case .edit(let editing):
                return organisation.persistentModelID != editing.persistentModelID
            }
        }
        guard duplicate == nil else {
            validationMessage = "A provider with this business name already exists."
            return
        }

        validationMessage = nil
        let provider: Organisation

        switch mode {
        case .create:
            provider = Organisation(name: normalizedName)
            modelContext.insert(provider)
        case .edit(let existing):
            provider = existing
        }

        provider.name = normalizedName
        provider.emailAddress = emailAddress.trimmedNilIfEmpty
        provider.phoneNumber = phoneNumber.trimmedNilIfEmpty
        provider.website = website.trimmedNilIfEmpty
        provider.postalAddress = postalAddress.trimmedNilIfEmpty
        provider.physicalAddress = physicalAddress.trimmedNilIfEmpty
        provider.customerServiceNumber = customerServiceNumber.trimmedNilIfEmpty
        provider.notes = notes.trimmedNilIfEmpty

        synchronizeContacts(for: provider)
        onCommit(provider)
        dismiss()
    }

    private var editorTitle: String {
        switch mode {
        case .create:
            return "New Provider"
        case .edit:
            return "Edit Provider"
        }
    }

    private func synchronizeContacts(for provider: Organisation) {
        let keptExistingIDs = Set(contactDrafts.compactMap(\.existingContactID))
        let existingByID = Dictionary(uniqueKeysWithValues: provider.contacts.map { ($0.persistentModelID, $0) })

        for existing in provider.contacts where !keptExistingIDs.contains(existing.persistentModelID) {
            provider.contacts.removeAll { $0.persistentModelID == existing.persistentModelID }
            if existing.purchases.isEmpty {
                modelContext.delete(existing)
            } else {
                existing.organisation = nil
            }
        }

        for draft in contactDrafts {
            guard let normalizedName = draft.name.trimmedNilIfEmpty else { continue }
            if let existingID = draft.existingContactID, let existing = existingByID[existingID] {
                existing.name = normalizedName
                existing.role = draft.role.trimmedNilIfEmpty
                existing.emailAddress = draft.emailAddress.trimmedNilIfEmpty
                existing.phoneNumber = draft.phoneNumber.trimmedNilIfEmpty
                existing.accountNumber = draft.accountNumber.trimmedNilIfEmpty
                existing.notes = draft.notes.trimmedNilIfEmpty
                existing.organisation = provider
            } else {
                let contact = Contact(
                    name: normalizedName,
                    role: draft.role.trimmedNilIfEmpty,
                    emailAddress: draft.emailAddress.trimmedNilIfEmpty,
                    phoneNumber: draft.phoneNumber.trimmedNilIfEmpty,
                    accountNumber: draft.accountNumber.trimmedNilIfEmpty,
                    notes: draft.notes.trimmedNilIfEmpty,
                    organisation: provider
                )
                modelContext.insert(contact)
                provider.contacts.append(contact)
            }
        }
    }
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
