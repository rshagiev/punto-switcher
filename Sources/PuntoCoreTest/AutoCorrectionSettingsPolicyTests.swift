import Foundation
import PuntoCore

func runAutoCorrectionSettingsPolicyTests() throws {
    try expect(
        AutoCorrectionPreflightPolicy.defaultAutoCorrectionEnabled,
        false,
        "settings defaults keep auto-correction off"
    )
    try expect(
        AutoCorrectionPreflightPolicy.legacyIsAutocorrectionActiveKey,
        "isAutocorrectionActive",
        "settings persistence preserves observed auto-correction active key"
    )
    try expect(
        AutoCorrectionUndoLearningPolicy.defaultUndoLearningEnabled,
        false,
        "settings defaults keep auto-correction undo learning off"
    )
    try expect(
        TextReplacementCommitPolicy.defaultSuppressAutoCorrectionAfterManualConversion,
        true,
        "settings defaults suppress auto-correction after manual conversion"
    )
    try expect(
        TextReplacementCommitPolicy.legacyShouldNotAutoconvertAfterConvertionKey,
        "shouldNotAutoconvertAfterConvertion",
        "settings persistence preserves observed post-conversion suppression key"
    )
    try expect(
        AutoCorrectionPreflightPolicy.legacyShouldNotAutoconvertWithTabOrEnterKey,
        "shouldNotAutoconvertWithTabOrEnter",
        "settings persistence owns observed Enter/Tab suppression key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.dontAutoconvertWordAfterConvertionSelector,
        "dontAutoconvertWordAfterConvertion:",
        "settings persistence preserves observed post-conversion suppression selector"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            invertedLegacyValue: false,
            defaultValue: TextReplacementCommitPolicy.defaultSuppressAutoCorrectionAfterManualConversion
        ),
        true,
        "settings persistence reads observed shouldNotAutoconvertAfterConvertion=false as suppression enabled"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            invertedLegacyValue: true,
            defaultValue: TextReplacementCommitPolicy.defaultSuppressAutoCorrectionAfterManualConversion
        ),
        false,
        "settings persistence reads observed shouldNotAutoconvertAfterConvertion=true as suppression disabled"
    )
    try expect(
        AutoCorrectionCancellingKeyPolicy.legacyCancellingKeysBitmaskKey,
        "cancellingKeys",
        "settings persistence owns observed cancelling-keys bitmask key"
    )
    try expect(
        AutoCorrectionCancellingKeyPolicy.legacyEnabledKeyNames(from: 0),
        [],
        "settings persistence reads observed Punto Switcher cancellingKeys=0 as no cancelling keys"
    )
    try expectNil(
        AutoCorrectionCancellingKeyPolicy.legacyEnabledKeyNames(from: 1),
        "settings persistence does not guess unknown Punto Switcher cancellingKeys bit order"
    )
    try expect(
        AutoCorrectionCancellingKeyPolicy.effectiveEnabledKeyNames(
            hasPersistedValue: false,
            persistedValue: [],
            hasLegacyValue: true,
            legacyBitmask: 0
        ),
        [],
        "settings persistence applies observed Punto Switcher cancellingKeys=0 alias"
    )
    try expect(
        AutoCorrectionCancellingKeyPolicy.effectiveEnabledKeyNames(
            hasPersistedValue: true,
            persistedValue: ["backspace"],
            hasLegacyValue: true,
            legacyBitmask: 0
        ),
        ["backspace"],
        "settings persistence prefers native cancelling-key names over legacy bitmask"
    )
    try expect(
        AutoCorrectionPreflightPolicy.defaultAutoCorrectOnEnterAndTab,
        true,
        "settings persistence defaults to auto-correction on Enter and Tab"
    )
    try expect(
        AutoCorrectionPreflightPolicy.legacyShouldNotAutoconvertWithTabOrEnterKey,
        "shouldNotAutoconvertWithTabOrEnter",
        "settings persistence preserves observed Enter/Tab suppression key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setDontAutoconvertWithEnterOrTabSelector,
        "setDontAutoconvertWithEnterOrTab:",
        "settings persistence preserves observed Enter/Tab suppression selector"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            invertedLegacyValue: false,
            defaultValue: AutoCorrectionPreflightPolicy.defaultAutoCorrectOnEnterAndTab
        ),
        true,
        "settings persistence reads observed shouldNotAutoconvertWithTabOrEnter=false as Enter/Tab auto-correction enabled"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            invertedLegacyValue: true,
            defaultValue: AutoCorrectionPreflightPolicy.defaultAutoCorrectOnEnterAndTab
        ),
        false,
        "settings persistence reads observed shouldNotAutoconvertWithTabOrEnter=true as Enter/Tab auto-correction disabled"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.defaultStarterRulesEnabled,
        true,
        "settings persistence defaults to Punto Switcher old-rules starter catalog"
    )
}
