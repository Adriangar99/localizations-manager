# LocalizationsManager

<div align="center">

**A modern macOS application for managing iOS/macOS project localizations**

![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Requirements](#requirements) • [Contributing](#contributing)

</div>

---

## Overview

LocalizationsManager is a powerful macOS helper application built with SwiftUI that streamlines the management of iOS and macOS project localizations. Say goodbye to manually editing dozens of `.strings` files across multiple language folders!

### What It Does

- **Import from Excel**: Bulk import localization strings from Excel files with automatic locale mapping
- **Bulk Delete**: Remove localization keys across all language variants in one click
- **Smart Detection**: Automatically detects all `.lproj` folders, languages, and `.strings` files in your Xcode project
- **Multiple Strings Files**: Works with any `.strings` file in your project, not just `Localizable.strings`
- **Real-time Feedback**: Live output log showing all operations and errors
- **Project Memory**: Quick access to recently configured projects

## Features

### 🌍 Multi-Language Support

Supports 30+ locale variants including:
- **Major languages**: English (US, GB, AU, CA), Spanish (ES, MX, AR), French (FR, CA), German, Italian, Portuguese (PT, BR)
- **Asian languages**: Chinese (Simplified, Traditional, HK), Japanese, Korean, Thai, Vietnamese, Indonesian
- **European languages**: Dutch, Swedish, Norwegian, Danish, Finnish, Polish, Russian, Turkish, Greek, Czech, Hungarian, Romanian
- **Middle Eastern**: Arabic, Hebrew
- **Other**: Hindi, Catalan, Ukrainian

### 📊 Excel Import

Import localizations from Excel files with the following format:

| Bundle Code | Locale | Text Key | Text Value |
|-------------|--------|----------|------------|
| com.example.app | en_US | welcome_message | Welcome to our app! |
| com.example.app | es_ES | welcome_message | ¡Bienvenido a nuestra aplicación! |
| com.example.app | fr_FR | welcome_message | Bienvenue dans notre application! |

The app will:
- Automatically map locale codes (e.g., `en_US`) to `.lproj` folders (e.g., `en-US.lproj`)
- Update existing keys and insert new ones alphabetically
- Add missing keys to your default language file
- Skip unsupported locales with clear logging

### 🗑️ Bulk Delete

Need to remove deprecated localization keys? The bulk delete feature:
- Lists all keys from your default language
- Allows multi-selection of keys to delete
- Removes selected keys from ALL language variants
- Cleans up associated comments and empty lines

### 🔍 Smart Project Detection

The app automatically:
- Scans your project directory for `.lproj` folders
- Detects all common `.strings` files across your language folders
- Allows you to select which `.strings` file to work with (e.g., `Localizable.strings`, `InfoPlist.strings`, or custom files)
- Determines your default language (prioritizes: Spanish → English → Base → others)
- Lists all available languages with display names

### 📝 Real-time Logging

Every operation is logged in real-time:
- Import progress and results
- Deletion confirmations
- Errors and warnings
- Locale mapping issues

## Requirements

### Runtime Requirements
- macOS 13.0 (Ventura) or later
- Python 3.x (pre-installed on macOS)
- Internet connection (first run only, to install `openpyxl` if needed)

### Development Requirements
- Xcode 15.0 or later
- Swift 5.9+
- macOS 13.0+ for development

## Installation

### Option 1: Build from Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/localizations-manager.git
cd localizations-manager
```

2. Open the project in Xcode:
```bash
open LocalizationsManager.xcodeproj
```

3. Build and run (⌘R)

### Option 2: Download Release (Coming Soon)

Pre-built binaries will be available in the [Releases](https://github.com/yourusername/localizations-manager/releases) section.

## Usage

### First Time Setup

1. **Launch the app** - You'll see the Project Setup screen

2. **Select your Xcode project**:
   - Click "Select Project Folder"
   - Navigate to your Xcode project root directory (where your `.xcodeproj` file is)
   - Select the folder

3. **Configure detection**:
   - The app will automatically detect all `.lproj` folders and available `.strings` files
   - Select which `.strings` file you want to work with
   - Review detected languages and the default language

4. **Start using** - Click "Continue" to access the main interface

### Importing from Excel

1. Go to the **Import** tab

2. **Prepare your Excel file** with these columns:
   - `Bundle Code`: Your app's bundle identifier (optional, for filtering)
   - `Locale`: Locale code (e.g., `en_US`, `es_ES`, `fr_FR`)
   - `Text Key`: The localization key
   - `Text Value`: The translated text

3. **Import the file**:
   - Drag and drop the Excel file, or
   - Click "Choose Excel File" to browse

4. **Review the logs** to see what was imported

### Deleting Keys

1. Go to the **Delete** tab

2. **Select keys to delete**:
   - Browse the list of all keys from your default language
   - Click to select individual keys, or
   - ⌘+Click for multiple selections

3. **Delete**:
   - Click "Delete Selected Keys"
   - Confirm the operation

4. **Review the logs** to see what was deleted

### Managing Projects

- **Recent Projects**: The app remembers your last 10 projects
- **Switch Projects**: Click "Change Project" in the main interface
- **Quick Access**: Recently used projects appear on the setup screen

## Excel File Format

### Required Columns

Your Excel file must include these exact column headers:

- `Bundle Code`
- `Locale`
- `Text Key`
- `Text Value`

### Example Excel Content

```
| Bundle Code         | Locale | Text Key           | Text Value                    |
|---------------------|--------|--------------------|------------------------------ |
| com.example.myapp   | en_US  | app_title          | My Awesome App                |
| com.example.myapp   | es_ES  | app_title          | Mi Aplicación Increíble       |
| com.example.myapp   | fr_FR  | app_title          | Mon Application Géniale       |
| com.example.myapp   | en_US  | settings_title     | Settings                      |
| com.example.myapp   | es_ES  | settings_title     | Configuración                 |
```

### Locale Code Mapping

The app uses intelligent locale mapping:

| Excel Locale | .lproj Folder | Language |
|--------------|---------------|----------|
| en_US        | en-US.lproj   | English (US) |
| es_ES        | es.lproj      | Spanish |
| fr_FR        | fr.lproj      | French |
| zh_CN        | zh-Hans.lproj | Chinese (Simplified) |
| zh_TW        | zh-Hant.lproj | Chinese (Traditional) |
| pt_BR        | pt-BR.lproj   | Portuguese (Brazil) |

## Architecture

### Project Structure

```
LocalizationsManager/
├── App/                      # App entry point
├── Models/                   # Data models
│   ├── ProjectConfiguration.swift
│   ├── LocalizationKey.swift
│   └── RecentProject.swift
├── Services/                 # Core business logic
│   ├── LocalizationDetector.swift
│   ├── LocalizationImporter.swift
│   ├── LocalizationDeleter.swift
│   └── LocalizationLogger.swift
├── Views/                    # SwiftUI views
│   ├── Components/           # Reusable UI components
│   ├── ContentView.swift
│   ├── MainTabView.swift
│   ├── ProjectSetupView.swift
│   ├── ImportView.swift
│   └── DeleteView.swift
├── Helpers/                  # Utility classes
│   ├── LocaleMapper.swift
│   ├── LanguageHelper.swift
│   └── ProjectInfoHelper.swift
└── Scripts/                  # Python scripts
    └── parse_excel.py
```

### Key Components

- **LocalizationDetector**: Scans projects for `.lproj` folders and languages
- **LocalizationImporter**: Imports from Excel using Python's `openpyxl`
- **LocalizationDeleter**: Bulk deletes keys across all languages
- **LocaleMapper**: Maps locale codes to `.lproj` folder names
- **ProjectConfiguration**: Manages app state and persistence

### Python Integration

The app uses a bundled Python script (`parse_excel.py`) to parse Excel files:
- Automatically installs `openpyxl` if not present
- Returns JSON output for processing
- Validates Excel file structure

## Development

### Building the Project

```bash
# Build
xcodebuild -project LocalizationsManager.xcodeproj -scheme LocalizationsManager build

# Run tests
xcodebuild -project LocalizationsManager.xcodeproj -scheme LocalizationsManager test

# Clean build
xcodebuild -project LocalizationsManager.xcodeproj -scheme LocalizationsManager clean build
```

### Running Tests

The project includes comprehensive unit tests:

```bash
# Run all tests
xcodebuild test -project LocalizationsManager.xcodeproj -scheme LocalizationsManager

# Run in Xcode
# Open project and press ⌘U
```

Test coverage includes:
- Locale mapping
- Project detection
- Localization parsing
- State management

### Code Style

- Swift code follows standard Swift conventions
- Use SwiftUI for all views
- Follow MVVM architecture pattern
- Document complex logic with comments

## Troubleshooting

### Common Issues

**Q: Import fails with "Missing required columns"**
- **A**: Verify your Excel file has exactly these column headers: "Bundle Code", "Locale", "Text Key", "Text Value"

**Q: Some locales are skipped during import**
- **A**: Check the output log for unsupported locale codes. The app supports 30+ locales - unsupported ones are logged and skipped.

**Q: Python/openpyxl errors**
- **A**: The app uses your system Python (`/usr/bin/python3`). Ensure Python 3 is installed and pip is functional.

**Q: Cannot access project files**
- **A**: The app requires full disk access. Grant permissions in System Settings > Privacy & Security > Full Disk Access.

**Q: Keys not appearing in Delete tab**
- **A**: Ensure your project has been detected correctly and has a default language configured.

### Getting Help

- Check the **output log** in the app for detailed error messages
- Review your Excel file format
- Verify your Xcode project structure has `.lproj` folders with `.strings` files
- Ensure you've selected the correct `.strings` file in the project configuration

## Contributing

Contributions are welcome! Here's how you can help:

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/yourusername/localizations-manager/issues)
2. Create a new issue with:
   - Detailed description
   - Steps to reproduce
   - Expected vs actual behavior
   - macOS version and app version
   - Relevant log output

### Suggesting Features

1. Open an issue with the `enhancement` label
2. Describe the feature and use case
3. Explain why it would be useful

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Ensure all tests pass
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Development Setup

1. Clone your fork
2. Open `LocalizationsManager.xcodeproj` in Xcode
3. Build and run (⌘R)
4. Make your changes
5. Run tests (⌘U)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI and Combine
- Excel parsing powered by Python's `openpyxl`
- Inspired by the need for efficient localization management in iOS/macOS development

## Contact

- **Issues**: [GitHub Issues](https://github.com/yourusername/localizations-manager/issues)
- **Author**: Adrián García García

---

<div align="center">
Made with ❤️ for iOS/macOS developers
</div>
