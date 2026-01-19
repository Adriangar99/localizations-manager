//
//  RecentProject.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import Foundation

/// Represents a recently opened project
struct RecentProject: Codable, Identifiable, Equatable {
    let id: UUID
    let projectPath: String
    let xcodeprojPath: String
    let lastOpened: Date
    let config: LocalizationConfig

    init(projectPath: String, xcodeprojPath: String, config: LocalizationConfig) {
        self.id = UUID()
        self.projectPath = projectPath
        self.xcodeprojPath = xcodeprojPath
        self.lastOpened = Date()
        self.config = config
    }

    var projectName: String {
        return URL(fileURLWithPath: xcodeprojPath).deletingPathExtension().lastPathComponent
    }

    var displayPath: String {
        return projectPath
    }

    static func == (lhs: RecentProject, rhs: RecentProject) -> Bool {
        return lhs.id == rhs.id
    }
}
