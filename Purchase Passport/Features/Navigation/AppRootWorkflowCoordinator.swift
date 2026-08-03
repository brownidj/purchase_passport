import AppKit
import SwiftData
import UniformTypeIdentifiers

struct AppRootWorkflowCoordinator {
    struct PurchaseNameConflictResolution: Equatable {
        let originalName: String
        let resolvedName: String
    }

    struct DocumentIdentifierConflictResolution: Equatable {
        let originalIdentifier: UUID
        let resolvedIdentifier: UUID
    }

    enum ExportWorkflowError: LocalizedError, Equatable {
        case cancelled

        var errorDescription: String? {
            switch self {
            case .cancelled:
                return "Export cancelled."
            }
        }
    }

    static func autoselectID<T: PersistentModel>(
        in items: [T],
        lastSelectedID: PersistentIdentifier?
    ) -> PersistentIdentifier? {
        guard !items.isEmpty else { return nil }

        if let lastSelectedID,
           items.contains(where: { $0.persistentModelID == lastSelectedID }) {
            return lastSelectedID
        }

        return items[0].persistentModelID
    }

    static func convertServiceRecordToFault(
        _ serviceRecord: ServiceRecord
    ) -> FaultRecord {
        FaultRecord(
            firstNoticedDate: serviceRecord.serviceDate ?? serviceRecord.completionDate ?? serviceRecord.bookingDate ?? serviceRecord.createdAt,
            title: serviceRecord.serviceType,
            detailedDescription: AppRootFormatting.nonEmpty(serviceRecord.workRequested),
            severity: .medium,
            status: .open,
            diagnosticInformation: AppRootFormatting.nonEmpty(serviceRecord.workCompleted),
            effectOnUse: AppRootFormatting.nonEmpty(serviceRecord.technicianNotes),
            notes: AppRootFormatting.convertedFaultNotes(from: serviceRecord),
            createdAt: serviceRecord.createdAt,
            updatedAt: .now,
            purchase: serviceRecord.purchase
        )
    }

    static func convertFaultToRepair(
        _ faultRecord: FaultRecord
    ) -> RepairRecord {
        RepairRecord(
            bookingDate: .now,
            repairDate: .now,
            diagnosis: AppRootFormatting.nonEmpty(faultRecord.title),
            workPerformed: AppRootFormatting.nonEmpty(faultRecord.detailedDescription),
            warrantyCoverage: faultRecord.sellerOrManufacturerNotified,
            paymentStatus: .unpaid,
            outcome: faultRecord.status == .resolved || faultRecord.status == .closed ? "Resolved" : nil,
            unresolvedIssues: AppRootFormatting.nonEmpty(faultRecord.effectOnUse),
            followUpRequired: faultRecord.status != .resolved && faultRecord.status != .closed,
            notes: AppRootFormatting.convertedRepairNotes(from: faultRecord),
            createdAt: .now,
            updatedAt: .now,
            purchase: faultRecord.purchase,
            fault: faultRecord
        )
    }

    @discardableResult
    static func applyServiceToFaultConversion(
        draggedServiceRecordID: PersistentIdentifier?,
        serviceRecords: [ServiceRecord],
        modelContext: ModelContext
    ) -> FaultRecord? {
        guard let draggedServiceRecordID,
              let serviceRecord = serviceRecords.first(where: { $0.persistentModelID == draggedServiceRecordID }) else {
            return nil
        }

        let faultRecord = convertServiceRecordToFault(serviceRecord)

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
            return nil
        }

