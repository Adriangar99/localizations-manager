//
//  ProjectSetupView.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ProjectSetupView: View {
    @ObservedObject var config: ProjectConfiguration
    @State private var selectedRecentProject: RecentProject?
    @State private var hoveredProject: RecentProject?
    @State private var errorMessage: String?

    var body: some View {
        HSplitView {
            // Left sidebar - Recent Projects
            VStack(alignment: .leading, spacing: 0) {
                // Sidebar header
                VStack(spacing: 0) {
                    HStack {
                        Text("Recent")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                    Divider()
                }
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                )

                // Recent projects list
                if config.recentProjects.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateView(
                            icon: "clock.arrow.circlepath",
                            message: "No Recent Projects"
                        )
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(config.recentProjects) { project in
                            RecentProjectRow(
                                project: project,
                                isSelected: selectedRecentProject?.id == project.id,
                                isHovered: hoveredProject?.id == project.id
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            .listRowSeparator(.hidden)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                openRecentProject(project)
                            }
                            .simultaneousGesture(
                                TapGesture(count: 1).onEnded {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        if self.selectedRecentProject?.id != project.id {
                                            self.selectedRecentProject = project
                                        }
                                    }
                                }
                            )
                            .onHover { hovering in
                                hoveredProject = hovering ? project : nil
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        config.removeRecentProject(project)
                                        if selectedRecentProject?.id == project.id {
                                            selectedRecentProject = nil
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button("Open") {
                                    openRecentProject(project)
                                }
                                Divider()
                                Button("Remove from Recent") {
                                    config.removeRecentProject(project)
                                }
                                Button("Show in Finder") {
                                    NSWorkspace.shared.selectFile(project.projectPath, inFileViewerRootedAtPath: "")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(minWidth: 250, idealWidth: 300, maxWidth: 350)
            .background(
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)

                    Rectangle()
                        .fill(Color.primary.opacity(0.02))

                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(width: 1)
                    }
                }
            )

            // Right content area
            VStack(spacing: 0) {
                Spacer()

                // Main content
                VStack(spacing: 32) {
                    // App icon and title
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.gearshape")
                            .font(.system(size: 72))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Welcome to Localizations Manager")
                            .font(.system(size: 28, weight: .semibold))

                        Text("Manage your Xcode project localizations")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        PrimaryGlassButton(
                            "Open Project",
                            icon: "folder",
                            color: .blue,
                            action: openProject
                        )
                        .frame(width: 240)

                        if let selected = selectedRecentProject {
                            SecondaryGlassButton(
                                "Open \"\(selected.projectName)\"",
                                icon: "clock.arrow.circlepath",
                                color: .blue,
                                action: { openRecentProject(selected) }
                            )
                            .frame(width: 240)
                        }
                    }

                    // Error message display
                    if let error = errorMessage {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                            Text("Please select a valid Xcode project (.xcodeproj)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: 400)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))

                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                            }
                        )
                    }
                }
                .frame(maxWidth: 600)

                Spacer()

                // Footer hint
                if !config.recentProjects.isEmpty {
                    Text("Double-click on a recent project to open it")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 500)
    }

    private func openProject() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = false
        panel.message = "Select the Xcode project file (.xcodeproj)"

        errorMessage = nil

        if panel.runModal() == .OK {
            if let url = panel.url {
                if url.pathExtension == "xcodeproj" {
                    let projectDirectory = url.deletingLastPathComponent().path

                    if let detectedConfig = LocalizationDetector.detectConfiguration(in: projectDirectory) {
                        config.addRecentProject(
                            projectPath: projectDirectory,
                            xcodeprojPath: url.path,
                            config: detectedConfig
                        )
                        config.projectPath = projectDirectory
                        config.setLocalizationConfig(detectedConfig)
                        errorMessage = nil
                    } else {
                        errorMessage = "No localization files found in this project"
                    }
                } else {
                    errorMessage = "Please select an .xcodeproj file"
                }
            }
        }
    }

    private func openRecentProject(_ project: RecentProject) {
        errorMessage = nil

        // Verify project still exists
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: project.projectPath) {
            config.openRecentProject(project)
        } else {
            errorMessage = "Project no longer exists at this location"
            config.removeRecentProject(project)
        }
    }
}

// Recent project row component
struct RecentProjectRow: View {
    let project: RecentProject
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Project icon
            NSImageView(
                image: ProjectInfoHelper.getProjectIcon(from: project.projectPath),
                size: 32
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(project.projectName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)

                Text(project.displayPath)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected
                    ? Color.accentColor
                    : isHovered
                        ? Color.primary.opacity(0.08)
                        : Color.clear)
        )
        .padding(.horizontal, 8)
    }
}

#Preview {
    ProjectSetupView(config: ProjectConfiguration())
}
