import Foundation

public struct AutoCorrectionRuleImportResult: Equatable {
    public let rules: [AutoCorrectionRule]
    public let skippedLines: [Int: String]

    public init(rules: [AutoCorrectionRule], skippedLines: [Int: String] = [:]) {
        self.rules = rules
        self.skippedLines = skippedLines
    }
}

public enum AutoCorrectionRuleStore {
    public enum StoreError: Error, Equatable, CustomStringConvertible {
        case invalidUTF8
        case unsupportedFormat(String)

        public var description: String {
            switch self {
            case .invalidUTF8:
                return "Input is not valid UTF-8 text"
            case .unsupportedFormat(let message):
                return message
            }
        }
    }

    public static func decodeRules(from data: Data) throws -> AutoCorrectionRuleImportResult {
        if let jsonRules = try? JSONDecoder().decode([AutoCorrectionRule].self, from: data) {
            return AutoCorrectionRuleImportResult(rules: normalize(jsonRules))
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw StoreError.invalidUTF8
        }

        let result = parseDelimitedRules(text)
        if result.rules.isEmpty && result.skippedLines.isEmpty {
            throw StoreError.unsupportedFormat("No auto-correction rules found")
        }
        return result
    }

    public static func encodeRules(_ rules: [AutoCorrectionRule]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(normalize(rules))
    }

    public static func normalizedRules(_ rules: [AutoCorrectionRule]) -> [AutoCorrectionRule] {
        normalize(rules)
    }

    public static func mergedRules(existing: [AutoCorrectionRule], imported: [AutoCorrectionRule]) -> [AutoCorrectionRule] {
        normalize(existing + imported)
    }

    private static func parseDelimitedRules(_ text: String) -> AutoCorrectionRuleImportResult {
        var rules: [AutoCorrectionRule] = []
        var skipped: [Int: String] = [:]

        for (index, rawLine) in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).enumerated() {
            let lineNumber = index + 1
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix("//") {
                continue
            }

            guard let columns = splitDelimitedLine(line) else {
                skipped[lineNumber] = String(line)
                continue
            }
            guard columns.count >= 2 else {
                skipped[lineNumber] = String(line)
                continue
            }

            let trigger = columns[0].trimmingCharacters(in: .whitespaces)
            let replacement = columns[1].trimmingCharacters(in: .whitespaces)
            guard !trigger.isEmpty, !replacement.isEmpty else {
                skipped[lineNumber] = String(line)
                continue
            }

            let matchMode: AutoCorrectionRule.MatchMode
            if columns.count >= 3 {
                let rawMatchMode = columns[2].trimmingCharacters(in: .whitespaces)
                guard let parsedMatchMode = AutoCorrectionRule.MatchMode(rawValue: rawMatchMode) else {
                    skipped[lineNumber] = String(line)
                    continue
                }
                matchMode = parsedMatchMode
            } else {
                matchMode = .exact
            }

            let preserveCase: Bool
            if columns.count >= 4 {
                let rawPreserveCase = columns[3].trimmingCharacters(in: .whitespaces)
                guard let parsedPreserveCase = parseBool(rawPreserveCase) else {
                    skipped[lineNumber] = String(line)
                    continue
                }
                preserveCase = parsedPreserveCase
            } else {
                preserveCase = true
            }

            rules.append(AutoCorrectionRule(
                trigger: trigger,
                replacement: replacement,
                matchMode: matchMode,
                preserveCase: preserveCase
            ))
        }

        return AutoCorrectionRuleImportResult(rules: normalize(rules), skippedLines: skipped)
    }

    private static func splitDelimitedLine(_ line: String) -> [String]? {
        if line.contains("\t") {
            return line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        }
        if line.contains("=>") {
            return line.components(separatedBy: "=>")
        }
        if line.contains(",") {
            return splitCommaDelimitedLine(line)
        }
        return []
    }

    private static func splitCommaDelimitedLine(_ line: String) -> [String]? {
        var columns: [String] = []
        var current = ""
        var inQuotes = false
        var quotedFieldClosed = false
        let characters = Array(line)
        var index = 0

        while index < characters.count {
            let character = characters[index]

            if character == "\"" {
                if inQuotes, index + 1 < characters.count, characters[index + 1] == "\"" {
                    current.append(character)
                    index += 2
                    continue
                }

                if inQuotes {
                    inQuotes = false
                    quotedFieldClosed = true
                } else {
                    guard current.trimmingCharacters(in: .whitespaces).isEmpty else {
                        return nil
                    }
                    current = ""
                    inQuotes = true
                    quotedFieldClosed = false
                }
                index += 1
                continue
            }

            if character == ",", !inQuotes {
                columns.append(current)
                current = ""
                quotedFieldClosed = false
            } else {
                if quotedFieldClosed && !character.isWhitespace {
                    return nil
                }
                current.append(character)
            }

            index += 1
        }

        guard !inQuotes else {
            return nil
        }

        columns.append(current)
        return columns
    }

    private static func parseBool(_ value: String) -> Bool? {
        switch value.lowercased() {
        case "true", "yes", "1", "on":
            return true
        case "false", "no", "0", "off":
            return false
        default:
            return nil
        }
    }

    private static func normalize(_ rules: [AutoCorrectionRule]) -> [AutoCorrectionRule] {
        var byKey: [String: AutoCorrectionRule] = [:]
        var orderedKeys: [String] = []

        for rule in rules {
            let trigger = rule.trigger.trimmingCharacters(in: .whitespacesAndNewlines)
            let replacement = rule.replacement.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trigger.isEmpty, !replacement.isEmpty else { continue }

            let normalizedRule = AutoCorrectionRule(
                trigger: trigger,
                replacement: replacement,
                matchMode: rule.matchMode,
                preserveCase: rule.preserveCase
            )
            let key = "\(rule.matchMode.rawValue):\(rule.matchMode == .caseInsensitive ? trigger.lowercased() : trigger)"
            if byKey[key] == nil {
                orderedKeys.append(key)
            }
            byKey[key] = normalizedRule
        }

        return orderedKeys.compactMap { byKey[$0] }
    }
}
