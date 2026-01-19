//
//  LocalizationImporter.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import Foundation

/// Service for importing localizations from Excel files to .strings files
final class LocalizationImporter {

    private let stringFileName = "Localizable"
    private let logger: LocalizationLogger

    init(logger: LocalizationLogger) {
        self.logger = logger
    }

    /// Imports localizations from an Excel file to the project's .lproj folders
    /// - Parameters:
    ///   - excelPath: Path to the Excel file (.xlsx)
    ///   - targetPath: Path to the project where .lproj folders are located
    ///   - defaultLanguage: Default language code (e.g., "en", "es") to ensure all keys have a fallback value
    /// - Throws: LocalizationError if the operation fails
    func importLocalizations(
        from excelPath: String,
        to targetPath: String,
        defaultLanguage: String
    ) async throws {
        await logger.log("📁 Excel file: \(excelPath)")
        await logger.log("📂 Target path: \(targetPath)")
        await logger.log("")

        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: excelPath) else {
            throw LocalizationError.invalidExcelFile("File not found")
        }

        guard fileManager.fileExists(atPath: targetPath) else {
            throw LocalizationError.projectPathNotFound(targetPath)
        }

        // Parse Excel file using Python + openpyxl - this is done ONCE
        await logger.log("📖 Parsing Excel file...")
        var localizations = try parseExcelFile(at: excelPath)
        await logger.log("   ✓ Parsed \(localizations.count) localization entries")
        await logger.log("")

        // Ensure all keys have a value in the default language
        let defaultLprojFolder = "\(defaultLanguage).lproj"

        // Find all unique keys
        let allKeys = Set(localizations.map { $0.key })

        // Find keys that exist in default language
        let defaultLanguageKeys = Set(localizations.filter { localization in
            guard let lprojFolder = LocaleMapper.lprojFolder(for: localization.locale) else {
                return false
            }
            return lprojFolder == defaultLprojFolder
        }.map { $0.key })

        // Find keys missing in default language
        let missingKeysInDefault = allKeys.subtracting(defaultLanguageKeys)

        if !missingKeysInDefault.isEmpty {
            await logger.log("🔑 Found \(missingKeysInDefault.count) key(s) without value in default language (\(defaultLanguage))")
            await logger.log("   Adding them with key as value...")

            // Get the first locale that maps to the default .lproj folder
            // This is necessary because the locale in the Excel might be different (e.g., "en_US" maps to "en.lproj")
            let defaultLocale = LocaleMapper.supportedLocales.first { locale in
                LocaleMapper.lprojFolder(for: locale) == defaultLprojFolder
            } ?? defaultLanguage

            // Add missing keys to localizations with key as value
            for key in missingKeysInDefault.sorted() {
                let entry = LocalizationEntry(
                    bundle: "",
                    locale: defaultLocale,
                    key: key,
                    value: key
                )
                localizations.append(entry)
            }

            await logger.log("   ✓ Added \(missingKeysInDefault.count) key(s) to \(defaultLanguage)")
            await logger.log("")
        }

        // Group by locale and file
        var groupedLocalizations: [String: [String: [String: String]]] = [:]
        var skippedLocales = Set<String>()

        for localization in localizations {
            guard let lprojFolder = LocaleMapper.lprojFolder(for: localization.locale) else {
                skippedLocales.insert(localization.locale)
                continue
            }

            if groupedLocalizations[lprojFolder] == nil {
                groupedLocalizations[lprojFolder] = [:]
            }

            if groupedLocalizations[lprojFolder]?[stringFileName] == nil {
                groupedLocalizations[lprojFolder]?[stringFileName] = [:]
            }

            groupedLocalizations[lprojFolder]?[stringFileName]?[localization.key] = localization.value
        }

        // Log skipped locales once
        if !skippedLocales.isEmpty {
            await logger.log("⚠️  Skipped unsupported locales: \(skippedLocales.sorted().joined(separator: ", "))")
            await logger.log("")
        }

        // Update .strings files
        await logger.log("📝 Updating \(groupedLocalizations.count) locale(s)...")
        var processedFiles = 0
        var totalUpdated = 0
        var totalAdded = 0
        var allAddedKeys = Set<String>()

        for (lprojFolder, files) in groupedLocalizations {
            // Extract locale code from .lproj folder
            let localeCode = lprojFolder.replacingOccurrences(of: ".lproj", with: "")

            for (fileName, updates) in files {
                let filePath = (targetPath as NSString)
                    .appendingPathComponent(lprojFolder)
                    .appending("/\(fileName).strings")

                let stats = try await patchStringsFile(at: filePath, with: updates, locale: localeCode)
                totalUpdated += stats.updated
                totalAdded += stats.added

                for key in stats.addedKeys {
                    allAddedKeys.insert(key)
                }

                processedFiles += 1
            }
        }

        await logger.log("")
        await logger.log("✅ Import completed!")
        await logger.log("   • Processed: \(processedFiles) file(s)")
        await logger.log("   • Updated: \(totalUpdated)")
        await logger.log("   • Added: \(totalAdded)")

