import Foundation

public enum AutoCorrectionUndoLearningPolicy {
    public static func originAfterUndo(record: ConversionRecord) -> ConversionOrigin {
        ConversionOriginPolicy.originAfterUndo(record: record)
    }

    public static func learnedRulesAfterUndo(
        rules: [AutoCorrectionRule],
        record: ConversionRecord,
        isUndoLearningEnabled: Bool = true
    ) -> [AutoCorrectionRule]? {
        guard isUndoLearningEnabled else {
            return nil
        }

        guard case .autoCorrection(let undoneRule) = record.origin else {
            return nil
        }

        let learnedRules = rules.filter { rule in
            !matches(rule, undoneRule: undoneRule)
        }

        guard learnedRules.count < rules.count else {
            return nil
        }
        return learnedRules
    }

    private static func matches(_ rule: AutoCorrectionRule, undoneRule: AutoCorrectionRule) -> Bool {
        normalizedTrigger(rule.trigger, matchMode: rule.matchMode) == normalizedTrigger(undoneRule.trigger, matchMode: undoneRule.matchMode) &&
        normalized(rule.replacement) == normalized(undoneRule.replacement) &&
        rule.matchMode == undoneRule.matchMode &&
        rule.preserveCase == undoneRule.preserveCase
    }

    private static func normalizedTrigger(_ value: String, matchMode: AutoCorrectionRule.MatchMode) -> String {
        let normalized = normalized(value)
        switch matchMode {
        case .exact:
            return normalized
        case .caseInsensitive:
            return normalized.lowercased()
        }
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
