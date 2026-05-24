import Foundation
import PuntoCore

public extension Notification.Name {
    static let puntoRussianKeyboardLayoutTypeChanged = Notification.Name("puntoRussianKeyboardLayoutTypeChanged")
    static let puntoInputSourcePreferencesChanged = Notification.Name("puntoInputSourcePreferencesChanged")
}

/// Composes application settings from native storage, import fallbacks, and policy-provided base values.
public final class SettingsManager {

    // MARK: - Properties

    private let store: SettingsDefaultsStore
    private lazy var resolver = SettingsValueResolver(store: store)

    /// Whether the app functionality is enabled
    public var isEnabled: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.isEnabled, defaultValue: SettingsPersistencePolicy.defaultIsEnabled) }
        set { store.set(newValue, forKey: SettingsStorageKeys.isEnabled) }
    }

    /// Whether this is the first launch
    public var isFirstLaunch: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.isFirstLaunch, legacyKey: SettingsImportKeys.isFirstInstallation, defaultValue: StartupPresentationPolicy.defaultIsFirstLaunch) }
        set { store.set(newValue, forKey: SettingsStorageKeys.isFirstLaunch) }
    }

    /// Consumes native and imported Punto Switcher first-run flags after onboarding.
    public func consumeFirstLaunchPresentationFlags() {
        store.set(false, forKey: SettingsStorageKeys.isFirstLaunch)
        store.set(false, forKey: SettingsImportKeys.isFirstInstallation)
        store.set(false, forKey: SettingsImportKeys.isJustInstalled)
    }

    /// Consumes imported Punto Switcher update flags after native update presentation.
    public func consumeUpdatePresentationImportFlags() {
        store.set(false, forKey: SettingsImportKeys.isJustUpdated)
        store.set(false, forKey: SettingsImportKeys.isUpdating)
    }

    /// Whether to show the icon in the menu bar
    public var showInMenuBar: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.showInMenuBar, defaultValue: SettingsPersistencePolicy.defaultShowInMenuBar) }
        set { store.set(newValue, forKey: SettingsStorageKeys.showInMenuBar) }
    }

    /// Whether advanced settings are visible in the preferences window
    public var showAdvancedSettings: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.showAdvancedSettings, defaultValue: SettingsPersistencePolicy.defaultShowAdvancedSettings) }
        set { store.set(newValue, forKey: SettingsStorageKeys.showAdvancedSettings) }
    }

    /// Whether to launch at login
    public var launchAtLogin: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.launchAtLogin, legacyKey: SettingsImportKeys.launchesOnStartup, defaultValue: LoginItemPolicy.defaultLaunchAtLogin) }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.launchAtLogin)
        }
    }

    /// Hotkey for converting layout
    public var convertLayoutHotkey: Hotkey {
        get {
            resolver.hotkey(
                nativeKey: SettingsStorageKeys.convertLayoutHotkey,
                legacyKey: SettingsImportKeys.shortcutChangeLayout,
                fallback: Hotkey.defaultConvertLayout
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultConvertLayout)
            store.encodeAndSet(normalized, forKey: SettingsStorageKeys.convertLayoutHotkey)
        }
    }

    /// Hotkey for toggling case
    public var toggleCaseHotkey: Hotkey {
        get {
            resolver.hotkey(
                nativeKey: SettingsStorageKeys.toggleCaseHotkey,
                legacyKey: SettingsImportKeys.shortcutChangeCase,
                fallback: Hotkey.defaultToggleCase
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultToggleCase)
            store.encodeAndSet(normalized, forKey: SettingsStorageKeys.toggleCaseHotkey)
        }
    }

    /// Hotkey for toggling auto-correction
    public var toggleAutoCorrectionHotkey: Hotkey {
        get {
            resolver.hotkey(
                nativeKey: SettingsStorageKeys.toggleAutoCorrectionHotkey,
                legacyKey: SettingsImportKeys.shortcutSwitchAutocorrection,
                fallback: Hotkey.defaultToggleAutoCorrection
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultToggleAutoCorrection)
            store.encodeAndSet(normalized, forKey: SettingsStorageKeys.toggleAutoCorrectionHotkey)
        }
    }

    /// Hotkey for cancelling the last layout change.
    public var cancelLayoutChangeHotkey: Hotkey {
        get {
            resolver.hotkey(
                nativeKey: SettingsStorageKeys.cancelLayoutChangeHotkey,
                legacyKey: SettingsImportKeys.shortcutCancelLayoutChange,
                fallback: Hotkey.defaultCancelLayoutChange
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultCancelLayoutChange)
            store.encodeAndSet(normalized, forKey: SettingsStorageKeys.cancelLayoutChangeHotkey)
        }
    }

    /// Hotkey for opening selected text in Yandex search.
    public var findInYandexHotkey: Hotkey {
        get {
            resolver.hotkey(
                nativeKey: SettingsStorageKeys.findInYandexHotkey,
                legacyKey: SettingsImportKeys.shortcutFindInYandex,
                fallback: Hotkey.defaultFindInYandex
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultFindInYandex)
            store.encodeAndSet(normalized, forKey: SettingsStorageKeys.findInYandexHotkey)
        }
    }

    /// Hotkey for opening selected text in Yandex Translate/Slovari flow.
    public var findInSlovariHotkey: Hotkey {
        get {
            resolver.hotkey(
                nativeKey: SettingsStorageKeys.findInSlovariHotkey,
                legacyKey: SettingsImportKeys.shortcutFindInSlovari,
                fallback: Hotkey.defaultFindInSlovari
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultFindInSlovari)
            store.encodeAndSet(normalized, forKey: SettingsStorageKeys.findInSlovariHotkey)
        }
    }

    public var hotkeyAssignments: [HotkeyAssignment] {
        HotkeyCommandPolicy.displayOrder.map {
            HotkeyAssignment(slot: $0.slot, hotkey: hotkey(for: $0.slot))
        }
    }

    public func hotkey(for slot: HotkeySlot) -> Hotkey {
        switch slot {
        case .convertLayout:
            return convertLayoutHotkey
        case .toggleCase:
            return toggleCaseHotkey
        case .toggleAutoCorrection:
            return toggleAutoCorrectionHotkey
        case .cancelLayoutChange:
            return cancelLayoutChangeHotkey
        case .findInYandex:
            return findInYandexHotkey
        case .findInSlovari:
            return findInSlovariHotkey
        }
    }

    public func setHotkey(_ hotkey: Hotkey, for slot: HotkeySlot) {
        switch slot {
        case .convertLayout:
            convertLayoutHotkey = hotkey
        case .toggleCase:
            toggleCaseHotkey = hotkey
        case .toggleAutoCorrection:
            toggleAutoCorrectionHotkey = hotkey
        case .cancelLayoutChange:
            cancelLayoutChangeHotkey = hotkey
        case .findInYandex:
            findInYandexHotkey = hotkey
        case .findInSlovari:
            findInSlovariHotkey = hotkey
        }
    }

    public func resetHotkey(for slot: HotkeySlot) {
        setHotkey(HotkeyCommandPolicy.defaultHotkey(for: slot), for: slot)
    }

    public func bool(for slot: SettingsToggleSlot) -> Bool {
        switch slot {
        case .launchAtLogin:
            return launchAtLogin
        case .showInMenuBar:
            return showInMenuBar
        case .switchLayoutAfterConversion:
            return switchLayoutAfterConversion
        case .autoCorrectionEnabled:
            return autoCorrectionEnabled
        case .soundEffectsEnabled:
            return soundEffectsEnabled
        case .showAdvancedSettings:
            return showAdvancedSettings
        case .switchLayoutAfterSelectedTextConversion:
            return switchLayoutAfterSelectedTextConversion
        case .searchSelectedTextByDoubleClick:
            return searchSelectedTextByDoubleClick
        case .manualConversionDisabled:
            return manualConversionDisabled
        case .rememberInputSourceForEachApp:
            return rememberInputSourceForEachApp
        case .autoCorrectOnEnterAndTab:
            return autoCorrectOnEnterAndTab
        case .autoCorrectionUndoLearningEnabled:
            return autoCorrectionUndoLearningEnabled
        case .suppressAutoCorrectionAfterManualConversion:
            return suppressAutoCorrectionAfterManualConversion
        case .completelyDisableInExceptionApplications:
            return completelyDisableInExceptionApplications
        }
    }

    public func setBool(_ isEnabled: Bool, for slot: SettingsToggleSlot) {
        switch slot {
        case .launchAtLogin:
            launchAtLogin = isEnabled
        case .showInMenuBar:
            showInMenuBar = isEnabled
        case .switchLayoutAfterConversion:
            switchLayoutAfterConversion = isEnabled
        case .autoCorrectionEnabled:
            autoCorrectionEnabled = isEnabled
        case .soundEffectsEnabled:
            soundEffectsEnabled = isEnabled
        case .showAdvancedSettings:
            showAdvancedSettings = isEnabled
        case .switchLayoutAfterSelectedTextConversion:
            switchLayoutAfterSelectedTextConversion = isEnabled
        case .searchSelectedTextByDoubleClick:
            searchSelectedTextByDoubleClick = isEnabled
        case .manualConversionDisabled:
            manualConversionDisabled = isEnabled
        case .rememberInputSourceForEachApp:
            rememberInputSourceForEachApp = isEnabled
        case .autoCorrectOnEnterAndTab:
            autoCorrectOnEnterAndTab = isEnabled
        case .autoCorrectionUndoLearningEnabled:
            autoCorrectionUndoLearningEnabled = isEnabled
        case .suppressAutoCorrectionAfterManualConversion:
            suppressAutoCorrectionAfterManualConversion = isEnabled
        case .completelyDisableInExceptionApplications:
            completelyDisableInExceptionApplications = isEnabled
        }
    }

    public var searchSelectedTextByDoubleClick: Bool {
        get {
            resolver.searchSelectedTextByDoubleClick(
                nativeKey: SettingsStorageKeys.searchSelectedTextByDoubleClick,
                legacyKey: SettingsImportKeys.searchbarSettings
            )
        }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.searchSelectedTextByDoubleClick)
        }
    }

    /// Переключать раскладку после конвертации
    public var switchLayoutAfterConversion: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.switchLayoutAfterConversion, defaultValue: LayoutSwitchPolicy.defaultSwitchLayoutAfterConversion) }
        set { store.set(newValue, forKey: SettingsStorageKeys.switchLayoutAfterConversion) }
    }

    public var switchLayoutAfterSelectedTextConversion: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.switchLayoutAfterSelectedTextConversion, legacyKey: SettingsImportKeys.switchLayoutOnSelectedTextSwitch, defaultValue: LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion) }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.switchLayoutAfterSelectedTextConversion)
        }
    }

    public var manualConversionDisabled: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.manualConversionDisabled, legacyKey: SettingsImportKeys.isManualConversionDisabled, defaultValue: TextActionPreflightPolicy.defaultManualConversionDisabled) }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.manualConversionDisabled)
        }
    }

    public var russianKeyboardLayoutType: KeyboardLayoutType {
        get { resolver.russianKeyboardLayoutType(nativeKey: SettingsStorageKeys.russianKeyboardLayoutType, legacyKey: SettingsImportKeys.kbdLayoutType) }
        set {
            store.set(newValue.rawValue, forKey: SettingsStorageKeys.russianKeyboardLayoutType)
            NotificationCenter.default.post(name: .puntoRussianKeyboardLayoutTypeChanged, object: self)
            NotificationCenter.default.post(name: .puntoInputSourcePreferencesChanged, object: self)
        }
    }

    public var preferredEnglishInputSourceID: String? {
        get { resolver.inputSourceID(nativeKey: SettingsStorageKeys.preferredEnglishInputSourceID, legacyKey: SettingsImportKeys.englishLayoutID) }
        set {
            setPreferredInputSourceID(newValue, nativeKey: SettingsStorageKeys.preferredEnglishInputSourceID)
        }
    }

    public var preferredRussianInputSourceID: String? {
        get { resolver.inputSourceID(nativeKey: SettingsStorageKeys.preferredRussianInputSourceID, legacyKey: SettingsImportKeys.russianLayoutID) }
        set {
            setPreferredInputSourceID(newValue, nativeKey: SettingsStorageKeys.preferredRussianInputSourceID)
        }
    }

    /// Punto Switcher-style per-application layout memory.
    public var rememberInputSourceForEachApp: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.rememberInputSourceForEachApp, legacyKey: SettingsImportKeys.shouldRememberInputSourceForEachApp, defaultValue: ApplicationLayoutPolicy.defaultRememberInputSourceForEachApp) }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.rememberInputSourceForEachApp)
        }
    }

    public var rememberedApplicationLayouts: [String: String] {
        get {
            ApplicationLayoutMemory.normalizedSnapshot(
                store.dictionary(forKey: SettingsStorageKeys.rememberedApplicationLayouts) as? [String: String] ?? [:]
            )
        }
        set {
            store.set(
                ApplicationLayoutMemory.normalizedSnapshot(newValue),
                forKey: SettingsStorageKeys.rememberedApplicationLayouts
            )
        }
    }

    public var disabledApplicationBundleIDs: Set<String> {
        get { resolver.disabledApplicationBundleIDs(nativeKey: SettingsStorageKeys.disabledApplicationBundleIDs, legacyKey: SettingsImportKeys.disabledApps) }
        set {
            let normalized = Array(ApplicationDisablePolicy.normalizedSet(newValue)).sorted()
            store.set(normalized, forKey: SettingsStorageKeys.disabledApplicationBundleIDs)
        }
    }

    public func isApplicationDisabled(bundleID: String?) -> Bool {
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: bundleID,
            disabledBundleIDs: disabledApplicationBundleIDs
        )
    }

    public var completelyDisableInExceptionApplications: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.completelyDisableInExceptionApplications, legacyKey: SettingsImportKeys.completelyDisableInExceptionApps, defaultValue: ApplicationDisablePolicy.defaultCompletelyDisableInExceptionApplications) }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.completelyDisableInExceptionApplications)
        }
    }

    public func isApplicationCompletelyDisabled(bundleID: String?) -> Bool {
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: bundleID,
            disabledBundleIDs: disabledApplicationBundleIDs,
            completelyDisableInExceptionApplications: completelyDisableInExceptionApplications
        )
    }

    public func setApplicationDisabled(bundleID: String?, disabled: Bool) {
        disabledApplicationBundleIDs = ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: bundleID,
            disabled: disabled,
            disabledBundleIDs: disabledApplicationBundleIDs
        )
    }

    public var resetOnReturnBundleComponents: Set<String> {
        get { resolver.resetOnReturnBundleComponents(nativeKey: SettingsStorageKeys.resetOnReturnBundleComponents, legacyKey: SettingsImportKeys.switcherResetOnReturn) }
        set {
            let normalized = Array(ApplicationReturnKeyPolicy.normalizedResetBundleComponents(newValue)).sorted()
            store.set(
                normalized,
                forKey: SettingsStorageKeys.resetOnReturnBundleComponents
            )
        }
    }

    public var autoCorrectionEnabled: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.autoCorrectionEnabled, legacyKey: SettingsImportKeys.isAutocorrectionActive, defaultValue: AutoCorrectionPreflightPolicy.defaultAutoCorrectionEnabled) }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.autoCorrectionEnabled)
        }
    }

    public var autoCorrectionStarterRulesEnabled: Bool {
        get {
            resolver.firstStoredBool(
                keys: [
                    SettingsStorageKeys.autoCorrectionStarterRulesEnabled,
                    SettingsImportKeys.switcherUseOldRulesDefaultConf,
                    SettingsImportKeys.switcherUseOldRulesAccessor
                ],
                defaultValue: AutoCorrectionRuleSourcePolicy.defaultStarterRulesEnabled
            )
        }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.autoCorrectionStarterRulesEnabled)
        }
    }

    public var autoCorrectOnEnterAndTab: Bool {
        get { resolver.invertedLegacyBool(nativeKey: SettingsStorageKeys.autoCorrectOnEnterAndTab, legacyKey: SettingsImportKeys.shouldNotAutoconvertWithTabOrEnter, defaultValue: AutoCorrectionPreflightPolicy.defaultAutoCorrectOnEnterAndTab) }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.autoCorrectOnEnterAndTab)
        }
    }

    public var autoCorrectionUndoLearningEnabled: Bool {
        get { resolver.undoLearningEnabled(nativeKey: SettingsStorageKeys.autoCorrectionUndoLearningEnabled, legacyKey: SettingsImportKeys.undoLearning, defaultValue: AutoCorrectionUndoLearningPolicy.defaultUndoLearningEnabled) }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.autoCorrectionUndoLearningEnabled)
        }
    }

    public var suppressAutoCorrectionAfterManualConversion: Bool {
        get { resolver.invertedLegacyBool(nativeKey: SettingsStorageKeys.suppressAutoCorrectionAfterManualConversion, legacyKey: SettingsImportKeys.shouldNotAutoconvertAfterConvertion, defaultValue: TextReplacementCommitPolicy.defaultSuppressAutoCorrectionAfterManualConversion) }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.suppressAutoCorrectionAfterManualConversion)
        }
    }

    public var autoCorrectionCancellingKeyNames: Set<String> {
        get { resolver.autoCorrectionCancellingKeyNames(nativeKey: SettingsStorageKeys.autoCorrectionCancellingKeyNames, legacyKey: SettingsImportKeys.cancellingKeys) }
        set {
            store.set(
                Array(AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames(newValue)).sorted(),
                forKey: SettingsStorageKeys.autoCorrectionCancellingKeyNames
            )
        }
    }

    public func isAutoCorrectionCancellingKeyEnabled(_ keyName: String) -> Bool {
        autoCorrectionCancellingKeyNames.contains(
            AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames([keyName]).first ?? ""
        )
    }

    public func setAutoCorrectionCancellingKey(_ keyName: String, enabled: Bool) {
        guard let normalized = AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames([keyName]).first else {
            return
        }
        var enabledKeyNames = autoCorrectionCancellingKeyNames
        if enabled {
            enabledKeyNames.insert(normalized)
        } else {
            enabledKeyNames.remove(normalized)
        }
        autoCorrectionCancellingKeyNames = enabledKeyNames
    }

    public var soundEffectsEnabled: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.soundEffectsEnabled, legacyKey: SettingsImportKeys.isSoundOn, defaultValue: SoundFeedbackPolicy.defaultSoundEffectsEnabled) }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.soundEffectsEnabled)
        }
    }

    public var enabledSoundResourceNames: Set<String> {
        get {
            resolver.enabledSoundResourceNames(
                nativeKey: SettingsStorageKeys.enabledSoundResourceNames,
                legacyBitmaskKey: SettingsImportKeys.enabledSounds,
                legacyToggleKeys: SoundFeedbackPolicy.legacyPerResourceToggleKeys
            )
        }
        set {
            let normalized = SoundFeedbackPolicy.normalizedEnabledResourceNames(newValue)
            store.set(Array(normalized).sorted(), forKey: SettingsStorageKeys.enabledSoundResourceNames)
        }
    }

    public func isSoundResourceEnabled(_ resourceName: String) -> Bool {
        enabledSoundResourceNames.contains(resourceName)
    }

    public func setSoundResource(_ resourceName: String, enabled: Bool) {
        var enabledNames = enabledSoundResourceNames
        if enabled {
            enabledNames.insert(resourceName)
        } else {
            enabledNames.remove(resourceName)
        }
        enabledSoundResourceNames = enabledNames
    }

    public var restorePasteboardAfterConversion: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.restorePasteboardAfterConversion, legacyKey: SettingsImportKeys.shouldRestorePasteboard, defaultValue: ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion) }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.restorePasteboardAfterConversion)
        }
    }

    public var productStatistics: ProductStatisticsSnapshot {
        get {
            resolver.productStatistics(
                nativeKey: SettingsStorageKeys.productStatistics,
                typedWordsKey: SettingsImportKeys.typedWords,
                typedSymbolsKey: SettingsImportKeys.typedSymbols,
                automaticSwitchesKey: SettingsImportKeys.automaticSwitches,
                manualSwitchesKey: SettingsImportKeys.manualSwitches,
                revertsKey: SettingsImportKeys.reverts,
                dayuseSettingsKey: SettingsImportKeys.dayuseSettings
            )
        }
        set {
            let normalized = ProductStatisticsPolicy.normalized(newValue)
            store.encodeAndSet(normalized, forKey: SettingsStorageKeys.productStatistics)
        }
    }

    public func recordProductStatisticsEvent(_ event: ProductStatisticsEvent) {
        productStatistics = ProductStatisticsPolicy.snapshot(after: event, current: productStatistics)
    }

    public var applicationUpdateSettings: ApplicationUpdateSettingsSnapshot {
        get { resolver.applicationUpdateSettings(nativeKey: SettingsStorageKeys.applicationUpdateSettings) }
        set {
            let normalized = ApplicationUpdateSettingsPolicy.normalized(newValue)
            store.encodeAndSet(normalized, forKey: SettingsStorageKeys.applicationUpdateSettings)
        }
    }

    public var autoCorrectionRules: [AutoCorrectionRule] {
        get {
            resolver.autoCorrectionRules(
                nativeKey: SettingsStorageKeys.autoCorrectionRules,
                legacyUserRulesKey: SettingsImportKeys.userRulesDictionary,
                useStarterRules: autoCorrectionStarterRulesEnabled
            )
        }
        set {
            guard let data = try? AutoCorrectionRuleStore.encodeRules(newValue) else { return }
            store.set(data, forKey: SettingsStorageKeys.autoCorrectionRules)
        }
    }

    @discardableResult
    public func importAutoCorrectionRules(from data: Data, merge: Bool = true) throws -> AutoCorrectionRuleImportResult {
        let result = try AutoCorrectionRuleStore.decodeRules(from: data)
        autoCorrectionRules = merge
            ? AutoCorrectionRuleStore.mergedRules(existing: autoCorrectionRules, imported: result.rules)
            : result.rules
        return result
    }

    public func exportAutoCorrectionRules() throws -> Data {
        try AutoCorrectionRuleStore.encodeRules(autoCorrectionRules)
    }

    // MARK: - Initialization

    public init(
        defaults: UserDefaults = .standard,
        domainName: String? = Bundle.main.bundleIdentifier
    ) {
        self.store = SettingsDefaultsStore(defaults: defaults, domainName: domainName)
        // Register defaults
        store.register(defaults: [
            SettingsStorageKeys.isEnabled: SettingsPersistencePolicy.defaultIsEnabled,
            SettingsStorageKeys.isFirstLaunch: StartupPresentationPolicy.defaultIsFirstLaunch,
            SettingsStorageKeys.showInMenuBar: SettingsPersistencePolicy.defaultShowInMenuBar,
            SettingsStorageKeys.showAdvancedSettings: SettingsPersistencePolicy.defaultShowAdvancedSettings,
            SettingsStorageKeys.launchAtLogin: LoginItemPolicy.defaultLaunchAtLogin,
            SettingsStorageKeys.switchLayoutAfterConversion: LayoutSwitchPolicy.defaultSwitchLayoutAfterConversion,
            SettingsStorageKeys.switchLayoutAfterSelectedTextConversion: LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion,
            SettingsStorageKeys.russianKeyboardLayoutType: KeyboardLayoutTypePolicy.defaultRussianLayoutTypeRawValue,
            SettingsStorageKeys.manualConversionDisabled: TextActionPreflightPolicy.defaultManualConversionDisabled,
            SettingsStorageKeys.rememberInputSourceForEachApp: ApplicationLayoutPolicy.defaultRememberInputSourceForEachApp,
            SettingsStorageKeys.rememberedApplicationLayouts: ApplicationLayoutMemory.defaultSnapshot,
            SettingsStorageKeys.disabledApplicationBundleIDs: ApplicationDisablePolicy.defaultDisabledBundleIDs,
            SettingsStorageKeys.completelyDisableInExceptionApplications: ApplicationDisablePolicy.defaultCompletelyDisableInExceptionApplications,
            SettingsStorageKeys.autoCorrectionEnabled: AutoCorrectionPreflightPolicy.defaultAutoCorrectionEnabled,
            SettingsStorageKeys.autoCorrectOnEnterAndTab: AutoCorrectionPreflightPolicy.defaultAutoCorrectOnEnterAndTab,
            SettingsStorageKeys.autoCorrectionUndoLearningEnabled: AutoCorrectionUndoLearningPolicy.defaultUndoLearningEnabled,
            SettingsStorageKeys.suppressAutoCorrectionAfterManualConversion: TextReplacementCommitPolicy.defaultSuppressAutoCorrectionAfterManualConversion,
            SettingsStorageKeys.autoCorrectionCancellingKeyNames: AutoCorrectionCancellingKeyPolicy.defaultEnabledKeyNameList,
            SettingsStorageKeys.soundEffectsEnabled: SoundFeedbackPolicy.defaultSoundEffectsEnabled,
            SettingsStorageKeys.restorePasteboardAfterConversion: ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion
        ])
    }

    // MARK: - Reset to Defaults

    public func resetConvertLayoutHotkey() {
        resetHotkey(for: .convertLayout)
    }

    public func resetToggleCaseHotkey() {
        resetHotkey(for: .toggleCase)
    }

    public func resetToggleAutoCorrectionHotkey() {
        resetHotkey(for: .toggleAutoCorrection)
    }

    public func resetCancelLayoutChangeHotkey() {
        resetHotkey(for: .cancelLayoutChange)
    }

    public func resetFindInYandexHotkey() {
        resetHotkey(for: .findInYandex)
    }

    public func resetFindInSlovariHotkey() {
        resetHotkey(for: .findInSlovari)
    }

    private func setPreferredInputSourceID(_ sourceID: String?, nativeKey: String) {
        if let normalized = InputSourceSelectionPolicy.normalizedSourceID(sourceID) {
            store.set(normalized, forKey: nativeKey)
        } else {
            store.removeObject(forKey: nativeKey)
        }
        NotificationCenter.default.post(name: .puntoInputSourcePreferencesChanged, object: self)
    }

}
