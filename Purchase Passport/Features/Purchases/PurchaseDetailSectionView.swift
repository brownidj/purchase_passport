import SwiftUI
import SwiftData

struct PurchaseDetailSectionView: View {
    let purchase: Purchase?

    @Binding var timelineFilter: TimelineFilter

    let selectedWarranty: Warranty?
    let selectedReminder: Reminder?
    let selectedInteraction: Interaction?
    let selectedComplaint: ComplaintCase?
    let selectedServiceRecord: ServiceRecord?
    let selectedFaultRecord: FaultRecord?
    let selectedRepairRecord: RepairRecord?
    let selectedDocument: StoredDocument?

    let formattedDate: (Date?) -> String
    let formattedDateTime: (Date?, Bool) -> String
    let formattedPrice: (Decimal?, String?) -> String
    let formattedUsefulLife: (Int?, String?) -> String
    let formattedTags: ([Tag]) -> String
    let formattedWarrantySubtitle: (Warranty) -> String
    let formattedReminderSubtitle: (Reminder) -> String
    let formattedInteractionSubtitle: (Interaction) -> String
    let formattedComplaintSubtitle: (ComplaintCase) -> String
    let formattedServiceSubtitle: (ServiceRecord) -> String
    let formattedFaultSubtitle: (FaultRecord) -> String
    let formattedRepairSubtitle: (RepairRecord) -> String

    let onSelectWarranty: (Warranty) -> Void
    let onSelectReminder: (Reminder) -> Void
    let onAddInteraction: () -> Void
    let onSelectInteraction: (Interaction) -> Void
    let onAddComplaint: () -> Void
    let onSelectComplaint: (ComplaintCase) -> Void
    let onAddService: () -> Void
    let onSelectService: (ServiceRecord) -> Void
    let onAddFault: () -> Void
    let onSelectFault: (FaultRecord) -> Void
    let onAddRepair: () -> Void
    let onSelectRepair: (RepairRecord) -> Void
    let onSelectDocument: (StoredDocument) -> Void

    let onAddWarranty: () -> Void
    let onEditWarranty: () -> Void
    let onAddReminder: () -> Void
    let onEditReminder: () -> Void
    let onEditInteraction: () -> Void
    let onEditComplaint: () -> Void
    let onEditService: () -> Void
    let onEditFault: () -> Void
    let onEditRepair: () -> Void
    let onOpenDocument: () -> Void
    let onExportReport: () -> Void
    let onExportPDFReport: () -> Void
    let onExportArchive: () -> Void

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

                    Section("Financial") {
                        LabeledContent("Purchase Price", value: formattedPrice(purchase.purchasePrice, purchase.currencyCode))
                        LabeledContent("Currency", value: purchase.currencyCode ?? "Not set")
                    }

                    Section("Details") {
                        LabeledContent("Provider", value: purchase.provider?.name ?? "Not set")
                        LabeledContent("Seller", value: purchase.seller ?? "Not set")
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
                            }
                        }
                    }

                    Section("Interactions") {
                        Button("Add Interaction", action: onAddInteraction)

                        if purchase.interactions.isEmpty {
                            Text("No interactions attached")
                                .foregroundStyle(.secondary)
                        } else {
                            let items = purchase.interactions.sorted(by: { $0.occurredAt > $1.occurredAt })
                            ForEach(items) { interaction in
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
                            }
                        }
                    }

                    Section("Complaints and Disputes") {
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
                            }
                        }
                    }

                    Section("Service History") {
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
                            }
                        }
                    }

                    Section("Faults") {
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
                            }
                        }
                    }

                    Section("Repairs") {
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
                                    Text("\(formattedDateTime(entry.date, true)) • \(entry.details)")
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
}
