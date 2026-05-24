import Foundation
import PuntoCore

func runApplicationLayoutMemoryTests() throws {
    let memory = ApplicationLayoutMemory()

    try expectNil(memory.layoutID(for: "com.example.editor"), "empty layout memory")

    memory.remember(bundleID: "com.example.editor", layoutID: "com.apple.keylayout.ABC")
    try expect(
        memory.layoutID(for: "com.example.editor"),
        "com.apple.keylayout.ABC",
        "layout memory stores bundle layout"
    )

    memory.remember(bundleID: "com.example.terminal", layoutID: "com.apple.keylayout.Russian")
    try expect(
        memory.snapshot().count,
        2,
        "layout memory snapshot includes remembered apps"
    )

    memory.forget(bundleID: "com.example.editor")
    try expectNil(memory.layoutID(for: "com.example.editor"), "layout memory forgets app")

    memory.remember(bundleID: "", layoutID: "ignored")
    memory.remember(bundleID: "com.example.empty", layoutID: "")
    try expectNil(memory.layoutID(for: "com.example.empty"), "layout memory ignores empty ids")

    memory.remember(bundleID: "  COM.Example.Editor  ", layoutID: "  com.apple.keylayout.Russian  ")
    try expect(
        memory.layoutID(for: "com.example.editor"),
        "com.apple.keylayout.Russian",
        "layout memory normalizes bundle id case and whitespace on remember"
    )
    try expect(
        memory.snapshot()["com.example.editor"],
        "com.apple.keylayout.Russian",
        "layout memory snapshot stores normalized ids"
    )

    memory.replaceAll(with: [
        " COM.Example.Terminal ": " com.apple.keylayout.ABC ",
        "": "ignored",
        "com.example.empty": " "
    ])
    try expect(
        memory.layoutID(for: "com.example.terminal"),
        "com.apple.keylayout.ABC",
        "layout memory normalizes restored settings snapshot"
    )
    try expectNil(
        memory.layoutID(for: "com.example.empty"),
        "layout memory drops empty restored layout ids"
    )
}

func runApplicationBundleIDPolicyTests() throws {
    try expect(
        ApplicationBundleIDPolicy.normalized("  COM.Example.Editor  "),
        "com.example.editor",
        "application bundle id policy trims and lowercases ids"
    )
    try expectNil(
        ApplicationBundleIDPolicy.normalized("   "),
        "application bundle id policy rejects blank ids"
    )
    try expectNil(
        ApplicationBundleIDPolicy.normalized(nil),
        "application bundle id policy rejects missing ids"
    )
    try expect(
        ApplicationBundleIDPolicy.normalizedSet([" COM.Example.Editor ", "", "com.example.Terminal"]),
        ["com.example.editor", "com.example.terminal"],
        "application bundle id policy normalizes persisted sets"
    )
    try expect(
        ApplicationBundleIDPolicy.isObservedScreenSaverEngine(" COM.Apple.ScreenSaver.Engine "),
        true,
        "application bundle id policy recognizes observed Punto Switcher screen saver engine bundle id"
    )
    try expect(
        ApplicationBundleIDPolicy.isVolatileSystemContext("com.apple.ScreenSaver.Engine"),
        true,
        "application bundle id policy treats screen saver engine as volatile system context"
    )
    try expect(
        ApplicationBundleIDPolicy.isVolatileSystemContext("com.example.editor"),
        false,
        "application bundle id policy keeps ordinary apps non-volatile"
    )
    try expect(
        ApplicationDisablePolicy.normalizedSet([" COM.Example.Editor ", "", "com.example.Terminal"]),
        ApplicationBundleIDPolicy.normalizedSet([" COM.Example.Editor ", "", "com.example.Terminal"]),
        "application disable policy shares bundle id normalization"
    )
    try expect(
        AccessibilityApplicationPolicy.isObservedBrowserInjectionBundleID(" COM.Apple.Safari "),
        true,
        "accessibility app policy shares bundle id normalization"
    )

    let session = ConversionSession()
    session.record(
        originalText: "ghbdtn",
        convertedText: "привет",
        replacementMethod: .keyboardBackspacePaste,
        contextID: " COM.Example.Editor "
    )
    try expect(
        session.lastConversion?.contextID,
        "com.example.editor",
        "conversion session shares bundle id normalization when recording context"
    )
    try expect(
        session.undoCandidate(contextID: "com.example.editor") != nil,
        true,
        "conversion session shares bundle id normalization when matching context"
    )
}

