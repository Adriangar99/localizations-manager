//
//  ContentView.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var config = ProjectConfiguration()

    var body: some View {
        Group {
            if let projectPath = config.projectPath,
               let localizationPath = config.localizationPath,
               let defaultLanguage = config.defaultLanguage,
               let selectedStringsFile = config.selectedStringsFile {
                MainTabView(
                    config: config,
                    projectPath: projectPath,
                    localizationPath: localizationPath,
                    defaultLanguage: defaultLanguage,
                    availableLanguages: config.availableLanguages,
                    selectedStringsFile: selectedStringsFile
                )
            } else {
                ProjectSetupView(config: config)
            }
        }
    }
}

#Preview {
    ContentView()
}
