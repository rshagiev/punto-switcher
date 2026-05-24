import Foundation
import PuntoCore

func runLegacyUserRulePolicyTests() throws {
    try expect(
        LegacyUserRulePolicy.legacyUserRulesDictionaryKey,
        PuntoSwitcherObservedSurface.UserRules.userRulesDictionaryKey,
        "legacy user rule policy keeps userRulesDictionary import key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyUserRulePolicy.legacyRuleStringKey,
        PuntoSwitcherObservedSurface.UserRules.ruleStringKey,
        "legacy user rule policy keeps rule_string field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyUserRulePolicy.legacyStringKey,
        PuntoSwitcherObservedSurface.UserRules.stringKey,
        "legacy user rule policy keeps string field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyUserRulePolicy.legacyRuleKey,
        PuntoSwitcherObservedSurface.UserRules.ruleKey,
        "legacy user rule policy keeps rule field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyUserRulePolicy.legacyIsActiveKey,
        PuntoSwitcherObservedSurface.UserRules.isActiveKey,
        "legacy user rule policy keeps is_active field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyUserRulePolicy.legacyIsRuleActiveKey,
        PuntoSwitcherObservedSurface.UserRules.isRuleActiveKey,
        "legacy user rule policy keeps isRuleActive field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyUserRulePolicy.legacyIsRegExpKey,
        PuntoSwitcherObservedSurface.UserRules.isRegExpKey,
        "legacy user rule policy keeps is_regexp field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyUserRulePolicy.legacyIsRegExpCamelKey,
        PuntoSwitcherObservedSurface.UserRules.isRegExpCamelKey,
        "legacy user rule policy keeps isRegExp field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyUserRulePolicy.legacyDoReplaceKey,
        PuntoSwitcherObservedSurface.UserRules.doReplaceKey,
        "legacy user rule policy keeps do_replace field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyUserRulePolicy.legacyShouldSwitchLayoutKey,
        PuntoSwitcherObservedSurface.UserRules.shouldSwitchLayoutKey,
        "legacy user rule policy keeps shouldSwitchLayout field aligned with reverse-audit anchor"
    )

    let legacyRules = LegacyUserRulePolicy.rules(from: [
        [
            "rule_string": " ghbdtn ",
            "rule": " привет ",
            "is_active": NSNumber(value: true),
            "is_regexp": NSNumber(value: false),
            "do_replace": NSNumber(value: true)
        ],
        [
            "string": "teh",
            "rule": "the",
            "isRuleActive": "yes",
            "isRegExp": "no",
            "shouldSwitchLayout": "true"
        ],
        [
            "rule_string": "inactive",
            "rule": "ignored",
            "is_active": NSNumber(value: false)
        ],
        [
            "rule_string": "regexp",
            "rule": "ignored",
            "is_regexp": NSNumber(value: true)
        ],
        [
            "rule_string": "switchOnly",
            "rule": "ignored",
            "do_replace": NSNumber(value: false)
        ],
        [
            "string": "layoutOnly",
            "rule": "ignored",
            "shouldSwitchLayout": "false"
        ]
    ])
    try expect(
        legacyRules,
        [
            AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"),
            AutoCorrectionRule(trigger: "teh", replacement: "the")
        ],
        "legacy user rule policy imports active non-regexp Punto Switcher replacement rules"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.createUserRuleSelector,
        "createUserRule",
        "observed surface preserves user-rule create selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.modifyUserRuleSelector,
        "modifyUserRule",
        "observed surface preserves user-rule modify selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.removeUserRuleWithIndexSelector,
        "removeUserRuleWithIndex:",
        "observed surface preserves user-rule remove selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.addUserRuleSelector,
        "addUserRuleWithString:rule:shouldSwitchLayout:isRuleActive:isRegExp:",
        "observed surface preserves user-rule add selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.modifyUserRuleWithIndexSelector,
        "modifyUserRuleWithIndex:string:rule:shouldSwitchLayout:isRuleActive:isRegExp:",
        "observed surface preserves user-rule indexed modify selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.showWordAddedTooltipSelector,
        "showWordAddedTooltip:",
        "observed surface preserves user-rule word-added tooltip selector"
    )
    try expect(
        LegacyUserRulePolicy.rules(from: []),
        [],
        "legacy user rule policy preserves observed empty userRulesDictionary as empty"
    )
    try expectNil(
        LegacyUserRulePolicy.rules(from: ["not": "array"]),
        "legacy user rule policy ignores unexpected userRulesDictionary shape"
    )
}