func runApplicationLayoutPolicyTests() throws {
    try expect(
        ApplicationLayoutPolicy.shouldRecordCurrentLayoutOnApplicationActivation(
            rememberInputSourceForEachApp: false
        ),
        false,
        "layout policy does not record app activation when memory disabled"
    )
    try expect(
        ApplicationLayoutPolicy.shouldRecordCurrentLayoutOnApplicationActivation(
            rememberInputSourceForEachApp: true
        ),
        false,
        "layout policy does not record new frontmost layout under previous app"
    )
    try expect(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        "com.example.editor",
        "layout policy restores remembered layout for external app"
    )
    try expect(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto"
        ),
        "com.example.editor",
        "layout policy normalizes restore bundle id"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto"
        ),
        "layout policy skips restore when Punto window activates"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            isApplicationDisabled: true
        ),
        "layout policy skips restore for disabled application"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: " COM.EXAMPLE.PUNTO ",
            ownBundleID: "com.example.punto"
        ),
        "layout policy normalizes own app id before restore decision"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: nil,
            ownBundleID: "com.example.punto"
        ),
        "layout policy skips restore without active bundle id"
    )
    try expectNil(
        ApplicationLayoutPolicy.bundleIDForLayoutRestoreOnActivation(
            newBundleID: "com.apple.ScreenSaver.Engine",
            ownBundleID: "com.example.punto"
        ),
        "layout policy skips restore for observed screen saver engine"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: "com.apple.keylayout.Russian",
            currentLayoutID: "com.apple.keylayout.ABC"
        ),
        .switchTo(layoutID: "com.apple.keylayout.Russian"),
        "layout policy switches to remembered layout when current layout differs"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: " com.apple.keylayout.Russian ",
            currentLayoutID: "com.apple.keylayout.Russian"
        ),
        .alreadyActive(layoutID: "com.apple.keylayout.Russian"),
        "layout policy skips TIS restore when remembered layout is already active"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: " com.apple.keylayout.Russian ",
            currentLayoutID: " com.apple.keylayout.Russian "
        ),
        .alreadyActive(layoutID: "com.apple.keylayout.Russian"),
        "layout policy normalizes layout ids before already-active restore decision"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            isApplicationDisabled: true,
            rememberedLayoutID: "com.apple.keylayout.Russian",
            currentLayoutID: "com.apple.keylayout.ABC"
        ),
        .skip,
        "layout policy skips restore action for disabled application"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: "com.apple.keylayout.Russian",
            currentLayoutID: "com.apple.keylayout.ABC"
        ),
        .skip,
        "layout policy skips restore action for Punto app"
    )
    try expect(
        ApplicationLayoutPolicy.restoreActionOnActivation(
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            rememberedLayoutID: " ",
            currentLayoutID: "com.apple.keylayout.ABC"
        ),
        .skip,
        "layout policy skips restore action without remembered layout"
    )

    try expect(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        )?.layoutID,
        "com.apple.keylayout.Russian",
        "layout policy records successful programmatic switch for active app"
    )
    try expect(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            targetLayoutID: " com.apple.keylayout.Russian ",
            didSwitch: true
        )?.bundleID,
        "com.example.editor",
        "layout policy normalizes programmatic switch bundle id"
    )
    try expect(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            targetLayoutID: " com.apple.keylayout.Russian ",
            didSwitch: true
        )?.layoutID,
        "com.apple.keylayout.Russian",
        "layout policy normalizes programmatic switch layout id"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: false,
            activeBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        ),
        "layout policy skips programmatic switch memory when disabled"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: false
        ),
        "layout policy skips failed programmatic switch memory"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.punto",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        ),
        "layout policy skips programmatic switch memory for Punto app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.apple.ScreenSaver.Engine",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        ),
        "layout policy skips programmatic switch memory for observed screen saver engine"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: " COM.EXAMPLE.PUNTO ",
            ownBundleID: "com.example.punto",
            targetLayoutID: "com.apple.keylayout.Russian",
            didSwitch: true
        ),
        "layout policy normalizes own app id before programmatic switch memory"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            targetLayoutID: " ",
            didSwitch: true
        ),
        "layout policy skips blank target layout id"
    )

    try expect(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        )?.layoutID,
        "com.apple.keylayout.US",
        "layout policy records observed input-source change for active external app"
    )
    let observedNormalizedUpdate = ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
        rememberInputSourceForEachApp: true,
        activeBundleID: " COM.Example.Editor ",
        frontmostBundleID: " COM.Example.Editor ",
        ownBundleID: "com.example.punto",
        currentLayoutID: " com.apple.keylayout.Russian "
    )
    try expect(
        observedNormalizedUpdate?.bundleID,
        "com.example.editor",
        "layout policy normalizes observed input-source bundle id"
    )
    try expect(
        observedNormalizedUpdate?.layoutID,
        "com.apple.keylayout.Russian",
        "layout policy normalizes observed input-source layout id"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.punto",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy does not write Punto settings-window layout under last external app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.browser",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy does not write a frontmost app layout under a stale active app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: " COM.Example.Editor ",
            frontmostBundleID: " com.example.browser ",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy normalizes before rejecting active/frontmost mismatch"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: nil,
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy skips observed input-source memory without known frontmost app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.punto",
            frontmostBundleID: "com.example.punto",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy skips observed input-source memory for Punto app"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.apple.ScreenSaver.Engine",
            frontmostBundleID: "com.apple.ScreenSaver.Engine",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy skips observed input-source memory for observed screen saver engine"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: false,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            currentLayoutID: "com.apple.keylayout.US"
        ),
        "layout policy skips observed input-source memory when disabled"
    )
    try expectNil(
        ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange(
            rememberInputSourceForEachApp: true,
            activeBundleID: "com.example.editor",
            frontmostBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            currentLayoutID: " "
        ),
        "layout policy skips observed input-source memory without layout id"
    )
}

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

func runUndoLearningSettingsPolicyTests() throws {
    try expect(
        UndoLearningSettingsPolicy.defaultSnapshot,
        UndoLearningSettingsSnapshot(
            undoCollectionEnabled: false,
            mustShowUndoWindow: true,
            undoDictionary: [:]
        ),
        "undo learning policy mirrors observed Punto Switcher defaults"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.setUndoCollectionEnabledSelector,
        "setUndoCollectionEnabled:",
        "observed surface preserves undo learning collection setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.setMustShowUndoWindowSelector,
        "setMustShowUndoWindow:",
        "observed surface preserves undo learning undo-window setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.setUndoDictionarySelector,
        "setUndoDictionary:",
        "observed surface preserves undo learning undo dictionary setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWindowControllerClassName,
        "UndoWindowController",
        "observed surface preserves undo window controller name"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWindowDelegateProtocolName,
        "UndoWindowDelegate",
        "observed surface preserves undo window delegate name"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWindowResourceName,
        "UndoWindow",
        "observed surface preserves undo window resource name"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoAlertFormatKey,
        "PMUserRuleUndoAlertFormat",
        "observed surface preserves undo alert format key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.showUndoLearningWindowCheckboxChangedSelector,
        "showUndoLearningWindowCheckboxChanged:",
        "observed surface preserves undo show-window checkbox selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoLearningCheckboxChangedSelector,
        "undoLearningCheckboxChanged:",
        "observed surface preserves undo learning checkbox selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoLearningCheckboxKey,
        "undoLearningCheckbox",
        "observed surface preserves undo learning checkbox key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.showUndoLearningWindowCheckboxKey,
        "showUndoLearningWindowCheckbox",
        "observed surface preserves undo show-window checkbox key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoTriesKey,
        "undoTries",
        "observed surface preserves undo tries key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoPersistsKey,
        "undoPersists",
        "observed surface preserves undo persistence key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWasDoneKey,
        "undoWasDone",
        "observed surface preserves undo completion key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoConvertionSelector,
        "undoConvertion",
        "observed surface preserves legacy undo selector spelling"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.resetUndoBufferSelector,
        "resetUndoBuffer",
        "observed surface preserves undo-buffer reset selector"
    )
    try expectNil(
        UndoLearningSettingsPolicy.snapshot(from: nil),
        "undo learning policy rejects missing dictionary"
    )
    try expect(
        UndoLearningSettingsPolicy.snapshot(from: [
            UndoLearningSettingsPolicy.undoCollectionEnabledKey: NSNumber(value: false),
            UndoLearningSettingsPolicy.mustShowUndoWindowKey: NSNumber(value: true),
            UndoLearningSettingsPolicy.undoDictionaryKey: [:]
        ]),
        UndoLearningSettingsPolicy.defaultSnapshot,
        "undo learning policy reads observed Punto Switcher plist shape"
    )
    try expect(
        UndoLearningSettingsPolicy.snapshot(from: [
            UndoLearningSettingsPolicy.undoCollectionEnabledKey: "yes",
            UndoLearningSettingsPolicy.mustShowUndoWindowKey: "0",
            UndoLearningSettingsPolicy.undoDictionaryKey: [
                " teh ": " the ",
                "": "ignored",
                "adn": " "
            ]
        ]),
        UndoLearningSettingsSnapshot(
            undoCollectionEnabled: true,
            mustShowUndoWindow: false,
            undoDictionary: ["teh": "the"]
        ),
        "undo learning policy parses imported string-backed values and normalizes undo dictionary"
    )
    try expect(
        UndoLearningSettingsPolicy.legacyUndoCollectionEnabled(from: [
            UndoLearningSettingsPolicy.undoCollectionEnabledKey: NSNumber(value: true)
        ]),
        true,
        "undo learning policy exposes imported undoCollectionEnabled for settings fallback"
    )
    try expectNil(
        UndoLearningSettingsPolicy.legacyUndoCollectionEnabled(from: nil),
        "undo learning policy ignores missing undoLearning dictionaries"
    )

    try expect(
        UndoLearningSettingsPolicy.normalizedUndoDictionary([
            " ghbdtn ": " привет ",
            "": "ignored",
            "adn": " "
        ]),
        ["ghbdtn": "привет"],
        "undo learning policy normalizes imported undo dictionary entries"
    )
}

