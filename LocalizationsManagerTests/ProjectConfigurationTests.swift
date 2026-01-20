//
//  ProjectConfigurationTests.swift
//  LocalizationsManagerTests
//
//  Created by Adrián García García on 20/1/26.
//

import Testing
import Foundation
@testable import LocalizationsManager

@Suite(.serialized)
final class ProjectConfigurationTests {

    deinit {
        // Clear UserDefaults before testing
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "projectPath")
        defaults.removeObject(forKey: "defaultLanguage")
        defaults.removeObject(forKey: "localizationPath")
        defaults.removeObject(forKey: "availableLanguages")
        defaults.removeObject(forKey: "recentProjects")
    }

    @Test func testInitialConfigurationIsEmpty() {
        let config = ProjectConfiguration()

        #expect(config.projectPath == nil)
        #expect(config.defaultLanguage == nil)
        #expect(config.localizationPath == nil)
        #expect(config.availableLanguages.isEmpty)
    }

    @Test func testSetLocalizationConfig() {
        let config = ProjectConfiguration()

        let localizationConfig = LocalizationConfig(
            defaultLanguage: "es",
            localizationPath: "/test/path",
            availableLanguages: ["es", "en", "fr"]
        )

        config.setLocalizationConfig(localizationConfig)

        #expect(config.defaultLanguage == "es")
        #expect(config.localizationPath == "/test/path")
        #expect(config.availableLanguages.count == 3)
        #expect(config.availableLanguages.contains("es"))
    }

    @Test func testClearConfiguration() {
        let config = ProjectConfiguration()

        config.projectPath = "/test/project"
        config.defaultLanguage = "es"
        config.localizationPath = "/test/path"
        config.availableLanguages = ["es", "en"]

        config.clearConfiguration()

        #expect(config.projectPath == nil)
        #expect(config.defaultLanguage == nil)
        #expect(config.localizationPath == nil)
        #expect(config.availableLanguages.isEmpty)
    }

    @Test func testAddRecentProject() {
        let config = ProjectConfiguration()

        let localizationConfig = LocalizationConfig(
            defaultLanguage: "es",
            localizationPath: "/test/path",
            availableLanguages: ["es", "en"]
        )

        config.addRecentProject(
            projectPath: "/test/project",
            xcodeprojPath: "/test/project/App.xcodeproj",
            config: localizationConfig
        )

        #expect(config.recentProjects.count == 1)
        #expect(config.recentProjects[0].projectPath == "/test/project")
        #expect(config.recentProjects[0].xcodeprojPath == "/test/project/App.xcodeproj")
    }

    @Test func testRecentProjectsLimit() {
        let config = ProjectConfiguration()

        let localizationConfig = LocalizationConfig(
            defaultLanguage: "es",
            localizationPath: "/test/path",
            availableLanguages: ["es"]
        )

        // Add more than 10 projects
        for i in 1...15 {
            config.addRecentProject(
                projectPath: "/test/project\(i)",
                xcodeprojPath: "/test/project\(i)/App.xcodeproj",
                config: localizationConfig
            )
        }

        // Should only keep 10 most recent
        #expect(config.recentProjects.count == 10)
        #expect(config.recentProjects[0].projectPath == "/test/project15")
        #expect(config.recentProjects[9].projectPath == "/test/project6")
    }

    @Test func testRemoveRecentProject() {
        let config = ProjectConfiguration()

        let localizationConfig = LocalizationConfig(
            defaultLanguage: "es",
            localizationPath: "/test/path",
            availableLanguages: ["es"]
        )

        config.addRecentProject(
            projectPath: "/test/project1",
            xcodeprojPath: "/test/project1/App.xcodeproj",
            config: localizationConfig
        )

        config.addRecentProject(
            projectPath: "/test/project2",
            xcodeprojPath: "/test/project2/App.xcodeproj",
            config: localizationConfig
        )

        #expect(config.recentProjects.count == 2)

        let projectToRemove = config.recentProjects[0]
        config.removeRecentProject(projectToRemove)

        #expect(config.recentProjects.count == 1)
    }
}
