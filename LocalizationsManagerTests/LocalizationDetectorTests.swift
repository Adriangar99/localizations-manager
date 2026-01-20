//
//  LocalizationDetectorTests.swift
//  LocalizationsManagerTests
//
//  Created by Adrián García García on 20/1/26.
//

import Testing
import Foundation
@testable import LocalizationsManager

struct LocalizationDetectorTests {

    @Test func testDetectConfigurationWithMultipleLanguages() throws {
        // Create temporary project structure
        let tempDir = FileManager.default.temporaryDirectory
        let projectDir = tempDir.appendingPathComponent("TestProject_\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: projectDir) }

        // Create .lproj folders with Localizable.strings
        let languages = ["es", "en", "fr"]
        for lang in languages {
            let lprojDir = projectDir.appendingPathComponent("\(lang).lproj")
            try FileManager.default.createDirectory(at: lprojDir, withIntermediateDirectories: true)

            let stringsFile = lprojDir.appendingPathComponent("Localizable.strings")
            try "\"test\" = \"test\";".write(to: stringsFile, atomically: true, encoding: .utf8)
        }

        let config = LocalizationDetector.detectConfiguration(in: projectDir.path)

        #expect(config != nil)
        #expect(config?.defaultLanguage == "es") // es has priority
        #expect(config?.availableLanguages.count == 3)
        #expect(config?.availableLanguages.contains("es") == true)
        #expect(config?.availableLanguages.contains("en") == true)
        #expect(config?.availableLanguages.contains("fr") == true)
    }

    @Test func testDetectConfigurationWithEnglishOnly() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let projectDir = tempDir.appendingPathComponent("TestProjectEN_\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: projectDir) }

        let lprojDir = projectDir.appendingPathComponent("en.lproj")
        try FileManager.default.createDirectory(at: lprojDir, withIntermediateDirectories: true)

        let stringsFile = lprojDir.appendingPathComponent("Localizable.strings")
        try "\"test\" = \"test\";".write(to: stringsFile, atomically: true, encoding: .utf8)

        let config = LocalizationDetector.detectConfiguration(in: projectDir.path)

        #expect(config != nil)
        #expect(config?.defaultLanguage == "en")
        #expect(config?.availableLanguages.count == 1)
    }

    @Test func testDetectConfigurationWithBaseLanguage() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let projectDir = tempDir.appendingPathComponent("TestProjectBase_\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: projectDir) }

        let lprojDir = projectDir.appendingPathComponent("Base.lproj")
        try FileManager.default.createDirectory(at: lprojDir, withIntermediateDirectories: true)

        let stringsFile = lprojDir.appendingPathComponent("Localizable.strings")
        try "\"test\" = \"test\";".write(to: stringsFile, atomically: true, encoding: .utf8)

        let config = LocalizationDetector.detectConfiguration(in: projectDir.path)

        #expect(config != nil)
        #expect(config?.defaultLanguage == "Base")
    }

    @Test func testDetectConfigurationNoLocalizationFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let projectDir = tempDir.appendingPathComponent("TestProjectEmpty_\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: projectDir) }

        let config = LocalizationDetector.detectConfiguration(in: projectDir.path)

        #expect(config == nil)
    }

    @Test func testDetectConfigurationIgnoresLprojWithoutStrings() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let projectDir = tempDir.appendingPathComponent("TestProjectNoStrings_\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: projectDir) }

        // Create .lproj folder without Localizable.strings
        let lprojDir = projectDir.appendingPathComponent("en.lproj")
        try FileManager.default.createDirectory(at: lprojDir, withIntermediateDirectories: true)

        // Create some other file, not Localizable.strings
        let otherFile = lprojDir.appendingPathComponent("Other.strings")
        try "\"test\" = \"test\";".write(to: otherFile, atomically: true, encoding: .utf8)

        let config = LocalizationDetector.detectConfiguration(in: projectDir.path)

        #expect(config == nil)
    }

    @Test func testStringsFilePathConstruction() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let projectDir = tempDir.appendingPathComponent("TestProjectPath_\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: projectDir) }

        let lprojDir = projectDir.appendingPathComponent("es.lproj")
        try FileManager.default.createDirectory(at: lprojDir, withIntermediateDirectories: true)

        let stringsFile = lprojDir.appendingPathComponent("Localizable.strings")
        try "\"test\" = \"test\";".write(to: stringsFile, atomically: true, encoding: .utf8)

        let config = LocalizationDetector.detectConfiguration(in: projectDir.path)

        #expect(config != nil)

        let stringsPath = LocalizationDetector.stringsFilePath(for: "es", in: config!)
        #expect(stringsPath.hasSuffix("es.lproj/Localizable.strings"))
    }
}
