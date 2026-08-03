import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedSection: AppSection? = .dashboard
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
    @State private var searchQuery = ""
    @State private var searchFilters = PurchaseSearchFilters.default
    @State private var searchSortOption: PurchaseSearchSortOption = .mostRecent
    @State private var savedPurchaseSearches: [SavedPurchaseSearch] = []
    @State private var hasLoadedSavedPurchaseSearches = false
    @AppStorage("savedPurchaseSearchesJSON") private var savedPurchaseSearchesJSON = "[]"

    @State private var purchaseEditorPresentation: PurchaseEditorPresentation?
    @State private var serviceRecordEditorPresentation: ServiceRecordEditorPresentation?
    @State private var faultRecordEditorPresentation: FaultRecordEditorPresentation?
    @State private var repairRecordEditorPresentation: RepairRecordEditorPresentation?
    @State private var warrantyEditorPresentation: WarrantyEditorPresentation?
    @State private var reminderEditorPresentation: ReminderEditorPresentation?
    @State private var interactionEditorPresentation: InteractionEditorPresentation?
    @State private var complaintEditorPresentation: ComplaintEditorPresentation?

    @State private var isShowingDocumentImporter = false
    @State private var operationAlertTitle = "Notice"
    @State private var operationAlertMessage: String?
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
        let withSelectionObservers = applyingSelectionObservers(to: compositionView)
        let withEditorSheets = applyingEditorSheets(to: withSelectionObservers)
        return applyingImportAndAlert(to: withEditorSheets)
    }

    private var compositionView: some View {
        AppRootCompositionView(
            selectedSection: $selectedSection,
            contentViewForSection: contentView(for:),
            detailViewForSection: detailView(for:)
        )
    }

    private func applyingSelectionObservers<V: View>(to view: V) -> some View {
        var wrapped = AnyView(view)

        wrapped = applyChange(to: wrapped, of: selectedSection, perform: handleSectionChange)
        wrapped = applyChange(to: wrapped, of: selectedPurchaseID, perform: handlePurchaseIDChange)
        wrapped = applyChange(to: wrapped, of: selectedPurchase, perform: handlePurchaseChange)
        wrapped = applyChange(to: wrapped, of: selectedServiceRecordID, perform: handleServiceRecordIDChange)
        wrapped = applyChange(to: wrapped, of: selectedFaultRecordID, perform: handleFaultRecordIDChange)
        wrapped = applyChange(to: wrapped, of: selectedRepairRecordID, perform: handleRepairRecordIDChange)
        wrapped = applyChange(to: wrapped, of: selectedServiceRecord) { selectedServiceRecordID = $0?.persistentModelID }
        wrapped = applyChange(to: wrapped, of: selectedFaultRecord) { selectedFaultRecordID = $0?.persistentModelID }
        wrapped = applyChange(to: wrapped, of: selectedRepairRecord) { selectedRepairRecordID = $0?.persistentModelID }
        wrapped = applyChange(to: wrapped, of: selectedWarranty) { selectedWarrantyID = $0?.persistentModelID }
        wrapped = applyChange(to: wrapped, of: selectedReminder) { selectedReminderID = $0?.persistentModelID }
        wrapped = applyChange(to: wrapped, of: selectedWarrantyID, perform: handleWarrantyIDChange)
        wrapped = applyChange(to: wrapped, of: selectedReminderID, perform: handleReminderIDChange)
        wrapped = applyChange(to: wrapped, of: selectedInteractionID, perform: handleInteractionIDChange)
        wrapped = applyChange(to: wrapped, of: selectedInteraction) { selectedInteractionID = $0?.persistentModelID }
        wrapped = applyChange(to: wrapped, of: selectedComplaintID, perform: handleComplaintIDChange)
        wrapped = applyChange(to: wrapped, of: selectedComplaint) { selectedComplaintID = $0?.persistentModelID }
        wrapped = applyChange(to: wrapped, of: searchQuery) { _ in
            guard selectedSection == .search else { return }
            autoselectSearchPurchase()
        }
        wrapped = applyChange(to: wrapped, of: searchFilters) { _ in
            guard selectedSection == .search else { return }
            autoselectSearchPurchase()
        }
        wrapped = applyChange(to: wrapped, of: searchSortOption) { _ in
            guard selectedSection == .search else { return }
            autoselectSearchPurchase()
        }
        wrapped = AnyView(wrapped.onAppear(perform: handleOnAppear))

        return wrapped
    }

    private func applyingEditorSheets<V: View>(to view: V) -> some View {
        var wrapped = AnyView(view)

        wrapped = applySheet(to: wrapped, item: $purchaseEditorPresentation) { presentation in
            AppRootEditorSheetCoordinator.purchaseEditorSheet(presentation) { selectedPurchase = $0 }
        }
        wrapped = applySheet(to: wrapped, item: $serviceRecordEditorPresentation) { presentation in
            AppRootEditorSheetCoordinator.serviceRecordEditorSheet(presentation) { selectedServiceRecord = $0 }
        }
        wrapped = applySheet(to: wrapped, item: $faultRecordEditorPresentation) { presentation in
            AppRootEditorSheetCoordinator.faultRecordEditorSheet(presentation) { selectedFaultRecord = $0 }
        }
        wrapped = applySheet(to: wrapped, item: $repairRecordEditorPresentation) { presentation in
            AppRootEditorSheetCoordinator.repairRecordEditorSheet(presentation) { selectedRepairRecord = $0 }
        }
        wrapped = applySheet(to: wrapped, item: $warrantyEditorPresentation) { presentation in
            AppRootEditorSheetCoordinator.warrantyEditorSheet(presentation) { selectedWarranty = $0 }
        }
        wrapped = applySheet(to: wrapped, item: $reminderEditorPresentation) { presentation in
            AppRootEditorSheetCoordinator.reminderEditorSheet(presentation) { selectedReminder = $0 }
        }
        wrapped = applySheet(to: wrapped, item: $interactionEditorPresentation) { presentation in
            AppRootEditorSheetCoordinator.interactionEditorSheet(presentation) { selectedInteraction = $0 }
        }
        wrapped = applySheet(to: wrapped, item: $complaintEditorPresentation) { presentation in
            AppRootEditorSheetCoordinator.complaintEditorSheet(presentation) { selectedComplaint = $0 }
        }

        return wrapped
    }

    private func applyingImportAndAlert<V: View>(to view: V) -> some View {
        AnyView(
            view
                .fileImporter(
                    isPresented: $isShowingDocumentImporter,
                    allowedContentTypes: [.data, .pdf, .image, .plainText, .text],
                    allowsMultipleSelection: false
                ) { result in
                    handleDocumentImport(result: result)
                }
                .alert(operationAlertTitle, isPresented: operationAlertBinding, actions: {
                    Button("OK") { operationAlertMessage = nil }
                }, message: {
                    Text(operationAlertMessage ?? "Unknown error.")
                })
        )
    }

    private var operationAlertBinding: Binding<Bool> {
        Binding(
            get: { operationAlertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    operationAlertMessage = nil
                }
            }
        )
    }

    private func applyChange<Value: Equatable>(
        to view: AnyView,
        of value: Value,
        perform: @escaping (Value) -> Void
    ) -> AnyView {
        AnyView(view.onChange(of: value) { _, newValue in
            perform(newValue)
        })
    }

    private func applySheet<Item: Identifiable, Content: View>(
        to view: AnyView,
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> AnyView {
        AnyView(view.sheet(item: item, content: content))
    }

    private func handleSectionChange(_ newValue: AppSection?) {
        AppRootSelectionCoordinator.applySectionChange(
            newValue,
            clearPurchaseAndDocument: {
                selectedPurchase = nil
                selectedDocument = nil
            },
            autoselectPurchase: autoselectPurchase,
            autoselectSearch: autoselectSearchPurchase,
            autoselectServicing: {
                autoselectServiceRecord()
                autoselectFaultRecord()
                autoselectRepairRecord()
            },
            autoselectInteractions: autoselectInteraction,
            autoselectComplaints: autoselectComplaint,
            autoselectWarranties: autoselectWarranty,
            autoselectReminders: autoselectReminder,
            clearAll: clearAllSelections
        )
    }

    private func clearAllSelections() {
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

    private func handlePurchaseIDChange(_ newValue: PersistentIdentifier?) {
        guard let newValue else {
            selectedPurchase = nil
            return
        }
        lastSelectedPurchaseID = newValue
        selectedPurchase = purchases.first { $0.persistentModelID == newValue }
    }

    private func handlePurchaseChange(_ newValue: Purchase?) {
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
        let linkedSelections = AppRootSelectionCoordinator.linkedSelections(for: purchase)
        selectedDocument = linkedSelections.document
        selectedServiceRecord = linkedSelections.serviceRecord
        selectedFaultRecord = linkedSelections.faultRecord
        selectedRepairRecord = linkedSelections.repairRecord
        selectedWarranty = linkedSelections.warranty
        selectedReminder = linkedSelections.reminder
        selectedInteraction = linkedSelections.interaction
        selectedComplaint = linkedSelections.complaint
        selectedServiceRecordID = linkedSelections.serviceRecordID
        selectedFaultRecordID = linkedSelections.faultRecordID
        selectedRepairRecordID = linkedSelections.repairRecordID
        selectedWarrantyID = linkedSelections.warrantyID
        selectedReminderID = linkedSelections.reminderID
        selectedInteractionID = linkedSelections.interactionID
        selectedComplaintID = linkedSelections.complaintID
    }

    private func handleServiceRecordIDChange(_ newValue: PersistentIdentifier?) {
        guard let newValue else { selectedServiceRecord = nil; return }
        lastSelectedServiceRecordID = newValue
        selectedServiceRecord = serviceRecords.first { $0.persistentModelID == newValue }
    }

    private func handleFaultRecordIDChange(_ newValue: PersistentIdentifier?) {
        guard let newValue else { selectedFaultRecord = nil; return }
        lastSelectedFaultRecordID = newValue
        selectedFaultRecord = faultRecords.first { $0.persistentModelID == newValue }
    }

    private func handleRepairRecordIDChange(_ newValue: PersistentIdentifier?) {
        guard let newValue else { selectedRepairRecord = nil; return }
        lastSelectedRepairRecordID = newValue
        selectedRepairRecord = repairRecords.first { $0.persistentModelID == newValue }
    }

    private func handleWarrantyIDChange(_ newValue: PersistentIdentifier?) {
        guard let newValue else { selectedWarranty = nil; return }
        lastSelectedWarrantyID = newValue
        selectedWarranty = warranties.first { $0.persistentModelID == newValue }
    }

    private func handleReminderIDChange(_ newValue: PersistentIdentifier?) {
        guard let newValue else { selectedReminder = nil; return }
        lastSelectedReminderID = newValue
        selectedReminder = reminders.first { $0.persistentModelID == newValue }
    }

    private func handleInteractionIDChange(_ newValue: PersistentIdentifier?) {
        guard let newValue else { selectedInteraction = nil; return }
        lastSelectedInteractionID = newValue
        selectedInteraction = interactions.first { $0.persistentModelID == newValue }
    }

    private func handleComplaintIDChange(_ newValue: PersistentIdentifier?) {
        guard let newValue else { selectedComplaint = nil; return }
        lastSelectedComplaintID = newValue
        selectedComplaint = complaintCases.first { $0.persistentModelID == newValue }
    }

    private func contentView(for section: AppSection) -> AnyView {
        switch section {
        case .dashboard:
            return AnyView(dashboardSummaryView)
        case .search:
            return AnyView(searchListView)
        case .allPurchases:
            return AnyView(purchaseListView)
        case .servicing:
            return AnyView(servicingListView)
        case .interactions:
            return AnyView(interactionListView)
        case .complaints:
            return AnyView(complaintListView)
        case .warranties:
            return AnyView(warrantyListView)
        case .reminders:
            return AnyView(reminderListView)
        case .documents:
            return AnyView(
                List {
                    Text(section.contentPlaceholder)
                }
                .navigationTitle(section.title)
            )
        }
    }

    private func detailView(for section: AppSection) -> AnyView {
        switch section {
        case .dashboard:
            return AnyView(dashboardDetailView)
        case .search:
            return AnyView(purchaseDetailView)
        case .allPurchases:
            return AnyView(purchaseDetailView)
        case .servicing:
            return AnyView(servicingDetailView)
        case .interactions:
            return AnyView(interactionDetailView)
        case .complaints:
            return AnyView(complaintDetailView)
        case .warranties:
            return AnyView(warrantyDetailView)
        case .reminders:
            return AnyView(reminderDetailView)
        case .documents:
            return AnyView(
                ContentUnavailableView(
                    section.title,
                    systemImage: section.systemImage,
                    description: Text(section.detailPlaceholder)
                )
            )
        }
    }

    private var dashboardSummaryView: some View {
        DashboardSummaryView(
            totalPurchases: purchases.count,
            upcomingRemindersCount: dashboardUpcomingReminders.count,
            expiringWarrantiesCount: dashboardExpiringWarranties.count,
            overdueFollowUpsCount: dashboardOverdueFollowUps.count,
            unresolvedFaultsCount: dashboardUnresolvedFaults.count,
            activeRepairsCount: dashboardActiveRepairs.count,
            activeComplaintsCount: dashboardActiveComplaints.count,
            openPurchases: { selectedSection = .allPurchases },
            openReminders: { selectedSection = .reminders },
            openWarranties: { selectedSection = .warranties },
            openServicing: { selectedSection = .servicing },
            openInteractions: { selectedSection = .interactions },
            openComplaints: { selectedSection = .complaints }
        )
    }

    private var dashboardDetailView: some View {
        DashboardDetailView(
            recentPurchases: dashboardRecentPurchases,
            upcomingReminders: dashboardUpcomingReminders,
            expiringWarranties: dashboardExpiringWarranties,
            overdueFollowUps: dashboardOverdueFollowUps,
            serviceDueRecords: dashboardServiceDueRecords,
            unresolvedFaults: dashboardUnresolvedFaults,
            activeRepairs: dashboardActiveRepairs,
            activeComplaints: dashboardActiveComplaints,
            recentInteractions: dashboardRecentInteractions,
            recentDocuments: dashboardRecentDocuments,
            recentActivity: dashboardRecentActivity,
            formatDate: formattedDate,
            formatDateTime: formattedDateTime,
            openPurchase: openPurchaseFromDashboard,
            openReminder: openReminderFromDashboard,
            openWarranty: openWarrantyFromDashboard,
            openService: openServiceFromDashboard,
            openFault: openFaultFromDashboard,
            openRepair: openRepairFromDashboard,
            openComplaint: openComplaintFromDashboard,
            openInteraction: openInteractionFromDashboard,
            openDocument: openDocumentFromDashboard
        )
    }

    private var searchListView: some View {
        SearchListSectionView(
            results: searchResults,
            availableCategoryNames: searchCategoryNames,
            savedSearches: savedPurchaseSearches,
            selectedPurchaseID: $selectedPurchaseID,
            searchQuery: $searchQuery,
            filters: $searchFilters,
            sortOption: $searchSortOption,
            onSaveCurrentSearch: saveCurrentSearch,
            onApplySavedSearch: applySavedSearch,
            onDeleteSavedSearch: deleteSavedSearch
        )
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
                    .accessibilityIdentifier("purchaseRow.\(purchase.name)")
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

                Button("Export Backup") {
                    exportFullBackup()
                }
                .disabled(purchases.isEmpty)

                Button("Import Archive") {
                    importPurchaseArchive()
                }

                Button("Restore Backup") {
                    restoreFullBackup()
                }
            }
        }
    }

    private var warrantyListView: some View {
        WarrantyListSectionView(
            warranties: warranties,
            selectedWarrantyID: $selectedWarrantyID,
            selectedWarranty: selectedWarranty,
            onEditWarranty: {
                guard let selectedWarranty else { return }
                warrantyEditorPresentation = .edit(selectedWarranty)
            }
        )
    }

    private var interactionListView: some View {
        InteractionListSectionView(
            interactions: interactions,
            selectedInteractionID: $selectedInteractionID,
            selectedInteraction: selectedInteraction,
            formattedDateTime: formattedDateTime,
            onEditInteraction: {
                guard let selectedInteraction else { return }
                interactionEditorPresentation = .edit(selectedInteraction)
            }
        )
    }

    private var complaintListView: some View {
        ComplaintListSectionView(
            complaintCases: complaintCases,
            selectedComplaintID: $selectedComplaintID,
            selectedComplaint: selectedComplaint,
            onEditComplaint: {
                guard let selectedComplaint else { return }
                complaintEditorPresentation = .edit(selectedComplaint)
            }
        )
    }

    private var servicingListView: some View {
        ServicingListSectionView(
            serviceRecords: serviceRecords,
            faultRecords: faultRecords,
            repairRecords: repairRecords,
            selectedServiceRecord: selectedServiceRecord,
            selectedFaultRecord: selectedFaultRecord,
            selectedRepairRecord: selectedRepairRecord,
            isFaultSectionDropTargeted: $isFaultSectionDropTargeted,
            isRepairSectionDropTargeted: $isRepairSectionDropTargeted,
            onSelectServiceRecord: { selectedServiceRecord = $0 },
            onSelectFaultRecord: { selectedFaultRecord = $0 },
            onSelectRepairRecord: { selectedRepairRecord = $0 },
            onDragServiceRecord: { record in
                draggedServiceRecordID = record.persistentModelID
                return NSItemProvider(object: NSString(string: "service-record"))
            },
            onDragFaultRecord: { fault in
                draggedFaultRecordID = fault.persistentModelID
                draggedServiceRecordID = nil
                return NSItemProvider(object: NSString(string: "fault-record"))
            },
            onDropServiceToFault: handleServiceToFaultDrop,
            onDropFaultToRepair: handleFaultToRepairDrop,
            onEditService: {
                guard let selectedServiceRecord else { return }
                serviceRecordEditorPresentation = .edit(selectedServiceRecord)
            },
            onEditFault: {
                guard let selectedFaultRecord else { return }
                faultRecordEditorPresentation = .edit(selectedFaultRecord)
            },
            onEditRepair: {
                guard let selectedRepairRecord else { return }
                repairRecordEditorPresentation = .edit(selectedRepairRecord)
            }
        )
    }

    private var reminderListView: some View {
        ReminderListSectionView(
            reminders: reminders,
            selectedReminderID: $selectedReminderID,
            selectedReminder: selectedReminder,
            formattedDateTime: formattedDateTime,
            onEditReminder: {
                guard let selectedReminder else { return }
                reminderEditorPresentation = .edit(selectedReminder)
            }
        )
    }

    private var purchaseDetailView: some View {
        PurchaseDetailSectionView(
            purchase: selectedPurchase,
            timelineFilter: $timelineFilter,
            selectedWarranty: selectedWarranty,
            selectedReminder: selectedReminder,
            selectedInteraction: selectedInteraction,
            selectedComplaint: selectedComplaint,
            selectedServiceRecord: selectedServiceRecord,
            selectedFaultRecord: selectedFaultRecord,
            selectedRepairRecord: selectedRepairRecord,
            selectedDocument: selectedDocument,
            formattedDate: formattedDate,
            formattedDateTime: formattedDateTime,
            formattedPrice: formattedPrice,
            formattedUsefulLife: formattedUsefulLife,
            formattedTags: formattedTags,
            formattedWarrantySubtitle: formattedWarrantySubtitle,
            formattedReminderSubtitle: formattedReminderSubtitle,
            formattedInteractionSubtitle: formattedInteractionSubtitle,
            formattedComplaintSubtitle: formattedComplaintSubtitle,
            formattedServiceSubtitle: formattedServiceSubtitle,
            formattedFaultSubtitle: formattedFaultSubtitle,
            formattedRepairSubtitle: formattedRepairSubtitle,
            onSelectWarranty: { selectedWarranty = $0 },
            onSelectReminder: { selectedReminder = $0 },
            onAddInteraction: {
                guard let purchase = selectedPurchase else { return }
                interactionEditorPresentation = .new(purchase)
            },
            onSelectInteraction: { selectedInteraction = $0 },
            onAddComplaint: {
                guard let purchase = selectedPurchase else { return }
                complaintEditorPresentation = .new(purchase)
            },
            onSelectComplaint: { selectedComplaint = $0 },
            onAddService: {
                guard let purchase = selectedPurchase else { return }
                serviceRecordEditorPresentation = .new(purchase)
            },
            onSelectService: { selectedServiceRecord = $0 },
            onAddFault: {
                guard let purchase = selectedPurchase else { return }
                faultRecordEditorPresentation = .new(purchase)
            },
            onSelectFault: { selectedFaultRecord = $0 },
            onAddRepair: {
                guard let purchase = selectedPurchase else { return }
                repairRecordEditorPresentation = .new(purchase)
            },
            onSelectRepair: { selectedRepairRecord = $0 },
            onSelectDocument: { selectedDocument = $0 },
            onAddWarranty: {
                guard let purchase = selectedPurchase else { return }
                warrantyEditorPresentation = .new(purchase)
            },
            onEditWarranty: {
                guard let selectedWarranty else { return }
                warrantyEditorPresentation = .edit(selectedWarranty)
            },
            onAddReminder: {
                guard let purchase = selectedPurchase else { return }
                reminderEditorPresentation = .new(purchase)
            },
            onEditReminder: {
                guard let selectedReminder else { return }
                reminderEditorPresentation = .edit(selectedReminder)
            },
            onEditInteraction: {
                guard let selectedInteraction else { return }
                interactionEditorPresentation = .edit(selectedInteraction)
            },
            onEditComplaint: {
                guard let selectedComplaint else { return }
                complaintEditorPresentation = .edit(selectedComplaint)
            },
            onEditService: {
                guard let selectedServiceRecord else { return }
                serviceRecordEditorPresentation = .edit(selectedServiceRecord)
            },
            onEditFault: {
                guard let selectedFaultRecord else { return }
                faultRecordEditorPresentation = .edit(selectedFaultRecord)
            },
            onEditRepair: {
                guard let selectedRepairRecord else { return }
                repairRecordEditorPresentation = .edit(selectedRepairRecord)
            },
            onOpenDocument: openSelectedDocument,
            onExportReport: exportSelectedPurchaseReport,
            onExportArchive: exportSelectedPurchaseArchive
        )
    }

    private var warrantyDetailView: some View {
        WarrantyDetailSectionView(
            warranty: selectedWarranty,
            formattedDate: formattedDate
        )
    }

    private var interactionDetailView: some View {
        InteractionDetailSectionView(
            interaction: selectedInteraction,
            formattedDate: formattedDate,
            formattedDateTime: formattedDateTime
        )
    }

    private var complaintDetailView: some View {
        ComplaintDetailSectionView(
            complaint: selectedComplaint,
            formattedDate: formattedDate,
            formattedDateTime: formattedDateTime
        )
    }

    private var servicingDetailView: some View {
        ServicingDetailSectionView(
            selectedServiceRecord: selectedServiceRecord,
            selectedFaultRecord: selectedFaultRecord,
            selectedRepairRecord: selectedRepairRecord,
            formattedDate: formattedDate,
            formattedDateTime: formattedDateTime,
            formattedPrice: formattedPrice
        )
    }

    private var reminderDetailView: some View {
        ReminderDetailSectionView(
            reminder: selectedReminder,
            formattedDateTime: formattedDateTime,
            formattedReminderState: formattedReminderState
        )
    }

    private var dashboardRecentPurchases: [Purchase] {
        DashboardService.recentPurchases(from: purchases)
    }

    private var dashboardUpcomingReminders: [Reminder] {
        DashboardService.upcomingReminders(from: reminders)
    }

    private var dashboardExpiringWarranties: [Warranty] {
        DashboardService.warrantiesNearingExpiry(from: warranties)
    }

    private var dashboardOverdueFollowUps: [Interaction] {
        DashboardService.overdueFollowUps(from: interactions)
    }

    private var dashboardServiceDueRecords: [ServiceRecord] {
        DashboardService.serviceDueDates(from: serviceRecords)
    }

    private var dashboardUnresolvedFaults: [FaultRecord] {
        DashboardService.unresolvedFaults(from: faultRecords)
    }

    private var dashboardActiveRepairs: [RepairRecord] {
        DashboardService.activeRepairs(from: repairRecords)
    }

    private var dashboardActiveComplaints: [ComplaintCase] {
        DashboardService.activeComplaints(from: complaintCases)
    }

    private var dashboardRecentInteractions: [Interaction] {
        DashboardService.recentInteractions(from: interactions)
    }

    private var dashboardRecentDocuments: [StoredDocument] {
        DashboardService.recentlyAddedDocuments(from: purchases)
    }

    private var dashboardRecentActivity: [DashboardService.ActivityEntry] {
        DashboardService.recentActivity(from: purchases)
    }

    private func openPurchaseFromDashboard(_ purchase: Purchase) {
        selectedSection = .allPurchases
        selectedPurchase = purchase
    }

    private func openReminderFromDashboard(_ reminder: Reminder) {
        selectedSection = .reminders
        selectedReminder = reminder
    }

    private func openWarrantyFromDashboard(_ warranty: Warranty) {
        selectedSection = .warranties
        selectedWarranty = warranty
    }

    private func openServiceFromDashboard(_ service: ServiceRecord) {
        selectedSection = .servicing
        selectedServiceRecord = service
    }

    private func openFaultFromDashboard(_ fault: FaultRecord) {
        selectedSection = .servicing
        selectedFaultRecord = fault
    }

    private func openRepairFromDashboard(_ repair: RepairRecord) {
        selectedSection = .servicing
        selectedRepairRecord = repair
    }

    private func openComplaintFromDashboard(_ complaint: ComplaintCase) {
        selectedSection = .complaints
        selectedComplaint = complaint
    }

    private func openInteractionFromDashboard(_ interaction: Interaction) {
        selectedSection = .interactions
        selectedInteraction = interaction
    }

    private func openDocumentFromDashboard(_ document: StoredDocument) {
        selectedSection = .allPurchases
        selectedPurchase = document.purchase
        selectedDocument = document
    }

    private var searchResults: [Purchase] {
        PurchaseSearchService.search(
            purchases: purchases,
            query: searchQuery,
            filters: searchFilters,
            sortOption: searchSortOption
        )
    }

    private var searchCategoryNames: [String] {
        Array(Set(purchases.compactMap { $0.category?.name }))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func loadSavedSearchesIfNeeded() {
        guard !hasLoadedSavedPurchaseSearches else { return }
        savedPurchaseSearches = PurchaseSearchService.decodeSavedSearches(from: savedPurchaseSearchesJSON)
        hasLoadedSavedPurchaseSearches = true
    }

    private func persistSavedSearches() {
        savedPurchaseSearchesJSON = PurchaseSearchService.encodeSavedSearches(savedPurchaseSearches)
    }

    private func saveCurrentSearch() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchName: String

        if trimmedQuery.isEmpty {
            searchName = "Saved Search \(savedPurchaseSearches.count + 1)"
        } else {
            searchName = trimmedQuery
        }

        let saved = SavedPurchaseSearch(
            name: searchName,
            query: searchQuery,
            filters: searchFilters,
            sortOption: searchSortOption
        )

        savedPurchaseSearches.insert(saved, at: 0)
        persistSavedSearches()
    }

    private func applySavedSearch(_ saved: SavedPurchaseSearch) {
        searchQuery = saved.query
        searchFilters = saved.filters
        searchSortOption = saved.sortOption
        if selectedSection == .search {
            autoselectSearchPurchase()
        }
    }

    private func deleteSavedSearch(_ saved: SavedPurchaseSearch) {
        savedPurchaseSearches.removeAll { $0.id == saved.id }
        persistSavedSearches()
    }

    private func formattedDate(_ value: Date?) -> String {
        AppRootFormatting.formattedDate(value)
    }

    private func formattedDateTime(_ value: Date?, includeTime: Bool) -> String {
        AppRootFormatting.formattedDateTime(value, includeTime: includeTime)
    }

    private func formattedPrice(amount: Decimal?, currencyCode: String?) -> String {
        AppRootFormatting.formattedPrice(amount: amount, currencyCode: currencyCode)
    }

    private func formattedUsefulLife(months: Int?, notes: String?) -> String {
        AppRootFormatting.formattedUsefulLife(months: months, notes: notes)
    }

    private func formattedTags(_ tags: [Tag]) -> String {
        AppRootFormatting.formattedTags(tags)
    }

    private func formattedWarrantySubtitle(_ warranty: Warranty) -> String {
        AppRootFormatting.formattedWarrantySubtitle(warranty)
    }

    private func formattedReminderSubtitle(_ reminder: Reminder) -> String {
        AppRootFormatting.formattedReminderSubtitle(reminder)
    }

    private func formattedInteractionSubtitle(_ interaction: Interaction) -> String {
        AppRootFormatting.formattedInteractionSubtitle(interaction)
    }

    private func formattedComplaintSubtitle(_ complaint: ComplaintCase) -> String {
        AppRootFormatting.formattedComplaintSubtitle(complaint)
    }

    private func formattedServiceSubtitle(_ record: ServiceRecord) -> String {
        AppRootFormatting.formattedServiceSubtitle(record)
    }

    private func formattedFaultSubtitle(_ fault: FaultRecord) -> String {
        AppRootFormatting.formattedFaultSubtitle(fault)
    }

    private func formattedRepairSubtitle(_ repair: RepairRecord) -> String {
        AppRootFormatting.formattedRepairSubtitle(repair)
    }

    private func formattedReminderState(_ reminder: Reminder) -> String {
        AppRootFormatting.formattedReminderState(reminder)
    }

    private func handleOnAppear() {
        loadSavedSearchesIfNeeded()

        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            selectedSection = .allPurchases
            autoselectPurchase()
            return
        }

        switch selectedSection {
        case .allPurchases:
            autoselectPurchase()
        case .search:
            autoselectSearchPurchase()
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

    private func autoselectSearchPurchase() {
        selectedPurchaseID = AppRootWorkflowCoordinator.autoselectID(
            in: searchResults,
            lastSelectedID: lastSelectedPurchaseID
        )
        if selectedPurchaseID == nil { selectedPurchase = nil }
    }

    private func autoselectPurchase() {
        selectedPurchaseID = AppRootWorkflowCoordinator.autoselectID(
            in: purchases,
            lastSelectedID: lastSelectedPurchaseID
        )
        if selectedPurchaseID == nil { selectedPurchase = nil }
    }

    private func autoselectServiceRecord() {
        selectedServiceRecordID = AppRootWorkflowCoordinator.autoselectID(
            in: serviceRecords,
            lastSelectedID: lastSelectedServiceRecordID
        )
        if selectedServiceRecordID == nil { selectedServiceRecord = nil }
    }

    private func autoselectFaultRecord() {
        selectedFaultRecordID = AppRootWorkflowCoordinator.autoselectID(
            in: faultRecords,
            lastSelectedID: lastSelectedFaultRecordID
        )
        if selectedFaultRecordID == nil { selectedFaultRecord = nil }
    }

    private func autoselectRepairRecord() {
        selectedRepairRecordID = AppRootWorkflowCoordinator.autoselectID(
            in: repairRecords,
            lastSelectedID: lastSelectedRepairRecordID
        )
        if selectedRepairRecordID == nil { selectedRepairRecord = nil }
    }

    private func autoselectWarranty() {
        selectedWarrantyID = AppRootWorkflowCoordinator.autoselectID(
            in: warranties,
            lastSelectedID: lastSelectedWarrantyID
        )
        if selectedWarrantyID == nil { selectedWarranty = nil }
    }

    private func autoselectReminder() {
        selectedReminderID = AppRootWorkflowCoordinator.autoselectID(
            in: reminders,
            lastSelectedID: lastSelectedReminderID
        )
        if selectedReminderID == nil { selectedReminder = nil }
    }

    private func autoselectInteraction() {
        selectedInteractionID = AppRootWorkflowCoordinator.autoselectID(
            in: interactions,
            lastSelectedID: lastSelectedInteractionID
        )
        if selectedInteractionID == nil { selectedInteraction = nil }
    }

    private func autoselectComplaint() {
        selectedComplaintID = AppRootWorkflowCoordinator.autoselectID(
            in: complaintCases,
            lastSelectedID: lastSelectedComplaintID
        )
        if selectedComplaintID == nil { selectedComplaint = nil }
    }

    private func handleServiceToFaultDrop() -> Bool {
        defer { draggedServiceRecordID = nil }
        guard let faultRecord = AppRootWorkflowCoordinator.applyServiceToFaultConversion(
            draggedServiceRecordID: draggedServiceRecordID,
            serviceRecords: serviceRecords,
            modelContext: modelContext
        ) else {
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
        guard let repairRecord = AppRootWorkflowCoordinator.applyFaultToRepairConversion(
            draggedFaultRecordID: draggedFaultRecordID,
            faultRecords: faultRecords,
            modelContext: modelContext
        ) else {
            return false
        }

        selectedRepairRecord = repairRecord
        selectedRepairRecordID = repairRecord.persistentModelID
        repairRecordEditorPresentation = .edit(repairRecord)
        return true
    }

    private func handleDocumentImport(result: Result<[URL], Error>) {
        guard let purchase = selectedPurchase else { return }

        do {
            selectedDocument = try AppRootWorkflowCoordinator.importDocument(
                from: result,
                into: purchase
            )
        } catch {
            operationAlertTitle = "Document Import Error"
            operationAlertMessage = error.localizedDescription
        }
    }

    private func openSelectedDocument() {
        guard let selectedDocument else { return }

        do {
            try AppRootWorkflowCoordinator.openDocument(selectedDocument)
        } catch {
            operationAlertTitle = "Document Open Error"
            operationAlertMessage = error.localizedDescription
        }
    }

    private func exportSelectedPurchaseReport() {
        guard let selectedPurchase else { return }

        do {
            let url = try AppRootWorkflowCoordinator.exportPurchaseReport(selectedPurchase)
            operationAlertTitle = "Report Exported"
            operationAlertMessage = "Saved to \(url.path)"
        } catch {
            if let workflowError = error as? AppRootWorkflowCoordinator.ExportWorkflowError,
               workflowError == .cancelled {
                return
            }
            operationAlertTitle = "Export Error"
            operationAlertMessage = error.localizedDescription
        }
    }

    private func exportSelectedPurchaseArchive() {
        guard let selectedPurchase else { return }

        do {
            let url = try AppRootWorkflowCoordinator.exportPurchaseArchive(selectedPurchase)
            let validationIssues = AppRootWorkflowCoordinator.validatePurchaseArchive(at: url)
            operationAlertTitle = validationIssues.isEmpty ? "Archive Exported" : "Archive Exported With Issues"
            if validationIssues.isEmpty {
                operationAlertMessage = "Saved to \(url.path)"
            } else {
                operationAlertMessage = "Saved to \(url.path)\n\n\(validationIssues.joined(separator: "\n"))"
            }
        } catch {
            if let workflowError = error as? AppRootWorkflowCoordinator.ExportWorkflowError,
               workflowError == .cancelled {
                return
            }
            operationAlertTitle = "Export Error"
            operationAlertMessage = error.localizedDescription
        }
    }

    private func exportFullBackup() {
        do {
            let url = try AppRootWorkflowCoordinator.exportFullBackup(purchases: purchases)
            let validationIssues = AppRootWorkflowCoordinator.validateBackup(at: url)
            operationAlertTitle = validationIssues.isEmpty ? "Backup Exported" : "Backup Exported With Issues"
            if validationIssues.isEmpty {
                operationAlertMessage = "Saved to \(url.path)"
            } else {
                operationAlertMessage = "Saved to \(url.path)\n\n\(validationIssues.joined(separator: "\n"))"
            }
        } catch {
            if let workflowError = error as? AppRootWorkflowCoordinator.ExportWorkflowError,
               workflowError == .cancelled {
                return
            }
            operationAlertTitle = "Backup Error"
            operationAlertMessage = error.localizedDescription
        }
    }

    private func importPurchaseArchive() {
        do {
            let importedPurchase = try AppRootWorkflowCoordinator.importPurchaseArchive()
            modelContext.insert(importedPurchase)
            try modelContext.save()
            selectedSection = .allPurchases
            selectedPurchase = importedPurchase
            operationAlertTitle = "Archive Imported"
            operationAlertMessage = "Imported purchase: \(importedPurchase.name)"
        } catch {
            if let workflowError = error as? AppRootWorkflowCoordinator.ExportWorkflowError,
               workflowError == .cancelled {
                return
            }
            operationAlertTitle = "Import Error"
            operationAlertMessage = error.localizedDescription
        }
    }

    private func restoreFullBackup() {
        do {
            let restoredPurchases = try AppRootWorkflowCoordinator.restoreFullBackup()
            for purchase in restoredPurchases {
                modelContext.insert(purchase)
            }
            try modelContext.save()
            selectedSection = .allPurchases
            if let firstPurchase = restoredPurchases.first {
                selectedPurchase = firstPurchase
            }
            operationAlertTitle = "Backup Restored"
            operationAlertMessage = "Imported \(restoredPurchases.count) purchase(s)."
        } catch {
            if let workflowError = error as? AppRootWorkflowCoordinator.ExportWorkflowError,
               workflowError == .cancelled {
                return
            }
            operationAlertTitle = "Restore Error"
            operationAlertMessage = error.localizedDescription
        }
    }
}

#Preview {
    AppRootView()
}
