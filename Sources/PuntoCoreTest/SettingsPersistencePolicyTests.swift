import Foundation
import PuntoCore

func runSettingsPersistencePolicyTests() throws {
    try expect(
        SettingsPersistencePolicy.defaultIsEnabled,
        true,
        "settings defaults keep Punto enabled"
    )
    try expect(
        SettingsPersistencePolicy.nativeIsEnabledKey,
        "isEnabled",
        "settings persistence preserves observed global enable key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setEnabledSelector,
        "setEnabled:",
        "settings persistence preserves observed global enable setter"
    )
    try expect(
        StartupPresentationPolicy.defaultIsFirstLaunch,
        true,
        "settings defaults treat missing first-launch marker as first launch"
    )
    try expect(
        SettingsPersistencePolicy.defaultShowInMenuBar,
        true,
        "settings defaults show menu bar icon"
    )
    try expect(
        SettingsPersistencePolicy.defaultShowAdvancedSettings,
        false,
        "settings defaults hide advanced settings like observed Punto Switcher plist"
    )
    try expect(
        SettingsPersistencePolicy.nativeShowAdvancedSettingsKey,
        "showAdvancedSettings",
        "settings persistence preserves observed advanced-settings key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setShowAdvancedSettingsSelector,
        "setShowAdvancedSettings:",
        "settings persistence preserves observed advanced-settings setter"
    )
    try expect(
        LoginItemPolicy.defaultLaunchAtLogin,
        false,
        "settings defaults do not launch at login"
    )
    try expect(
        LoginItemPolicy.legacyLaunchesOnStartupKey,
        "launchesOnStartup",
        "settings persistence preserves observed launch-at-login alias key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setLaunchesOnStartupSelector,
        "setLaunchesOnStartup:",
        "settings persistence preserves observed launch-at-login setter"
    )
    try expect(
        LayoutSwitchPolicy.defaultSwitchLayoutAfterConversion,
        false,
        "settings defaults do not switch input source after conversion"
    )
    try expect(
        LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion,
        true,
        "settings defaults allow selected-text layout switching when global switching is enabled"
    )
    try expect(
        LayoutSwitchPolicy.legacySwitchLayoutOnSelectedTextSwitchKey,
        "switchLayoutOnSelectedTextSwitch",
        "settings persistence preserves observed selected-text switch key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setSwitchLanguageWhenChangingSelectionLayoutSelector,
        "setSwitchLanguageWhenChangingSelectionLayout:",
        "settings persistence preserves observed selected-text switch setter"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion
        ),
        true,
        "settings persistence reads Punto Switcher switchLayoutOnSelectedTextSwitch alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion
        ),
        false,
        "settings persistence prefers native selected-text layout switch over Punto Switcher alias"
    )
    try expect(
        KeyboardLayoutTypePolicy.defaultRussianLayoutTypeRawValue,
        "mac",
        "settings defaults use Mac Russian keyboard layout"
    )
    try expect(
        TextActionPreflightPolicy.defaultManualConversionDisabled,
        false,
        "settings defaults keep manual conversion enabled"
    )
    try expect(
        TextActionPreflightPolicy.legacyIsManualConversionDisabledKey,
        "isManualConversionDisabled",
        "settings persistence preserves observed manual-conversion-disable key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setIsManualConversionDisabledSelector,
        "setIsManualConversionDisabled:",
        "settings persistence preserves observed manual-conversion-disable setter"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: TextActionPreflightPolicy.defaultManualConversionDisabled
        ),
        true,
        "settings persistence reads Punto Switcher isManualConversionDisabled alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: TextActionPreflightPolicy.defaultManualConversionDisabled
        ),
        false,
        "settings persistence prefers native manual conversion setting over Punto Switcher alias"
    )
    try expect(
        ApplicationLayoutPolicy.defaultRememberInputSourceForEachApp,
        false,
        "settings defaults keep per-app layout memory off"
    )
    try expect(
        ApplicationLayoutPolicy.legacyShouldRememberInputSourceForEachAppKey,
        "shouldRememberInputSourceForEachApp",
        "settings persistence preserves observed per-app layout memory key"
    )
    try expect(
        ApplicationLayoutMemory.defaultSnapshot,
        [:],
        "settings defaults start with empty remembered layout snapshot"
    )
    try expect(
        ApplicationDisablePolicy.defaultDisabledBundleIDs,
        [],
        "settings defaults start with no disabled applications"
    )
    try expect(
        ApplicationDisablePolicy.legacyDisabledAppsKey,
        "disabledApps",
        "settings persistence preserves observed disabled-apps key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setDisabledApplicationsSelector,
        "setDisabledApplications:",
        "settings persistence preserves observed disabled-apps setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.disabledAppsPreferencesControllerKey,
        "disabledAppsPreferencesController",
        "settings persistence preserves observed disabled-apps preferences controller key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setDisabledAppsPreferencesControllerSelector,
        "setDisabledAppsPreferencesController:",
        "settings persistence preserves observed disabled-apps preferences controller setter"
    )
    try expect(
        ApplicationDisablePolicy.defaultCompletelyDisableInExceptionApplications,
        false,
        "settings defaults keep exception apps partially disabled"
    )
    try expect(
        ApplicationDisablePolicy.legacyCompletelyDisableInExceptionApplicationsKey,
        "CompletelyDisableInExceptionApps",
        "settings persistence preserves observed full-disable exception-apps key"
    )
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
        SoundFeedbackPolicy.defaultSoundEffectsEnabled,
        false,
        "settings defaults keep sound effects off"
    )
    try expect(
        SoundFeedbackPolicy.legacyIsSoundOnKey,
        "isSoundOn",
        "sound feedback preserves observed global sound key"
    )
    try expect(
        PuntoSwitcherObservedSurface.SoundFeedback.setSoundStateSelector,
        "setSoundState:isSoundOn:",
        "sound feedback preserves observed sound-state setter"
    )
    try expect(
        ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion,
        true,
        "settings defaults restore pasteboard after clipboard fallbacks"
    )
    try expect(
        ClipboardReplacementPolicy.legacyShouldRestorePasteboardKey,
        "shouldRestorePasteboard",
        "clipboard replacement policy preserves observed pasteboard restore setting key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.previousPasteboardContentsKey,
        "previousPasteboardContents",
        "clipboard replacement policy preserves observed previous pasteboard storage key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.pasteboardRestoreTimerKey,
        "pasteboardRestoreTimer",
        "clipboard replacement policy preserves observed pasteboard restore timer key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.generalPasteboardSelector,
        "generalPasteboard",
        "clipboard replacement policy preserves observed general pasteboard selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.getPasteboardStringSelector,
        "getPasteboardString",
        "clipboard replacement policy preserves observed pasteboard read selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.setPasteboardStringSelector,
        "setPasteboardString:",
        "clipboard replacement policy preserves observed pasteboard write selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.restorePasteboardByTimerSelector,
        "restorePasteboardByTimer:",
        "clipboard replacement policy preserves observed AX pasteboard restore selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ClipboardReplacement.restorePasteboardForKeyboardByTimerSelector,
        "restorePasteboardForKeyboardByTimer:",
        "clipboard replacement policy preserves observed keyboard pasteboard restore selector"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: true,
            hasLegacyValue: true,
            legacyValue: false,
            defaultValue: ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion
        ),
        false,
        "settings persistence reads Punto Switcher shouldRestorePasteboard alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: true,
            hasLegacyValue: true,
            legacyValue: false,
            defaultValue: ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion
        ),
        true,
        "settings persistence prefers native pasteboard restore setting over Punto Switcher alias"
    )
    try expect(
        ProductStatisticsPolicy.defaultSnapshot,
        ProductStatisticsSnapshot(),
        "settings defaults start with empty product statistics"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBool(
            hasPersistedValue: false,
            persistedValue: false,
            defaultValue: true
        ),
        true,
        "settings persistence uses boolean default before a value is saved"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBool(
            hasPersistedValue: true,
            persistedValue: false,
            defaultValue: true
        ),
        false,
        "settings persistence preserves explicit false boolean value"
    )
    try expect(
        LegacyValuePolicy.bool(" YES "),
        true,
        "legacy value policy parses string-backed true boolean imports"
    )
    try expect(
        LegacyValuePolicy.bool("0"),
        false,
        "legacy value policy parses string-backed false boolean imports"
    )
    try expectNil(
        LegacyValuePolicy.bool("maybe"),
        "legacy value policy rejects unknown string-backed boolean imports"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: false
        ),
        true,
        "settings persistence reads Punto Switcher-style legacy boolean alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            legacyValue: LegacyValuePolicy.bool("on"),
            defaultValue: false
        ),
        true,
        "settings persistence reads string-backed Punto Switcher-style legacy boolean alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: LegacyValuePolicy.bool("0"),
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: true
        ),
        false,
        "settings persistence prefers string-backed native boolean key over legacy alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: true
        ),
        false,
        "settings persistence prefers native boolean key over legacy alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: true,
            invertedLegacyValue: false,
            defaultValue: false
        ),
        true,
        "settings persistence reads inverted Punto Switcher-style boolean alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            invertedLegacyValue: LegacyValuePolicy.bool("false"),
            defaultValue: false
        ),
        true,
        "settings persistence reads string-backed inverted Punto Switcher-style boolean alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: true,
            persistedValue: false,
            hasLegacyValue: true,
            invertedLegacyValue: false,
            defaultValue: true
        ),
        false,
        "settings persistence prefers native boolean key over inverted legacy alias"
    )
    try expect(
        ApplicationDisablePolicy.normalizedSet([
            " COM.Example.Editor ",
            "",
            "com.example.Terminal"
        ]),
        ["com.example.editor", "com.example.terminal"],
        "settings persistence normalizes disabled app ids"
    )
    try expect(
        ApplicationDisablePolicy.effectiveDisabledBundleIDs(
            hasPersistedValue: false,
            persistedValue: [],
            hasLegacyValue: true,
            legacyValue: [" COM.Example.Legacy ", ""]
        ),
        ["com.example.legacy"],
        "settings persistence reads Punto Switcher-style disabledApps alias"
    )
    try expect(
        ApplicationDisablePolicy.effectiveDisabledBundleIDs(
            hasPersistedValue: true,
            persistedValue: ["com.example.native"],
            hasLegacyValue: true,
            legacyValue: ["com.example.legacy"]
        ),
        ["com.example.native"],
        "settings persistence prefers native disabled app ids over legacy alias"
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
    try expect(
        KeyboardLayoutTypePolicy.normalized(" Windows "),
        .windows,
        "settings persistence normalizes Windows Russian keyboard layout type"
    )
    try expect(
        KeyboardLayoutTypePolicy.normalized("appl"),
        .mac,
        "settings persistence normalizes observed Punto Switcher Mac keyboard layout type"
    )
    try expect(
        KeyboardLayoutTypePolicy.normalized("unknown"),
        .mac,
        "settings persistence falls back to Mac Russian keyboard layout type"
    )
    try expect(
        KeyboardLayoutTypePolicy.effectiveRussianKeyboardLayoutType(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            legacyValue: "pc"
        ),
        .windows,
        "settings persistence reads Punto Switcher-style kbdLayoutType alias"
    )
    try expect(
        KeyboardLayoutTypePolicy.legacyRussianKeyboardLayoutTypeKey,
        "kbdLayoutType",
        "settings persistence owns observed Russian keyboard layout type key"
    )
    try expect(
        InputSourceSelectionPolicy.legacyEnglishInputSourceIDKey,
        "englishLayoutID",
        "settings persistence owns observed English input-source id key"
    )
    try expect(
        InputSourceSelectionPolicy.legacyRussianInputSourceIDKey,
        "russianLayoutID",
        "settings persistence owns observed Russian input-source id key"
    )
    try expect(
        KeyboardLayoutTypePolicy.effectiveRussianKeyboardLayoutType(
            hasPersistedValue: true,
            persistedValue: "mac",
            hasLegacyValue: true,
            legacyValue: "pc"
        ),
        .mac,
        "settings persistence prefers native keyboard layout type over legacy alias"
    )
    try expect(
        InputSourceSelectionPolicy.normalizedSourceID(" com.apple.keylayout.Dvorak "),
        "com.apple.keylayout.Dvorak",
        "settings persistence normalizes preferred input source ids"
    )
    try expectNil(
        InputSourceSelectionPolicy.normalizedSourceID(" \n\t "),
        "settings persistence rejects blank preferred input source ids"
    )
    try expectNil(
        InputSourceSelectionPolicy.normalizedSourceID(" undefined "),
        "settings persistence treats Punto Switcher UNDEFINED layout id as unset"
    )
    try expect(
        InputSourceSelectionPolicy.effectiveInputSourceID(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            legacyValue: " com.apple.keylayout.ABC "
        ),
        "com.apple.keylayout.ABC",
        "settings persistence reads Punto Switcher-style layout id alias"
    )
    try expectNil(
        InputSourceSelectionPolicy.effectiveInputSourceID(
            hasPersistedValue: false,
            persistedValue: nil,
            hasLegacyValue: true,
            legacyValue: "UNDEFINED"
        ),
        "settings persistence ignores Punto Switcher UNDEFINED layout id alias"
    )
    try expect(
        InputSourceSelectionPolicy.effectiveInputSourceID(
            hasPersistedValue: true,
            persistedValue: "com.apple.keylayout.Dvorak",
            hasLegacyValue: true,
            legacyValue: "com.apple.keylayout.ABC"
        ),
        "com.apple.keylayout.Dvorak",
        "settings persistence prefers native input source id over legacy alias"
    )
    try expect(
        ApplicationReturnKeyPolicy.normalizedResetBundleComponents([
            " Telegram ",
            "",
            "SLACK"
        ]),
        ["telegram", "slack"],
        "settings persistence normalizes reset-on-return components"
    )
    try expect(
        ApplicationReturnKeyPolicy.effectiveResetBundleComponents(
            hasPersistedComponents: false,
            persistedComponents: nil
        ),
        ApplicationReturnKeyPolicy.defaultResetBundleComponents,
        "settings persistence uses default reset-on-return components before user config"
    )
    try expect(
        ApplicationReturnKeyPolicy.effectiveResetBundleComponents(
            hasPersistedComponents: false,
            persistedComponents: nil,
            hasLegacyComponents: true,
            legacyComponents: [" Telegram ", "", "SLACK"]
        ),
        ["telegram", "slack"],
        "settings persistence reads Punto Switcher switcher.reset_on_return alias"
    )
    try expect(
        ApplicationReturnKeyPolicy.effectiveResetBundleComponents(
            hasPersistedComponents: true,
            persistedComponents: [],
            hasLegacyComponents: true,
            legacyComponents: ["telegram"]
        ),
        [],
        "settings persistence prefers intentionally empty native reset-on-return override"
    )
    try expect(
        ApplicationReturnKeyPolicy.effectiveResetBundleComponents(
            hasPersistedComponents: true,
            persistedComponents: nil,
            hasLegacyComponents: true,
            legacyComponents: ["telegram"]
        ),
        ApplicationReturnKeyPolicy.defaultResetBundleComponents,
        "settings persistence falls back to default for unreadable reset-on-return config"
    )

    let layouts = ApplicationLayoutMemory.normalizedSnapshot([
        " COM.Example.Editor ": " com.apple.keylayout.Russian ",
        "": "ignored",
        "com.example.empty": " ",
        "com.example.Terminal": "com.apple.keylayout.ABC"
    ])
    try expect(
        layouts["com.example.editor"],
        "com.apple.keylayout.Russian",
        "settings persistence normalizes remembered layout app ids"
    )
    try expect(
        layouts["com.example.terminal"],
        "com.apple.keylayout.ABC",
        "settings persistence preserves valid remembered layout ids"
    )
    try expectNil(
        layouts["com.example.empty"],
        "settings persistence drops blank remembered layout ids"
    )
    try expectNil(
        layouts[""],
        "settings persistence drops blank remembered app ids"
    )
}

