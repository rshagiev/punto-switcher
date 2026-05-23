import Foundation

public struct AutoCorrectionRule: Codable, Equatable {
    public enum MatchMode: String, Codable {
        case exact
        case caseInsensitive
    }

    public let trigger: String
    public let replacement: String
    public let matchMode: MatchMode
    public let preserveCase: Bool

    public init(
        trigger: String,
        replacement: String,
        matchMode: MatchMode = .exact,
        preserveCase: Bool = true
    ) {
        self.trigger = trigger
        self.replacement = replacement
        self.matchMode = matchMode
        self.preserveCase = preserveCase
    }
}

public struct AutoCorrectionDecision: Equatable {
    public let original: String
    public let replacement: String
    public let rule: AutoCorrectionRule

    public init(original: String, replacement: String, rule: AutoCorrectionRule) {
        self.original = original
        self.replacement = replacement
        self.rule = rule
    }
}

public final class AutoCorrectionEngine {
    private let exactRules: [String: AutoCorrectionRule]
    private let caseInsensitiveRules: [String: AutoCorrectionRule]

    public init(rules: [AutoCorrectionRule]) {
        var exact: [String: AutoCorrectionRule] = [:]
        var caseInsensitive: [String: AutoCorrectionRule] = [:]

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

            switch rule.matchMode {
            case .exact:
                exact[trigger] = normalizedRule
            case .caseInsensitive:
                caseInsensitive[trigger.lowercased()] = normalizedRule
            }
        }

        self.exactRules = exact
        self.caseInsensitiveRules = caseInsensitive
    }

    public func correction(for completedWord: String) -> AutoCorrectionDecision? {
        guard !completedWord.isEmpty else { return nil }

        if let rule = exactRules[completedWord], rule.replacement != completedWord {
            return AutoCorrectionDecision(original: completedWord, replacement: rule.replacement, rule: rule)
        }

        let lowered = completedWord.lowercased()
        guard let rule = caseInsensitiveRules[lowered] else { return nil }

        let replacement = rule.preserveCase
            ? Self.applyCasePattern(from: completedWord, to: rule.replacement)
            : rule.replacement

        guard replacement != completedWord else { return nil }
        return AutoCorrectionDecision(original: completedWord, replacement: replacement, rule: rule)
    }

    private static func applyCasePattern(from original: String, to replacement: String) -> String {
        let originalLetters = original.filter { $0.isLetter }
        guard !originalLetters.isEmpty else {
            return replacement
        }

        if original == original.uppercased() {
            return replacement.uppercased()
        }

        if original == original.lowercased() {
            return replacement.lowercased()
        }

        guard let first = original.first else { return replacement }
        let rest = original.dropFirst()
        if String(first).uppercased() == String(first), rest == rest.lowercased() {
            return replacement.prefix(1).uppercased() + replacement.dropFirst().lowercased()
        }

        guard originalLetters.contains(where: { $0.isUppercase }) else {
            return replacement
        }

        var result = ""
        var patternIndex = originalLetters.startIndex

        for character in replacement {
            guard character.isLetter else {
                result.append(character)
                continue
            }

            if patternIndex < originalLetters.endIndex {
                let pattern = originalLetters[patternIndex]
                result += pattern.isUppercase ? character.uppercased() : character.lowercased()
                patternIndex = originalLetters.index(after: patternIndex)
            } else {
                result += character.lowercased()
            }
        }

        return result
    }
}
