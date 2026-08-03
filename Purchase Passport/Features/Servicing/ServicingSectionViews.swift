import SwiftUI
import UniformTypeIdentifiers

struct ServicingListSectionView: View {
    let serviceRecords: [ServiceRecord]
    let faultRecords: [FaultRecord]
    let repairRecords: [RepairRecord]

    let selectedServiceRecord: ServiceRecord?
    let selectedFaultRecord: FaultRecord?
    let selectedRepairRecord: RepairRecord?

    @Binding var isFaultSectionDropTargeted: Bool
    @Binding var isRepairSectionDropTargeted: Bool

    let onSelectServiceRecord: (ServiceRecord) -> Void
    let onSelectFaultRecord: (FaultRecord) -> Void
    let onSelectRepairRecord: (RepairRecord) -> Void

    let onDragServiceRecord: (ServiceRecord) -> NSItemProvider
    let onDragFaultRecord: (FaultRecord) -> NSItemProvider

    let onDropServiceToFault: () -> Bool
    let onDropFaultToRepair: () -> Bool

    let onEditService: () -> Void
    let onEditFault: () -> Void
    let onEditRepair: () -> Void

    var body: some View {
        List {
            Section("Service Records") {
                if serviceRecords.isEmpty {
                    Text("No service records")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(serviceRecords) { record in
                        Button {
                            onSelectServiceRecord(record)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.serviceType)
                                Text(record.purchase?.name ?? "Unlinked Purchase")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .onDrag { onDragServiceRecord(record) }
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
                            onSelectFaultRecord(fault)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fault.title)
                                Text(fault.purchase?.name ?? "Unlinked Purchase")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .onDrag { onDragFaultRecord(fault) }
                    }
                }
            }
            .onDrop(of: [.text], isTargeted: $isFaultSectionDropTargeted) { _ in
                onDropServiceToFault()
            }

            Section("Repairs") {
                if repairRecords.isEmpty {
                    Text("No repairs")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(repairRecords) { repair in
                        Button {
                            onSelectRepairRecord(repair)
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
                onDropFaultToRepair()
            }
        }
        .navigationTitle("Servicing and Repairs")
        .toolbar {
            ToolbarItemGroup {
                Button("Edit Service", action: onEditService)
                    .disabled(selectedServiceRecord == nil)

                Button("Edit Fault", action: onEditFault)
                    .disabled(selectedFaultRecord == nil)

                Button("Edit Repair", action: onEditRepair)
                    .disabled(selectedRepairRecord == nil)
            }
        }
    }
}

struct ServicingDetailSectionView: View {
    let selectedServiceRecord: ServiceRecord?
    let selectedFaultRecord: FaultRecord?
    let selectedRepairRecord: RepairRecord?

    let formattedDate: (Date?) -> String
    let formattedDateTime: (Date?, Bool) -> String
    let formattedPrice: (Decimal?, String?) -> String

    var body: some View {
        List {
            Section("Selected Service Record") {
                if let record = selectedServiceRecord {
                    LabeledContent("Service Type", value: record.serviceType)
                    LabeledContent("Provider", value: record.serviceProvider ?? "Not set")
                    LabeledContent("Service Date", value: formattedDate(record.serviceDate))
                    LabeledContent("Completion Date", value: formattedDate(record.completionDate))
                    LabeledContent("Cost", value: formattedPrice(record.costAmount, record.currencyCode))
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
                    LabeledContent("First Noticed", value: formattedDateTime(fault.firstNoticedDate, false))
                    LabeledContent("Effect On Use", value: fault.effectOnUse ?? "Not set")
                } else {
                    Text("No fault selected")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Selected Repair") {
                if let repair = selectedRepairRecord {
                    LabeledContent("Diagnosis", value: repair.diagnosis ?? "Not set")
                    LabeledContent("Repair Date", value: formattedDateTime(repair.repairDate, false))
                    LabeledContent("Provider", value: repair.repairProvider ?? "Not set")
                    LabeledContent("Total Cost", value: formattedPrice(repair.totalCost, repair.currencyCode))
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
}
