//
//  DeleteView.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import SwiftUI
import AppKit

struct DeleteView: View {
    let projectPath: String
    let localizationPath: String
    let defaultLanguage: String
    let stringsFileName: String
    @State private var availableKeys: [LocalizationKey] = []
    @State private var selectedKeys: [LocalizationKey] = []
    @State private var searchText: String = ""
    @State private var isProcessing: Bool = false
    @State private var outputLog: String = ""
    @State private var isLoading: Bool = false
    @State private var selectedAvailableKey: LocalizationKey? = nil
    @State private var selectedDeleteKey: LocalizationKey? = nil
    @Namespace private var animation

    var filteredAvailableKeys: [LocalizationKey] {
        if searchText.isEmpty {
            return availableKeys
        }
        return availableKeys.filter { key in
            key.key.localizedCaseInsensitiveContains(searchText) ||
            key.value.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        HSplitView {
            // Left Column - Key Selection
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .imageScale(.large)
                        .font(.system(size: 50))
                        .foregroundStyle(.red)
                    Text("Delete Localizations")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top)

                // Search bar with refresh button
                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search keys...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .frame(height: 36)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)

                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                        }
                    )

                    SecondaryGlassButton(
                        "",
                        icon: "arrow.clockwise",
                        color: .blue,
                        action: refreshKeys
                    )
                    .frame(height: 36)
                    .help("Refresh keys list")
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.5 : 1.0)
                }
                .padding(.horizontal)

                // Double list view
                HStack(spacing: 12) {
                    // Available keys list
                    VStack(alignment: .leading, spacing: 8) {
                        ListSectionHeader(
                            title: "Available Keys",
                            count: filteredAvailableKeys.count,
                            subtitle: "Double-click to add"
                        )

                        if isLoading {
                            EmptyStateView(
                                icon: "arrow.clockwise",
                                message: "Loading keys..."
                            )
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.5)
                            )
                        } else if availableKeys.isEmpty {
                            EmptyStateView(
                                icon: "doc.text.magnifyingglass",
                                message: "No keys found"
                            )
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 4) {
                                    ForEach(filteredAvailableKeys) { key in
                                        LocalizationKeyRow(
                                            key: key,
                                            isSelected: selectedAvailableKey == key,
                                            highlightColor: .blue,
                                            onSingleTap: {
                                                if self.selectedAvailableKey != key {
                                                    self.selectedAvailableKey = key
                                                }
                                            },
                                            onDoubleTap: {
                                                addSingleKey(key)
                                            }
                                        )
                                        .matchedGeometryEffect(id: key.key, in: animation)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.5)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Selected keys to delete list
                    VStack(alignment: .leading, spacing: 8) {
                        ListSectionHeader(
                            title: "Keys to Delete",
                            count: selectedKeys.count,
                            subtitle: "Double-click to remove"
                        )

                        if selectedKeys.isEmpty {
                            EmptyStateView(
                                icon: "trash.slash",
                                message: "No keys selected"
                            )
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 4) {
                                    ForEach(selectedKeys) { key in
                                        LocalizationKeyRow(
                                            key: key,
                                            isSelected: selectedDeleteKey == key,
                                            highlightColor: .red,
                                            onSingleTap: {
                                                if self.selectedDeleteKey != key {
                                                    self.selectedDeleteKey = key
                                                }
                                            },
                                            onDoubleTap: {
                                                removeSingleKey(key)
                                            }
                                        )
                                        .matchedGeometryEffect(id: key.key, in: animation)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.5)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                // Execute Button
                PrimaryGlassButton(
                    isProcessing ? "Processing..." : "Delete Selected Keys",
                    icon: isProcessing ? nil : "trash.fill",
                    color: canExecute ? .red : .gray,
                    isProcessing: isProcessing,
                    action: executeScript
                )
                .frame(maxWidth: .infinity)
                .disabled(!canExecute || isProcessing)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(minWidth: 600, idealWidth: 700)
            .padding(.vertical)
            .onAppear {
                // Always refresh keys when the view appears
                refreshKeys()
            }

            // Right Column - Output Log
            OutputLogView(outputLog: outputLog, onCopy: copyToClipboard)
        }
    }

    private var canExecute: Bool {
        !selectedKeys.isEmpty
    }

    private func refreshKeys() {
        isLoading = true

        // Clear current lists and selections (but keep search text)
        selectedKeys.removeAll()
        selectedAvailableKey = nil
        selectedDeleteKey = nil

        let stringsFilePath = "\(localizationPath)/\(defaultLanguage).lproj/\(stringsFileName).strings"

        DispatchQueue.global(qos: .userInitiated).async {
            let keys = LocalizationParser.parseStringsFile(at: stringsFilePath)

            DispatchQueue.main.async {
                self.availableKeys = keys
                self.isLoading = false

                if keys.isEmpty {
                    self.outputLog = "⚠️ No keys found in \(stringsFilePath)\n"
                    self.outputLog += "Make sure the file exists and contains valid localization entries.\n"
                } else {
                    self.outputLog = "✅ Loaded \(keys.count) keys from \(self.defaultLanguage).lproj\n"
                }
            }
        }
    }

    private func addSingleKey(_ key: LocalizationKey) {
        withAnimation(.easeInOut(duration: 0.25)) {
            if let index = availableKeys.firstIndex(of: key) {
                availableKeys.remove(at: index)
                selectedKeys.append(key)
                sortSelectedKeys()
                selectedAvailableKey = nil
            }
        }
    }

    private func removeSingleKey(_ key: LocalizationKey) {
        withAnimation(.easeInOut(duration: 0.25)) {
            if let index = selectedKeys.firstIndex(of: key) {
                selectedKeys.remove(at: index)
                availableKeys.append(key)
                sortAvailableKeys()
                selectedDeleteKey = nil
            }
        }
    }

    private func sortAvailableKeys() {
        availableKeys.sort { $0.key < $1.key }
    }

    private func sortSelectedKeys() {
        selectedKeys.sort { $0.key < $1.key }
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(outputLog, forType: .string)
    }

    private func executeScript() {
        guard !selectedKeys.isEmpty else { return }

        isProcessing = true
        outputLog = ""

        let keysToDelete = selectedKeys.map { $0.key }

        Task { @MainActor in
            let logger = BroadcastLogger()
            let (subscriptionId, logStream) = await logger.subscribe()

            // Start listening to log messages
            let logTask = Task { @MainActor in
                for await message in logStream {
                    self.outputLog += message + "\n"
                }
            }

            let deleter = LocalizationDeleter(logger: logger)

            do {
                try await deleter.deleteKeys(
                    keysToDelete,
                    from: localizationPath,
                    stringsFileName: stringsFileName
                )

                self.selectedKeys.removeAll()
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
    DeleteView(projectPath: "/Users/example/Project", localizationPath: "/Users/example/Project", defaultLanguage: "es", stringsFileName: "Localizable")
}