        return faultRecord
    }

    @discardableResult
    static func applyFaultToRepairConversion(
        draggedFaultRecordID: PersistentIdentifier?,
        faultRecords: [FaultRecord],
        modelContext: ModelContext
    ) -> RepairRecord? {
        guard let draggedFaultRecordID,
              let faultRecord = faultRecords.first(where: { $0.persistentModelID == draggedFaultRecordID }) else {
            return nil
        }

        let repairRecord = convertFaultToRepair(faultRecord)

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
            return nil
        }

        return repairRecord
    }

    static func importDocument(
        from result: Result<[URL], Error>,
        into purchase: Purchase
    ) throws -> StoredDocument? {
        let urls = try result.get()
        guard let sourceURL = urls.first else { return nil }

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
        return document
    }

    static func resolveDocumentURL(for document: StoredDocument) throws -> URL {
        try DocumentStorageService.resolvedURL(for: document.storedRelativePath)
    }

    static func openDocument(_ document: StoredDocument) throws {
        let url = try resolveDocumentURL(for: document)
        NSWorkspace.shared.open(url)
    }

    static func exportPurchaseReport(_ purchase: Purchase) throws -> URL {
        let defaultFileName = "\(purchase.name)-report.txt"
        let destinationURL = try saveURL(
            title: "Export Purchase Report",
            defaultFileName: defaultFileName,
            allowedContentTypes: [.plainText]
        )
        try PurchaseExportService.exportReport(for: purchase, to: destinationURL)
        return destinationURL
    }

    static func exportPurchasePDFReport(_ purchase: Purchase) throws -> URL {
        let defaultFileName = "\(purchase.name)-report.pdf"
        let destinationURL = try saveURL(
            title: "Export Purchase PDF Report",
            defaultFileName: defaultFileName,
            allowedContentTypes: [.pdf]
        )
        try PurchaseExportService.exportPDFReport(for: purchase, to: destinationURL)
        return destinationURL
    }

    static func exportPurchaseArchive(_ purchase: Purchase) throws -> URL {
        let defaultFolderName = "\(purchase.name).pparchive"
        let destinationURL = try saveURL(
            title: "Export Purchase Archive",
            defaultFileName: defaultFolderName
        )
        try PurchaseExportService.exportArchive(for: purchase, to: destinationURL)
        return destinationURL
    }

    static func exportFullBackup(purchases: [Purchase]) throws -> URL {
        let timestamp = ISO8601DateFormatter()
            .string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let defaultFolderName = "PurchasePassport-Backup-\(timestamp).ppbackup"
        let destinationURL = try saveURL(
            title: "Export Full Backup",
            defaultFileName: defaultFolderName
        )
        try BackupService.exportBackup(for: purchases, to: destinationURL)
        return destinationURL
    }

    static func importPurchaseArchive() throws -> Purchase {
        let archiveURL = try openDirectoryURL(
            title: "Import Purchase Archive",
            allowedContentTypes: [UTType(filenameExtension: "pparchive")].compactMap { $0 }
        )
        return try PurchaseExportService.importArchive(at: archiveURL)
    }

    static func restoreFullBackup() throws -> [Purchase] {
        let backupURL = try openDirectoryURL(
            title: "Restore Full Backup",
            allowedContentTypes: [UTType(filenameExtension: "ppbackup")].compactMap { $0 }
        )
        return try BackupService.restoreBackup(at: backupURL)
    }

    static func restoreFullBackupWithReport() throws -> (url: URL, report: BackupService.RestoreReport, logURL: URL?) {
        let backupURL = try openDirectoryURL(
            title: "Restore Full Backup",
            allowedContentTypes: [UTType(filenameExtension: "ppbackup")].compactMap { $0 }
        )
        let report = try BackupService.restoreBackupWithReport(at: backupURL)
        do {
            let logURL = try BackupService.writeRestoreReport(for: backupURL, report: report)
            return (backupURL, report, logURL)
        } catch {
            let augmentedReport = BackupService.RestoreReport(
                restoredPurchases: report.restoredPurchases,
                issues: report.issues + ["Restore log could not be written: \(error.localizedDescription)"]
            )
            return (backupURL, augmentedReport, nil)
        }
    }

    static func resolvePurchaseNameConflicts(
        importedPurchases: [Purchase],
        existingPurchases: [Purchase]
    ) -> [PurchaseNameConflictResolution] {
        var usedNames = Set(existingPurchases.map { normalizedName($0.name) })
        var resolutions: [PurchaseNameConflictResolution] = []

        for purchase in importedPurchases {
            let originalName = purchase.name
            let trimmed = originalName.trimmingCharacters(in: .whitespacesAndNewlines)
            let baseName = trimmed.isEmpty ? "Imported Purchase" : trimmed
            var candidateName = baseName
            var suffix = 2

            while usedNames.contains(normalizedName(candidateName)) {
                candidateName = "\(baseName) (Imported \(suffix))"
                suffix += 1
            }

            purchase.name = candidateName
            usedNames.insert(normalizedName(candidateName))
            if candidateName != originalName {
                resolutions.append(
                    PurchaseNameConflictResolution(
                        originalName: originalName,
                        resolvedName: candidateName
                    )
                )
            }
        }

        return resolutions
    }

    static func resolveDocumentIdentifierConflicts(
        importedPurchases: [Purchase],
        existingPurchases: [Purchase]
    ) -> [DocumentIdentifierConflictResolution] {
        var usedIdentifiers = Set<UUID>()
        for purchase in existingPurchases {
            for document in purchase.documents {
                usedIdentifiers.insert(document.identifier)
            }
        }

        var resolutions: [DocumentIdentifierConflictResolution] = []
        for purchase in importedPurchases {
            for document in purchase.documents {
                let originalIdentifier = document.identifier
                if !usedIdentifiers.contains(originalIdentifier) {
                    usedIdentifiers.insert(originalIdentifier)
                    continue
                }

                var newIdentifier = UUID()
                while usedIdentifiers.contains(newIdentifier) {
                    newIdentifier = UUID()
                }

                document.identifier = newIdentifier
                usedIdentifiers.insert(newIdentifier)
                resolutions.append(
                    DocumentIdentifierConflictResolution(
                        originalIdentifier: originalIdentifier,
                        resolvedIdentifier: newIdentifier
                    )
                )
            }
        }

        return resolutions
    }

    static func validatePurchaseArchive(at archiveURL: URL) -> [String] {
        PurchaseExportService.validateArchive(at: archiveURL)
    }

    static func validateBackup(at backupURL: URL) -> [String] {
        BackupService.validateBackup(at: backupURL)
    }

    static func validateSelectedPurchaseArchive() throws -> (url: URL, issues: [String]) {
        let archiveURL = try openDirectoryURL(
            title: "Validate Purchase Archive",
            allowedContentTypes: [UTType(filenameExtension: "pparchive")].compactMap { $0 }
        )
        return (archiveURL, PurchaseExportService.validateArchive(at: archiveURL))
    }

    static func validateSelectedBackup() throws -> (url: URL, issues: [String]) {
        let backupURL = try openDirectoryURL(
            title: "Validate Full Backup",
            allowedContentTypes: [UTType(filenameExtension: "ppbackup")].compactMap { $0 }
        )
        return (backupURL, BackupService.validateBackup(at: backupURL))
    }

    private static func saveURL(
        title: String,
        defaultFileName: String,
        allowedContentTypes: [UTType] = []
    ) throws -> URL {
        let panel = NSSavePanel()
        panel.title = title
        panel.nameFieldStringValue = defaultFileName
        panel.canCreateDirectories = true
        if !allowedContentTypes.isEmpty {
            panel.allowedContentTypes = allowedContentTypes
        }

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            throw ExportWorkflowError.cancelled
        }
        return url
    }

    private static func openDirectoryURL(
        title: String,
        allowedContentTypes: [UTType] = []
    ) throws -> URL {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        if !allowedContentTypes.isEmpty {
            panel.allowedContentTypes = allowedContentTypes
        }

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            throw ExportWorkflowError.cancelled
        }
        return url
    }

    private static func normalizedName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
