//
//  LocalizationDeleter.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import Foundation

/// Service for deleting localization keys from .strings files across all .lproj folders
final class LocalizationDeleter {

    private let logger: LocalizationLogger

    init(logger: LocalizationLogger) {
        self.logger = logger
    }

    /// Deletes the specified localization keys from all .strings files in the project
    /// - Parameters:
    ///   - keys: Array of localization keys to delete
    ///   - projectPath: Path to the project containing .lproj folders
    ///   - stringsFileName: Name of the .strings file to process (without extension)
    /// - Throws: LocalizationError if the operation fails
    func deleteKeys(
        _ keys: [String],
        from projectPath: String,
        stringsFileName: String
    ) async throws {
        guard !keys.isEmpty else {
            throw LocalizationError.emptyKeysList
        }

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: projectPath) else {
            throw LocalizationError.projectPathNotFound(projectPath)
        }

        await logger.log("🗑️  Starting deletion process...")
        await logger.log("📂 Project path: \(projectPath)")
        await logger.log("   Keys to delete: \(keys.count)")
        await logger.log("")

        let keysSet = Set(keys)
        var processedFiles = 0
        var totalDeleted = 0

        // Find all .lproj directories
        let lprojDirs = try findLprojDirectories(in: projectPath)
        await logger.log("🔍 Found \(lprojDirs.count) .lproj directories")
        await logger.log("")

        await logger.log("🧹 Cleaning files...")
        for lprojDir in lprojDirs {
            let lprojURL = URL(fileURLWithPath: lprojDir)

            // Process only the selected .strings file
            let targetFileName = "\(stringsFileName).strings"
            let filePath = lprojURL.appendingPathComponent(targetFileName).path

            // Check if the file exists before processing
            if fileManager.fileExists(atPath: filePath) {
                let deletedCount = try cleanStringsFile(at: filePath, removingKeys: keysSet)
                if deletedCount > 0 {
                    totalDeleted += deletedCount
                }
                processedFiles += 1
            }
        }

        await logger.log("")
        await logger.log("✅ Deletion completed!")
        await logger.log("   • Processed: \(processedFiles) file(s)")
        await logger.log("   • Deleted: \(totalDeleted) key(s)")
    }

    /// Finds all .lproj directories in the project path (excluding third-party directories)
    private func findLprojDirectories(in path: String) throws -> [String] {
        // Delegate to the shared exclusion logic in LocalizationDetector
        return LocalizationDetector.findLprojDirectories(in: path)
    }

    /// Cleans a .strings file by removing specified keys along with their comments
    /// - Returns: Number of keys deleted
    private func cleanStringsFile(at filePath: String, removingKeys keysToDelete: Set<String>) throws -> Int {
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            return 0 // Skip if file cannot be read
        }

        let lines = content.components(separatedBy: .newlines)
        var newLines: [String] = []
        var i = 0
        var deletedCount = 0

        // Regex pattern to match: "key" = "value";
        let pattern = #"^\s*"(.+?)"\s*=\s*".*?";\s*$"#
        let regex = try NSRegularExpression(pattern: pattern)

        while i < lines.count {
            let line = lines[i]

            // Check if this line is a localization entry
            let range = NSRange(line.startIndex..., in: line)
            if let match = regex.firstMatch(in: line, range: range),
               let keyRange = Range(match.range(at: 1), in: line) {
                let key = String(line[keyRange])

                if keysToDelete.contains(key) {
                    // Delete comment above if it exists
                    while !newLines.isEmpty &&
                          newLines.last?.trimmingCharacters(in: .whitespaces).hasPrefix("/*") == true {
                        newLines.removeLast()
                    }

                    // Delete empty lines before the comment
                    while !newLines.isEmpty &&
                          newLines.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
                        newLines.removeLast()
                    }

                    // Skip this translation line
                    deletedCount += 1
                    i += 1
                    continue
                }
            }

            newLines.append(line)
            i += 1
        }

        // Only write if changes were made
        if deletedCount > 0 {
            let newContent = newLines.joined(separator: "\n")
            try newContent.write(toFile: filePath, atomically: true, encoding: .utf8)
        }

        return deletedCount
    }
}

/// Errors that can occur during localization operations
enum LocalizationError: LocalizedError {
    case projectPathNotFound(String)
    case emptyKeysList
    case invalidExcelFile(String)
    case missingRequiredColumns([String])
    case unsupportedLocale(String)

    var errorDescription: String? {
        switch self {
        case .projectPathNotFound(let path):
            return "Project path not found: \(path)"
        case .emptyKeysList:
            return "No keys provided to delete"
        case .invalidExcelFile(let reason):
            return "Invalid Excel file: \(reason)"
        case .missingRequiredColumns(let columns):
            return "Excel file missing required columns: \(columns.joined(separator: ", "))"
        case .unsupportedLocale(let locale):
            return "Unsupported locale: \(locale)"
        }
    }
}
