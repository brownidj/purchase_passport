import SwiftUI

enum AppRootEditorSheetCoordinator {
    @ViewBuilder
    static func purchaseEditorSheet(
        _ presentation: PurchaseEditorPresentation,
        onSave: @escaping (Purchase) -> Void
    ) -> some View {
        switch presentation {
        case .new:
            PurchaseEditorView(mode: .create, onCommit: onSave)
                .frame(minWidth: 700, minHeight: 700)
        case .edit(let purchase):
            PurchaseEditorView(mode: .edit(purchase), onCommit: onSave)
                .frame(minWidth: 700, minHeight: 700)
        }
    }

    @ViewBuilder
    static func serviceRecordEditorSheet(
        _ presentation: ServiceRecordEditorPresentation,
        onSave: @escaping (ServiceRecord) -> Void
    ) -> some View {
        switch presentation {
        case .new(let purchase):
            ServiceRecordEditorView(mode: .create(purchase: purchase), onCommit: onSave)
                .frame(minWidth: 700, minHeight: 680)
        case .edit(let record):
            ServiceRecordEditorView(mode: .edit(record), onCommit: onSave)
                .frame(minWidth: 700, minHeight: 680)
        }
    }

    @ViewBuilder
    static func faultRecordEditorSheet(
        _ presentation: FaultRecordEditorPresentation,
        onSave: @escaping (FaultRecord) -> Void
    ) -> some View {
        switch presentation {
        case .new(let purchase):
            FaultRecordEditorView(mode: .create(purchase: purchase), onCommit: onSave)
                .frame(minWidth: 700, minHeight: 620)
        case .edit(let fault):
            FaultRecordEditorView(mode: .edit(fault), onCommit: onSave)
                .frame(minWidth: 700, minHeight: 620)
        }
    }

    @ViewBuilder
    static func repairRecordEditorSheet(
        _ presentation: RepairRecordEditorPresentation,
        onSave: @escaping (RepairRecord) -> Void
    ) -> some View {
        switch presentation {
        case .new(let purchase):
            RepairRecordEditorView(mode: .create(purchase: purchase), onCommit: onSave)
                .frame(minWidth: 760, minHeight: 700)
        case .edit(let repair):
            RepairRecordEditorView(mode: .edit(repair), onCommit: onSave)
                .frame(minWidth: 760, minHeight: 700)
        }
    }

    @ViewBuilder
    static func warrantyEditorSheet(
        _ presentation: WarrantyEditorPresentation,
        onSave: @escaping (Warranty) -> Void
    ) -> some View {
        switch presentation {
        case .new(let purchase):
            WarrantyEditorView(mode: .create(purchase: purchase), onCommit: onSave)
                .frame(minWidth: 650, minHeight: 620)
        case .edit(let warranty):
            WarrantyEditorView(mode: .edit(warranty), onCommit: onSave)
                .frame(minWidth: 650, minHeight: 620)
        }
    }

    @ViewBuilder
    static func reminderEditorSheet(
        _ presentation: ReminderEditorPresentation,
        onSave: @escaping (Reminder) -> Void
    ) -> some View {
        switch presentation {
        case .new(let purchase):
            ReminderEditorView(mode: .create(purchase: purchase), onCommit: onSave)
                .frame(minWidth: 650, minHeight: 560)
        case .edit(let reminder):
            ReminderEditorView(mode: .edit(reminder), onCommit: onSave)
                .frame(minWidth: 650, minHeight: 560)
        }
    }

    @ViewBuilder
    static func interactionEditorSheet(
        _ presentation: InteractionEditorPresentation,
        onSave: @escaping (Interaction) -> Void
    ) -> some View {
        switch presentation {
        case .new(let purchase):
            InteractionEditorView(mode: .create(purchase: purchase), onCommit: onSave)
                .frame(minWidth: 700, minHeight: 620)
        case .draft(let purchase, let draft):
            InteractionEditorView(mode: .createDraft(purchase: purchase, draft: draft), onCommit: onSave)
                .frame(minWidth: 700, minHeight: 700)
        case .edit(let interaction):
            InteractionEditorView(mode: .edit(interaction), onCommit: onSave)
                .frame(minWidth: 700, minHeight: 620)
        }
    }

    static func providerEmailComposerSheet(
        _ presentation: ProviderEmailComposerPresentation,
        onSave: @escaping (Interaction) -> Void
    ) -> some View {
        ProviderEmailComposerSheet(
            provider: presentation.provider,
            linkedPurchases: presentation.linkedPurchases,
            initialPurchase: presentation.initialPurchase,
            initialCorrespondence: presentation.initialCorrespondence,
            onCommit: onSave
        )
        .frame(minWidth: 760, minHeight: 760)
    }

    @ViewBuilder
    static func complaintEditorSheet(
        _ presentation: ComplaintEditorPresentation,
        onSave: @escaping (ComplaintCase) -> Void
    ) -> some View {
        switch presentation {
        case .new(let purchase):
            ComplaintCaseEditorView(mode: .create(purchase: purchase), onCommit: onSave)
                .frame(minWidth: 760, minHeight: 760)
        case .edit(let complaint):
            ComplaintCaseEditorView(mode: .edit(complaint), onCommit: onSave)
                .frame(minWidth: 760, minHeight: 760)
        }
    }

    @ViewBuilder
    static func providerEditorSheet(
        _ presentation: ProviderEditorPresentation,
        onSave: @escaping (Organisation) -> Void
    ) -> some View {
        switch presentation {
        case .new:
            ProviderEditorView(mode: .create, onCommit: onSave)
                .frame(minWidth: 760, minHeight: 700)
        case .edit(let provider):
            ProviderEditorView(mode: .edit(provider), onCommit: onSave)
                .frame(minWidth: 760, minHeight: 700)
        }
    }
}
