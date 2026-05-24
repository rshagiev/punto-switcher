import Foundation

public enum LegacyUserRulePolicy {
    public static let legacyUserRulesDictionaryKey = "userRulesDictionary"
    public static let legacyRuleStringKey = "rule_string"
    public static let legacyStringKey = "string"
    public static let legacyRuleKey = "rule"
    public static let legacyIsActiveKey = "is_active"
    public static let legacyIsRuleActiveKey = "isRuleActive"
    public static let legacyIsRegExpKey = "is_regexp"
    public static let legacyIsRegExpCamelKey = "isRegExp"
    public static let legacyDoReplaceKey = "do_replace"
    public static let legacyShouldSwitchLayoutKey = "shouldSwitchLayout"

    public static func rules(from legacyRules: Any?) -> [AutoCorrectionRule]? {
        guard let entries = legacyRules as? [Any] else {
            return nil
        }

        let rules = entries.compactMap(rule(from:))
        return rules.isEmpty ? [] : AutoCorrectionRuleStore.normalizedRules(rules)
    }

    private static func rule(from entry: Any) -> AutoCorrectionRule? {
        guard let dictionary = entry as? [String: Any] else {
            return nil
        }

        guard boolValue(dictionary[legacyIsActiveKey] ?? dictionary[legacyIsRuleActiveKey], defaultValue: true) else {
            return nil
        }

        guard !boolValue(dictionary[legacyIsRegExpKey] ?? dictionary[legacyIsRegExpCamelKey], defaultValue: false) else {
            return nil
        }

        if let shouldReplace = boolValue(dictionary[legacyDoReplaceKey]) ?? boolValue(dictionary[legacyShouldSwitchLayoutKey]),
           !shouldReplace {
            return nil
        }

        guard let trigger = stringValue(dictionary[legacyRuleStringKey] ?? dictionary[legacyStringKey])?.trimmingCharacters(in: .whitespacesAndNewlines),
              let replacement = stringValue(dictionary[legacyRuleKey])?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trigger.isEmpty,
              !replacement.isEmpty else {
            return nil
        }

        return AutoCorrectionRule(trigger: trigger, replacement: replacement)
    }

    private static func stringValue(_ value: Any?) -> String? {
        switch value {
        case let value as String:
            return value
        case let value as NSString:
            return value as String
        default:
            return nil
        }
    }

    private static func boolValue(_ value: Any?, defaultValue: Bool) -> Bool {
        LegacyValuePolicy.bool(value, defaultValue: defaultValue)
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        LegacyValuePolicy.bool(value)
    }
}
