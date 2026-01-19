//
//  LocalizationKey.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import Foundation

struct LocalizationKey: Identifiable, Hashable {
    let id = UUID()
    let key: String
    let value: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    static func == (lhs: LocalizationKey, rhs: LocalizationKey) -> Bool {
        lhs.key == rhs.key
    }
}

class LocalizationParser {
    static func parseStringsFile(at path: String) -> [LocalizationKey] {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return []
        }

        var keys: [LocalizationKey] = []
        let lines = content.components(separatedBy: .newlines)

        // Regex pattern to match: "key" = "value";
        let pattern = #"^\s*"(.+?)"\s*=\s*"(.*?)";\s*$"#

        for line in lines {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {

                if let keyRange = Range(match.range(at: 1), in: line),
                   let valueRange = Range(match.range(at: 2), in: line) {
                    let key = String(line[keyRange])
                    let value = String(line[valueRange])
                    keys.append(LocalizationKey(key: key, value: value))
                }
            }
        }

        return keys.sorted { $0.key < $1.key }
    }
}
