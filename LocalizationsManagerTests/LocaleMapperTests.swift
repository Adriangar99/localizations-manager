//
//  LocaleMapperTests.swift
//  LocalizationsManagerTests
//
//  Created by Adrián García García on 20/1/26.
//

import Testing
import Foundation
@testable import LocalizationsManager

struct LocaleMapperTests {

    @Test func testSupportedLocaleMapping() {
        // Test common locales
        #expect(LocaleMapper.lprojFolder(for: "en_US") == "en-US.lproj")
        #expect(LocaleMapper.lprojFolder(for: "en_GB") == "en.lproj")
        #expect(LocaleMapper.lprojFolder(for: "es_ES") == "es.lproj")
        #expect(LocaleMapper.lprojFolder(for: "es_MX") == "es.lproj")
        #expect(LocaleMapper.lprojFolder(for: "fr_FR") == "fr.lproj")
        #expect(LocaleMapper.lprojFolder(for: "de_DE") == "de.lproj")
    }

    @Test func testChineseLocaleMapping() {
        // Test Chinese variants
        #expect(LocaleMapper.lprojFolder(for: "zh_CN") == "zh-Hans.lproj")
        #expect(LocaleMapper.lprojFolder(for: "zh_TW") == "zh-Hant.lproj")
    }

    @Test func testPortugueseLocaleMapping() {
        // Test Portuguese variants
        #expect(LocaleMapper.lprojFolder(for: "pt_BR") == "pt-BR.lproj")
        #expect(LocaleMapper.lprojFolder(for: "pt_PT") == "pt.lproj")
    }

    @Test func testUnsupportedLocale() {
        // Test unsupported locale returns nil
        #expect(LocaleMapper.lprojFolder(for: "xx_XX") == nil)
        #expect(LocaleMapper.lprojFolder(for: "invalid") == nil)
        #expect(LocaleMapper.lprojFolder(for: "") == nil)
    }

    @Test func testIsSupported() {
        #expect(LocaleMapper.isSupported(locale: "en_US") == true)
        #expect(LocaleMapper.isSupported(locale: "es_ES") == true)
        #expect(LocaleMapper.isSupported(locale: "xx_XX") == false)
        #expect(LocaleMapper.isSupported(locale: "") == false)
    }

    @Test func testSupportedLocalesNotEmpty() {
        // Verify we have supported locales
        let locales = LocaleMapper.supportedLocales
        #expect(locales.count > 0)
        #expect(locales.contains("en_US"))
        #expect(locales.contains("es_ES"))
    }
}
