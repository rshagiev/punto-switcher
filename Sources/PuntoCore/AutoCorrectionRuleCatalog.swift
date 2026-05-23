import Foundation

public struct AutoCorrectionRuleValidationIssue: Equatable {
    public enum Severity: String, Equatable {
        case error
        case warning
    }

    public let ruleIndex: Int
    public let severity: Severity
    public let message: String

    public init(ruleIndex: Int, severity: Severity, message: String) {
        self.ruleIndex = ruleIndex
        self.severity = severity
        self.message = message
    }
}

public enum AutoCorrectionRuleCatalog {
    public static func filteredRuleIndexes(in rules: [AutoCorrectionRule], query: String) -> [Int] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else {
            return Array(rules.indices)
        }

        return rules.indices.filter { index in
            let rule = rules[index]
            let trigger = rule.trigger.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let replacement = rule.replacement.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return trigger.contains(needle)
                || replacement.contains(needle)
                || rule.matchMode.rawValue.lowercased().contains(needle)
        }
    }

    public static func validationIssues(for rules: [AutoCorrectionRule]) -> [AutoCorrectionRuleValidationIssue] {
        var issues: [AutoCorrectionRuleValidationIssue] = []
        var seen: [String: Int] = [:]

        for (index, rule) in rules.enumerated() {
            let trigger = rule.trigger.trimmingCharacters(in: .whitespacesAndNewlines)
            let replacement = rule.replacement.trimmingCharacters(in: .whitespacesAndNewlines)

            if trigger.isEmpty {
                issues.append(AutoCorrectionRuleValidationIssue(
                    ruleIndex: index,
                    severity: .error,
                    message: "Trigger is empty"
                ))
            }

            if replacement.isEmpty {
                issues.append(AutoCorrectionRuleValidationIssue(
                    ruleIndex: index,
                    severity: .error,
                    message: "Replacement is empty"
                ))
            }

            if trigger == replacement, !trigger.isEmpty {
                issues.append(AutoCorrectionRuleValidationIssue(
                    ruleIndex: index,
                    severity: .warning,
                    message: "Replacement is identical"
                ))
            }

            let key = "\(rule.matchMode.rawValue):\(rule.matchMode == .caseInsensitive ? trigger.lowercased() : trigger)"
            if !trigger.isEmpty, let firstIndex = seen[key] {
                issues.append(AutoCorrectionRuleValidationIssue(
                    ruleIndex: index,
                    severity: .warning,
                    message: "Duplicate of row \(firstIndex + 1)"
                ))
            } else {
                seen[key] = index
            }
        }

        return issues
    }

    public static func hasBlockingIssues(_ rules: [AutoCorrectionRule]) -> Bool {
        validationIssues(for: rules).contains { $0.severity == .error }
    }
}
