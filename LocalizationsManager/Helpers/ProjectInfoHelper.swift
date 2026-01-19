//
//  ProjectInfoHelper.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import Foundation
import AppKit
import SwiftUI

struct ProjectInfoHelper {
    // Get project name from path
    static func getProjectName(from projectPath: String) -> String {
        let url = URL(fileURLWithPath: projectPath)

        // Look for .xcodeproj in the directory
        let fileManager = FileManager.default

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: projectPath)
            if let xcodeprojFile = contents.first(where: { $0.hasSuffix(".xcodeproj") }) {
                // Remove .xcodeproj extension
                return xcodeprojFile.replacingOccurrences(of: ".xcodeproj", with: "")
            }
        } catch {
            // If we can't read directory, fall back to directory name
        }

        // Fallback: use directory name
        return url.lastPathComponent
    }

    // Get icon for the project (from Assets.xcassets matching project name)
    static func getProjectIcon(from projectPath: String) -> NSImage? {
        // Try to find AppIcon matching project name
        if let appIcon = findAppIcon(in: projectPath) {
            return appIcon
        }

        // If no matching icon found, return nil to use generic icon
        return nil
    }

    // Find AppIcon in Assets.xcassets
    private static func findAppIcon(in projectPath: String) -> NSImage? {
        let fileManager = FileManager.default
        let projectName = getProjectName(from: projectPath)

        // Search for all .appiconset directories recursively
        if let appiconsetPaths = findAppIconSets(in: projectPath, fileManager: fileManager) {
            // First, try to find an .appiconset matching the project name
            for appiconsetPath in appiconsetPaths {
                let appiconsetName = (appiconsetPath as NSString).lastPathComponent
                    .replacingOccurrences(of: ".appiconset", with: "")

                // Check if this appiconset matches the project name or is the main AppIcon
                if appiconsetName.lowercased() == projectName.lowercased() ||
                   appiconsetName.lowercased() == "appicon" {
                    if let appStoreIcon = loadAppStoreIcon(from: appiconsetPath, fileManager: fileManager) {
                        return appStoreIcon
                    }
                }
            }
        }

        return nil
    }

    // Search for all .appiconset directories recursively
    private static func findAppIconSets(in path: String, fileManager: FileManager) -> [String]? {
        guard let enumerator = fileManager.enumerator(atPath: path) else { return nil }

        var appiconsets: [String] = []

        while let element = enumerator.nextObject() as? String {
            if element.hasSuffix(".appiconset") {
                let fullPath = (path as NSString).appendingPathComponent(element)
                appiconsets.append(fullPath)
            }
        }

        return appiconsets.isEmpty ? nil : appiconsets
    }

    // Load the App Store icon (1024x1024) from an .appiconset
    private static func loadAppStoreIcon(from appiconsetPath: String, fileManager: FileManager) -> NSImage? {
        let contentsJsonPath = (appiconsetPath as NSString).appendingPathComponent("Contents.json")

        // Try to read Contents.json
        if fileManager.fileExists(atPath: contentsJsonPath) {
            if let appStoreIcon = loadIconFromContentsJson(contentsJsonPath: contentsJsonPath, appiconsetPath: appiconsetPath) {
                return appStoreIcon
            }
        }

        // Fallback: search for files with "1024" in the name
        return loadIconByFilename(from: appiconsetPath, fileManager: fileManager)
    }

    // Parse Contents.json and find App Store icon (ios-marketing or 1024x1024)
    private static func loadIconFromContentsJson(contentsJsonPath: String, appiconsetPath: String) -> NSImage? {
        do {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: contentsJsonPath))

            if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let images = json["images"] as? [[String: Any]] {

                // Look for ios-marketing (App Store icon) or 1024x1024
                for imageInfo in images {
                    let idiom = imageInfo["idiom"] as? String
                    let size = imageInfo["size"] as? String

                    // App Store icon is marked as "ios-marketing" or size "1024x1024"
                    if idiom == "ios-marketing" || size == "1024x1024" {
                        if let filename = imageInfo["filename"] as? String {
                            let imagePath = (appiconsetPath as NSString).appendingPathComponent(filename)
                            if let image = NSImage(contentsOfFile: imagePath) {
                                return image
                            }
                        }
                    }
                }
            }
        } catch {
            // Failed to parse JSON
        }

        return nil
    }

    // Fallback: find icon by filename containing "1024"
    private static func loadIconByFilename(from appiconsetPath: String, fileManager: FileManager) -> NSImage? {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: appiconsetPath)

            // Look for files with "1024" in the name
            for file in contents {
                let lowercased = file.lowercased()
                if lowercased.contains("1024") && (lowercased.hasSuffix(".png") || lowercased.hasSuffix(".jpg") || lowercased.hasSuffix(".jpeg")) {
                    let imagePath = (appiconsetPath as NSString).appendingPathComponent(file)
                    if let image = NSImage(contentsOfFile: imagePath) {
                        return image
                    }
                }
            }
        } catch {
            // Failed to read directory
        }

        return nil
    }
}

// SwiftUI wrapper for NSImage
struct NSImageView: View {
    let image: NSImage?
    let size: CGFloat

    var body: some View {
        if let image = image {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            // Generic app icon
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.225)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)

                Image(systemName: "app.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.white)
            }
        }
    }
}
