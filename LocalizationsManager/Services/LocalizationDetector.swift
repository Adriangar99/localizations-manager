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
    let availableStringsFiles: [String]
    let selectedStringsFile: String

    // Custom decoding to handle backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultLanguage = try container.decode(String.self, forKey: .defaultLanguage)
        localizationPath = try container.decode(String.self, forKey: .localizationPath)
        availableLanguages = try container.decode([String].self, forKey: .availableLanguages)

        // Default to "Localizable" if these fields don't exist (backward compatibility)
        availableStringsFiles = try container.decodeIfPresent([String].self, forKey: .availableStringsFiles) ?? ["Localizable"]
        selectedStringsFile = try container.decodeIfPresent(String.self, forKey: .selectedStringsFile) ?? "Localizable"
    }

    // Standard initializer for new configs
    init(defaultLanguage: String, localizationPath: String, availableLanguages: [String], availableStringsFiles: [String], selectedStringsFile: String) {
        self.defaultLanguage = defaultLanguage
        self.localizationPath = localizationPath
        self.availableLanguages = availableLanguages
        self.availableStringsFiles = availableStringsFiles
        self.selectedStringsFile = selectedStringsFile
    }
}

class LocalizationDetector {

    /// Detects common .strings files across all .lproj directories
    /// - Returns: Array of .strings file names (without extension) that are present in most directories
    private static func detectCommonStringsFiles(in lprojPaths: [String]) -> [String] {
        let fileManager = FileManager.default
        var filesPerLproj: [[String]] = []

        // Collect .strings files from each .lproj directory
        for lprojPath in lprojPaths {
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: lprojPath)
                let stringsFiles = contents
                    .filter { $0.hasSuffix(".strings") && $0 != "InfoPlist.strings" }
                    .map { ($0 as NSString).deletingPathExtension }
                filesPerLproj.append(stringsFiles)
            } catch {
                continue
            }
        }

        guard !filesPerLproj.isEmpty else {
            return ["Localizable"]
        }

        // Count occurrences of each file
        var fileCount: [String: Int] = [:]
        for files in filesPerLproj {
            for file in files {
                fileCount[file, default: 0] += 1
            }
        }

        // Get files that appear in all directories
        let totalDirs = lprojPaths.count
        var commonFiles = fileCount.filter { $0.value == totalDirs }.map { $0.key }

        // If no common files, use files that appear in at least 50% of directories
        if commonFiles.isEmpty {
            let threshold = max(1, totalDirs / 2)
            commonFiles = fileCount.filter { $0.value >= threshold }.map { $0.key }
        }

        // If still no files, default to Localizable
        if commonFiles.isEmpty {
            return ["Localizable"]
        }

        return commonFiles.sorted()
    }

    /// Detects localization configuration in a project directory
    static func detectConfiguration(in projectPath: String) -> LocalizationConfig? {
        let fileManager = FileManager.default

        // Find all .lproj directories recursively
        var allLprojPaths: [(path: String, language: String)] = []

        if let enumerator = fileManager.enumerator(atPath: projectPath) {
            for case let file as String in enumerator {
                if file.hasSuffix(".lproj") {
                    let fullPath = (projectPath as NSString).appendingPathComponent(file)

                    // Extract language code from directory name (e.g., "es.lproj" -> "es")
                    let dirName = (file as NSString).lastPathComponent
                    let language = dirName.replacingOccurrences(of: ".lproj", with: "")

                    allLprojPaths.append((path: fullPath, language: language))
                }
            }
        }

        guard !allLprojPaths.isEmpty else {
            return nil
        }

        // Detect common .strings files
        let availableStringsFiles = detectCommonStringsFiles(in: allLprojPaths.map { $0.path })

        // Select default file: prefer "Localizable", otherwise use first
        let selectedStringsFile = availableStringsFiles.contains("Localizable") ? "Localizable" : availableStringsFiles[0]

        // Filter .lproj directories that contain the selected strings file
        var lprojPaths: [(path: String, language: String)] = []
        for lprojInfo in allLprojPaths {
            let stringsPath = (lprojInfo.path as NSString).appendingPathComponent("\(selectedStringsFile).strings")
            if fileManager.fileExists(atPath: stringsPath) {
                lprojPaths.append(lprojInfo)
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
            availableLanguages: availableLanguages,
            availableStringsFiles: availableStringsFiles,
            selectedStringsFile: selectedStringsFile
        )
    }

    /// Gets the path to a specific language's strings file
    static func stringsFilePath(for language: String, in config: LocalizationConfig) -> String {
        return "\(config.localizationPath)/\(language).lproj/\(config.selectedStringsFile).strings"
    }
}
