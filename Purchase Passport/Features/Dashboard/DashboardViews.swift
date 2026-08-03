import SwiftUI

struct DashboardSummaryView: View {
    let totalPurchases: Int
    let upcomingRemindersCount: Int
    let expiringWarrantiesCount: Int
    let overdueFollowUpsCount: Int
    let unresolvedFaultsCount: Int
    let activeRepairsCount: Int
    let activeComplaintsCount: Int

    let openPurchases: () -> Void
    let openReminders: () -> Void
    let openWarranties: () -> Void
    let openServicing: () -> Void
    let openInteractions: () -> Void
    let openComplaints: () -> Void

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Total Purchases", value: "\(totalPurchases)")
                LabeledContent("Upcoming Reminders", value: "\(upcomingRemindersCount)")
                LabeledContent("Warranties Near Expiry", value: "\(expiringWarrantiesCount)")
                LabeledContent("Overdue Follow-ups", value: "\(overdueFollowUpsCount)")
                LabeledContent("Unresolved Faults", value: "\(unresolvedFaultsCount)")
                LabeledContent("Active Repairs", value: "\(activeRepairsCount)")
                LabeledContent("Active Complaints", value: "\(activeComplaintsCount)")
            }

            Section("Quick Navigation") {
                Button("Open Purchases", action: openPurchases)
                Button("Open Reminders", action: openReminders)
                Button("Open Warranties", action: openWarranties)
                Button("Open Servicing", action: openServicing)
                Button("Open Interactions", action: openInteractions)
                Button("Open Complaints", action: openComplaints)
            }
        }
        .navigationTitle("Dashboard")
    }
}

struct DashboardDetailView: View {
    let recentPurchases: [Purchase]
    let upcomingReminders: [Reminder]
    let expiringWarranties: [Warranty]
    let overdueFollowUps: [Interaction]
    let serviceDueRecords: [ServiceRecord]
    let unresolvedFaults: [FaultRecord]
    let activeRepairs: [RepairRecord]
    let activeComplaints: [ComplaintCase]
    let recentInteractions: [Interaction]
    let recentDocuments: [StoredDocument]
    let recentActivity: [DashboardService.ActivityEntry]

    let formatDate: (Date?) -> String
    let formatDateTime: (Date?, Bool) -> String

    let openPurchase: (Purchase) -> Void
    let openReminder: (Reminder) -> Void
    let openWarranty: (Warranty) -> Void
    let openService: (ServiceRecord) -> Void
    let openFault: (FaultRecord) -> Void
    let openRepair: (RepairRecord) -> Void
    let openComplaint: (ComplaintCase) -> Void
    let openInteraction: (Interaction) -> Void
    let openDocument: (StoredDocument) -> Void

    var body: some View {
        List {
            Section("Recent Purchases") {
                if recentPurchases.isEmpty {
                    Text("No recent purchases")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recentPurchases) { purchase in
                        Button {
                            openPurchase(purchase)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(purchase.name)
                                Text("Status: \(purchase.status.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Upcoming Reminders") {
                if upcomingReminders.isEmpty {
                    Text("No upcoming reminders")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(upcomingReminders) { reminder in
                        Button {
                            openReminder(reminder)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reminder.title)
                                Text(formatDateTime(reminder.dueDate, reminder.hasSpecificTime))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Warranties Nearing Expiry") {
                if expiringWarranties.isEmpty {
                    Text("No warranties nearing expiry")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(expiringWarranties) { warranty in
                        Button {
                            openWarranty(warranty)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(warranty.title)
                                Text("Ends: \(formatDate(warranty.endDate))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Overdue Follow-ups") {
                if overdueFollowUps.isEmpty {
                    Text("No overdue follow-ups")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(overdueFollowUps) { interaction in
                        Button {
                            openInteraction(interaction)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(interaction.subject)
                                Text("Follow-up: \(formatDate(interaction.followUpDate))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Service Due Dates") {
                if serviceDueRecords.isEmpty {
                    Text("No service due dates in the next 30 days")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(serviceDueRecords) { service in
                        Button {
                            openService(service)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(service.serviceType)
                                Text("Next service: \(formatDate(service.nextServiceDate))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Unresolved Faults") {
                if unresolvedFaults.isEmpty {
                    Text("No unresolved faults")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(unresolvedFaults) { fault in
                        Button {
                            openFault(fault)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fault.title)
                                Text("Status: \(fault.status.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Active Repairs") {
                if activeRepairs.isEmpty {
                    Text("No active repairs")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeRepairs) { repair in
                        Button {
                            openRepair(repair)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(repair.diagnosis ?? "Repair")
                                Text("Follow-up required: \(repair.followUpRequired ? "Yes" : "No")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Active Complaints") {
                if activeComplaints.isEmpty {
                    Text("No active complaints")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeComplaints) { complaint in
                        Button {
                            openComplaint(complaint)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(complaint.title)
                                Text("Status: \(complaint.status.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Recent Interactions") {
                if recentInteractions.isEmpty {
                    Text("No recent interactions")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recentInteractions) { interaction in
                        Button {
                            openInteraction(interaction)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(interaction.subject)
                                Text(formatDateTime(interaction.occurredAt, true))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Recently Added Documents") {
                if recentDocuments.isEmpty {
                    Text("No recent documents")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recentDocuments) { document in
                        Button {
                            openDocument(document)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(document.title)
                                Text("Added: \(formatDate(document.dateAdded))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Recent Activity") {
                if recentActivity.isEmpty {
                    Text("No recent activity")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recentActivity) { activity in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.title)
                            Text("\(formatDateTime(activity.date, true)) • \(activity.purchaseName) • \(activity.details)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Actionable Overview")
    }
}