func runProductStatisticsPolicyTests() throws {
    var utcCalendar = Calendar(identifier: .gregorian)
    utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let today = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01 00:00:00 +0000
    let laterToday = Date(timeIntervalSince1970: 1_704_110_400) // 2024-01-01 12:00:00 +0000
    let tomorrow = Date(timeIntervalSince1970: 1_704_153_600) // 2024-01-02 00:00:00 +0000
    let lastProductStatDate = Date(timeIntervalSince1970: 1_704_024_000)

    let legacyNativeData = Data("""
    {"typedWords":2,"typedSymbols":3,"automaticSwitches":4,"manualSwitches":5}
    """.utf8)
    let legacyNativeSnapshot = try JSONDecoder().decode(ProductStatisticsSnapshot.self, from: legacyNativeData)
    try expect(
        legacyNativeSnapshot,
        ProductStatisticsSnapshot(typedWords: 2, typedSymbols: 3, automaticSwitches: 4, manualSwitches: 5, reverts: 0),
        "product statistics snapshot decodes older native payloads without reverts"
    )

    try expect(
        ProductStatisticsPolicy.normalized(ProductStatisticsSnapshot(
            typedWords: -1,
            typedSymbols: -2,
            automaticSwitches: -3,
            manualSwitches: -4,
            reverts: -5
        )),
        ProductStatisticsSnapshot(),
        "product statistics policy clamps negative persisted counters"
    )

    var snapshot = ProductStatisticsSnapshot()
    snapshot = ProductStatisticsPolicy.snapshot(after: .typedText("ab в\n "), current: snapshot, now: today, calendar: utcCalendar)
    try expect(
        snapshot,
        ProductStatisticsSnapshot(
            typedWords: 0,
            typedSymbols: 3,
            automaticSwitches: 0,
            manualSwitches: 0,
            lastDayuseDate: today
        ),
        "product statistics policy counts typed non-whitespace symbols"
    )
    snapshot = ProductStatisticsPolicy.snapshot(after: .completedWord, current: snapshot, now: today, calendar: utcCalendar)
    snapshot = ProductStatisticsPolicy.snapshot(after: .manualSwitch, current: snapshot, now: today, calendar: utcCalendar)
    snapshot = ProductStatisticsPolicy.snapshot(after: .automaticSwitch, current: snapshot, now: today, calendar: utcCalendar)
    snapshot = ProductStatisticsPolicy.snapshot(after: .revert, current: snapshot, now: today, calendar: utcCalendar)
    try expect(
        snapshot,
        ProductStatisticsSnapshot(
            typedWords: 1,
            typedSymbols: 3,
            automaticSwitches: 1,
            manualSwitches: 1,
            reverts: 1,
            lastDayuseDate: today
        ),
        "product statistics policy increments Punto Switcher-style counters"
    )
    try expect(
        ProductStatisticsPolicy.typedSymbolCount(nil),
        0,
        "product statistics policy ignores missing typed text"
    )
    try expect(
        ProductStatisticsPolicy.snapshot(after: .typedText("\n\t "), current: snapshot, now: laterToday, calendar: utcCalendar),
        snapshot,
        "product statistics policy ignores whitespace-only typed text"
    )
    try expect(
        ProductStatisticsPolicy.eventAfterCompletedTokenConsumption(true),
        .completedWord,
        "product statistics policy records completed words when a token is consumed outside autocorrect"
    )
    try expect(
        ProductStatisticsPolicy.eventAfterCompletedTokenConsumption(false),
        nil,
        "product statistics policy skips completed-word event without a consumed token"
    )
    try expect(
        ProductStatisticsPolicy.snapshot(
            after: .completedWord,
            current: ProductStatisticsSnapshot(
                typedWords: 2,
                typedSymbols: 9,
                automaticSwitches: 3,
                manualSwitches: 4,
                reverts: 5,
                lastDayuseDate: today,
                lastProductStatDate: lastProductStatDate
            ),
            now: tomorrow,
            calendar: utcCalendar
        ),
        ProductStatisticsSnapshot(
            typedWords: 1,
            typedSymbols: 0,
            automaticSwitches: 0,
            manualSwitches: 0,
            reverts: 0,
            lastDayuseDate: tomorrow,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy resets day-use counters when the day changes"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromLegacyCounters(
            typedWords: 2,
            typedSymbols: -1,
            automaticSwitches: nil,
            manualSwitches: 3,
            reverts: 4,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        ProductStatisticsSnapshot(
            typedWords: 2,
            typedSymbols: 0,
            automaticSwitches: 0,
            manualSwitches: 3,
            reverts: 4,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy reads Punto Switcher-style individual counters"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromLegacyCounters(
            typedWords: nil,
            typedSymbols: nil,
            automaticSwitches: nil,
            manualSwitches: nil,
            reverts: nil,
            lastDayuseDate: nil,
            lastProductStatDate: nil
        ),
        nil,
        "product statistics policy ignores missing legacy counters"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromDayuseSettings([
            "TypedWords": 109879,
            "TypedSymbols": NSNumber(value: 375547),
            "AutoSwitches": -1,
            "ManualSwitches": 901,
            "Reverts": 12,
            "LastDayuseDate": today,
            "LastProductStatDate": lastProductStatDate
        ]),
        ProductStatisticsSnapshot(
            typedWords: 109879,
            typedSymbols: 375547,
            automaticSwitches: 0,
            manualSwitches: 901,
            reverts: 12,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy reads Punto Switcher PSDayuseSettings counters and dates"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromDayuseSettings([
            "TypedWords": " 109879 ",
            "TypedSymbols": "375547",
            "AutoSwitches": "-1",
            "ManualSwitches": "901",
            "Reverts": "12",
            "LastDayuseDate": "2024-01-01 00:00:00 +0000",
            "LastProductStatDate": "2023-12-31 12:00:00 +0000"
        ]),
        ProductStatisticsSnapshot(
            typedWords: 109879,
            typedSymbols: 375547,
            automaticSwitches: 0,
            manualSwitches: 901,
            reverts: 12,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy reads string-backed Punto Switcher PSDayuseSettings counters and dates"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromLegacySources(
            typedWords: 10,
            typedSymbols: nil,
            automaticSwitches: nil,
            manualSwitches: 40,
            reverts: nil,
            dayuseSettings: [
                "TypedWords": 1,
                "TypedSymbols": 20,
                "AutoSwitches": 30,
                "ManualSwitches": 4,
                "Reverts": 50,
                "LastDayuseDate": today,
                "LastProductStatDate": lastProductStatDate
            ]
        ),
        ProductStatisticsSnapshot(
            typedWords: 10,
            typedSymbols: 20,
            automaticSwitches: 30,
            manualSwitches: 40,
            reverts: 50,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy merges partial legacy counters with Punto Switcher PSDayuseSettings"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromLegacySources(
            typedWords: nil,
            typedSymbols: -2,
            automaticSwitches: nil,
            manualSwitches: nil,
            reverts: nil,
            dayuseSettings: [
                "TypedWords": 1,
                "TypedSymbols": 20,
                "AutoSwitches": 30,
                "ManualSwitches": 40,
                "Reverts": 50
            ]
        ),
        ProductStatisticsSnapshot(
            typedWords: 1,
            typedSymbols: 0,
            automaticSwitches: 30,
            manualSwitches: 40,
            reverts: 50
        ),
        "product statistics policy lets present stale individual counters override matching dayuse fields only"
    )
    try expect(
        ProductStatisticsPolicy.dayuseSettingsKey,
        "PSDayuseSettings",
        "product statistics policy preserves observed dayuse settings key"
    )
    try expect(
        ProductStatisticsPolicy.legacyTypedWordsKey,
        "typedWords",
        "product statistics policy owns legacy typed-words counter key"
    )
    try expect(
        ProductStatisticsPolicy.legacyTypedSymbolsKey,
        "typedSymbols",
        "product statistics policy owns legacy typed-symbols counter key"
    )
    try expect(
        ProductStatisticsPolicy.legacyAutomaticSwitchesKey,
        "automaticSwitches",
        "product statistics policy owns legacy automatic-switch counter key"
    )
    try expect(
        ProductStatisticsPolicy.legacyManualSwitchesKey,
        "manualSwitches",
        "product statistics policy owns legacy manual-switch counter key"
    )
    try expect(
        ProductStatisticsPolicy.legacyRevertsKey,
        "reverts",
        "product statistics policy owns legacy revert counter key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.dayuseStatClassName,
        "PSDayuseStat",
        "product statistics policy preserves observed dayuse stat class boundary"
    )
    try expect(
        ProductStatisticsPolicy.dayuseLastDayuseDateKey,
        "LastDayuseDate",
        "product statistics policy preserves observed dayuse date key"
    )
    try expect(
        ProductStatisticsPolicy.dayuseLastProductStatDateKey,
        "LastProductStatDate",
        "product statistics policy preserves observed product stat date key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setDayuseSelector,
        "setDayuse:",
        "product statistics policy preserves observed setDayuse selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setTypedWordsSelector,
        "setTypedWords:",
        "product statistics policy preserves observed typed words setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setTypedSymbolsSelector,
        "setTypedSymbols:",
        "product statistics policy preserves observed typed symbols setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setAutomaticSwitchesSelector,
        "setAutomaticSwitches:",
        "product statistics policy preserves observed automatic switches setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setManualSwitchesSelector,
        "setManualSwitches:",
        "product statistics policy preserves observed manual switches setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setRevertsSelector,
        "setReverts:",
        "product statistics policy preserves observed reverts setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.typedSymbolMetricName,
        "product.typed.symbol",
        "product statistics policy preserves observed typed-symbol metric name"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.typedWordMetricName,
        "product.typed.word",
        "product statistics policy preserves observed typed-word metric name"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.automaticSwitchMetricName,
        "product.switch.auto",
        "product statistics policy preserves observed automatic-switch metric name"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.manualSwitchMetricName,
        "product.switch.manual",
        "product statistics policy preserves observed manual-switch metric name"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.revertMetricName,
        "product.switch.reverse",
        "product statistics policy preserves observed revert metric name"
    )
    try expect(
        ProductStatisticsPolicy.typedSymbolMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.typedSymbolMetricName,
        "product statistics policy keeps typed-symbol metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.typedWordMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.typedWordMetricName,
        "product statistics policy keeps typed-word metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.automaticSwitchMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.automaticSwitchMetricName,
        "product statistics policy keeps automatic-switch metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.manualSwitchMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.manualSwitchMetricName,
        "product statistics policy keeps manual-switch metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.revertMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.revertMetricName,
        "product statistics policy keeps revert metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .typedText("a ")),
        "product.typed.symbol",
        "product statistics policy maps typed-symbol events to observed metric name"
    )
    try expectNil(
        ProductStatisticsPolicy.metricName(for: .typedText("\n\t ")),
        "product statistics policy skips observed typed-symbol metric for whitespace-only text"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .completedWord),
        "product.typed.word",
        "product statistics policy maps completed words to observed metric name"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .automaticSwitch),
        "product.switch.auto",
        "product statistics policy maps automatic switches to observed metric name"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .manualSwitch),
        "product.switch.manual",
        "product statistics policy maps manual switches to observed metric name"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .revert),
        "product.switch.reverse",
        "product statistics policy maps reverts to observed metric name"
    )
    try expect(
        ProductStatisticsPolicy.effectiveSnapshot(
            persistedSnapshot: ProductStatisticsSnapshot(typedWords: 5),
            legacyCountersSnapshot: ProductStatisticsSnapshot(typedWords: 1)
        ),
        ProductStatisticsSnapshot(typedWords: 5),
        "product statistics policy prefers native snapshot over legacy counters"
    )
    try expect(
        ProductStatisticsPolicy.effectiveSnapshot(
            persistedSnapshot: nil,
            legacyCountersSnapshot: ProductStatisticsSnapshot(typedSymbols: 7)
        ),
        ProductStatisticsSnapshot(typedSymbols: 7),
        "product statistics policy falls back to legacy counters"
    )
}

