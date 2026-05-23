import Foundation

public enum LegacyUserRulePolicy {
    public static let observedCreateUserRuleSelector = "createUserRule"
    public static let observedModifyUserRuleSelector = "modifyUserRule"
    public static let observedRemoveUserRuleWithIndexSelector = "removeUserRuleWithIndex:"
    public static let observedAddUserRuleSelector = "addUserRuleWithString:rule:shouldSwitchLayout:isRuleActive:isRegExp:"
    public static let observedModifyUserRuleWithIndexSelector = "modifyUserRuleWithIndex:string:rule:shouldSwitchLayout:isRuleActive:isRegExp:"
    public static let observedShowWordAddedTooltipSelector = "showWordAddedTooltip:"

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

    public static func dictionaries(from rules: [AutoCorrectionRule]) -> [[String: Any]] {
        AutoCorrectionRuleStore.normalizedRules(rules).map { rule in
            [
                ruleStringKey: rule.trigger,
                stringKey: rule.trigger,
                ruleKey: rule.replacement,
                isActiveKey: true,
                isRuleActiveKey: true,
                isRegExpKey: false,
                isRegExpCamelKey: false,
                doReplaceKey: true,
                shouldSwitchLayoutKey: true
            ]
        }
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
        boolValue(value) ?? defaultValue
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        switch value {
        case let value as Bool:
            return value
        case let value as NSNumber:
            return value.boolValue
        case let value as String:
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "yes", "1", "on":
                return true
            case "false", "no", "0", "off":
                return false
            default:
                return nil
            }
        default:
            return nil
        }
    }
}
