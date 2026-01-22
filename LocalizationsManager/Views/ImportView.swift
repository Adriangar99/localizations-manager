//
//  ImportView.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ImportView: View {
    let projectPath: String
    let localizationPath: String
    let defaultLanguage: String
    let stringsFileName: String
    @State private var excelFilePath: String? = nil
    @State private var isProcessing: Bool = false
    @State private var outputLog: String = ""
    @State private var isDragOver: Bool = false

    var body: some View {
        HSplitView {
            // Left Column - Configuration & Drag & Drop
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc.fill")
                        .imageScale(.large)
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    Text("Import Localizations")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top)

                // Drag & Drop Area
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)

                    // Tint overlay
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDragOver ? Color.blue.opacity(0.1) : Color.primary.opacity(0.02))

                    // Dashed border
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 2, dash: [10])
                        )
                        .foregroundColor(isDragOver ? .blue : Color.primary.opacity(0.2))

                    VStack(spacing: 12) {
                        if let filePath = excelFilePath {
                            Text("Selected: \(URL(fileURLWithPath: filePath).lastPathComponent)")
                                .font(.headline)
                                .foregroundColor(.green)
                        } else {
                            Text("Drag & Drop Excel File Here")
                                .font(.headline)
                            Text("or click to browse")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("(.xlsx or .xls)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 150)
                .padding(.horizontal)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectExcelFile()
                }
                .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                    handleDrop(providers: providers)
                }

                // Execute Button
                PrimaryGlassButton(
                    isProcessing ? "Processing..." : "Import Localizations",
                    icon: isProcessing ? nil : "arrow.down.doc.fill",
                    color: canExecute ? .blue : .gray,
                    isProcessing: isProcessing,
                    action: executeScript
                )
                .frame(maxWidth: .infinity)
                .disabled(!canExecute || isProcessing)
                .padding(.horizontal)

                Spacer()
            }
            .frame(minWidth: 350, idealWidth: 400, maxWidth: 500)
            .padding(.vertical)

            // Right Column - Output Log
            OutputLogView(outputLog: outputLog, onCopy: copyToClipboard)
        }
    }

    private var canExecute: Bool {
        excelFilePath != nil
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(outputLog, forType: .string)
    }

    private func selectExcelFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "xlsx")!,
            UTType(filenameExtension: "xls")!
        ]
        panel.message = "Select an Excel file to import"

        if panel.runModal() == .OK {
            if let url = panel.url {
                excelFilePath = url.path
                outputLog = "✅ File loaded: \(url.lastPathComponent)"
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }

            let fileExtension = url.pathExtension.lowercased()
            if fileExtension == "xlsx" || fileExtension == "xls" {
                DispatchQueue.main.async {
                    self.excelFilePath = url.path
                    self.outputLog = "✅ File loaded: \(url.lastPathComponent)"
                }
            } else {
                DispatchQueue.main.async {
                    self.outputLog = "❌ Invalid file type. Please drop an Excel file (.xlsx or .xls)"
                }
            }
        }

        return true
    }

    private func executeScript() {
        guard let excelPath = excelFilePath else { return }

        isProcessing = true
        outputLog = ""

        Task { @MainActor in
            let logger = BroadcastLogger()
            let (subscriptionId, logStream) = await logger.subscribe()

            // Start listening to log messages
            let logTask = Task { @MainActor in
                for await message in logStream {
                    self.outputLog += message + "\n"
                }
            }

            let importer = LocalizationImporter(stringsFileName: stringsFileName, logger: logger)

            do {
                try await importer.importLocalizations(
                    from: excelPath,
                    to: localizationPath,
                    defaultLanguage: defaultLanguage
                )

                self.isProcessing = false
            } catch {
                self.outputLog += "❌ Error: \(error.localizedDescription)\n"
                self.isProcessing = false
            }

            // Cleanup: unsubscribe and wait for log task to finish
            await logger.unsubscribe(id: subscriptionId)
            await logTask.value
        }
    }
}

#Preview {
    ImportView(projectPath: "/Users/example/Project", localizationPath: "/Users/example/Project", defaultLanguage: "en", stringsFileName: "Localizable")
}
