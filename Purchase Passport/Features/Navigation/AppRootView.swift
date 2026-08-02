import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedSection: AppSection? = .allPurchases
    @State private var selectedPurchaseID: PersistentIdentifier?
    @State private var selectedServiceRecordID: PersistentIdentifier?
    @State private var selectedFaultRecordID: PersistentIdentifier?
    @State private var selectedRepairRecordID: PersistentIdentifier?
    @State private var selectedWarrantyID: PersistentIdentifier?
    @State private var selectedReminderID: PersistentIdentifier?
    @State private var selectedInteractionID: PersistentIdentifier?
    @State private var selectedComplaintID: PersistentIdentifier?
    @State private var lastSelectedPurchaseID: PersistentIdentifier?
    @State private var lastSelectedServiceRecordID: PersistentIdentifier?
    @State private var lastSelectedFaultRecordID: PersistentIdentifier?
    @State private var lastSelectedRepairRecordID: PersistentIdentifier?
    @State private var lastSelectedWarrantyID: PersistentIdentifier?
    @State private var lastSelectedReminderID: PersistentIdentifier?
    @State private var lastSelectedInteractionID: PersistentIdentifier?
    @State private var lastSelectedComplaintID: PersistentIdentifier?
    @State private var selectedPurchase: Purchase?
    @State private var selectedServiceRecord: ServiceRecord?
    @State private var selectedFaultRecord: FaultRecord?
    @State private var selectedRepairRecord: RepairRecord?
    @State private var selectedDocument: StoredDocument?
    @State private var selectedWarranty: Warranty?
    @State private var selectedReminder: Reminder?
    @State private var selectedInteraction: Interaction?
    @State private var selectedComplaint: ComplaintCase?
    @State private var timelineFilter: TimelineFilter = .all

    @State private var purchaseEditorPresentation: PurchaseEditorPresentation?
    @State private var serviceRecordEditorPresentation: ServiceRecordEditorPresentation?
    @State private var faultRecordEditorPresentation: FaultRecordEditorPresentation?
    @State private var repairRecordEditorPresentation: RepairRecordEditorPresentation?
    @State private var warrantyEditorPresentation: WarrantyEditorPresentation?
    @State private var reminderEditorPresentation: ReminderEditorPresentation?
    @State private var interactionEditorPresentation: InteractionEditorPresentation?
    @State private var complaintEditorPresentation: ComplaintEditorPresentation?

    @State private var isShowingDocumentImporter = false
    @State private var documentErrorMessage: String?
    @State private var draggedServiceRecordID: PersistentIdentifier?
    @State private var draggedFaultRecordID: PersistentIdentifier?
    @State private var isFaultSectionDropTargeted = false
    @State private var isRepairSectionDropTargeted = false

    @Query(sort: \Purchase.createdAt, order: .reverse)
    private var purchases: [Purchase]

    @Query(sort: \Warranty.updatedAt, order: .reverse)
    private var warranties: [Warranty]

    @Query(sort: \Reminder.dueDate)
    private var reminders: [Reminder]

    @Query(sort: \Interaction.occurredAt, order: .reverse)
    private var interactions: [Interaction]

    @Query(sort: \ServiceRecord.updatedAt, order: .reverse)
    private var serviceRecords: [ServiceRecord]

    @Query(sort: \FaultRecord.updatedAt, order: .reverse)
    private var faultRecords: [FaultRecord]

    @Query(sort: \RepairRecord.updatedAt, order: .reverse)
    private var repairRecords: [RepairRecord]

    @Query(sort: \ComplaintCase.updatedAt, order: .reverse)
    private var complaintCases: [ComplaintCase]

    var body: some View {
        var view = AnyView(
            NavigationSplitView {
                sidebarView
            } content: {
                contentColumnView
            } detail: {
                detailColumnView
            }
        )

        view = AnyView(view.onChange(of: selectedSection) { _, newValue in
            switch newValue {
            case .allPurchases:
                autoselectPurchase()
            case .servicing:
                selectedPurchase = nil
                selectedDocument = nil
                autoselectServiceRecord()
                autoselectFaultRecord()
                autoselectRepairRecord()
            case .interactions:
                selectedPurchase = nil
                selectedDocument = nil
                autoselectInteraction()
            case .complaints:
                selectedPurchase = nil
                selectedDocument = nil
                autoselectComplaint()
            case .warranties:
                selectedPurchase = nil
                selectedDocument = nil
                autoselectWarranty()
            case .reminders:
                selectedPurchase = nil
                selectedDocument = nil
                autoselectReminder()
            case .some, .none:
                selectedPurchaseID = nil
                selectedServiceRecordID = nil
                selectedFaultRecordID = nil
                selectedRepairRecordID = nil
                selectedInteractionID = nil
                selectedComplaintID = nil
                selectedWarrantyID = nil
                selectedReminderID = nil
                selectedPurchase = nil
                selectedServiceRecord = nil
                selectedFaultRecord = nil
                selectedRepairRecord = nil
                selectedInteraction = nil
                selectedComplaint = nil
                selectedWarranty = nil
                selectedReminder = nil
                selectedDocument = nil
            }
        })

        view = AnyView(view.onChange(of: selectedPurchaseID) { _, newValue in
            guard let newValue else {
                selectedPurchase = nil
                return
            }
            lastSelectedPurchaseID = newValue
            selectedPurchase = purchases.first { $0.persistentModelID == newValue }
        })

        view = AnyView(view.onChange(of: selectedPurchase) { _, newValue in
            selectedPurchaseID = newValue?.persistentModelID
            guard let purchase = newValue else {
                selectedDocument = nil
                selectedServiceRecord = nil
                selectedFaultRecord = nil
                selectedRepairRecord = nil
                selectedWarranty = nil
                selectedReminder = nil
                selectedInteraction = nil
                selectedComplaint = nil
                selectedServiceRecordID = nil
                selectedFaultRecordID = nil
                selectedRepairRecordID = nil
                selectedWarrantyID = nil
                selectedReminderID = nil
                selectedInteractionID = nil
                selectedComplaintID = nil
                return
            }
            selectedDocument = purchase.documents.sorted(by: { $0.dateAdded > $1.dateAdded }).first
            selectedServiceRecord = purchase.serviceRecords.sorted(by: { ($0.serviceDate ?? .distantPast) > ($1.serviceDate ?? .distantPast) }).first
            selectedFaultRecord = purchase.faultRecords.sorted(by: { $0.firstNoticedDate > $1.firstNoticedDate }).first
            selectedRepairRecord = purchase.repairRecords.sorted(by: { $0.repairDate > $1.repairDate }).first
            selectedWarranty = purchase.warranties.sorted(by: { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) }).first
            selectedReminder = purchase.reminders.sorted(by: { $0.dueDate < $1.dueDate }).first
            selectedInteraction = purchase.interactions.sorted(by: { $0.occurredAt > $1.occurredAt }).first
            selectedComplaint = purchase.complaintCases.sorted(by: { $0.dateOpened > $1.dateOpened }).first
            selectedServiceRecordID = selectedServiceRecord?.persistentModelID
            selectedFaultRecordID = selectedFaultRecord?.persistentModelID
            selectedRepairRecordID = selectedRepairRecord?.persistentModelID
            selectedWarrantyID = selectedWarranty?.persistentModelID
            selectedReminderID = selectedReminder?.persistentModelID
            selectedInteractionID = selectedInteraction?.persistentModelID
            selectedComplaintID = selectedComplaint?.persistentModelID
        })

        view = AnyView(view.onChange(of: selectedServiceRecordID) { _, newValue in
            guard let newValue else { selectedServiceRecord = nil; return }
            lastSelectedServiceRecordID = newValue
            selectedServiceRecord = serviceRecords.first { $0.persistentModelID == newValue }
        })
        view = AnyView(view.onChange(of: selectedFaultRecordID) { _, newValue in
            guard let newValue else { selectedFaultRecord = nil; return }
            lastSelectedFaultRecordID = newValue
            selectedFaultRecord = faultRecords.first { $0.persistentModelID == newValue }
        })
        view = AnyView(view.onChange(of: selectedRepairRecordID) { _, newValue in
            guard let newValue else { selectedRepairRecord = nil; return }
            lastSelectedRepairRecordID = newValue
            selectedRepairRecord = repairRecords.first { $0.persistentModelID == newValue }
        })
        view = AnyView(view.onChange(of: selectedServiceRecord) { _, newValue in selectedServiceRecordID = newValue?.persistentModelID })
        view = AnyView(view.onChange(of: selectedFaultRecord) { _, newValue in selectedFaultRecordID = newValue?.persistentModelID })
        view = AnyView(view.onChange(of: selectedRepairRecord) { _, newValue in selectedRepairRecordID = newValue?.persistentModelID })
        view = AnyView(view.onChange(of: selectedWarranty) { _, newValue in selectedWarrantyID = newValue?.persistentModelID })
        view = AnyView(view.onChange(of: selectedReminder) { _, newValue in selectedReminderID = newValue?.persistentModelID })
        view = AnyView(view.onChange(of: selectedWarrantyID) { _, newValue in
            guard let newValue else { selectedWarranty = nil; return }
            lastSelectedWarrantyID = newValue
            selectedWarranty = warranties.first { $0.persistentModelID == newValue }
        })
        view = AnyView(view.onChange(of: selectedReminderID) { _, newValue in
            guard let newValue else { selectedReminder = nil; return }
            lastSelectedReminderID = newValue
            selectedReminder = reminders.first { $0.persistentModelID == newValue }
        })
        view = AnyView(view.onChange(of: selectedInteractionID) { _, newValue in
            guard let newValue else { selectedInteraction = nil; return }
            lastSelectedInteractionID = newValue
            selectedInteraction = interactions.first { $0.persistentModelID == newValue }
        })
        view = AnyView(view.onChange(of: selectedInteraction) { _, newValue in selectedInteractionID = newValue?.persistentModelID })
        view = AnyView(view.onChange(of: selectedComplaintID) { _, newValue in
            guard let newValue else { selectedComplaint = nil; return }
            lastSelectedComplaintID = newValue
            selectedComplaint = complaintCases.first { $0.persistentModelID == newValue }
        })
        view = AnyView(view.onChange(of: selectedComplaint) { _, newValue in selectedComplaintID = newValue?.persistentModelID })
        view = AnyView(view.onAppear(perform: handleOnAppear))

        view = AnyView(view.sheet(item: $purchaseEditorPresentation) { presentation in
            switch presentation {
            case .new:
                PurchaseEditorView(mode: .create) { purchase in selectedPurchase = purchase }
                    .frame(minWidth: 700, minHeight: 700)
            case .edit(let purchase):
                PurchaseEditorView(mode: .edit(purchase)) { updated in selectedPurchase = updated }
                    .frame(minWidth: 700, minHeight: 700)
            }
        })
        view = AnyView(view.sheet(item: $serviceRecordEditorPresentation) { presentation in
            switch presentation {
            case .new(let purchase):
                ServiceRecordEditorView(mode: .create(purchase: purchase)) { record in selectedServiceRecord = record }
                    .frame(minWidth: 700, minHeight: 680)
            case .edit(let record):
                ServiceRecordEditorView(mode: .edit(record)) { updated in selectedServiceRecord = updated }
                    .frame(minWidth: 700, minHeight: 680)
            }
        })
        view = AnyView(view.sheet(item: $faultRecordEditorPresentation) { presentation in
            switch presentation {
            case .new(let purchase):
                FaultRecordEditorView(mode: .create(purchase: purchase)) { fault in selectedFaultRecord = fault }
                    .frame(minWidth: 700, minHeight: 620)
            case .edit(let fault):
                FaultRecordEditorView(mode: .edit(fault)) { updated in selectedFaultRecord = updated }
                    .frame(minWidth: 700, minHeight: 620)
            }
        })
        view = AnyView(view.sheet(item: $repairRecordEditorPresentation) { presentation in
            switch presentation {
            case .new(let purchase):
                RepairRecordEditorView(mode: .create(purchase: purchase)) { repair in selectedRepairRecord = repair }
                    .frame(minWidth: 760, minHeight: 700)
            case .edit(let repair):
                RepairRecordEditorView(mode: .edit(repair)) { updated in selectedRepairRecord = updated }
                    .frame(minWidth: 760, minHeight: 700)
            }
        })
        view = AnyView(view.sheet(item: $warrantyEditorPresentation) { presentation in
            switch presentation {
            case .new(let purchase):
                WarrantyEditorView(mode: .create(purchase: purchase)) { warranty in selectedWarranty = warranty }
                    .frame(minWidth: 650, minHeight: 620)
            case .edit(let warranty):
                WarrantyEditorView(mode: .edit(warranty)) { updated in selectedWarranty = updated }
                    .frame(minWidth: 650, minHeight: 620)
            }
        })
        view = AnyView(view.sheet(item: $reminderEditorPresentation) { presentation in
            switch presentation {
            case .new(let purchase):
                ReminderEditorView(mode: .create(purchase: purchase)) { reminder in selectedReminder = reminder }
                    .frame(minWidth: 650, minHeight: 560)
            case .edit(let reminder):
                ReminderEditorView(mode: .edit(reminder)) { updated in selectedReminder = updated }
                    .frame(minWidth: 650, minHeight: 560)
            }
        })
        view = AnyView(view.sheet(item: $interactionEditorPresentation) { presentation in
            switch presentation {
            case .new(let purchase):
                InteractionEditorView(mode: .create(purchase: purchase)) { interaction in selectedInteraction = interaction }
                    .frame(minWidth: 700, minHeight: 620)
            case .edit(let interaction):
                InteractionEditorView(mode: .edit(interaction)) { updated in selectedInteraction = updated }
                    .frame(minWidth: 700, minHeight: 620)
            }
        })
        view = AnyView(view.sheet(item: $complaintEditorPresentation) { presentation in
            switch presentation {
            case .new(let purchase):
                ComplaintCaseEditorView(mode: .create(purchase: purchase)) { complaint in selectedComplaint = complaint }
                    .frame(minWidth: 760, minHeight: 760)
            case .edit(let complaint):
                ComplaintCaseEditorView(mode: .edit(complaint)) { updated in selectedComplaint = updated }
                    .frame(minWidth: 760, minHeight: 760)
            }
        })
        view = AnyView(view.fileImporter(
            isPresented: $isShowingDocumentImporter,
            allowedContentTypes: [.data, .pdf, .image, .plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleDocumentImport(result: result)
        })
        view = AnyView(view.alert("Document Import Error", isPresented: .constant(documentErrorMessage != nil), actions: {
            Button("OK") { documentErrorMessage = nil }
        }, message: {
            Text(documentErrorMessage ?? "Unknown error.")
        }))

        return view
    }

    private var sidebarView: some View {
        List(AppSection.allCases, selection: $selectedSection) { section in
            Label(section.title, systemImage: section.systemImage)
                .tag(section)
        }
        .navigationTitle("Purchase Passport")
    }

    @ViewBuilder
    private var contentColumnView: some View {
        switch selectedSection {
        case .allPurchases:
            purchaseListView
        case .servicing:
            servicingListView
        case .interactions:
            interactionListView
        case .complaints:
            complaintListView
        case .warranties:
            warrantyListView
        case .reminders:
            reminderListView
        case .some(let section):
            List {
                Text(section.contentPlaceholder)
            }
            .navigationTitle(section.title)
        case .none:
            ContentUnavailableView(
                "No Section Selected",
                systemImage: "sidebar.left"
            )
        }
    }

    @ViewBuilder
    private var detailColumnView: some View {
        switch selectedSection {
        case .allPurchases:
            purchaseDetailView
        case .servicing:
            servicingDetailView
        case .interactions:
            interactionDetailView
        case .complaints:
            complaintDetailView
        case .warranties:
            warrantyDetailView
        case .reminders:
            reminderDetailView
        case .some(let section):
            ContentUnavailableView(
                section.title,
                systemImage: section.systemImage,
                description: Text(section.detailPlaceholder)
            )
        case .none:
            ContentUnavailableView(
                "No Section Selected",
                systemImage: "sidebar.left"
            )
        }
    }

    private var purchaseListView: some View {
        Group {
            if purchases.isEmpty {
                ContentUnavailableView(
                    "No Purchases Yet",
                    systemImage: "cart",
                    description: Text("Create a purchase record to see it listed here.")
                )
            } else {
                List(purchases, selection: $selectedPurchaseID) { purchase in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(purchase.name)
                            .font(.headline)

                        HStack(spacing: 8) {
                            Text(purchase.status.rawValue)
                            if let categoryName = purchase.category?.name, !categoryName.isEmpty {
                                Text("•")
                                Text(categoryName)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .tag(purchase.persistentModelID)
                }
            }
        }
        .navigationTitle("All Purchases")
        .toolbar {
            ToolbarItemGroup {
                Button("New Purchase") {
                    purchaseEditorPresentation = .new
                }
                .keyboardShortcut("n")

                Button("Edit Purchase") {
                    guard let selectedPurchase else { return }
                    purchaseEditorPresentation = .edit(selectedPurchase)
                }
                .disabled(selectedPurchase == nil)

                Button("Import Document") {
                    isShowingDocumentImporter = true
                }
                .keyboardShortcut("i")
                .disabled(selectedPurchase == nil)
            }
        }
    }

    private var warrantyListView: some View {
        Group {
            if warranties.isEmpty {
                ContentUnavailableView(
                    "No Warranties",
                    systemImage: "checkmark.shield",
                    description: Text("Add a warranty from a purchase detail view.")
                )
            } else {
                List(warranties, selection: $selectedWarrantyID) { warranty in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(warranty.title)
                            .font(.headline)
                        Text(warranty.purchase?.name ?? "Unlinked Purchase")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .tag(warranty.persistentModelID)
                }
            }
        }
        .navigationTitle("Warranties")
        .toolbar {
            ToolbarItem {
                Button("Edit Warranty") {
                    guard let selectedWarranty else { return }
                    warrantyEditorPresentation = .edit(selectedWarranty)
                }
                .disabled(selectedWarranty == nil)
            }
        }
    }

    private var interactionListView: some View {
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
                            Text(formattedDateTime(interaction.occurredAt, includeTime: true))
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
                Button("Edit Interaction") {
                    guard let selectedInteraction else { return }
                    interactionEditorPresentation = .edit(selectedInteraction)
                }
                .disabled(selectedInteraction == nil)
            }
        }
    }

    private var complaintListView: some View {
        Group {
            if complaintCases.isEmpty {
                ContentUnavailableView(
                    "No Complaint Cases",
                    systemImage: "exclamationmark.bubble",
                    description: Text("Add a complaint case from a purchase detail view.")
                )
            } else {
                List(complaintCases, selection: $selectedComplaintID) { complaint in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(complaint.title)
                            .font(.headline)
                        HStack(spacing: 8) {
                            Text(complaint.status.rawValue)
                            Text("•")
                            Text(complaint.purchase?.name ?? "Unlinked Purchase")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .tag(complaint.persistentModelID)
                }
            }
        }
        .navigationTitle("Complaints")
        .toolbar {
            ToolbarItem {
                Button("Edit Complaint") {
                    guard let selectedComplaint else { return }
                    complaintEditorPresentation = .edit(selectedComplaint)
                }
                .disabled(selectedComplaint == nil)
            }
        }
    }

    private var servicingListView: some View {
        List {
            Section("Service Records") {
                if serviceRecords.isEmpty {
                    Text("No service records")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(serviceRecords) { record in
                        Button {
                            selectedServiceRecord = record
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.serviceType)
                                Text(record.purchase?.name ?? "Unlinked Purchase")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .onDrag {
                            draggedServiceRecordID = record.persistentModelID
                            return NSItemProvider(object: NSString(string: "service-record"))
                        }
                    }
                }
            }

            Section("Faults") {
                if faultRecords.isEmpty {
                    Text("No faults")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(faultRecords) { fault in
                        Button {
                            selectedFaultRecord = fault
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fault.title)
                                Text(fault.purchase?.name ?? "Unlinked Purchase")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .onDrag {
                            draggedFaultRecordID = fault.persistentModelID
                            draggedServiceRecordID = nil
                            return NSItemProvider(object: NSString(string: "fault-record"))
                        }
                    }
                }
            }
            .onDrop(of: [.text], isTargeted: $isFaultSectionDropTargeted) { _ in
                handleServiceToFaultDrop()
            }

            Section("Repairs") {
                if repairRecords.isEmpty {
                    Text("No repairs")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(repairRecords) { repair in
                        Button {
                            selectedRepairRecord = repair
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(repair.diagnosis ?? "Repair")
                                Text(repair.purchase?.name ?? "Unlinked Purchase")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onDrop(of: [.text], isTargeted: $isRepairSectionDropTargeted) { _ in
                handleFaultToRepairDrop()
            }
        }
        .navigationTitle("Servicing and Repairs")
        .toolbar {
            ToolbarItemGroup {
                Button("Edit Service") {
                    guard let selectedServiceRecord else { return }
                    serviceRecordEditorPresentation = .edit(selectedServiceRecord)
                }
                .disabled(selectedServiceRecord == nil)

                Button("Edit Fault") {
                    guard let selectedFaultRecord else { return }
                    faultRecordEditorPresentation = .edit(selectedFaultRecord)
                }
                .disabled(selectedFaultRecord == nil)

                Button("Edit Repair") {
                    guard let selectedRepairRecord else { return }
                    repairRecordEditorPresentation = .edit(selectedRepairRecord)
                }
                .disabled(selectedRepairRecord == nil)
            }
        }
    }

    private var reminderListView: some View {
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
                            Text(formattedDateTime(reminder.dueDate, includeTime: reminder.hasSpecificTime))
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
                Button("Edit Reminder") {
                    guard let selectedReminder else { return }
                    reminderEditorPresentation = .edit(selectedReminder)
                }
                .disabled(selectedReminder == nil)
            }
        }
    }

    private var purchaseDetailView: some View {
        Group {
            if let purchase = selectedPurchase {
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

                    Section("Financial") {
                        LabeledContent("Purchase Price", value: formattedPrice(amount: purchase.purchasePrice, currencyCode: purchase.currencyCode))
                        LabeledContent("Currency", value: purchase.currencyCode ?? "Not set")
                    }

                    Section("Details") {
                        LabeledContent("Seller", value: purchase.seller ?? "Not set")
                        LabeledContent("Manufacturer", value: purchase.manufacturer ?? "Not set")
                        LabeledContent("Model", value: purchase.modelName ?? "Not set")
                        LabeledContent("Serial Number", value: purchase.serialNumber ?? "Not set")
                        LabeledContent("Invoice Number", value: purchase.invoiceNumber ?? "Not set")
                        LabeledContent("Order Number", value: purchase.orderNumber ?? "Not set")
                        LabeledContent("Purchase Location", value: purchase.purchaseLocation ?? "Not set")
                        LabeledContent("Storage Location", value: purchase.storageLocation ?? "Not set")
                        LabeledContent("Ownership", value: purchase.ownershipStatus?.rawValue ?? "Not set")
                        LabeledContent("Expected Useful Life", value: formattedUsefulLife(months: purchase.expectedUsefulLifeMonths, notes: purchase.expectedUsefulLifeNotes))
                    }

                    Section("Tags") {
                        LabeledContent("Tags", value: formattedTags(purchase.tags))
                    }

                    Section("Warranties") {
                        if purchase.warranties.isEmpty {
                            Text("No warranties attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.warranties.sorted(by: { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) })
                            ForEach(items) { warranty in
                                Button {
                                    selectedWarranty = warranty
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
                            }
                        }
                    }

                    Section("Reminders") {
                        if purchase.reminders.isEmpty {
                            Text("No reminders attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.reminders.sorted(by: { $0.dueDate < $1.dueDate })
                            ForEach(items) { reminder in
                                Button {
                                    selectedReminder = reminder
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
                            }
                        }
                    }

                    Section("Interactions") {
                        Button("Add Interaction") {
                            interactionEditorPresentation = .new(purchase)
                        }

                        if purchase.interactions.isEmpty {
                            Text("No interactions attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.interactions.sorted(by: { $0.occurredAt > $1.occurredAt })
                            ForEach(items) { interaction in
                                Button {
                                    selectedInteraction = interaction
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
                            }
                        }
                    }

                    Section("Complaints and Disputes") {
                        Button("Add Complaint Case") {
                            complaintEditorPresentation = .new(purchase)
                        }

                        if purchase.complaintCases.isEmpty {
                            Text("No complaint cases attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.complaintCases.sorted(by: { $0.dateOpened > $1.dateOpened })
                            ForEach(items) { complaint in
                                Button {
                                    selectedComplaint = complaint
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
                            }
                        }
                    }

                    Section("Service History") {
                        Button("Add Service Record") {
                            serviceRecordEditorPresentation = .new(purchase)
                        }

                        if purchase.serviceRecords.isEmpty {
                            Text("No service records")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.serviceRecords.sorted(by: { ($0.serviceDate ?? .distantPast) > ($1.serviceDate ?? .distantPast) })
                            ForEach(items) { record in
                                Button {
                                    selectedServiceRecord = record
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
                            }
                        }
                    }

                    Section("Faults") {
                        Button("Add Fault") {
                            faultRecordEditorPresentation = .new(purchase)
                        }

                        if purchase.faultRecords.isEmpty {
                            Text("No faults recorded")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.faultRecords.sorted(by: { $0.firstNoticedDate > $1.firstNoticedDate })
                            ForEach(items) { fault in
                                Button {
                                    selectedFaultRecord = fault
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
                            }
                        }
                    }

                    Section("Repairs") {
                        Button("Add Repair") {
                            repairRecordEditorPresentation = .new(purchase)
                        }

                        if purchase.repairRecords.isEmpty {
                            Text("No repairs recorded")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.repairRecords.sorted(by: { $0.repairDate > $1.repairDate })
                            ForEach(items) { repair in
                                Button {
                                    selectedRepairRecord = repair
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
                            }
                        }
                    }

                    Section("Timeline") {
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
                                    Text("\(formattedDateTime(entry.date, includeTime: true)) • \(entry.details)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 1)
                            }
                        }
                    }

                    Section("Documents") {
                        if purchase.documents.isEmpty {
                            Text("No documents attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let documents = purchase.documents.sorted(by: { $0.dateAdded > $1.dateAdded })
                            ForEach(documents) { document in
                                Button {
                                    selectedDocument = document
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
                        Button("Add Warranty") {
                            warrantyEditorPresentation = .new(purchase)
                        }

                        Button("Edit Warranty") {
                            guard let selectedWarranty else { return }
                            warrantyEditorPresentation = .edit(selectedWarranty)
                        }
                        .disabled(selectedWarranty == nil)

                        Button("Add Reminder") {
                            reminderEditorPresentation = .new(purchase)
                        }

                        Button("Edit Reminder") {
                            guard let selectedReminder else { return }
                            reminderEditorPresentation = .edit(selectedReminder)
                        }
                        .disabled(selectedReminder == nil)

                        Button("Add Interaction") {
                            interactionEditorPresentation = .new(purchase)
                        }

                        Button("Edit Interaction") {
                            guard let selectedInteraction else { return }
                            interactionEditorPresentation = .edit(selectedInteraction)
                        }
                        .disabled(selectedInteraction == nil)

                        Button("Add Complaint Case") {
                            complaintEditorPresentation = .new(purchase)
                        }

                        Button("Edit Complaint Case") {
                            guard let selectedComplaint else { return }
                            complaintEditorPresentation = .edit(selectedComplaint)
                        }
                        .disabled(selectedComplaint == nil)

                        Button("Edit Service") {
                            guard let selectedServiceRecord else { return }
                            serviceRecordEditorPresentation = .edit(selectedServiceRecord)
                        }
                        .disabled(selectedServiceRecord == nil)

                        Button("Edit Fault") {
                            guard let selectedFaultRecord else { return }
                            faultRecordEditorPresentation = .edit(selectedFaultRecord)
                        }
                        .disabled(selectedFaultRecord == nil)

                        Button("Edit Repair") {
                            guard let selectedRepairRecord else { return }
                            repairRecordEditorPresentation = .edit(selectedRepairRecord)
                        }
                        .disabled(selectedRepairRecord == nil)

                        Button("Open Document") {
                            openSelectedDocument()
                        }
                        .disabled(selectedDocument == nil)
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

    private var warrantyDetailView: some View {
        Group {
            if let warranty = selectedWarranty {
                List {
                    Section("Summary") {
                        LabeledContent("Title", value: warranty.title)
                        LabeledContent("Type", value: warranty.type.rawValue)
                        LabeledContent("Provider", value: warranty.provider ?? "Not set")
                        LabeledContent("Purchase", value: warranty.purchase?.name ?? "Not set")
                        LabeledContent("Status", value: WarrantyStatusService.status(for: warranty).rawValue)
                    }

                    Section("Dates") {
                        LabeledContent("Start Date", value: formattedDate(warranty.startDate))
                        LabeledContent("End Date", value: formattedDate(warranty.endDate))
                    }

                    Section("Claim") {
                        LabeledContent("Reference", value: warranty.warrantyReferenceNumber ?? "Not set")
                        LabeledContent("Claim Procedure", value: warranty.claimProcedure ?? "Not set")
                        LabeledContent("Proof Of Purchase", value: warranty.proofOfPurchaseRequired ? "Required" : "Not required")
                    }

                    Section("Notes") {
                        LabeledContent("Coverage", value: warranty.coverageDescription ?? "Not set")
                        LabeledContent("Notes", value: warranty.notes ?? "Not set")
                    }
                }
                .navigationTitle(warranty.title)
            } else {
                ContentUnavailableView(
                    "No Warranty Selected",
                    systemImage: "checkmark.shield",
                    description: Text("Select a warranty to view details.")
                )
            }
        }
    }

    private var interactionDetailView: some View {
        Group {
            if let interaction = selectedInteraction {
                List {
                    Section("Summary") {
                        LabeledContent("Subject", value: interaction.subject)
                        LabeledContent("Type", value: interaction.type.rawValue)
                        LabeledContent("Status", value: interaction.status.rawValue)
                        LabeledContent("Occurred", value: formattedDateTime(interaction.occurredAt, includeTime: true))
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

    private var complaintDetailView: some View {
        Group {
            if let complaint = selectedComplaint {
                List {
                    Section("Summary") {
                        LabeledContent("Title", value: complaint.title)
                        LabeledContent("Issue Type", value: complaint.issueType.rawValue)
                        LabeledContent("Status", value: complaint.status.rawValue)
                        LabeledContent("Date Opened", value: formattedDate(complaint.dateOpened))
                        LabeledContent("Date Closed", value: formattedDate(complaint.dateClosed))
                        LabeledContent("Purchase", value: complaint.purchase?.name ?? "Not set")
                        LabeledContent("Party Responsible", value: complaint.partyResponsible ?? "Not set")
                        LabeledContent("Reference", value: complaint.caseReferenceNumber ?? "Not set")
                    }

                    Section("Resolution and Deadlines") {
                        LabeledContent("Desired Resolution", value: complaint.desiredResolution ?? "Not set")
                        LabeledContent("Consumer Guarantee/Warranty", value: complaint.consumerGuaranteeOrWarranty ?? "Not set")
                        LabeledContent("Response Deadline", value: formattedDateTime(complaint.responseDeadline, includeTime: false))
                        LabeledContent("Deadline State", value: ComplaintService.deadlineState(for: complaint).rawValue)
                        LabeledContent("Commitments", value: complaint.commitmentsMade ?? "Not set")
                        LabeledContent("Outcome", value: complaint.outcome ?? "Not set")
                        LabeledContent("Compensation Details", value: complaint.compensationDetails ?? "Not set")
                    }

                    Section("Linked Records") {
                        LabeledContent("Interactions", value: "\(complaint.relatedInteractions.count)")
                        LabeledContent("Faults", value: "\(complaint.relatedFaults.count)")
                        LabeledContent("Repairs", value: "\(complaint.relatedRepairs.count)")
                        LabeledContent("Documents", value: "\(complaint.relatedDocuments.count)")
                    }

                    Section("Chronology") {
                        let chronologyEntries = ComplaintService.chronology(for: complaint)
                        if chronologyEntries.isEmpty {
                            Text("No chronology available")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(chronologyEntries) { entry in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.title)
                                    Text("\(formattedDateTime(entry.date, includeTime: true)) • \(entry.details)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section("Notes") {
                        LabeledContent("Chronology Notes", value: complaint.chronology ?? "Not set")
                        LabeledContent("Key Evidence", value: complaint.keyEvidence ?? "Not set")
                        LabeledContent("Correspondence", value: complaint.correspondence ?? "Not set")
                    }
                }
                .navigationTitle(complaint.title)
            } else {
                ContentUnavailableView(
                    "No Complaint Selected",
                    systemImage: "exclamationmark.bubble",
                    description: Text("Select a complaint case to view details.")
                )
            }
        }
    }

    private var servicingDetailView: some View {
        List {
            Section("Selected Service Record") {
                if let record = selectedServiceRecord {
                    LabeledContent("Service Type", value: record.serviceType)
                    LabeledContent("Provider", value: record.serviceProvider ?? "Not set")
                    LabeledContent("Service Date", value: formattedDate(record.serviceDate))
                    LabeledContent("Completion Date", value: formattedDate(record.completionDate))
                    LabeledContent("Cost", value: formattedPrice(amount: record.costAmount, currencyCode: record.currencyCode))
                    LabeledContent("Work Completed", value: record.workCompleted ?? "Not set")
                } else {
                    Text("No service record selected")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Selected Fault") {
                if let fault = selectedFaultRecord {
                    LabeledContent("Title", value: fault.title)
                    LabeledContent("Severity", value: fault.severity.rawValue)
                    LabeledContent("Status", value: fault.status.rawValue)
                    LabeledContent("First Noticed", value: formattedDateTime(fault.firstNoticedDate, includeTime: false))
                    LabeledContent("Effect On Use", value: fault.effectOnUse ?? "Not set")
                } else {
                    Text("No fault selected")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Selected Repair") {
                if let repair = selectedRepairRecord {
                    LabeledContent("Diagnosis", value: repair.diagnosis ?? "Not set")
                    LabeledContent("Repair Date", value: formattedDateTime(repair.repairDate, includeTime: false))
                    LabeledContent("Provider", value: repair.repairProvider ?? "Not set")
                    LabeledContent("Total Cost", value: formattedPrice(amount: repair.totalCost, currencyCode: repair.currencyCode))
                    LabeledContent("Payment Status", value: repair.paymentStatus.rawValue)
                    LabeledContent("Outcome", value: repair.outcome ?? "Not set")
                } else {
                    Text("No repair selected")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Servicing and Repairs")
    }

    private var reminderDetailView: some View {
        Group {
            if let reminder = selectedReminder {
                List {
                    Section("Summary") {
                        LabeledContent("Title", value: reminder.title)
                        LabeledContent("Type", value: reminder.type.rawValue)
                        LabeledContent("Due", value: formattedDateTime(reminder.dueDate, includeTime: reminder.hasSpecificTime))
                        LabeledContent("Purchase", value: reminder.purchase?.name ?? "Not set")
                        LabeledContent("Priority", value: reminder.priority.rawValue)
                        LabeledContent("Recurrence", value: reminder.recurrence.rawValue)
                    }

                    Section("Tracking") {
                        LabeledContent("Advance Warning", value: "\(reminder.advanceWarningDays) day(s)")
                        LabeledContent("State", value: formattedReminderState(reminder))
                        LabeledContent("Completed", value: reminder.isCompleted ? "Yes" : "No")
                        LabeledContent("Next Due", value: formattedDateTime(ReminderService.nextDueDate(for: reminder), includeTime: reminder.hasSpecificTime))
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

    private func formattedDate(_ value: Date?) -> String {
        guard let value else { return "Not set" }
        return value.formatted(date: .abbreviated, time: .omitted)
    }

    private func formattedDateTime(_ value: Date?, includeTime: Bool) -> String {
        guard let value else { return "Not set" }
        if includeTime {
            return value.formatted(date: .abbreviated, time: .shortened)
        }
        return value.formatted(date: .abbreviated, time: .omitted)
    }

    private func formattedPrice(amount: Decimal?, currencyCode: String?) -> String {
        guard let amount else { return "Not set" }
        if let currencyCode, !currencyCode.isEmpty {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currencyCode
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            if let formatted = formatter.string(from: amount as NSDecimalNumber) {
                return formatted
            }
        }
        return NSDecimalNumber(decimal: amount).stringValue
    }

    private func formattedUsefulLife(months: Int?, notes: String?) -> String {
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        switch (months, trimmedNotes) {
        case let (.some(months), .some(notes)) where !notes.isEmpty:
            return "\(months) months (\(notes))"
        case let (.some(months), _):
            return "\(months) months"
        case let (_, .some(notes)) where !notes.isEmpty:
            return notes
        default:
            return "Not set"
        }
    }

    private func formattedTags(_ tags: [Tag]) -> String {
        if tags.isEmpty { return "Not set" }
        return tags.map(\.name).joined(separator: ", ")
    }

    private func formattedWarrantySubtitle(_ warranty: Warranty) -> String {
        let status = WarrantyStatusService.status(for: warranty).rawValue
        let end = formattedDate(warranty.endDate)
        return "\(status) • End: \(end)"
    }

    private func formattedReminderSubtitle(_ reminder: Reminder) -> String {
        let due = formattedDateTime(reminder.dueDate, includeTime: reminder.hasSpecificTime)
        return "\(formattedReminderState(reminder)) • Due: \(due)"
    }

    private func formattedInteractionSubtitle(_ interaction: Interaction) -> String {
        let occurred = formattedDateTime(interaction.occurredAt, includeTime: true)
        return "\(interaction.type.rawValue) • \(interaction.status.rawValue) • \(occurred)"
    }

    private func formattedComplaintSubtitle(_ complaint: ComplaintCase) -> String {
        let opened = formattedDate(complaint.dateOpened)
        let deadlineState = ComplaintService.deadlineState(for: complaint).rawValue
        return "\(complaint.status.rawValue) • \(deadlineState) • Opened: \(opened)"
    }

    private func formattedServiceSubtitle(_ record: ServiceRecord) -> String {
        let date = formattedDate(record.serviceDate ?? record.completionDate ?? record.bookingDate)
        return "\(date) • \(formattedPrice(amount: record.costAmount, currencyCode: record.currencyCode))"
    }

    private func formattedFaultSubtitle(_ fault: FaultRecord) -> String {
        "\(fault.severity.rawValue) • \(fault.status.rawValue)"
    }

    private func formattedRepairSubtitle(_ repair: RepairRecord) -> String {
        let date = formattedDateTime(repair.repairDate, includeTime: false)
        let total = formattedPrice(amount: repair.totalCost, currencyCode: repair.currencyCode)
        return "\(date) • \(total) • \(repair.paymentStatus.rawValue)"
    }

    private func formattedReminderState(_ reminder: Reminder) -> String {
        if reminder.isCompleted { return "completed" }
        if ReminderService.isOverdue(reminder) { return "overdue" }
        if ReminderService.isDueSoon(reminder) { return "due soon" }
        return "scheduled"
    }

    private func handleOnAppear() {
        switch selectedSection {
        case .allPurchases:
            autoselectPurchase()
        case .servicing:
            autoselectServiceRecord()
            autoselectFaultRecord()
            autoselectRepairRecord()
        case .interactions:
            autoselectInteraction()
        case .complaints:
            autoselectComplaint()
        case .warranties:
            autoselectWarranty()
        case .reminders:
            autoselectReminder()
        default:
            break
        }
    }

    private func autoselectPurchase() {
        guard !purchases.isEmpty else {
            selectedPurchaseID = nil
            selectedPurchase = nil
            return
        }

        if let lastSelectedPurchaseID,
           purchases.contains(where: { $0.persistentModelID == lastSelectedPurchaseID }) {
            selectedPurchaseID = lastSelectedPurchaseID
        } else {
            selectedPurchaseID = purchases[0].persistentModelID
        }
    }

    private func autoselectServiceRecord() {
        guard !serviceRecords.isEmpty else {
            selectedServiceRecordID = nil
            selectedServiceRecord = nil
            return
        }
        if let lastSelectedServiceRecordID,
           serviceRecords.contains(where: { $0.persistentModelID == lastSelectedServiceRecordID }) {
            selectedServiceRecordID = lastSelectedServiceRecordID
        } else {
            selectedServiceRecordID = serviceRecords[0].persistentModelID
        }
    }

    private func autoselectFaultRecord() {
        guard !faultRecords.isEmpty else {
            selectedFaultRecordID = nil
            selectedFaultRecord = nil
            return
        }
        if let lastSelectedFaultRecordID,
           faultRecords.contains(where: { $0.persistentModelID == lastSelectedFaultRecordID }) {
            selectedFaultRecordID = lastSelectedFaultRecordID
        } else {
            selectedFaultRecordID = faultRecords[0].persistentModelID
        }
    }

    private func autoselectRepairRecord() {
        guard !repairRecords.isEmpty else {
            selectedRepairRecordID = nil
            selectedRepairRecord = nil
            return
        }
        if let lastSelectedRepairRecordID,
           repairRecords.contains(where: { $0.persistentModelID == lastSelectedRepairRecordID }) {
            selectedRepairRecordID = lastSelectedRepairRecordID
        } else {
            selectedRepairRecordID = repairRecords[0].persistentModelID
        }
    }

    private func autoselectWarranty() {
        guard !warranties.isEmpty else {
            selectedWarrantyID = nil
            selectedWarranty = nil
            return
        }

        if let lastSelectedWarrantyID,
           warranties.contains(where: { $0.persistentModelID == lastSelectedWarrantyID }) {
            selectedWarrantyID = lastSelectedWarrantyID
        } else {
            selectedWarrantyID = warranties[0].persistentModelID
        }
    }

    private func autoselectReminder() {
        guard !reminders.isEmpty else {
            selectedReminderID = nil
            selectedReminder = nil
            return
        }

        if let lastSelectedReminderID,
           reminders.contains(where: { $0.persistentModelID == lastSelectedReminderID }) {
            selectedReminderID = lastSelectedReminderID
        } else {
            selectedReminderID = reminders[0].persistentModelID
        }
    }

    private func autoselectInteraction() {
        guard !interactions.isEmpty else {
            selectedInteractionID = nil
            selectedInteraction = nil
            return
        }

        if let lastSelectedInteractionID,
           interactions.contains(where: { $0.persistentModelID == lastSelectedInteractionID }) {
            selectedInteractionID = lastSelectedInteractionID
        } else {
            selectedInteractionID = interactions[0].persistentModelID
        }
    }

    private func autoselectComplaint() {
        guard !complaintCases.isEmpty else {
            selectedComplaintID = nil
            selectedComplaint = nil
            return
        }

        if let lastSelectedComplaintID,
           complaintCases.contains(where: { $0.persistentModelID == lastSelectedComplaintID }) {
            selectedComplaintID = lastSelectedComplaintID
        } else {
            selectedComplaintID = complaintCases[0].persistentModelID
        }
    }

    private func handleServiceToFaultDrop() -> Bool {
        defer { draggedServiceRecordID = nil }

        guard let draggedServiceRecordID,
              let serviceRecord = serviceRecords.first(where: { $0.persistentModelID == draggedServiceRecordID }) else {
            return false
        }

        let faultRecord = FaultRecord(
            firstNoticedDate: serviceRecord.serviceDate ?? serviceRecord.completionDate ?? serviceRecord.bookingDate ?? serviceRecord.createdAt,
            title: serviceRecord.serviceType,
            detailedDescription: nonEmpty(serviceRecord.workRequested),
            severity: .medium,
            status: .open,
            diagnosticInformation: nonEmpty(serviceRecord.workCompleted),
            effectOnUse: nonEmpty(serviceRecord.technicianNotes),
            notes: convertedFaultNotes(from: serviceRecord),
            createdAt: serviceRecord.createdAt,
            updatedAt: .now,
            purchase: serviceRecord.purchase
        )

        if let purchase = serviceRecord.purchase {
            purchase.faultRecords.append(faultRecord)
            purchase.serviceRecords.removeAll { $0.persistentModelID == serviceRecord.persistentModelID }
            purchase.updatedAt = .now
        } else {
            modelContext.insert(faultRecord)
        }

        modelContext.delete(serviceRecord)

        do {
            try modelContext.save()
        } catch {
            return false
        }

        selectedServiceRecord = nil
        selectedServiceRecordID = nil
        selectedFaultRecord = faultRecord
        selectedFaultRecordID = faultRecord.persistentModelID
        faultRecordEditorPresentation = .edit(faultRecord)
        return true
    }

    private func handleFaultToRepairDrop() -> Bool {
        defer { draggedFaultRecordID = nil }

        guard let draggedFaultRecordID,
              let faultRecord = faultRecords.first(where: { $0.persistentModelID == draggedFaultRecordID }) else {
            return false
        }

        let repairRecord = RepairRecord(
            bookingDate: .now,
            repairDate: .now,
            diagnosis: nonEmpty(faultRecord.title),
            workPerformed: nonEmpty(faultRecord.detailedDescription),
            warrantyCoverage: faultRecord.sellerOrManufacturerNotified,
            paymentStatus: .unpaid,
            outcome: faultRecord.status == .resolved || faultRecord.status == .closed ? "Resolved" : nil,
            unresolvedIssues: nonEmpty(faultRecord.effectOnUse),
            followUpRequired: faultRecord.status != .resolved && faultRecord.status != .closed,
            notes: convertedRepairNotes(from: faultRecord),
            createdAt: .now,
            updatedAt: .now,
            purchase: faultRecord.purchase,
            fault: faultRecord
        )

        if let purchase = faultRecord.purchase {
            purchase.repairRecords.append(repairRecord)
            purchase.updatedAt = .now
        } else {
            modelContext.insert(repairRecord)
        }

        faultRecord.relatedRepairs.append(repairRecord)

        do {
            try modelContext.save()
        } catch {
            return false
        }

        selectedRepairRecord = repairRecord
        selectedRepairRecordID = repairRecord.persistentModelID
        repairRecordEditorPresentation = .edit(repairRecord)
        return true
    }

    private func convertedFaultNotes(from serviceRecord: ServiceRecord) -> String? {
        var details: [String] = []

        if let notes = nonEmpty(serviceRecord.notes) {
            details.append(notes)
        }
        if let reference = nonEmpty(serviceRecord.serviceReferenceNumber) {
            details.append("Converted from service record reference: \(reference)")
        }
        if let provider = nonEmpty(serviceRecord.serviceProvider) {
            details.append("Original provider: \(provider)")
        }

        return details.isEmpty ? nil : details.joined(separator: "\n\n")
    }

    private func convertedRepairNotes(from faultRecord: FaultRecord) -> String? {
        var details: [String] = []

        if let notes = nonEmpty(faultRecord.notes) {
            details.append(notes)
        }
        if let diagnostics = nonEmpty(faultRecord.diagnosticInformation) {
            details.append("Diagnostic information: \(diagnostics)")
        }
        if let safety = nonEmpty(faultRecord.safetyConcerns) {
            details.append("Safety concerns: \(safety)")
        }

        return details.isEmpty ? nil : details.joined(separator: "\n\n")
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func handleDocumentImport(result: Result<[URL], Error>) {
        guard let purchase = selectedPurchase else { return }

        do {
            let urls = try result.get()
            guard let sourceURL = urls.first else { return }

            let imported = try DocumentStorageService.importFile(from: sourceURL)
            let title = sourceURL.deletingPathExtension().lastPathComponent
            let document = StoredDocument(
                title: title.isEmpty ? imported.originalFilename : title,
                category: .other,
                originalFilename: imported.originalFilename,
                contentType: imported.contentType,
                storedRelativePath: imported.storedRelativePath,
                purchase: purchase
            )

            purchase.documents.append(document)
            purchase.updatedAt = .now
            selectedDocument = document
        } catch {
            documentErrorMessage = error.localizedDescription
        }
    }

    private func openSelectedDocument() {
        guard let selectedDocument else { return }

        do {
            let url = try DocumentStorageService.resolvedURL(for: selectedDocument.storedRelativePath)
            NSWorkspace.shared.open(url)
        } catch {
            documentErrorMessage = error.localizedDescription
        }
    }
}

private enum PurchaseEditorPresentation: Identifiable {
    case new
    case edit(Purchase)

    var id: String {
        switch self {
        case .new:
            return "new"
        case .edit(let purchase):
            return "edit-\(purchase.persistentModelID)"
        }
    }
}

private enum ServiceRecordEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(ServiceRecord)

    var id: String {
        switch self {
        case .new(let purchase):
            return "service-new-\(purchase.persistentModelID)"
        case .edit(let record):
            return "service-edit-\(record.persistentModelID)"
        }
    }
}

private enum FaultRecordEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(FaultRecord)

    var id: String {
        switch self {
        case .new(let purchase):
            return "fault-new-\(purchase.persistentModelID)"
        case .edit(let fault):
            return "fault-edit-\(fault.persistentModelID)"
        }
    }
}

private enum RepairRecordEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(RepairRecord)

    var id: String {
        switch self {
        case .new(let purchase):
            return "repair-new-\(purchase.persistentModelID)"
        case .edit(let repair):
            return "repair-edit-\(repair.persistentModelID)"
        }
    }
}

private enum WarrantyEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(Warranty)

    var id: String {
        switch self {
        case .new(let purchase):
            return "warranty-new-\(purchase.persistentModelID)"
        case .edit(let warranty):
            return "warranty-edit-\(warranty.persistentModelID)"
        }
    }
}

private enum ReminderEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(Reminder)

    var id: String {
        switch self {
        case .new(let purchase):
            return "reminder-new-\(purchase.persistentModelID)"
        case .edit(let reminder):
            return "reminder-edit-\(reminder.persistentModelID)"
        }
    }
}

private enum InteractionEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(Interaction)

    var id: String {
        switch self {
        case .new(let purchase):
            return "interaction-new-\(purchase.persistentModelID)"
        case .edit(let interaction):
            return "interaction-edit-\(interaction.persistentModelID)"
        }
    }
}

private enum ComplaintEditorPresentation: Identifiable {
    case new(Purchase)
    case edit(ComplaintCase)

    var id: String {
        switch self {
        case .new(let purchase):
            return "complaint-new-\(purchase.persistentModelID)"
        case .edit(let complaint):
            return "complaint-edit-\(complaint.persistentModelID)"
        }
    }
}

private enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case allPurchases
    case servicing
    case interactions
    case complaints
    case warranties
    case reminders
    case documents

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            "Dashboard"
        case .allPurchases:
            "All Purchases"
        case .servicing:
            "Servicing"
        case .interactions:
            "Interactions"
        case .complaints:
            "Complaints"
        case .warranties:
            "Warranties"
        case .reminders:
            "Reminders"
        case .documents:
            "Documents"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            "square.grid.2x2"
        case .allPurchases:
            "cart"
        case .servicing:
            "wrench.and.screwdriver"
        case .interactions:
            "bubble.left.and.bubble.right"
        case .complaints:
            "exclamationmark.bubble"
        case .warranties:
            "checkmark.shield"
        case .reminders:
            "bell"
        case .documents:
            "doc.text"
        }
    }

    var contentPlaceholder: String {
        switch self {
        case .dashboard:
            "Dashboard content will be implemented in a later task."
        case .allPurchases:
            "Purchase list is available in this section."
        case .servicing:
            "Service, fault and repair records are available in this section."
        case .interactions:
            "Interaction list is available in this section."
        case .complaints:
            "Complaint and dispute records are available in this section."
        case .warranties:
            "Warranty list is available in this section."
        case .reminders:
            "Reminder list is available in this section."
        case .documents:
            "Document import is available from All Purchases."
        }
    }

    var detailPlaceholder: String {
        switch self {
        case .dashboard:
            "This section is not part of the current task."
        case .allPurchases:
            "Select a purchase to view its details."
        case .servicing:
            "Select service, fault, or repair records to view details."
        case .interactions:
            "Select an interaction to view details."
        case .complaints:
            "Select a complaint case to view details."
        case .warranties:
            "Select a warranty to view details."
        case .reminders:
            "Select a reminder to view details."
        case .documents:
            "Document detail view will be expanded in a later task."
        }
    }
}

#Preview {
    AppRootView()
}