func runApplicationUpdateSettingsPolicyTests() throws {
    try expect(
        ApplicationUpdateSettingsPolicy.configVersionKey,
        "configVersion",
        "update settings policy preserves observed config-version key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.isFirstInstallationKey,
        "isFirstInstallation",
        "update settings policy preserves observed first-install key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.isJustInstalledKey,
        "isJustInstalled",
        "update settings policy preserves observed just-installed key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.isJustUpdatedKey,
        "isJustUpdated",
        "update settings policy preserves observed just-updated key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.isUpdatingKey,
        "isUpdating",
        "update settings policy preserves observed updating key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.shouldCheckForUpdatesAutomaticallyKey,
        "shouldCheckForUpdatesAutomatically",
        "update settings policy preserves observed automatic-update-check key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey,
        "updateRequestRateInDays",
        "update settings policy preserves observed update-request-rate key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.lastStatisticsRequestDateKey,
        "lastStatisticsRequestDate",
        "update settings policy preserves observed statistics-request date key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.lastUpdateRequestDateKey,
        "lastUpdateRequestDate",
        "update settings policy preserves observed update-request date key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.lastUpdateShownDateKey,
        "lastUpdateShownDate",
        "update settings policy preserves observed update-shown date key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.configVersion,
        8,
        "update settings policy defaults to observed Punto Switcher config version"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.isUpdating,
        false,
        "update settings policy defaults to non-updating state"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.shouldCheckForUpdatesAutomatically,
        true,
        "update settings policy mirrors observed automatic update check preference"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.updateRequestRateInDays,
        0,
        "update settings policy mirrors observed update request rate"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.lastStatisticsRequestDate,
        ApplicationUpdateSettingsPolicy.legacyInitialDate,
        "update settings policy mirrors observed initial statistics date"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.snapshot(from: [
            ApplicationUpdateSettingsPolicy.configVersionKey: NSNumber(value: 8),
            ApplicationUpdateSettingsPolicy.isFirstInstallationKey: NSNumber(value: true),
            ApplicationUpdateSettingsPolicy.isJustInstalledKey: NSNumber(value: false),
            ApplicationUpdateSettingsPolicy.isJustUpdatedKey: NSNumber(value: false),
            ApplicationUpdateSettingsPolicy.isUpdatingKey: NSNumber(value: false),
            ApplicationUpdateSettingsPolicy.shouldCheckForUpdatesAutomaticallyKey: NSNumber(value: true),
            ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey: NSNumber(value: 0),
            ApplicationUpdateSettingsPolicy.lastStatisticsRequestDateKey: "2008-12-31 21:00:00 +0000",
            ApplicationUpdateSettingsPolicy.lastUpdateShownDateKey: "2008-12-31 21:00:00 +0000"
        ]),
        ApplicationUpdateSettingsPolicy.defaultSnapshot,
        "update settings policy reads observed Punto Switcher updater/install state"
    )

    let updateRequestDate = Date(timeIntervalSince1970: 1_768_132_509)
    let snapshot = ApplicationUpdateSettingsPolicy.snapshot(from: [
        ApplicationUpdateSettingsPolicy.configVersionKey: "9",
        ApplicationUpdateSettingsPolicy.isFirstInstallationKey: "0",
        ApplicationUpdateSettingsPolicy.isJustInstalledKey: "yes",
        ApplicationUpdateSettingsPolicy.isJustUpdatedKey: NSNumber(value: true),
        ApplicationUpdateSettingsPolicy.isUpdatingKey: "false",
        ApplicationUpdateSettingsPolicy.shouldCheckForUpdatesAutomaticallyKey: "no",
        ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey: " 14 ",
        ApplicationUpdateSettingsPolicy.lastStatisticsRequestDateKey: ApplicationUpdateSettingsPolicy.legacyInitialDate,
        ApplicationUpdateSettingsPolicy.lastUpdateRequestDateKey: updateRequestDate.timeIntervalSince1970,
        ApplicationUpdateSettingsPolicy.lastUpdateShownDateKey: "2008-12-31 21:00:00 +0000"
    ])
    try expect(snapshot.configVersion, 9, "update settings policy parses string config version")
    try expect(snapshot.isFirstInstallation, false, "update settings policy parses string first-install flag")
    try expect(snapshot.isJustInstalled, true, "update settings policy parses yes boolean")
    try expect(snapshot.isJustUpdated, true, "update settings policy parses NSNumber boolean")
    try expect(snapshot.isUpdating, false, "update settings policy parses false boolean")
    try expect(snapshot.shouldCheckForUpdatesAutomatically, false, "update settings policy parses no boolean")
    try expect(snapshot.updateRequestRateInDays, 14, "update settings policy parses string update request rate")
    try expect(snapshot.lastUpdateRequestDate, updateRequestDate, "update settings policy parses numeric date")

    let clamped = ApplicationUpdateSettingsPolicy.snapshot(from: [
        ApplicationUpdateSettingsPolicy.configVersionKey: -1,
        ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey: -7
    ])
    try expect(clamped.configVersion, 0, "update settings policy clamps negative config version")
    try expect(clamped.updateRequestRateInDays, 0, "update settings policy clamps negative update request rate")

    let encoded = try JSONEncoder().encode(snapshot)
    let decoded = try JSONDecoder().decode(ApplicationUpdateSettingsSnapshot.self, from: encoded)
    try expect(decoded, snapshot, "update settings snapshot supports native Codable persistence")

    let normalized = ApplicationUpdateSettingsPolicy.normalized(
        ApplicationUpdateSettingsSnapshot(
            configVersion: -2,
            isFirstInstallation: false,
            isJustInstalled: true,
            isJustUpdated: true,
            isUpdating: false,
            shouldCheckForUpdatesAutomatically: false,
            updateRequestRateInDays: -5,
            lastStatisticsRequestDate: nil,
            lastUpdateRequestDate: updateRequestDate,
            lastUpdateShownDate: nil
        )
    )
    try expect(normalized.configVersion, 0, "update settings native snapshot clamps config version")
    try expect(normalized.updateRequestRateInDays, 0, "update settings native snapshot clamps update rate")
    try expect(normalized.isJustInstalled, true, "update settings native snapshot preserves install flag")
    try expect(normalized.lastUpdateRequestDate, updateRequestDate, "update settings native snapshot preserves update date")
}

