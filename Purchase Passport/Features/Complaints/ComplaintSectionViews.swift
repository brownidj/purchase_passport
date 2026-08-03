import SwiftUI
import SwiftData

struct ComplaintListSectionView: View {
    let complaintCases: [ComplaintCase]
    @Binding var selectedComplaintID: PersistentIdentifier?
    let selectedComplaint: ComplaintCase?
    let onEditComplaint: () -> Void

    var body: some View {
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
                Button("Edit Complaint", action: onEditComplaint)
                    .disabled(selectedComplaint == nil)
            }
        }
    }
}

struct ComplaintDetailSectionView: View {
    let complaint: ComplaintCase?
    let formattedDate: (Date?) -> String
    let formattedDateTime: (Date?, Bool) -> String

    var body: some View {
        Group {
            if let complaint {
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
                        LabeledContent("Response Deadline", value: formattedDateTime(complaint.responseDeadline, false))
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
                                    Text("\(formattedDateTime(entry.date, true)) • \(entry.details)")
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
}
