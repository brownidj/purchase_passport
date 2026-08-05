import Foundation
import SwiftData
import SwiftUI

struct ProviderMailImportWindow: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Organisation.name)
    private var providers: [Organisation]

    @Query(sort: \Purchase.createdAt, order: .reverse)
    private var purchases: [Purchase]

    @Query(sort: \CorrespondenceRecord.occurredAt, order: .reverse)
    private var correspondences: [CorrespondenceRecord]

    let providerName: String?

    @State private var isDropTargeted = false
    @State private var isShowingFileImporter = false
    @State private var isImporting = false
    @State private var pendingImportMode: ProviderEmailImportService.ImportMode = .importNewOnly
    @State private var resultTitle = "Ready to Import"
    @State private var resultMessage = "Drag Mail message files into the drop zone or browse for exported files."
    @State private var resultDetails: String?

    private var resolvedProviderName: String? {
        providerName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private var provider: Organisation? {
        guard let resolvedProviderName else { return nil }
        return providers.first {
            $0.name.localizedCaseInsensitiveCompare(resolvedProviderName) == .orderedSame
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            headerView
            instructionsView
            dropZone
            statusView
            Spacer(minLength: 0)
        }
        .padding(20)
        .navigationTitle(provider?.name ?? "Provider Email Import")
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: ProviderEmailImportService.supportedContentTypes,
            allowsMultipleSelection: true
        ) { result in
            handleFileImporter(result)
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Provider Email Import")
                .font(.title2.weight(.semibold))
            Text(provider?.name ?? resolvedProviderName ?? "No provider selected")
                .font(.headline)
                .foregroundStyle(provider == nil ? .secondary : .primary)
        }
    }

    private var instructionsView: some View {
            Text("Open this window from a provider, then drag exported email files here. Purchase Passport accepts `.eml` files and Apple Mail `.emlx` exports.")
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private var dropZone: some View {
        VStack(spacing: 12) {
            Image(systemName: isImporting ? "hourglass" : "tray.and.arrow.down")
                .font(.system(size: 30, weight: .medium))
            Text(isImporting ? "Importing..." : "Drop Mail Files Here")
                .font(.headline)
            Text("You can also browse for files manually.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Choose Email Files...") {
                    pendingImportMode = .importNewOnly
                    isShowingFileImporter = true
                }
                .disabled(provider == nil || isImporting)

                Button("Reimport Email Files...") {
                    pendingImportMode = .overwriteExisting
                    isShowingFileImporter = true
                }
                .disabled(provider == nil || isImporting)
            }

            Text("Reimport overwrites matching imported emails, refreshes their stored content, and rebuilds any generated linked interactions.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: isDropTargeted ? 2.5 : 1.5, dash: [8, 6])
                )
        )
        .onDrop(
            of: ProviderEmailImportService.supportedDropContentTypes,
            isTargeted: $isDropTargeted,
            perform: handleDroppedProviders
        )
    }

    private var statusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resultTitle)
                .font(.headline)
            Text(resultMessage)
                .foregroundStyle(.primary)

            if let resultDetails, !resultDetails.isEmpty {
                ScrollView {
                    Text(resultDetails)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 80, maxHeight: 140)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }

    private func handleFileImporter(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            importURLs(urls, mode: pendingImportMode)
        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain, nsError.code == NSUserCancelledError {
                return
            }
            resultTitle = "Mail Import Error"
            resultMessage = error.localizedDescription
            resultDetails = nil
        }
    }

    private func importURLs(_ urls: [URL], mode: ProviderEmailImportService.ImportMode = .importNewOnly) {
        guard let provider else {
            resultTitle = "No Provider Selected"
            resultMessage = "Reopen this window from a provider detail page before importing email files."
            resultDetails = nil
            return
        }

        guard !urls.isEmpty else {
            return
        }

        isImporting = true
        resultTitle = "Importing..."
        resultMessage = mode == .overwriteExisting
            ? "Reimporting \(urls.count) file(s) for \(provider.name)."
            : "Processing \(urls.count) file(s) for \(provider.name)."
        resultDetails = nil

        Task { @MainActor in
            defer { isImporting = false }

            do {
                let summary = try ProviderEmailImportService.importEmailFiles(
                    at: urls,
                    forProviderNamed: provider.name,
                    providers: providers,
                    correspondences: correspondences,
                    purchases: purchases,
                    modelContext: modelContext,
                    mode: mode
                )
                present(summary, mode: mode)
            } catch {
                resultTitle = "Mail Import Error"
                resultMessage = error.localizedDescription
                resultDetails = nil
            }
        }
    }

    private func handleDroppedProviders(_ itemProviders: [NSItemProvider]) -> Bool {
        guard !itemProviders.isEmpty else {
            return false
        }

        isImporting = true
        resultTitle = "Importing..."
        resultMessage = "Reading dropped Mail items..."
        resultDetails = nil

        ProviderEmailImportService.loadDroppedEmailFiles(from: itemProviders) { result in
            Task { @MainActor in
                switch result {
                case .success(let urls):
                    importURLs(urls)
                case .failure(let error):
                    isImporting = false
                    resultTitle = "Mail Import Error"
                    resultMessage = error.localizedDescription
                    resultDetails = nil
                }
            }
        }

        return true
    }

    private func present(_ summary: ProviderEmailImportService.ImportSummary, mode: ProviderEmailImportService.ImportMode) {
        if summary.matchingCount == 0 {
            resultTitle = "No Matching Imported Emails"
            resultMessage = "The dropped files did not match \(summary.providerName) or its saved email addresses."
        } else if mode == .overwriteExisting {
            if summary.importedCount == 0, summary.overwrittenCount == 0 {
                resultTitle = "No Emails Reimported"
                resultMessage = "No matching emails were imported or refreshed for \(summary.providerName)."
            } else {
                resultTitle = "Provider Emails Reimported"
                resultMessage = "Imported \(summary.importedCount) new and refreshed \(summary.overwrittenCount) existing email(s) for \(summary.providerName)."
            }
        } else if summary.importedCount == 0 {
            resultTitle = "No New Emails Imported"
            resultMessage = "All matching emails for \(summary.providerName) were already imported."
        } else {
            resultTitle = "Provider Emails Imported"
            resultMessage = "Imported \(summary.importedCount) email(s) for \(summary.providerName)."
        }
        resultDetails = summary.diagnostics
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