func runStartupPresentationPolicyTests() throws {
    try expect(
        StartupPresentationPolicy.installArgument,
        "--install",
        "startup presentation policy preserves observed installer argument"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.handleInstallArgumentSelector,
        "handleInstallArgument",
        "startup presentation policy preserves observed install handler selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.installedTooltipKey,
        "tooltip-app-installed",
        "startup presentation policy preserves observed installed tooltip key"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.showUpdateFinishedTooltipSelector,
        "showUpdateFinishedTooltip",
        "startup presentation policy preserves observed update-finished tooltip selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.shouldDisplayWelcomeSelector,
        "shouldDisplayWelcome",
        "startup presentation policy preserves observed welcome selector"
    )
    try expect(
        StartupPresentationPolicy.installArgumentHandlerLogName,
        PuntoSwitcherObservedSurface.StartupPresentation.handleInstallArgumentSelector,
        "startup presentation policy keeps install handler log aligned with reverse-audit anchor"
    )
    try expect(
        StartupPresentationPolicy.updateFinishedTooltipLogName,
        PuntoSwitcherObservedSurface.StartupPresentation.showUpdateFinishedTooltipSelector,
        "startup presentation policy keeps update-finished log aligned with reverse-audit anchor"
    )
    try expect(
        StartupPresentationPolicy.welcomeLogMessage,
        "Displaying welcome screen...",
        "startup presentation policy preserves observed welcome log"
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: true,
            updateSettings: ApplicationUpdateSettingsPolicy.defaultSnapshot
        ),
        true,
        "startup presentation policy shows welcome on native first launch"
    )
    let alreadyInstalled = ApplicationUpdateSettingsSnapshot(
        configVersion: 8,
        isFirstInstallation: false,
        isJustInstalled: false,
        isJustUpdated: false,
        isUpdating: false,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: false,
            updateSettings: alreadyInstalled
        ),
        false,
        "startup presentation policy skips welcome after first-install flags are consumed"
    )
    let justInstalled = ApplicationUpdateSettingsSnapshot(
        configVersion: 8,
        isFirstInstallation: false,
        isJustInstalled: true,
        isJustUpdated: false,
        isUpdating: false,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: false,
            updateSettings: justInstalled
        ),
        true,
        "startup presentation policy shows welcome for observed just-installed flag"
    )
    let consumed = StartupPresentationPolicy.updateSettingsAfterWelcome(justInstalled)
    try expect(consumed.isFirstInstallation, false, "startup presentation policy consumes first-install flag")
    try expect(consumed.isJustInstalled, false, "startup presentation policy consumes just-installed flag")
    try expect(consumed.configVersion, justInstalled.configVersion, "startup presentation policy preserves config version")

    try expect(
        StartupPresentationPolicy.shouldHandleInstallArgument(["/Applications/Punto.app/Contents/MacOS/Punto", "--install"]),
        true,
        "startup presentation policy detects observed installer launch argument"
    )
    try expect(
        StartupPresentationPolicy.shouldHandleInstallArgument(["/Applications/Punto.app/Contents/MacOS/Punto", "--not-install"]),
        false,
        "startup presentation policy rejects non-matching installer argument"
    )

    let afterInstallArgument = StartupPresentationPolicy.updateSettingsAfterInstallArgument(alreadyInstalled)
    try expect(afterInstallArgument.isJustInstalled, true, "startup presentation policy marks just-installed after installer argument")
    try expect(afterInstallArgument.isUpdating, false, "startup presentation policy clears updating after installer argument")
    try expect(afterInstallArgument.configVersion, alreadyInstalled.configVersion, "startup presentation policy preserves config version after installer argument")
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(isFirstLaunch: false, updateSettings: afterInstallArgument),
        true,
        "startup presentation policy shows welcome after installer argument"
    )

    let justUpdated = ApplicationUpdateSettingsSnapshot(
        configVersion: 9,
        isFirstInstallation: false,
        isJustInstalled: false,
        isJustUpdated: true,
        isUpdating: true,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayUpdateFinishedTooltip(updateSettings: justUpdated),
        true,
        "startup presentation policy shows update-finished tooltip for observed just-updated flag"
    )
    let afterUpdateTooltip = StartupPresentationPolicy.updateSettingsAfterUpdateFinishedTooltip(justUpdated)
    try expect(afterUpdateTooltip.isJustUpdated, false, "startup presentation policy consumes just-updated flag")
    try expect(afterUpdateTooltip.isUpdating, false, "startup presentation policy clears updating after update-finished tooltip")
    try expect(afterUpdateTooltip.configVersion, justUpdated.configVersion, "startup presentation policy preserves config version after update-finished tooltip")
}

