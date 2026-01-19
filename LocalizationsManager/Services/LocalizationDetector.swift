//
//  LocalizationDetector.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import Foundation

struct LocalizationConfig: Codable {
    let defaultLanguage: String
    let localizationPath: String
    let availableLanguages: [String]
}

class LocalizationDetector {

    /// Detects localization configuration in a project directory
    static func detectConfiguration(in projectPath: String) -> LocalizationConfig? {
        let fileManager = FileManager.default

        // Find all .lproj directories recursively
        var lprojPaths: [(path: String, language: String)] = []

        if let enumerator = fileManager.enumerator(atPath: projectPath) {
            for case let file as String in enumerator {
                if file.hasSuffix(".lproj") {
                    let fullPath = (projectPath as NSString).appendingPathComponent(file)

                    // Extract language code from directory name (e.g., "es.lproj" -> "es")
                    let dirName = (file as NSString).lastPathComponent
                    let language = dirName.replacingOccurrences(of: ".lproj", with: "")

                    // Check if this directory contains Localizable.strings
                    let stringsPath = (fullPath as NSString).appendingPathComponent("Localizable.strings")
                    if fileManager.fileExists(atPath: stringsPath) {
                        lprojPaths.append((path: fullPath, language: language))
                    }
                }
            }
        }

        guard !lprojPaths.isEmpty else {
            return nil
        }

        // Sort to prioritize certain languages
        let sortedPaths = lprojPaths.sorted { first, second in
            // Prioritize: es > en > Base > others
            let priority = ["es": 3, "en": 2, "Base": 1]
            let firstPriority = priority[first.language] ?? 0
            let secondPriority = priority[second.language] ?? 0

            if firstPriority != secondPriority {
                return firstPriority > secondPriority
            }
            return first.language < second.language
        }

        // Get the default language (highest priority)
        let defaultLanguage = sortedPaths.first!.language

        // Get the base path (parent directory of .lproj folders)
        let firstLprojPath = sortedPaths.first!.path
        let localizationPath = (firstLprojPath as NSString).deletingLastPathComponent

        // Get all available languages
        let availableLanguages = sortedPaths.map { $0.language }

        return LocalizationConfig(
            defaultLanguage: defaultLanguage,
            localizationPath: localizationPath,
            availableLanguages: availableLanguages
        )
    }

    /// Gets the path to a specific language's strings file
    static func stringsFilePath(for language: String, in config: LocalizationConfig) -> String {
        return "\(config.localizationPath)/\(language).lproj/Localizable.strings"
    }
}
