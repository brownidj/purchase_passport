import SwiftUI
import SwiftData

struct WarrantyListSectionView: View {
    let warranties: [Warranty]
    @Binding var selectedWarrantyID: PersistentIdentifier?
    let selectedWarranty: Warranty?
    let onEditWarranty: () -> Void

    var body: some View {
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
                Button("Edit Warranty", action: onEditWarranty)
                    .disabled(selectedWarranty == nil)
            }
        }
    }
}

struct WarrantyDetailSectionView: View {
    let warranty: Warranty?
    let formattedDate: (Date?) -> String

    var body: some View {
        Group {
            if let warranty {
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
}