func runLayoutSwitchPolicyTests() throws {
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .lastWord,
            switchLayoutAfterConversion: false,
            switchLayoutAfterSelectedTextConversion: true
        ),
        false,
        "layout switch policy respects global switch-off for last-word conversion"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .selectedText,
            switchLayoutAfterConversion: false,
            switchLayoutAfterSelectedTextConversion: true
        ),
        false,
        "layout switch policy respects global switch-off for selected-text conversion"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false
        ),
        true,
        "layout switch policy keeps last-word switching when selected-text switching is disabled"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .undo,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false
        ),
        true,
        "layout switch policy keeps undo layout switching when selected-text switching is disabled"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .selectedText,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false
        ),
        false,
        "layout switch policy can suppress selected-text layout switching only"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .selectedText,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: true
        ),
        true,
        "layout switch policy allows selected-text layout switching when both switches are enabled"
    )

    let now = Date(timeIntervalSince1970: 500)
    let expectedDeadline = now.addingTimeInterval(ConversionProtectionPolicy.inputSourceSwitchGraceInterval)
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .russian,
            surface: .lastWord,
            switchLayoutAfterConversion: false,
            switchLayoutAfterSelectedTextConversion: true,
            now: now
        ),
        .skip,
        "layout switch runtime skips when global switch is disabled"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .russian,
            surface: .selectedText,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false,
            now: now
        ),
        .skip,
        "layout switch runtime skips selected text when selected-text switch is disabled"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .russian,
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false,
            now: now
        ),
        .switchTo(LayoutSwitchRuntimeRequest(
            language: .russian,
            targetLayout: .russian,
            ignoreInputSourceChangesUntil: expectedDeadline
        )),
        "layout switch runtime requests Russian switch with programmatic grace deadline"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .english,
            surface: .undo,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false,
            now: now
        ),
        .switchTo(LayoutSwitchRuntimeRequest(
            language: .english,
            targetLayout: .english,
            ignoreInputSourceChangesUntil: expectedDeadline
        )),
        "layout switch runtime requests English switch for undo"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .mixed,
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: true,
            now: now
        ),
        .unsupportedTarget(clearInputSourceIgnoreDeadline: true),
        "layout switch runtime clears programmatic guard for mixed target"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .unknown,
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: true,
            now: now
        ),
        .unsupportedTarget(clearInputSourceIgnoreDeadline: true),
        "layout switch runtime clears programmatic guard for unknown target"
    )
}

