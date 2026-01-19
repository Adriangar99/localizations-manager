//
//  LanguageHelper.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import Foundation

struct LanguageHelper {
    // Map language codes to full language names
    static func name(for languageCode: String) -> String {
        let lowercased = languageCode.lowercased()

        switch lowercased {
        case "es":
            return "Spanish"
        case "en":
            return "English"
        case "en-gb":
            return "English (UK)"
        case "en-au":
            return "English (Australia)"
        case "en-ca":
            return "English (Canada)"
        case "fr":
            return "French"
        case "de":
            return "German"
        case "it":
            return "Italian"
        case "pt":
            return "Portuguese"
        case "pt-br":
            return "Portuguese (Brazil)"
        case "ja":
            return "Japanese"
        case "ko":
            return "Korean"
        case "zh-hans", "zh-cn", "zh":
            return "Chinese (Simplified)"
        case "zh-hant", "zh-tw":
            return "Chinese (Traditional)"
        case "zh-hk":
            return "Chinese (Hong Kong)"
        case "ar":
            return "Arabic"
        case "ru":
            return "Russian"
        case "nl":
            return "Dutch"
        case "pl":
            return "Polish"
        case "tr":
            return "Turkish"
        case "sv":
            return "Swedish"
        case "da":
            return "Danish"
        case "fi":
            return "Finnish"
        case "no":
            return "Norwegian"
        case "el":
            return "Greek"
        case "cs":
            return "Czech"
        case "hu":
            return "Hungarian"
        case "ro":
            return "Romanian"
        case "th":
            return "Thai"
        case "id":
            return "Indonesian"
        case "vi":
            return "Vietnamese"
        case "uk":
            return "Ukrainian"
        case "ca":
            return "Catalan"
        case "hr":
            return "Croatian"
        case "he":
            return "Hebrew"
        case "hi":
            return "Hindi"
        case "ms":
            return "Malay"
        case "sk":
            return "Slovak"
        case "base":
            return "Base"
        default:
            return languageCode.uppercased()
        }
    }

    // Format language with code: "Spanish (es)"
    static func displayName(for languageCode: String) -> String {
        return "\(name(for: languageCode)) (\(languageCode))"
    }
}