func runLegacyValuePolicyTests() throws {
    let legacyDate = Date(timeIntervalSince1970: 1_230_757_200)

    try expect(
        LegacyValuePolicy.bool(" on "),
        true,
        "legacy value policy parses on-style true strings"
    )
    try expect(
        LegacyValuePolicy.bool("OFF"),
        false,
        "legacy value policy parses off-style false strings"
    )
    try expectNil(
        LegacyValuePolicy.bool("maybe"),
        "legacy value policy rejects unknown boolean strings"
    )
    try expect(
        LegacyValuePolicy.bool("maybe", defaultValue: true),
        true,
        "legacy value policy falls back for unknown boolean strings"
    )
    try expect(
        LegacyValuePolicy.int(" 42 "),
        42,
        "legacy value policy parses string-backed integers"
    )
    try expectNil(
        LegacyValuePolicy.int("4.2"),
        "legacy value policy rejects non-integer numeric strings"
    )
    try expect(
        LegacyValuePolicy.nonNegativeInt("-3", defaultValue: 7),
        0,
        "legacy value policy clamps negative integers"
    )
    try expect(
        LegacyValuePolicy.nonNegativeInt("bad", defaultValue: 7),
        7,
        "legacy value policy falls back for unreadable integers"
    )
    try expect(
        LegacyValuePolicy.date("2009-01-01 00:00:00 +0300"),
        legacyDate,
        "legacy value policy parses Punto Switcher date strings"
    )
    try expectNil(
        LegacyValuePolicy.date("1230757200"),
        "legacy value policy does not parse numeric date strings unless requested"
    )
    try expect(
        LegacyValuePolicy.date("1230757200", allowNumericString: true),
        legacyDate,
        "legacy value policy parses numeric date strings for policies that already accepted them"
    )
    try expect(
        LegacyValuePolicy.normalizedStringArray([" COM.Example.App ", "", "com.example.app", "org.example.Editor"]),
        ["com.example.app", "org.example.editor"],
        "legacy value policy normalizes bundle-id arrays"
    )
}