func runApplicationDisablePolicyTests() throws {
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "com.microsoft.Word",
            disabledBundleIDs: ["com.microsoft"]
        ),
        true,
        "application disable policy matches bundle prefix"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "com.microsoft",
            disabledBundleIDs: ["com.microsoft"]
        ),
        true,
        "application disable policy matches exact bundle id"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "com.microsoftWord",
            disabledBundleIDs: ["com.microsoft"]
        ),
        false,
        "application disable policy rejects glued prefix"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "  COM.MICROSOFT.Excel  ",
            disabledBundleIDs: [" com.microsoft "]
        ),
        true,
        "application disable policy normalizes case and whitespace"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: nil,
            disabledBundleIDs: ["com.microsoft"]
        ),
        false,
        "application disable policy ignores missing bundle id"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: "com.microsoft.Word",
            disabledBundleIDs: ["com.microsoft"],
            completelyDisableInExceptionApplications: false
        ),
        false,
        "application disable policy keeps exception apps partially disabled by default"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: "com.microsoft.Word",
            disabledBundleIDs: ["com.microsoft"],
            completelyDisableInExceptionApplications: true
        ),
        true,
        "application disable policy fully disables exception apps when configured"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: "com.example.editor",
            disabledBundleIDs: ["com.microsoft"],
            completelyDisableInExceptionApplications: true
        ),
        false,
        "application disable policy does not fully disable unrelated apps"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: " com.example.App ",
            disabled: true,
            disabledBundleIDs: ["com.other.App"]
        ),
        ["com.example.app", "com.other.app"],
        "application disable policy stores normalized ids"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "COM.MICROSOFT.Word",
            disabled: true,
            disabledBundleIDs: [" com.microsoft ", "com.other.App"]
        ),
        ["com.microsoft.word", "com.other.app"],
        "application disable policy replaces matching prefix with specific disabled app"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoft",
            disabled: true,
            disabledBundleIDs: ["com.microsoft.Word", "com.other.App"]
        ),
        ["com.microsoft", "com.other.app"],
        "application disable policy replaces covered child ids with broader prefix"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoft.Word",
            disabled: false,
            disabledBundleIDs: ["com.microsoft", "com.other.App"]
        ),
        ["com.other.app"],
        "application disable policy removes matching disabled prefix"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "COM.MICROSOFT.Word",
            disabled: false,
            disabledBundleIDs: [" com.microsoft ", "com.other.App"]
        ),
        ["com.other.app"],
        "application disable policy removes matching prefix case-insensitively"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoft",
            disabled: false,
            disabledBundleIDs: ["com.microsoft.Word", "com.microsoft.Excel", "com.other.App"]
        ),
        ["com.other.app"],
        "application disable policy removes child ids when enabling broader app family"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoftWord",
            disabled: false,
            disabledBundleIDs: ["com.microsoft", "com.other.App"]
        ),
        ["com.microsoft", "com.other.app"],
        "application disable policy keeps glued prefix when enabling app"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: nil,
            disabled: false,
            disabledBundleIDs: [" com.microsoft ", "", "COM.OTHER.App"]
        ),
        ["com.microsoft", "com.other.app"],
        "application disable policy normalizes persisted ids when bundle id is missing"
    )
    try expect(
        ApplicationDisablePolicy.normalizedSet([" com.microsoft ", "", "COM.OTHER.App"]),
        ["com.microsoft", "com.other.app"],
        "application disable policy normalizes disabled-app set"
    )
    try expect(
        ApplicationDisablePolicy.toggleAction(
            bundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableToggleAction(
            bundleID: "com.example.editor",
            disabled: true,
            shouldClearState: true,
            clearTrackedTextReason: "disabled current app",
            clearConversionSessionReason: "disabled current app"
        ),
        "application disable policy disables current external app and clears state"
    )
    try expect(
        ApplicationDisablePolicy.toggleAction(
            bundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: true
        ),
        ApplicationDisableToggleAction(
            bundleID: "com.example.editor",
            disabled: false,
            shouldClearState: false
        ),
        "application disable policy re-enables current external app without clearing state"
    )
    try expect(
        ApplicationDisablePolicy.toggleLogMessage(
            action: ApplicationDisableToggleAction(
                bundleID: "com.example.editor",
                disabled: true,
                shouldClearState: true,
                clearTrackedTextReason: "disabled current app",
                clearConversionSessionReason: "disabled current app"
            ),
            applicationName: " TextEdit "
        ),
        "Disabled Punto in app 'TextEdit' (com.example.editor)",
        "application disable policy trims display name in toggle log"
    )
    try expect(
        ApplicationDisablePolicy.toggleLogMessage(
            action: ApplicationDisableToggleAction(
                bundleID: "com.example.editor",
                disabled: false,
                shouldClearState: false
            ),
            applicationName: "   "
        ),
        "Enabled Punto in app 'com.example.editor' (com.example.editor)",
        "application disable policy falls back to bundle id in toggle log"
    )
    try expectNil(
        ApplicationDisablePolicy.toggleAction(
            bundleID: " COM.Example.Punto ",
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: false
        ),
        "application disable policy refuses to disable Punto itself"
    )
    try expectNil(
        ApplicationDisablePolicy.toggleAction(
            bundleID: nil,
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: false
        ),
        "application disable policy ignores missing current app id"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            displayName: " TextEdit ",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "Disable in TextEdit",
            isEnabled: true,
            isChecked: false
        ),
        "application disable policy shows enabled disable action for current external app"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            displayName: "TextEdit",
            isCurrentlyDisabled: true
        ),
        ApplicationDisableMenuState(
            title: "Enable in TextEdit",
            isEnabled: true,
            isChecked: true
        ),
        "application disable policy shows checked enable action for disabled current app"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            displayName: "   ",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "Disable in Current App",
            isEnabled: true,
            isChecked: false
        ),
        "application disable policy falls back to generic current app title"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: "com.example.punto",
            ownBundleID: " COM.Example.Punto ",
            displayName: "Punto",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "No Current App",
            isEnabled: false,
            isChecked: false
        ),
        "application disable policy disables menu action for Punto itself"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: nil,
            ownBundleID: "com.example.punto",
            displayName: "Unknown",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "No Current App",
            isEnabled: false,
            isChecked: false
        ),
        "application disable policy disables menu action without current bundle id"
    )
}

