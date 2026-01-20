# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LocalizationsManager is a macOS helper application built with SwiftUI for managing iOS/macOS project localizations. It allows importing localization strings from Excel files and bulk-deleting localization keys across all language variants (.lproj folders).

**Version**: 1.0.1 (Build 2)
**Bundle ID**: com.magicalonso.LocalizationsManager
**Category**: Developer Tools
**Minimum macOS**: 13.0 (Ventura)

### Key Features

1. **Excel Import**: Import localization strings from Excel files with automatic locale mapping
2. **Bulk Delete**: Delete localization keys across all language variants simultaneously
3. **Project Detection**: Automatic detection of `.lproj` folders and `Localizable.strings` files
4. **Recent Projects**: Quick access to recently configured projects
5. **Real-time Logging**: Live output log showing all operations and errors
6. **Multi-language Support**: Handles 30+ locale variants with intelligent mapping

## Requirements

### Development Requirements
- **Xcode**: 15.0 or later
- **macOS**: 13.0 (Ventura) or later for development
- **Swift**: 5.9+
- **Python**: 3.x (system default `/usr/bin/python3`)
- **Python Packages**: `openpyxl` (auto-installed by the app if missing)

### Runtime Requirements
- **macOS**: 13.0 (Ventura) or later
- **Python**: Pre-installed system Python 3
- **App Sandbox**: Disabled (requires file system access to Xcode projects)

## Build and Development Commands

### Building the Project
```bash
# Build the project
xcodebuild -project LocalizationsManager.xcodeproj -scheme LocalizationsManager build

# Clean build
xcodebuild -project LocalizationsManager.xcodeproj -scheme LocalizationsManager clean build

# Run tests
xcodebuild -project LocalizationsManager.xcodeproj -scheme LocalizationsManager test

# Build for release
xcodebuild -project LocalizationsManager.xcodeproj -scheme LocalizationsManager -configuration Release build
```

### Running the App
Open `LocalizationsManager.xcodeproj` in Xcode and run directly (⌘R).

### Code Signing
The app is configured to run without App Sandbox to allow full file system access to Xcode project directories.

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

**LocalizationLogger** (`Services/LocalizationLogger.swift`)
- Async logging service to prevent UI blocking
- Publishes log messages through Combine for real-time display
- Maintains log history for debugging

**LanguageHelper** (`Helpers/LanguageHelper.swift`)
- Provides human-readable display names for language codes
- Maps `.lproj` folder names to localized language names

**ProjectInfoHelper** (`Helpers/ProjectInfoHelper.swift`)
- Extracts project metadata (name, bundle ID) from Xcode project files
- Parses `.pbxproj` files to read project configuration

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

### Views and UI Components

**Main Views**
- **ContentView**: Root coordinator view that switches between setup and main interface
- **ProjectSetupView**: Initial project selection and configuration screen
- **MainTabView**: Tab-based interface with Import and Delete functionality
- **ImportView**: Excel file import with drag-and-drop support
- **DeleteView**: Bulk key deletion with multi-selection list

**Reusable Components**
- **OutputLogView**: Scrollable log viewer with auto-scroll to bottom
- **LocalizationKeyRow**: List row displaying key name and language count
- **EmptyStateView**: Placeholder view for empty states with icon and message
- **GlassButtonStyles**: Custom button styles with glassmorphism effects
- **CountBadge**: Circular badge displaying counts (e.g., language count)
- **ListSectionHeader**: Styled section headers for grouped lists

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
- Test coverage for:
  - `LocaleMapperTests`: Locale code to `.lproj` folder name mapping
  - `LocalizationDetectorTests`: Project scanning and language detection
  - `LocalizationKeyTests`: Localization key model validation
  - `LocalizationParserTests`: `.strings` file parsing with various formats
  - `ProjectConfigurationTests`: State management and persistence
- Manual testing recommended for:
  - Excel import with real-world files
  - Deletion across multiple `.lproj` folders
  - Python script integration and `openpyxl` installation

## Supported Locales

The app supports 30+ locale variants through `LocaleMapper`, including:
- Major languages: English (US, GB, AU, CA), Spanish (ES, MX, AR), French (FR, CA), German, Italian, Portuguese (PT, BR)
- Asian languages: Chinese (Simplified, Traditional, HK), Japanese, Korean, Thai, Vietnamese, Indonesian
- European languages: Dutch, Swedish, Norwegian, Danish, Finnish, Polish, Russian, Turkish, Greek, Czech, Hungarian, Romanian
- Middle Eastern: Arabic, Hebrew
- Other: Hindi, Catalan, Ukrainian

Unsupported or unknown locale codes in Excel files are logged and skipped during import.

## Deployment and Distribution

### Building for Distribution
```bash
# Archive for distribution
xcodebuild -project LocalizationsManager.xcodeproj -scheme LocalizationsManager -configuration Release archive -archivePath build/LocalizationsManager.xcarchive

# Export app
xcodebuild -exportArchive -archivePath build/LocalizationsManager.xcarchive -exportPath build -exportOptionsPlist exportOptions.plist
```

### Important Notes
- **Code Signing**: Configure your development team and signing certificate in Xcode
- **Python Script**: The `parse_excel.py` script must be included in Copy Bundle Resources build phase
- **No Sandboxing**: App requires file system access, so App Sandbox must remain disabled
- **Notarization**: For distribution outside the App Store, notarize the app with Apple

## Troubleshooting

### Common Issues

1. **Python script not found**: Ensure `parse_excel.py` is in Copy Bundle Resources
2. **openpyxl installation fails**: Check system Python and pip are functional
3. **Cannot access project files**: Verify App Sandbox is disabled
4. **Import fails silently**: Check Excel file has required columns: "Bundle Code", "Locale", "Text Key", "Text Value"
5. **Locale not recognized**: Verify locale code is supported in `LocaleMapper.swift`

### Debug Tips
- Check the output log in the app for detailed error messages
- Use `LocalizationLogger` to add custom logging during development
- Test with sample Excel files containing various locale combinations
