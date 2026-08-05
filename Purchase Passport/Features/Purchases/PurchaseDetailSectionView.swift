import SwiftUI
import SwiftData

struct PurchaseDetailSectionView: View {
    let purchase: Purchase?
    let correspondences: [CorrespondenceRecord]

    @Binding var timelineFilter: TimelineFilter

    let selectedWarranty: Warranty?
    let selectedReminder: Reminder?
    let selectedInteraction: Interaction?
    let selectedComplaint: ComplaintCase?
    let selectedServiceRecord: ServiceRecord?
    let selectedFaultRecord: FaultRecord?
    let selectedRepairRecord: RepairRecord?
    let selectedDocument: StoredDocument?
    let selectedCorrespondence: CorrespondenceRecord?

    let formattedDate: (Date?) -> String
    let formattedDateTime: (Date?, Bool) -> String
    let formattedPrice: (Decimal?, String?) -> String
    let formattedUsefulLife: (Int?, String?) -> String
    let formattedTags: ([Tag]) -> String
    let formattedWarrantySubtitle: (Warranty) -> String
    let formattedReminderSubtitle: (Reminder) -> String
    let formattedInteractionSubtitle: (Interaction) -> String
    let formattedCorrespondenceSubtitle: (CorrespondenceRecord) -> String
    let formattedComplaintSubtitle: (ComplaintCase) -> String
    let formattedServiceSubtitle: (ServiceRecord) -> String
    let formattedFaultSubtitle: (FaultRecord) -> String
    let formattedRepairSubtitle: (RepairRecord) -> String

    let onSelectWarranty: (Warranty) -> Void
    let onSelectReminder: (Reminder) -> Void
    let onAddInteraction: () -> Void
    let onCallProvider: () -> Void
    let onSelectInteraction: (Interaction) -> Void
    let onAddComplaint: () -> Void
    let onSelectComplaint: (ComplaintCase) -> Void
    let onSelectCorrespondence: (CorrespondenceRecord) -> Void
    let onSetCorrespondenceStatus: (CorrespondenceRecord, CorrespondenceReviewStatus) -> Void
    let onApplyCorrespondenceExtraction: (CorrespondenceRecord) -> Void
    let onAddService: () -> Void
    let onSelectService: (ServiceRecord) -> Void
    let onAddFault: () -> Void
    let onSelectFault: (FaultRecord) -> Void
    let onAddRepair: () -> Void
    let onSelectRepair: (RepairRecord) -> Void
    let onSelectDocument: (StoredDocument) -> Void

    let onAddWarranty: () -> Void
    let onEditWarranty: () -> Void
    let onOpenWarrantyEditor: (Warranty) -> Void
    let onAddReminder: () -> Void
    let onEditReminder: () -> Void
    let onOpenReminderEditor: (Reminder) -> Void
    let onEditInteraction: () -> Void
    let onOpenInteractionEditor: (Interaction) -> Void
    let onEditComplaint: () -> Void
    let onOpenComplaintEditor: (ComplaintCase) -> Void
    let onEditService: () -> Void
    let onOpenServiceEditor: (ServiceRecord) -> Void
    let onEditFault: () -> Void
    let onOpenFaultEditor: (FaultRecord) -> Void
    let onEditRepair: () -> Void
    let onOpenRepairEditor: (RepairRecord) -> Void
    let onOpenProvider: () -> Void
    let onOpenDocument: () -> Void
    let onExportReport: () -> Void
    let onExportPDFReport: () -> Void
    let onExportArchive: () -> Void

    @State private var isFinancialExpanded = false
    @State private var isDetailsExpanded = false
    @State private var isTagsExpanded = false
    @State private var isWarrantiesExpanded = false
    @State private var isRemindersExpanded = false
    @State private var isInteractionsExpanded = false
    @State private var isComplaintsExpanded = false
    @State private var isServiceHistoryExpanded = false
    @State private var isFaultsExpanded = false
    @State private var isRepairsExpanded = false
    @State private var isTimelineExpanded = false
    @State private var isDocumentsExpanded = false

