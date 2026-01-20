# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LocalizationsManager is a macOS helper application built with SwiftUI for managing iOS/macOS project localizations. It allows importing localization strings from Excel files and bulk-deleting localization keys across all language variants (.lproj folders).

## Build and Development Commands

### Building the Project
```bash
# Build the project
xcodebuild -project LocalizationsManager.xcodeproj -scheme LocalizationsManager build

# Clean build
xcodebuild -project LocalizationsManager.xcodeproj -scheme LocalizationsManager clean build

# Run tests
xcodebuild -project LocalizationsManager.xcodeproj -scheme LocalizationsManager test
```

### Running the App
Open `LocalizationsManager.xcodeproj` in Xcode and run directly (⌘R).

## Architecture

### Application Flow

The app uses a configuration-driven flow:
1. **ProjectSetupView**: Initial setup screen for selecting an Xcode project directory
2. **ProjectConfiguration**: Detects `.lproj` folders and `Localizable.strings` files automatically via `LocalizationDetector`
3. **MainTabView**: Main interface with two tabs (Import and Delete) once project is configured

### Core Services

**LocalizationDetector** (`Services/LocalizationDetector.swift`)
- Scans project directories to find all `.lproj` folders containing `Localizable.strings`
- Determines default language (prioritizes: es > en > Base > others)
- Returns `LocalizationConfig` with base path and available languages

**LocalizationImporter** (`Services/LocalizationImporter.swift`)
- Imports localizations from Excel files to `.strings` files
- Uses Python script (`Scripts/parse_excel.py`) with `openpyxl` to parse Excel files
- Expected Excel columns: "Bundle Code", "Locale", "Text Key", "Text Value"
- Automatically adds missing keys to default language (using key as value)
- Updates existing keys and inserts new ones alphabetically

**LocalizationDeleter** (`Services/LocalizationDeleter.swift`)
- Bulk deletes localization keys across all `.lproj` folders
- Removes keys along with their associated comments and empty lines
- Uses regex pattern to match `.strings` file format: `"key" = "value";`

**LocaleMapper** (`Helpers/LocaleMapper.swift`)
- Maps locale identifiers (e.g., "en_US", "es_ES") to Xcode `.lproj` folder names
- Critical for Excel import: converts locale codes to proper folder names
- Examples: "en_US" → "en-US.lproj", "zh_CN" → "zh-Hans.lproj"

### Python Integration

The Excel parsing relies on a Python script at `LocalizationsManager/Scripts/parse_excel.py`:
- Must be bundled with the app (included in Build Phases > Copy Bundle Resources)
- Auto-installs `openpyxl` if missing using `pip install --user`
- Executes via `/usr/bin/python3` and returns JSON output
- Validates required Excel columns before parsing

### State Management

**ProjectConfiguration** (`Models/ProjectConfiguration.swift`)
- Main app state as `ObservableObject`
- Persists configuration to `UserDefaults`
- Manages recent projects list (max 10 entries)
- Auto-saves on any property change

### File Structure Conventions

```
LocalizationsManager/
├── App/                      # App entry point
├── Models/                   # Data models (ProjectConfiguration, LocalizationKey, RecentProject)
├── Services/                 # Core business logic (Detector, Importer, Deleter, Logger)
├── Views/                    # SwiftUI views
│   ├── Components/           # Reusable UI components
│   ├── ContentView.swift     # Root view with conditional rendering
│   ├── MainTabView.swift     # Main interface with tabs
│   ├── ProjectSetupView.swift
│   ├── ImportView.swift
│   └── DeleteView.swift
├── Helpers/                  # Utility classes (LocaleMapper, LanguageHelper, ProjectInfoHelper)
└── Scripts/                  # Python scripts for Excel parsing
```

## Important Implementation Notes

### Working with .strings Files

The `.strings` file format is parsed using this regex pattern:
```
^\s*"(.+?)"\s*=\s*"(.*?)";\s*$
```

When adding new keys, the importer follows this format:
```
/* No comment provided by engineer. */
"key" = "value";
```

### Locale Handling

Always use `LocaleMapper.lprojFolder(for:)` to convert locale codes from Excel to `.lproj` folder names. Unsupported locales are skipped during import and logged once.

### Error Handling

All service operations are async and throw `LocalizationError` with specific cases:
- `projectPathNotFound(String)`
- `emptyKeysList`
- `invalidExcelFile(String)`
- `missingRequiredColumns([String])`
- `unsupportedLocale(String)`

### Logging

Services use `LocalizationLogger` for async logging to avoid UI blocking. All logs are displayed in real-time via `OutputLogView` component.

## Testing Strategy

- Unit tests in `LocalizationsManagerTests/`
- UI tests in `LocalizationsManagerUITests/`
- Test localization parsing with various `.strings` file formats
- Test Excel import with different locale combinations
- Test deletion across multiple `.lproj` folders
