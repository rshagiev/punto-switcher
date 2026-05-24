import Foundation

public enum AutoCorrectionRuleSourcePolicy {
    public static let useOldRulesDefaultConfPath = "switcher.use_old_rules"
    public static let useOldRulesAccessor = "switcherUseOldRules"

    public static func effectiveRules(
        hasPersistedRules: Bool,
        persistedRules: [AutoCorrectionRule]?,
        legacyUserRules: [AutoCorrectionRule]? = nil,
        starterRules: [AutoCorrectionRule] = AutoCorrectionStarterCatalog.rules,
        useStarterRules: Bool = SettingsPersistencePolicy.defaultAutoCorrectionStarterRulesEnabled
    ) -> [AutoCorrectionRule] {
        guard hasPersistedRules else {
            let starterRules = useStarterRules ? starterRules : []
            if let legacyUserRules, !legacyUserRules.isEmpty {
                return AutoCorrectionRuleStore.mergedRules(existing: starterRules, imported: legacyUserRules)
            }
            return starterRules
        }

        guard let persistedRules else {
            return starterRules
        }

        return persistedRules
    }
}
