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

    var body: some View {
        Group {
            if let provider {
                List {
                    Section("Summary") {
                        LabeledContent("Business Name", value: provider.name)
                        LabeledContent("Linked Purchases", value: "\(linkedPurchaseCount)")
                    }

                    Section("Linked Purchases") {
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

                    Section("Linked Emails") {
                        Button("Open Email Import Window") {
                            onOpenEmailImport()
                        }

                        Text("Open the import window, then drag exported `.eml` or `.emlx` email files onto it for this provider.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

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

                    Section("Contact Details") {
                        LabeledContent("Email", value: provider.emailAddress ?? "Not set")
                        LabeledContent("Phone", value: provider.phoneNumber ?? "Not set")
                        LabeledContent("Website", value: provider.website ?? "Not set")
                        LabeledContent("Customer Service", value: provider.customerServiceNumber ?? "Not set")
                    }

                    Section("Addresses") {
                        LabeledContent("Postal", value: provider.postalAddress ?? "Not set")
                        LabeledContent("Physical", value: provider.physicalAddress ?? "Not set")
                    }

                    Section("Notes") {
                        Text(provider.notes ?? "Not set")
                            .foregroundStyle(provider.notes == nil ? .secondary : .primary)
                    }

                    Section("Associated Contacts") {
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
