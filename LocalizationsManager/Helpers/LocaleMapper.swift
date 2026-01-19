//
//  LocaleMapper.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import Foundation

/// Maps locale identifiers to Xcode .lproj folder names
struct LocaleMapper {

    /// Dictionary mapping locale codes (e.g., "en_US") to .lproj folder names (e.g., "en-US.lproj")
    private static let localeMap: [String: String] = [
        "ar_AE": "ar.lproj",
        "ar_LB": "ar.lproj",
        "ar_MA": "ar.lproj",
        "ar_SA": "ar.lproj",
        "bg_BG": "bg.lproj",
        "ca_ES": "ca.lproj",
        "cs_CZ": "cs.lproj",
        "da_DK": "da.lproj",
        "de_DE": "de.lproj",
        "el_GR": "el.lproj",
        "en_GB": "en.lproj",
        "en_US": "en-US.lproj",
        "es_ES": "es.lproj",
        "es_MX": "es.lproj",
        "et_EE": "et.lproj",
        "eu_ES": "eu-ES.lproj",
        "fi_FI": "fi-FI.lproj",
        "fr_FR": "fr.lproj",
        "gl_ES": "gl-ES.lproj",
        "he_IL": "he.lproj",
        "hr_HR": "hr.lproj",
        "hu_HU": "hu.lproj",
        "id_ID": "id.lproj",
        "it_IT": "it.lproj",
        "ja_JP": "ja.lproj",
        "ka_GE": "ka-GE.lproj",
        "kk_KZ": "kk-KZ.lproj",
        "ko_KR": "ko.lproj",
        "lt_LT": "lt.lproj",
        "lv_LV": "lv.lproj",
        "mk_MK": "mk-MK.lproj",
        "nl_NL": "nl.lproj",
        "no_NO": "nb.lproj",
        "pl_PL": "pl.lproj",
        "pt_BR": "pt-BR.lproj",
        "pt_PT": "pt.lproj",
        "ro_RO": "ro.lproj",
        "ru_RU": "ru.lproj",
        "sk_SK": "sk.lproj",
        "sl_SI": "sl.lproj",
        "sq_AL": "sq.lproj",
        "sr_RS": "sr.lproj",
        "sv_SE": "sv.lproj",
        "th_TH": "th.lproj",
        "tr_TR": "tr.lproj",
        "uk_UA": "uk.lproj",
        "uz_UZ": "uz-UZ.lproj",
        "vi_VN": "vi.lproj",
        "zh_CN": "zh-Hans.lproj",
        "zh_TW": "zh-Hant.lproj"
    ]

    /// Converts a locale identifier to its corresponding .lproj folder name
    /// - Parameter locale: Locale identifier (e.g., "en_US")
    /// - Returns: The .lproj folder name (e.g., "en-US.lproj"), or nil if the locale is not supported
    static func lprojFolder(for locale: String) -> String? {
        return localeMap[locale]
    }

    /// Returns all supported locale identifiers
    static var supportedLocales: [String] {
        return Array(localeMap.keys).sorted()
    }

    /// Checks if a locale is supported
    /// - Parameter locale: Locale identifier to check
    /// - Returns: true if the locale is supported, false otherwise
    static func isSupported(locale: String) -> Bool {
        return localeMap[locale] != nil
    }
}