    var body: some View {
        Group {
            if let purchase {
                List {
                    Section("Summary") {
                        LabeledContent("Name", value: purchase.name)
                        LabeledContent("Status", value: purchase.status.rawValue)
                        LabeledContent("Category", value: purchase.category?.name ?? "Not set")
                        LabeledContent("Description", value: purchase.shortDescription ?? "Not set")
                        LabeledContent("Notes", value: purchase.notes ?? "Not set")
                        LabeledContent("Order Date", value: formattedDate(purchase.orderDate))
                        LabeledContent("Purchase Date", value: formattedDate(purchase.purchaseDate))
                        LabeledContent("Delivery Date", value: formattedDate(purchase.deliveryDate))
                    }

                    DisclosureGroup("Financial", isExpanded: $isFinancialExpanded) {
                        LabeledContent("Purchase Price", value: formattedPrice(purchase.purchasePrice, purchase.currencyCode))
                        LabeledContent("Currency", value: purchase.currencyCode ?? "Not set")
                    }

                    DisclosureGroup("Details", isExpanded: $isDetailsExpanded) {
                        LabeledContent("Provider", value: purchase.provider?.name ?? "Not set")
                        if purchase.provider != nil {
                            Button("Open Provider", action: onOpenProvider)
                        }
                        LabeledContent("Manufacturer", value: purchase.manufacturer ?? "Not set")
                        LabeledContent("Model", value: purchase.modelName ?? "Not set")
                        LabeledContent("Serial Number", value: purchase.serialNumber ?? "Not set")
                        LabeledContent("Invoice Number", value: purchase.invoiceNumber ?? "Not set")
                        LabeledContent("Order Number", value: purchase.orderNumber ?? "Not set")
                        LabeledContent("Purchase Location", value: purchase.purchaseLocation ?? "Not set")
                        LabeledContent("Storage Location", value: purchase.storageLocation ?? "Not set")
                        LabeledContent("Ownership", value: purchase.ownershipStatus?.rawValue ?? "Not set")
                        LabeledContent("Expected Useful Life", value: formattedUsefulLife(purchase.expectedUsefulLifeMonths, purchase.expectedUsefulLifeNotes))
                    }

                    DisclosureGroup("Tags", isExpanded: $isTagsExpanded) {
                        LabeledContent("Tags", value: formattedTags(purchase.tags))
                    }

                    DisclosureGroup("Warranties", isExpanded: $isWarrantiesExpanded) {
                        if purchase.warranties.isEmpty {
                            Text("No warranties attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.warranties.sorted(by: { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) })
                            ForEach(items) { warranty in
                                Button {
                                    onSelectWarranty(warranty)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(warranty.title)
                                                .font(.body)
                                            Text(formattedWarrantySubtitle(warranty))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedWarranty?.persistentModelID == warranty.persistentModelID {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .onTapGesture(count: 2) {
                                    onOpenWarrantyEditor(warranty)
                                }
                            }
                        }
                    }

                    DisclosureGroup("Reminders", isExpanded: $isRemindersExpanded) {
                        if purchase.reminders.isEmpty {
                            Text("No reminders attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.reminders.sorted(by: { $0.dueDate < $1.dueDate })
                            ForEach(items) { reminder in
                                Button {
                                    onSelectReminder(reminder)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(reminder.title)
                                                .font(.body)
                                            Text(formattedReminderSubtitle(reminder))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedReminder?.persistentModelID == reminder.persistentModelID {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .onTapGesture(count: 2) {
                                    onOpenReminderEditor(reminder)
                                }
                            }
                        }
                    }

                    DisclosureGroup("Interactions", isExpanded: $isInteractionsExpanded) {
                        Button("Add Interaction", action: onAddInteraction)
                        if purchase.provider != nil {
                            Button("Call Provider", action: onCallProvider)
                        }

                        if interactionFeedSections.isEmpty {
                            Text("No interactions attached")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(interactionFeedSections) { section in
                                Text(section.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                    .padding(.top, 4)

                                ForEach(section.items) { item in
                                    switch item {
                                    case .interaction(let interaction):
                                        interactionRow(interaction)
                                    case .correspondence(let correspondence):
                                        correspondenceRow(correspondence)
                                    }
                                }
                            }
                        }
                    }

                    DisclosureGroup("Complaints and Disputes", isExpanded: $isComplaintsExpanded) {
                        Button("Add Complaint Case", action: onAddComplaint)

                        if purchase.complaintCases.isEmpty {
                            Text("No complaint cases attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.complaintCases.sorted(by: { $0.dateOpened > $1.dateOpened })
                            ForEach(items) { complaint in
                                Button {
                                    onSelectComplaint(complaint)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(complaint.title)
                                            Text(formattedComplaintSubtitle(complaint))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedComplaint?.persistentModelID == complaint.persistentModelID {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .onTapGesture(count: 2) {
                                    onOpenComplaintEditor(complaint)
                                }
                            }
                        }
                    }

                    DisclosureGroup("Service History", isExpanded: $isServiceHistoryExpanded) {
                        Button("Add Service Record", action: onAddService)

                        if purchase.serviceRecords.isEmpty {
                            Text("No service records")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.serviceRecords.sorted(by: { ($0.serviceDate ?? .distantPast) > ($1.serviceDate ?? .distantPast) })
                            ForEach(items) { record in
                                Button {
                                    onSelectService(record)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(record.serviceType)
                                            Text(formattedServiceSubtitle(record))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedServiceRecord?.persistentModelID == record.persistentModelID {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .onTapGesture(count: 2) {
                                    onOpenServiceEditor(record)
                                }
                            }
                        }
                    }

                    DisclosureGroup("Faults", isExpanded: $isFaultsExpanded) {
                        Button("Add Fault", action: onAddFault)

                        if purchase.faultRecords.isEmpty {
                            Text("No faults recorded")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.faultRecords.sorted(by: { $0.firstNoticedDate > $1.firstNoticedDate })
                            ForEach(items) { fault in
                                Button {
                                    onSelectFault(fault)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(fault.title)
                                            Text(formattedFaultSubtitle(fault))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedFaultRecord?.persistentModelID == fault.persistentModelID {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .onTapGesture(count: 2) {
                                    onOpenFaultEditor(fault)
                                }
                            }
                        }
                    }

                    DisclosureGroup("Repairs", isExpanded: $isRepairsExpanded) {
                        Button("Add Repair", action: onAddRepair)

                        if purchase.repairRecords.isEmpty {
                            Text("No repairs recorded")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.repairRecords.sorted(by: { $0.repairDate > $1.repairDate })
                            ForEach(items) { repair in
                                Button {
                                    onSelectRepair(repair)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(repair.diagnosis ?? "Repair")
                                            Text(formattedRepairSubtitle(repair))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedRepairRecord?.persistentModelID == repair.persistentModelID {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .onTapGesture(count: 2) {
                                    onOpenRepairEditor(repair)
                                }
                            }
                        }
                    }

                    DisclosureGroup("Timeline", isExpanded: $isTimelineExpanded) {
                        Picker("Filter", selection: $timelineFilter) {
                            ForEach(TimelineFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)

                        let timelineEntries = TimelineService.entries(for: purchase, filter: timelineFilter)
                        if timelineEntries.isEmpty {
                            Text("No timeline events for this filter")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(timelineEntries) { entry in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.title)
                                        .font(.body)
                                    Text("\(formattedDateTime(entry.date, true)) • \(entry.details)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 1)
                            }
                        }
                    }

                    DisclosureGroup("Documents", isExpanded: $isDocumentsExpanded) {
                        if purchase.documents.isEmpty {
                            Text("No documents attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let documents = purchase.documents.sorted(by: { $0.dateAdded > $1.dateAdded })
                            ForEach(documents) { document in
                                Button {
                                    onSelectDocument(document)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(document.title)
                                                .font(.body)
                                            Text(document.category.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedDocument?.identifier == document.identifier {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .navigationTitle(purchase.name)
                .toolbar {
                    ToolbarItemGroup {
                        Button("Add Warranty", action: onAddWarranty)
                        Button("Edit Warranty", action: onEditWarranty)
                            .disabled(selectedWarranty == nil)

                        Button("Add Reminder", action: onAddReminder)
                        Button("Edit Reminder", action: onEditReminder)
                            .disabled(selectedReminder == nil)

                        Button("Edit Interaction", action: onEditInteraction)
                            .disabled(selectedInteraction == nil)

                        Button("Mark Correspondence Accepted") {
                            guard let selectedCorrespondence else { return }
                            onSetCorrespondenceStatus(selectedCorrespondence, .accepted)
                        }
                        .disabled(selectedCorrespondence == nil)

                        Button("Mark Correspondence Rejected") {
                            guard let selectedCorrespondence else { return }
                            onSetCorrespondenceStatus(selectedCorrespondence, .rejected)
                        }
                        .disabled(selectedCorrespondence == nil)

                        Button("Apply Extracted Fields") {
                            guard let selectedCorrespondence else { return }
                            onApplyCorrespondenceExtraction(selectedCorrespondence)
                        }
                        .disabled(!canApplySelectedCorrespondence)

                        Button("Edit Complaint Case", action: onEditComplaint)
                            .disabled(selectedComplaint == nil)

                        Button("Edit Service", action: onEditService)
                            .disabled(selectedServiceRecord == nil)

                        Button("Edit Fault", action: onEditFault)
                            .disabled(selectedFaultRecord == nil)

                        Button("Edit Repair", action: onEditRepair)
                            .disabled(selectedRepairRecord == nil)

                        Button("Open Document", action: onOpenDocument)
                            .disabled(selectedDocument == nil)

                        Button("Export Report", action: onExportReport)
                        Button("Export PDF Report", action: onExportPDFReport)
                        Button("Export Archive", action: onExportArchive)
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Purchase Selected",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Select a purchase in the list to view details.")
                )
            }
        }
    }

    private var canApplySelectedCorrespondence: Bool {
        guard let selectedCorrespondence else { return false }
        return selectedCorrespondence.extractedOrderNumber != nil ||
            selectedCorrespondence.extractedTrackingNumber != nil ||
            selectedCorrespondence.extractedRMANumber != nil ||
            selectedCorrespondence.extractedWarrantyExpiryDate != nil
    }

    private var interactionFeedItems: [InteractionFeedItem] {
        let interactionItems = (purchase?.interactions ?? []).map(InteractionFeedItem.interaction)
        let correspondenceItems = correspondences.map(InteractionFeedItem.correspondence)

        return (interactionItems + correspondenceItems)
            .sorted(by: { $0.occurredAt > $1.occurredAt })
    }

    private var interactionFeedSections: [InteractionFeedSection] {
        let groupedItems = Dictionary(grouping: interactionFeedItems, by: \.category)
        return InteractionFeedSection.orderedCategories.compactMap { category in
            guard let items = groupedItems[category], !items.isEmpty else { return nil }
            return InteractionFeedSection(
                title: category.title,
                items: items.sorted(by: { $0.occurredAt > $1.occurredAt })
            )
        }
    }

    @ViewBuilder
    private func interactionRow(_ interaction: Interaction) -> some View {
        Button {
            onSelectInteraction(interaction)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(interaction.subject)
                        .font(.body)
                    Text(formattedInteractionSubtitle(interaction))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if selectedInteraction?.persistentModelID == interaction.persistentModelID {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .onTapGesture(count: 2) {
            onOpenInteractionEditor(interaction)
        }
    }

    @ViewBuilder
    private func correspondenceRow(_ correspondence: CorrespondenceRecord) -> some View {
        Button {
            onSelectCorrespondence(correspondence)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(correspondence.subject)
                        .font(.body)
                    Text("Email • \(formattedCorrespondenceSubtitle(correspondence))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if correspondence.purchase == nil {
                        Text("Unlinked provider match")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if selectedCorrespondence?.persistentModelID == correspondence.persistentModelID {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private enum InteractionFeedItem: Identifiable {
    case interaction(Interaction)
    case correspondence(CorrespondenceRecord)

    var id: String {
        switch self {
        case .interaction(let interaction):
            return "interaction-\(interaction.persistentModelID)"
        case .correspondence(let correspondence):
            return "correspondence-\(correspondence.persistentModelID)"
        }
    }

    var occurredAt: Date {
        switch self {
        case .interaction(let interaction):
            return interaction.occurredAt
        case .correspondence(let correspondence):
            return correspondence.occurredAt
        }
    }

    var category: InteractionFeedCategory {
        switch self {
        case .interaction(let interaction):
            return .init(type: interaction.type)
        case .correspondence:
            return .email
        }
    }
}

private struct InteractionFeedSection: Identifiable {
    static let orderedCategories = InteractionFeedCategory.allCases

    let title: String
    let items: [InteractionFeedItem]

    var id: String { title }
}

private enum InteractionFeedCategory: CaseIterable {
    case email
    case phoneCall
    case letter
    case onlineChat
    case inPerson
    case serviceAppointment
    case other

    init(type: InteractionType) {
        switch type {
        case .email:
            self = .email
        case .phoneCall:
            self = .phoneCall
        case .letter:
            self = .letter
        case .onlineChat:
            self = .onlineChat
        case .inPersonVisit:
            self = .inPerson
        case .serviceAppointment:
            self = .serviceAppointment
        default:
            self = .other
        }
    }

    var title: String {
        switch self {
        case .email:
            return "Emails"
        case .phoneCall:
            return "Phone Calls"
        case .letter:
            return "Letters"
        case .onlineChat:
            return "Online Chat"
        case .inPerson:
            return "In-Person"
        case .serviceAppointment:
            return "Service Appointments"
        case .other:
            return "Other Interactions"
        }
    }
}
