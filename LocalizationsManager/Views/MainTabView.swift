//
//  MainTabView.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var config: ProjectConfiguration
    let projectPath: String
    let localizationPath: String
    let defaultLanguage: String
    let availableLanguages: [String]
    let selectedStringsFile: String
    @State private var showLanguagesPopover: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with project info and change button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        NSImageView(
                            image: ProjectInfoHelper.getProjectIcon(from: projectPath),
                            size: 32
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ProjectInfoHelper.getProjectName(from: projectPath))
                                .font(.headline)
                                .fontWeight(.semibold)
                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Text("Language:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(LanguageHelper.displayName(for: defaultLanguage))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                HStack(spacing: 4) {
                                    Text("Available:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button(action: { showLanguagesPopover.toggle() }) {
                                        HStack(spacing: 2) {
                                            Text("\(availableLanguages.count)")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                            Image(systemName: "chevron.down.circle.fill")
                                                .font(.system(size: 10))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.blue)
                                    .popover(isPresented: $showLanguagesPopover) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Available Languages")
                                                .font(.headline)
                                                .padding(.bottom, 4)

                                            ScrollView {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    ForEach(availableLanguages, id: \.self) { language in
                                                        Text(LanguageHelper.displayName(for: language))
                                                            .font(.subheadline)
                                                            .padding(.vertical, 4)
                                                            .padding(.horizontal, 8)
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 4)
                                                                    .fill(Color.primary.opacity(0.05))
                                                            )
                                                    }
                                                }
                                                .padding(.trailing, 12)
                                            }
                                            .frame(maxHeight: 300)
                                        }
                                        .padding()
                                        .frame(minWidth: 250, maxWidth: 300)
                                        .background(.ultraThinMaterial)
                                    }
                                }

                                // Strings file selector (only show if multiple files available)
                                if config.availableStringsFiles.count > 1 {
                                    HStack(spacing: 4) {
                                        Text("File:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Picker("", selection: Binding(
                                            get: { config.selectedStringsFile ?? selectedStringsFile },
                                            set: { config.selectedStringsFile = $0 }
                                        )) {
                                            ForEach(config.availableStringsFiles, id: \.self) { file in
                                                Text("\(file).strings").tag(file)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .font(.caption)
                                        .frame(width: 150)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.leading)

                Spacer()

                SecondaryGlassButton(
                    "Change Project",
                    icon: "arrow.left.circle",
                    color: .blue,
                    action: changeProject
                )
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .glassHeader()

            // Tab View
            TabView {
                ImportView(
                    projectPath: projectPath,
                    localizationPath: localizationPath,
                    defaultLanguage: defaultLanguage,
                    stringsFileName: config.selectedStringsFile ?? selectedStringsFile
                )
                .tabItem {
                    Label("Import", systemImage: "arrow.down.doc.fill")
                }

                DeleteView(
                    projectPath: projectPath,
                    localizationPath: localizationPath,
                    defaultLanguage: defaultLanguage,
                    stringsFileName: config.selectedStringsFile ?? selectedStringsFile
                )
                .tabItem {
                    Label("Delete", systemImage: "trash.fill")
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    private func changeProject() {
        config.clearConfiguration()
    }
}

#Preview {
    MainTabView(
        config: ProjectConfiguration(),
        projectPath: "/Users/example/Project",
        localizationPath: "/Users/example/Project",
        defaultLanguage: "es",
        availableLanguages: ["es", "en", "fr"],
        selectedStringsFile: "Localizable"
    )
}
