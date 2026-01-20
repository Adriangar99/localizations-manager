//
//  LocalizationParserTests.swift
//  LocalizationsManagerTests
//
//  Created by Adrián García García on 20/1/26.
//

import Testing
import Foundation
@testable import LocalizationsManager

struct LocalizationParserTests {

    @Test func testParseValidStringsFile() throws {
        // Create temporary .strings file
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).strings")

        let content = """
        /* Comment 1 */
        "key1" = "value1";

        /* Comment 2 */
        "key2" = "value2";

        "key3" = "value with spaces";
        """

        try content.write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let keys = LocalizationParser.parseStringsFile(at: testFile.path)

        #expect(keys.count == 3)
        #expect(keys[0].key == "key1")
        #expect(keys[0].value == "value1")
        #expect(keys[1].key == "key2")
        #expect(keys[1].value == "value2")
        #expect(keys[2].key == "key3")
        #expect(keys[2].value == "value with spaces")
    }

    @Test func testParseEmptyFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("empty_\(UUID().uuidString).strings")

        try "".write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let keys = LocalizationParser.parseStringsFile(at: testFile.path)
        #expect(keys.isEmpty)
    }

    @Test func testParseFileWithSpecialCharacters() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("special_\(UUID().uuidString).strings")

        let content = """
        "key.with.dots" = "Value";
        "key_with_underscores" = "Another value";
        "key-with-dashes" = "Yet another";
        "UPPERCASE_KEY" = "uppercase value";
        """

        try content.write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let keys = LocalizationParser.parseStringsFile(at: testFile.path)

        #expect(keys.count == 4)
        #expect(keys.contains { $0.key == "key.with.dots" })
        #expect(keys.contains { $0.key == "key_with_underscores" })
        #expect(keys.contains { $0.key == "key-with-dashes" })
        #expect(keys.contains { $0.key == "UPPERCASE_KEY" })
    }

    @Test func testParseAlphabeticalSorting() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("sorted_\(UUID().uuidString).strings")

        let content = """
        "zebra" = "last";
        "apple" = "first";
        "middle" = "middle";
        """

        try content.write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let keys = LocalizationParser.parseStringsFile(at: testFile.path)

        #expect(keys.count == 3)
        #expect(keys[0].key == "apple")
        #expect(keys[1].key == "middle")
        #expect(keys[2].key == "zebra")
    }

    @Test func testParseNonExistentFile() {
        let keys = LocalizationParser.parseStringsFile(at: "/nonexistent/path/file.strings")
        #expect(keys.isEmpty)
    }

    @Test func testParseFileWithComments() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("comments_\(UUID().uuidString).strings")

        let content = """
        /* This is a comment */
        "key1" = "value1";

        // This is not a valid comment format for .strings but shouldn't break parsing

        /* Multi-line
           comment */
        "key2" = "value2";
        """

        try content.write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let keys = LocalizationParser.parseStringsFile(at: testFile.path)

        // Should only parse valid key-value pairs
        #expect(keys.count == 2)
        #expect(keys[0].key == "key1")
        #expect(keys[1].key == "key2")
    }
}