        // Show detailed summary of added keys
        if !allAddedKeys.isEmpty {
            await logger.log("")
            await logger.log("➕ Added keys:")
            let sortedKeys = allAddedKeys.sorted()
            await logger.log("   \(sortedKeys.joined(separator: ", "))")
        }
    }

    /// Parses an Excel file using Python + openpyxl
    private func parseExcelFile(at path: String) throws -> [LocalizationEntry] {
        // Get path to Python script

        guard let finalPath = Bundle.main.path(forResource: "parse_excel", ofType: "py") else {
            throw LocalizationError.invalidExcelFile("Python script not found.")
        }

        // Execute Python script
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [finalPath, path]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            // Read output
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            guard process.terminationStatus == 0 else {
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                throw LocalizationError.invalidExcelFile("Python script failed: \(errorMessage)")
            }

            // Parse JSON response
            guard let jsonResult = try? JSONSerialization.jsonObject(with: outputData) as? [String: Any] else {
                throw LocalizationError.invalidExcelFile("Invalid JSON response from Python script")
            }

            // Check for errors
            if let error = jsonResult["error"] as? String {
                throw LocalizationError.invalidExcelFile(error)
            }

            // Parse entries
            guard let entriesArray = jsonResult["entries"] as? [[String: String]] else {
                throw LocalizationError.invalidExcelFile("Invalid entries format in JSON")
            }

            var entries: [LocalizationEntry] = []
            for entryDict in entriesArray {
                guard let bundle = entryDict["bundle"],
                      let locale = entryDict["locale"],
                      let key = entryDict["key"],
                      let value = entryDict["value"] else {
                    continue
                }

                entries.append(LocalizationEntry(
                    bundle: bundle,
                    locale: locale,
                    key: key,
                    value: value
                ))
            }

            return entries

        } catch {
            throw LocalizationError.invalidExcelFile("Failed to execute Python script: \(error.localizedDescription)")
        }
    }

    /// Statistics for a strings file update operation
    private struct PatchStats {
        let updated: Int
        let added: Int
        let addedKeys: [String]
    }

    /// Updates a .strings file with new or modified keys
    private func patchStringsFile(
        at filePath: String,
        with updates: [String: String],
        locale: String
    ) async throws -> PatchStats {
        var updates = updates
        let fileManager = FileManager.default

        // Read existing file or create empty array
        let lines: [String]
        if fileManager.fileExists(atPath: filePath) {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            lines = content.components(separatedBy: .newlines)
        } else {
            lines = []
        }

        // Parse existing keys
        let pattern = #"^\s*"(.+?)"\s*=\s*"(.*?)";\s*$"#
        let regex = try NSRegularExpression(pattern: pattern)
        var keyLines: [String: Int] = [:]
        var newLines = lines

        for (idx, line) in newLines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Skip comments
            if trimmedLine.hasPrefix("/*") && trimmedLine.hasSuffix("*/") {
                continue
            }

            let range = NSRange(line.startIndex..., in: line)
            if let match = regex.firstMatch(in: line, range: range),
               let keyRange = Range(match.range(at: 1), in: line) {
                let key = String(line[keyRange])
                keyLines[key] = idx
            }
        }

        // Track stats for bulk logging
        var updatedCount = 0
        var addedCount = 0
        var addedKeys: [String] = []

        // Update existing keys
        for (key, value) in updates {
            if let idx = keyLines[key] {
                let oldLine = newLines[idx].trimmingCharacters(in: .whitespaces)
                let newLine = "\"\(key)\" = \"\(value)\";"

                if oldLine != newLine {
                    newLines[idx] = newLine
                    updatedCount += 1
                }

                updates.removeValue(forKey: key)
            }
        }

        // Insert new keys alphabetically
        if !updates.isEmpty {
            let newKeysSorted = updates.sorted { $0.key < $1.key }
            let allKeysSorted = (Array(keyLines.keys) + newKeysSorted.map(\.key)).sorted()

            for (key, value) in newKeysSorted {
                // Find insertion index
                guard let keyIndex = allKeysSorted.firstIndex(of: key) else {
                    continue
                }

                let insertIdx: Int
                if keyIndex == 0 {
                    insertIdx = 0
                } else {
                    let prevKey = allKeysSorted[keyIndex - 1]
                    if let prevIdx = keyLines[prevKey] {
                        insertIdx = prevIdx + 1
                    } else {
                        insertIdx = newLines.count
                    }
                }

                // Insert: empty line + comment + key-value
                let linesToInsert = [
                    "",
                    "/* No comment provided by engineer. */",
                    "\"\(key)\" = \"\(value)\";"
                ]

                for (offset, lineToInsert) in linesToInsert.enumerated() {
                    newLines.insert(lineToInsert, at: insertIdx + offset)
                }

                // Update key_lines mapping
                keyLines[key] = insertIdx + 2

                // Shift subsequent indices
                for (k, v) in keyLines where k != key && v >= insertIdx {
                    keyLines[k] = v + 3
                }

                addedCount += 1
                addedKeys.append(key)
            }
        }

        // Write back to file
        let directoryPath = (filePath as NSString).deletingLastPathComponent
        try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)

        let newContent = newLines.joined(separator: "\n")
        try newContent.write(toFile: filePath, atomically: true, encoding: .utf8)

        // Log summary once
        if updatedCount > 0 || addedCount > 0 {
            await logger.log("   \(locale)")
            await logger.log("   updated \(updatedCount), added \(addedCount)")
            await logger.log("")
        }

        return PatchStats(updated: updatedCount, added: addedCount, addedKeys: addedKeys)
    }
}

/// Represents a single localization entry from the Excel file
private struct LocalizationEntry {
    let bundle: String
    let locale: String
    let key: String
    let value: String
}
