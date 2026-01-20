//
//  LocalizationKeyTests.swift
//  LocalizationsManagerTests
//
//  Created by Adrián García García on 20/1/26.
//

import Testing
import Foundation
@testable import LocalizationsManager

struct LocalizationKeyTests {

    @Test func testLocalizationKeyEquality() {
        let key1 = LocalizationKey(key: "test.key", value: "Test Value")
        let key2 = LocalizationKey(key: "test.key", value: "Different Value")
        let key3 = LocalizationKey(key: "different.key", value: "Test Value")

        // Keys with same key string should be equal
        #expect(key1 == key2)
        // Keys with different key strings should not be equal
        #expect(key1 != key3)
    }

    @Test func testLocalizationKeyHashing() {
        let key1 = LocalizationKey(key: "test.key", value: "Test Value")
        let key2 = LocalizationKey(key: "test.key", value: "Different Value")

        var set = Set<LocalizationKey>()
        set.insert(key1)
        set.insert(key2)

        // Should only contain one element since keys are the same
        #expect(set.count == 1)
    }
}
