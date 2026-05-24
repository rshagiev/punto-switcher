import Foundation

public enum LegacyUserRulePolicy {
    public static let userRulesDictionaryKey = "userRulesDictionary"
    public static let ruleStringKey = "rule_string"
    public static let stringKey = "string"
    public static let ruleKey = "rule"
    public static let isActiveKey = "is_active"
    public static let isRuleActiveKey = "isRuleActive"
    public static let isRegExpKey = "is_regexp"
    public static let isRegExpCamelKey = "isRegExp"
    public static let doReplaceKey = "do_replace"
    public static let shouldSwitchLayoutKey = "shouldSwitchLayout"

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

        guard boolValue(dictionary[isActiveKey] ?? dictionary[isRuleActiveKey], defaultValue: true) else {
            return nil
        }

        guard !boolValue(dictionary[isRegExpKey] ?? dictionary[isRegExpCamelKey], defaultValue: false) else {
            return nil
        }

        if let shouldReplace = boolValue(dictionary[doReplaceKey]) ?? boolValue(dictionary[shouldSwitchLayoutKey]),
           !shouldReplace {
            return nil
        }

        guard let trigger = stringValue(dictionary[ruleStringKey] ?? dictionary[stringKey])?.trimmingCharacters(in: .whitespacesAndNewlines),
              let replacement = stringValue(dictionary[ruleKey])?.trimmingCharacters(in: .whitespacesAndNewlines),
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
