//
//  ProjectConfiguration.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import Foundation
import Combine

class ProjectConfiguration: ObservableObject {
    @Published var projectPath: String? {
        didSet {
            saveConfiguration()
        }
    }

    @Published var defaultLanguage: String? {
        didSet {
            saveConfiguration()
        }
    }

    @Published var localizationPath: String? {
        didSet {
            saveConfiguration()
        }
    }

    @Published var availableLanguages: [String] = [] {
        didSet {
            saveConfiguration()
        }
    }

    @Published var availableStringsFiles: [String] = [] {
        didSet {
            saveConfiguration()
        }
    }

    @Published var selectedStringsFile: String? {
        didSet {
            saveConfiguration()
        }
    }

    @Published var recentProjects: [RecentProject] = []

    private let projectPathKey = "projectPath"
    private let defaultLanguageKey = "defaultLanguage"
    private let localizationPathKey = "localizationPath"
    private let availableLanguagesKey = "availableLanguages"
    private let availableStringsFilesKey = "availableStringsFiles"
    private let selectedStringsFileKey = "selectedStringsFile"
    private let recentProjectsKey = "recentProjects"
    private let maxRecentProjects = 10

    init() {
        loadConfiguration()
    }

    private func loadConfiguration() {
        if let path = UserDefaults.standard.string(forKey: projectPathKey), !path.isEmpty {
            projectPath = path
        }
        if let language = UserDefaults.standard.string(forKey: defaultLanguageKey), !language.isEmpty {
            defaultLanguage = language
        }
        if let path = UserDefaults.standard.string(forKey: localizationPathKey), !path.isEmpty {
            localizationPath = path
        }
        if let languages = UserDefaults.standard.stringArray(forKey: availableLanguagesKey) {
            availableLanguages = languages
        }
        if let stringsFiles = UserDefaults.standard.stringArray(forKey: availableStringsFilesKey) {
            availableStringsFiles = stringsFiles
        }
        if let selectedFile = UserDefaults.standard.string(forKey: selectedStringsFileKey), !selectedFile.isEmpty {
            selectedStringsFile = selectedFile
        }
        loadRecentProjects()
    }

    private func loadRecentProjects() {
        if let data = UserDefaults.standard.data(forKey: recentProjectsKey),
           let projects = try? JSONDecoder().decode([RecentProject].self, from: data) {
            recentProjects = projects.sorted { $0.lastOpened > $1.lastOpened }
        }
    }

    private func saveConfiguration() {
        if let path = projectPath {
            UserDefaults.standard.set(path, forKey: projectPathKey)
        } else {
            UserDefaults.standard.removeObject(forKey: projectPathKey)
        }

        if let language = defaultLanguage {
            UserDefaults.standard.set(language, forKey: defaultLanguageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: defaultLanguageKey)
        }

        if let path = localizationPath {
            UserDefaults.standard.set(path, forKey: localizationPathKey)
        } else {
            UserDefaults.standard.removeObject(forKey: localizationPathKey)
        }

        UserDefaults.standard.set(availableLanguages, forKey: availableLanguagesKey)

        UserDefaults.standard.set(availableStringsFiles, forKey: availableStringsFilesKey)

        if let selectedFile = selectedStringsFile {
            UserDefaults.standard.set(selectedFile, forKey: selectedStringsFileKey)
        } else {
            UserDefaults.standard.removeObject(forKey: selectedStringsFileKey)
        }
    }

    func setLocalizationConfig(_ config: LocalizationConfig) {
        self.defaultLanguage = config.defaultLanguage
        self.localizationPath = config.localizationPath
        self.availableLanguages = config.availableLanguages
        self.availableStringsFiles = config.availableStringsFiles
        self.selectedStringsFile = config.selectedStringsFile
    }

    func clearConfiguration() {
        projectPath = nil
        defaultLanguage = nil
        localizationPath = nil
        availableLanguages = []
        availableStringsFiles = []
        selectedStringsFile = nil
    }

    func addRecentProject(projectPath: String, xcodeprojPath: String, config: LocalizationConfig) {
        // Remove if already exists (to update lastOpened)
        recentProjects.removeAll { $0.projectPath == projectPath }

        // Add new project
        let newProject = RecentProject(projectPath: projectPath, xcodeprojPath: xcodeprojPath, config: config)
        recentProjects.insert(newProject, at: 0)

        // Keep only max recent projects
        if recentProjects.count > maxRecentProjects {
            recentProjects = Array(recentProjects.prefix(maxRecentProjects))
        }

        saveRecentProjects()
    }

    func removeRecentProject(_ project: RecentProject) {
        recentProjects.removeAll { $0.id == project.id }
        saveRecentProjects()
    }

    private func saveRecentProjects() {
        if let data = try? JSONEncoder().encode(recentProjects) {
            UserDefaults.standard.set(data, forKey: recentProjectsKey)
        }
    }

    func openRecentProject(_ project: RecentProject) {
        self.projectPath = project.projectPath
        self.setLocalizationConfig(project.config)
    }
}