func runAutoCorrectionTogglePolicyTests() throws {
    try expect(
        AutoCorrectionTogglePolicy.action(wasEnabled: true),
        AutoCorrectionToggleAction(
            newEnabledValue: false,
            clearTrackedTextReason: "auto-correction toggled",
            clearConversionSessionReason: "auto-correction toggled",
            logMessage: "Auto-correction disabled by hotkey",
            shouldFlashIcon: true
        ),
        "auto-correction toggle policy disables enabled setting and clears runtime state"
    )
    try expect(
        AutoCorrectionTogglePolicy.action(wasEnabled: false),
        AutoCorrectionToggleAction(
            newEnabledValue: true,
            clearTrackedTextReason: "auto-correction toggled",
            clearConversionSessionReason: "auto-correction toggled",
            logMessage: "Auto-correction enabled by hotkey",
            shouldFlashIcon: true
        ),
        "auto-correction toggle policy enables disabled setting and clears runtime state"
    )
}

func runStatusIconPolicyTests() throws {
    try expect(
        PuntoSwitcherObservedSurface.StatusIcon.updateMenubarIconSelector,
        "updateMenubarIcon:",
        "status icon policy preserves observed Punto Switcher menu bar update selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.StatusIcon.resourceNames,
        [
            "icon_active",
            "icon_inactive",
            "icon_disabled",
            "icon_active_w",
            "icon_inactive_w",
            "icon_disabled_w"
        ],
        "status icon policy preserves observed Punto Switcher resource names"
    )
    try expect(
        StatusIconPolicy.state(isEnabled: true, isCurrentApplicationDisabled: false),
        .active,
        "status icon policy marks enabled external app as active"
    )
    try expect(
        StatusIconPolicy.state(isEnabled: false, isCurrentApplicationDisabled: false),
        .inactive,
        "status icon policy marks globally disabled Punto as inactive"
    )
    try expect(
        StatusIconPolicy.state(isEnabled: true, isCurrentApplicationDisabled: true),
        .disabled,
        "status icon policy marks disabled current app separately"
    )
    try expect(
        StatusIconPolicy.state(isEnabled: false, isCurrentApplicationDisabled: true),
        .inactive,
        "status icon policy gives global inactive state priority over app exception"
    )
    try expect(
        StatusIconPolicy.accessibilityDescription(for: .disabled),
        "Punto disabled in current app",
        "status icon policy exposes disabled state description"
    )
}

func runAccessibilityPreferencesPolicyTests() throws {
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityPreferences.launchAccessibilityPreferencesSelector,
        "launchAccessibilityPreferences",
        "accessibility preferences policy pins observed launch selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityPreferences.openAccessibilityPrefPaneSelector,
        "openAccesibilityPrefPane:",
        "accessibility preferences policy pins observed Accessibility pane opener selector"
    )
    try expect(
        AccessibilityPreferencesPolicy.securityPrivacyPaneID,
        "com.apple.preference.security",
        "accessibility preferences policy preserves observed security pane id"
    )
    try expect(
        AccessibilityPreferencesPolicy.accessibilityPrivacyAnchor,
        "Privacy_Accessibility",
        "accessibility preferences policy preserves observed accessibility anchor"
    )
    try expect(
        AccessibilityPreferencesPolicy.preferencesURL.absoluteString,
        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
        "accessibility preferences policy builds observed System Settings URL"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityPreferences.accessibilityAlertMessageKey,
        "accessibility-alert-message",
        "accessibility preferences policy preserves observed modern alert message key"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityPreferences.accessibilityAlertLegacyMessageKey,
        "accessibility-alert-messageLegacy",
        "accessibility preferences policy preserves observed legacy alert message key"
    )
    try expect(
        AccessibilityPreferencesPolicy.permissionRequestMessage.contains("System Settings > Privacy & Security > Accessibility"),
        true,
        "accessibility preferences policy keeps native permission copy on the observed Accessibility path"
    )
    try expect(
        AccessibilityPreferencesPolicy.openSettingsButtonTitle,
        "Open System Settings",
        "accessibility preferences policy centralizes open-settings button copy"
    )
    try expect(
        AccessibilityPreferencesPolicy.legacyAppleScriptSource.contains("tell application \"System Preferences\""),
        true,
        "accessibility preferences policy preserves observed System Preferences fallback"
    )
    try expect(
        AccessibilityPreferencesPolicy.legacyAppleScriptSource.contains("reveal anchor \"Privacy_Accessibility\" of pane id \"com.apple.preference.security\""),
        true,
        "accessibility preferences policy reveals observed Accessibility privacy anchor"
    )
    try expect(
        AccessibilityPreferencesPolicy.shouldRunLegacyFallback(openedURL: false),
        true,
        "accessibility preferences policy falls back when URL open fails"
    )
    try expect(
        AccessibilityPreferencesPolicy.shouldRunLegacyFallback(openedURL: true),
        false,
        "accessibility preferences policy skips fallback after successful URL open"
    )
}

