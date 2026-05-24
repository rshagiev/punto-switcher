import Foundation
import PuntoCore

func runAutoCorrectionRuleSourcePolicyTests() throws {
    let starterRules = [
        AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    ]
    let persistedRules = [
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive)
    ]

    try expect(
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesDefaultConfPath,
        "switcher.use_old_rules",
        "observed surface pins Punto Switcher default-conf old-rules path"
    )
    try expect(
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesAccessor,
        "switcherUseOldRules",
        "observed surface pins Punto Switcher old-rules accessor"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.useOldRulesDefaultConfPath,
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesDefaultConfPath,
        "rule source policy keeps default-conf old-rules path aligned with reverse-audit anchor"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.useOldRulesAccessor,
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesAccessor,
        "rule source policy keeps old-rules accessor aligned with reverse-audit anchor"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
            starterRules: starterRules
        ),
        [
            AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"),
            AutoCorrectionRule(trigger: "custom", replacement: "замена")
        ],
        "rule source policy adds Punto Switcher userRulesDictionary rules to starter catalog"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [],
            starterRules: starterRules
        ),
        starterRules,
        "rule source policy keeps starter catalog when Punto Switcher userRulesDictionary is empty"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [],
            starterRules: starterRules,
            useStarterRules: false
        ),
        [],
        "rule source policy disables starter catalog when switcher.use_old_rules is false"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
            starterRules: starterRules,
            useStarterRules: false
        ),
        [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
        "rule source policy keeps user rules when old starter rules are disabled"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: persistedRules,
            legacyUserRules: [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
            starterRules: starterRules
        ),
        persistedRules,
        "rule source policy prefers native saved rules over Punto Switcher userRulesDictionary"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            starterRules: starterRules
        ),
        starterRules,
        "rule source policy uses starter catalog before rules are saved"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: persistedRules,
            starterRules: starterRules
        ),
        persistedRules,
        "rule source policy uses persisted user rules"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: [],
            starterRules: starterRules
        ),
        [],
        "rule source policy preserves intentionally empty persisted rules"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: nil,
            starterRules: starterRules
        ),
        starterRules,
        "rule source policy falls back to starter catalog for unreadable persisted rules"
    )
}

