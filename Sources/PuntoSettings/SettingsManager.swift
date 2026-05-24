import Foundation
import PuntoCore
import ServiceManagement

public extension Notification.Name {
    static let puntoRussianKeyboardLayoutTypeChanged = Notification.Name("puntoRussianKeyboardLayoutTypeChanged")
    static let puntoInputSourcePreferencesChanged = Notification.Name("puntoInputSourcePreferencesChanged")
}

/// Composes application settings from native storage, import fallbacks, and policy-provided base values.
public final class SettingsManager {

    // MARK: - Keys

    private enum Keys {
        static let isEnabled = SettingsPersistencePolicy.nativeIsEnabledKey
        static let isFirstLaunch = "isFirstLaunch"
        static let showInMenuBar = "showInMenuBar"
        static let showAdvancedSettings = SettingsPersistencePolicy.nativeShowAdvancedSettingsKey
        static let launchAtLogin = "launchAtLogin"
        static let convertLayoutHotkey = "convertLayoutHotkey"
        static let toggleCaseHotkey = "toggleCaseHotkey"
        static let toggleAutoCorrectionHotkey = "toggleAutoCorrectionHotkey"
        static let cancelLayoutChangeHotkey = "cancelLayoutChangeHotkey"
        static let findInYandexHotkey = "findInYandexHotkey"
        static let findInSlovariHotkey = "findInSlovariHotkey"
        static let searchSelectedTextByDoubleClick = "searchSelectedTextByDoubleClick"
        static let switchLayoutAfterConversion = "switchLayoutAfterConversion"
        static let switchLayoutAfterSelectedTextConversion = "switchLayoutAfterSelectedTextConversion"
        static let russianKeyboardLayoutType = "russianKeyboardLayoutType"
        static let preferredEnglishInputSourceID = "preferredEnglishInputSourceID"
        static let preferredRussianInputSourceID = "preferredRussianInputSourceID"
        static let manualConversionDisabled = "manualConversionDisabled"
        static let rememberInputSourceForEachApp = "rememberInputSourceForEachApp"
        static let rememberedApplicationLayouts = "rememberedApplicationLayouts"
        static let disabledApplicationBundleIDs = "disabledApplicationBundleIDs"
        static let completelyDisableInExceptionApplications = "completelyDisableInExceptionApplications"
        static let resetOnReturnBundleComponents = "resetOnReturnBundleComponents"
        static let autoCorrectionEnabled = "autoCorrectionEnabled"
        static let autoCorrectionStarterRulesEnabled = "autoCorrectionStarterRulesEnabled"
        static let autoCorrectOnEnterAndTab = "autoCorrectOnEnterAndTab"
        static let autoCorrectionUndoLearningEnabled = "autoCorrectionUndoLearningEnabled"
        static let suppressAutoCorrectionAfterManualConversion = "suppressAutoCorrectionAfterManualConversion"
        static let autoCorrectionCancellingKeyNames = "autoCorrectionCancellingKeyNames"
        static let autoCorrectionRules = "autoCorrectionRules"
        static let soundEffectsEnabled = "soundEffectsEnabled"
        static let enabledSoundResourceNames = "enabledSoundResourceNames"
        static let restorePasteboardAfterConversion = "restorePasteboardAfterConversion"
        static let productStatistics = "productStatistics"
        static let applicationUpdateSettings = "applicationUpdateSettings"
    }

    private enum ImportKeys {
        static let isFirstInstallation = ApplicationUpdateSettingsPolicy.isFirstInstallationKey
        static let launchesOnStartup = LoginItemPolicy.legacyLaunchesOnStartupKey
        static let shortcutChangeLayout = LegacyHotkeyPolicy.legacyShortcutChangeLayoutKey
        static let shortcutChangeCase = LegacyHotkeyPolicy.legacyShortcutChangeCaseKey
        static let shortcutSwitchAutocorrection = LegacyHotkeyPolicy.legacyShortcutSwitchAutocorrectionKey
        static let shortcutCancelLayoutChange = LegacyHotkeyPolicy.legacyShortcutCancelLayoutChangeKey
        static let shortcutFindInYandex = LegacyHotkeyPolicy.legacyShortcutFindInYandexKey
        static let shortcutFindInSlovari = LegacyHotkeyPolicy.legacyShortcutFindInSlovariKey
        static let searchbarSettings = SearchbarSettingsPolicy.settingsKey
        static let switchLayoutOnSelectedTextSwitch = LayoutSwitchPolicy.legacySwitchLayoutOnSelectedTextSwitchKey
        static let isManualConversionDisabled = TextActionPreflightPolicy.legacyIsManualConversionDisabledKey
        static let kbdLayoutType = KeyboardLayoutTypePolicy.legacyRussianKeyboardLayoutTypeKey
        static let englishLayoutID = InputSourceSelectionPolicy.legacyEnglishInputSourceIDKey
        static let russianLayoutID = InputSourceSelectionPolicy.legacyRussianInputSourceIDKey
        static let shouldRememberInputSourceForEachApp = ApplicationLayoutPolicy.legacyShouldRememberInputSourceForEachAppKey
        static let disabledApps = ApplicationDisablePolicy.legacyDisabledAppsKey
        static let completelyDisableInExceptionApps = ApplicationDisablePolicy.legacyCompletelyDisableInExceptionApplicationsKey
        static let switcherResetOnReturn = ApplicationReturnKeyPolicy.legacyResetOnReturnKey
        static let isAutocorrectionActive = AutoCorrectionPreflightPolicy.legacyIsAutocorrectionActiveKey
        static let switcherUseOldRulesDefaultConf = AutoCorrectionRuleSourcePolicy.useOldRulesDefaultConfPath
        static let switcherUseOldRulesAccessor = AutoCorrectionRuleSourcePolicy.useOldRulesAccessor
        static let shouldNotAutoconvertWithTabOrEnter = AutoCorrectionPreflightPolicy.legacyShouldNotAutoconvertWithTabOrEnterKey
        static let undoLearning = UndoLearningSettingsPolicy.settingsKey
        static let shouldNotAutoconvertAfterConvertion = TextReplacementCommitPolicy.legacyShouldNotAutoconvertAfterConvertionKey
        static let cancellingKeys = AutoCorrectionCancellingKeyPolicy.legacyCancellingKeysBitmaskKey
        static let userRulesDictionary = LegacyUserRulePolicy.userRulesDictionaryKey
        static let isSoundOn = SoundFeedbackPolicy.legacyIsSoundOnKey
        static let enabledSounds = SoundFeedbackPolicy.legacyEnabledSoundsKey
        static let shouldRestorePasteboard = ClipboardReplacementPolicy.legacyShouldRestorePasteboardKey
        static let typedWords = ProductStatisticsPolicy.legacyTypedWordsKey
        static let typedSymbols = ProductStatisticsPolicy.legacyTypedSymbolsKey
        static let automaticSwitches = ProductStatisticsPolicy.legacyAutomaticSwitchesKey
        static let manualSwitches = ProductStatisticsPolicy.legacyManualSwitchesKey
        static let reverts = ProductStatisticsPolicy.legacyRevertsKey
        static let dayuseSettings = ProductStatisticsPolicy.dayuseSettingsKey
        static let configVersion = ApplicationUpdateSettingsPolicy.configVersionKey
        static let isJustInstalled = ApplicationUpdateSettingsPolicy.isJustInstalledKey
        static let isJustUpdated = ApplicationUpdateSettingsPolicy.isJustUpdatedKey
        static let isUpdating = ApplicationUpdateSettingsPolicy.isUpdatingKey
        static let shouldCheckForUpdatesAutomatically = ApplicationUpdateSettingsPolicy.shouldCheckForUpdatesAutomaticallyKey
        static let updateRequestRateInDays = ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey
        static let lastStatisticsRequestDate = ApplicationUpdateSettingsPolicy.lastStatisticsRequestDateKey
        static let lastUpdateRequestDate = ApplicationUpdateSettingsPolicy.lastUpdateRequestDateKey
        static let lastUpdateShownDate = ApplicationUpdateSettingsPolicy.lastUpdateShownDateKey
    }

    // MARK: - Properties

    private let store: SettingsDefaultsStore
    private lazy var resolver = SettingsValueResolver(store: store)

    /// Whether the app functionality is enabled
    public var isEnabled: Bool {
        get { resolver.bool(nativeKey: Keys.isEnabled, defaultValue: SettingsPersistencePolicy.defaultIsEnabled) }
        set { store.set(newValue, forKey: Keys.isEnabled) }
    }

    /// Whether this is the first launch
    public var isFirstLaunch: Bool {
        get { resolver.bool(nativeKey: Keys.isFirstLaunch, legacyKey: ImportKeys.isFirstInstallation, defaultValue: StartupPresentationPolicy.defaultIsFirstLaunch) }
        set { store.set(newValue, forKey: Keys.isFirstLaunch) }
    }

    /// Consumes native and imported Punto Switcher first-run flags after onboarding.
    public func consumeFirstLaunchPresentationFlags() {
        store.set(false, forKey: Keys.isFirstLaunch)
        store.set(false, forKey: ImportKeys.isFirstInstallation)
        store.set(false, forKey: ImportKeys.isJustInstalled)
    }

    /// Consumes imported Punto Switcher update flags after native update presentation.
    public func consumeUpdatePresentationImportFlags() {
        store.set(false, forKey: ImportKeys.isJustUpdated)
        store.set(false, forKey: ImportKeys.isUpdating)
    }

    /// Whether to show the icon in the menu bar
    public var showInMenuBar: Bool {
        get { resolver.bool(nativeKey: Keys.showInMenuBar, defaultValue: SettingsPersistencePolicy.defaultShowInMenuBar) }
        set { store.set(newValue, forKey: Keys.showInMenuBar) }
    }

    /// Whether advanced settings are visible in the preferences window
    public var showAdvancedSettings: Bool {
        get { resolver.bool(nativeKey: Keys.showAdvancedSettings, defaultValue: SettingsPersistencePolicy.defaultShowAdvancedSettings) }
        set { store.set(newValue, forKey: Keys.showAdvancedSettings) }
    }

    /// Whether to launch at login
    public var launchAtLogin: Bool {
        get { resolver.bool(nativeKey: Keys.launchAtLogin, legacyKey: ImportKeys.launchesOnStartup, defaultValue: LoginItemPolicy.defaultLaunchAtLogin) }
        set {
            store.set(newValue, forKey: Keys.launchAtLogin)
            updateLoginItem(enabled: newValue)
        }
    }

    /// Hotkey for converting layout
    public var convertLayoutHotkey: Hotkey {
        get {
            resolver.hotkey(
                nativeKey: Keys.convertLayoutHotkey,
                legacyKey: ImportKeys.shortcutChangeLayout,
                fallback: Hotkey.defaultConvertLayout
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultConvertLayout)
            store.encodeAndSet(normalized, forKey: Keys.convertLayoutHotkey)
        }
    }

    /// Hotkey for toggling case
    public var toggleCaseHotkey: Hotkey {
        get {
            resolver.hotkey(
                nativeKey: Keys.toggleCaseHotkey,
                legacyKey: ImportKeys.shortcutChangeCase,
                fallback: Hotkey.defaultToggleCase
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultToggleCase)
            store.encodeAndSet(normalized, forKey: Keys.toggleCaseHotkey)
        }
    }

    /// Hotkey for toggling auto-correction
    public var toggleAutoCorrectionHotkey: Hotkey {
        get {
            resolver.hotkey(
                nativeKey: Keys.toggleAutoCorrectionHotkey,
                legacyKey: ImportKeys.shortcutSwitchAutocorrection,
                fallback: Hotkey.defaultToggleAutoCorrection
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultToggleAutoCorrection)
            store.encodeAndSet(normalized, forKey: Keys.toggleAutoCorrectionHotkey)
        }
    }

    /// Hotkey for cancelling the last layout change.
    public var cancelLayoutChangeHotkey: Hotkey {
        get {
            resolver.hotkey(
                nativeKey: Keys.cancelLayoutChangeHotkey,
                legacyKey: ImportKeys.shortcutCancelLayoutChange,
                fallback: Hotkey.defaultCancelLayoutChange
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultCancelLayoutChange)
            store.encodeAndSet(normalized, forKey: Keys.cancelLayoutChangeHotkey)
        }
    }

    /// Hotkey for opening selected text in Yandex search.
    public var findInYandexHotkey: Hotkey {
        get {
            resolver.hotkey(
                nativeKey: Keys.findInYandexHotkey,
                legacyKey: ImportKeys.shortcutFindInYandex,
                fallback: Hotkey.defaultFindInYandex
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultFindInYandex)
            store.encodeAndSet(normalized, forKey: Keys.findInYandexHotkey)
        }
    }

    /// Hotkey for opening selected text in Yandex Translate/Slovari flow.
    public var findInSlovariHotkey: Hotkey {
        get {
            resolver.hotkey(
                nativeKey: Keys.findInSlovariHotkey,
                legacyKey: ImportKeys.shortcutFindInSlovari,
                fallback: Hotkey.defaultFindInSlovari
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultFindInSlovari)
            store.encodeAndSet(normalized, forKey: Keys.findInSlovariHotkey)
        }
    }

    public var searchSelectedTextByDoubleClick: Bool {
        get {
            resolver.searchSelectedTextByDoubleClick(
                nativeKey: Keys.searchSelectedTextByDoubleClick,
                legacyKey: ImportKeys.searchbarSettings
            )
        }
        set {
            store.set(newValue, forKey: Keys.searchSelectedTextByDoubleClick)
        }
    }

    /// Переключать раскладку после конвертации
    public var switchLayoutAfterConversion: Bool {
        get { resolver.bool(nativeKey: Keys.switchLayoutAfterConversion, defaultValue: LayoutSwitchPolicy.defaultSwitchLayoutAfterConversion) }
        set { store.set(newValue, forKey: Keys.switchLayoutAfterConversion) }
    }

    public var switchLayoutAfterSelectedTextConversion: Bool {
        get { resolver.bool(nativeKey: Keys.switchLayoutAfterSelectedTextConversion, legacyKey: ImportKeys.switchLayoutOnSelectedTextSwitch, defaultValue: LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion) }
        set {
            store.set(newValue, forKey: Keys.switchLayoutAfterSelectedTextConversion)
        }
    }

    public var manualConversionDisabled: Bool {
        get { resolver.bool(nativeKey: Keys.manualConversionDisabled, legacyKey: ImportKeys.isManualConversionDisabled, defaultValue: TextActionPreflightPolicy.defaultManualConversionDisabled) }
        set {
            store.set(newValue, forKey: Keys.manualConversionDisabled)
        }
    }

    public var russianKeyboardLayoutType: KeyboardLayoutType {
        get { resolver.russianKeyboardLayoutType(nativeKey: Keys.russianKeyboardLayoutType, legacyKey: ImportKeys.kbdLayoutType) }
        set {
            store.set(newValue.rawValue, forKey: Keys.russianKeyboardLayoutType)
            NotificationCenter.default.post(name: .puntoRussianKeyboardLayoutTypeChanged, object: self)
            NotificationCenter.default.post(name: .puntoInputSourcePreferencesChanged, object: self)
        }
    }

    public var preferredEnglishInputSourceID: String? {
        get { resolver.inputSourceID(nativeKey: Keys.preferredEnglishInputSourceID, legacyKey: ImportKeys.englishLayoutID) }
        set {
            setPreferredInputSourceID(newValue, nativeKey: Keys.preferredEnglishInputSourceID)
        }
    }

    public var preferredRussianInputSourceID: String? {
        get { resolver.inputSourceID(nativeKey: Keys.preferredRussianInputSourceID, legacyKey: ImportKeys.russianLayoutID) }
        set {
            setPreferredInputSourceID(newValue, nativeKey: Keys.preferredRussianInputSourceID)
        }
    }

    /// Punto Switcher-style per-application layout memory.
    public var rememberInputSourceForEachApp: Bool {
        get { resolver.bool(nativeKey: Keys.rememberInputSourceForEachApp, legacyKey: ImportKeys.shouldRememberInputSourceForEachApp, defaultValue: ApplicationLayoutPolicy.defaultRememberInputSourceForEachApp) }
        set {
            store.set(newValue, forKey: Keys.rememberInputSourceForEachApp)
        }
    }

    public var rememberedApplicationLayouts: [String: String] {
        get {
            ApplicationLayoutMemory.normalizedSnapshot(
                store.dictionary(forKey: Keys.rememberedApplicationLayouts) as? [String: String] ?? [:]
            )
        }
        set {
            store.set(
                ApplicationLayoutMemory.normalizedSnapshot(newValue),
                forKey: Keys.rememberedApplicationLayouts
            )
        }
    }

    public var disabledApplicationBundleIDs: Set<String> {
        get { resolver.disabledApplicationBundleIDs(nativeKey: Keys.disabledApplicationBundleIDs, legacyKey: ImportKeys.disabledApps) }
        set {
            let normalized = Array(ApplicationDisablePolicy.normalizedSet(newValue)).sorted()
            store.set(normalized, forKey: Keys.disabledApplicationBundleIDs)
        }
    }

    public func isApplicationDisabled(bundleID: String?) -> Bool {
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: bundleID,
            disabledBundleIDs: disabledApplicationBundleIDs
        )
    }

    public var completelyDisableInExceptionApplications: Bool {
        get { resolver.bool(nativeKey: Keys.completelyDisableInExceptionApplications, legacyKey: ImportKeys.completelyDisableInExceptionApps, defaultValue: ApplicationDisablePolicy.defaultCompletelyDisableInExceptionApplications) }
        set {
            store.set(newValue, forKey: Keys.completelyDisableInExceptionApplications)
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
        get { resolver.resetOnReturnBundleComponents(nativeKey: Keys.resetOnReturnBundleComponents, legacyKey: ImportKeys.switcherResetOnReturn) }
        set {
            let normalized = Array(ApplicationReturnKeyPolicy.normalizedResetBundleComponents(newValue)).sorted()
            store.set(
                normalized,
                forKey: Keys.resetOnReturnBundleComponents
            )
        }
    }

    public var autoCorrectionEnabled: Bool {
        get { resolver.bool(nativeKey: Keys.autoCorrectionEnabled, legacyKey: ImportKeys.isAutocorrectionActive, defaultValue: AutoCorrectionPreflightPolicy.defaultAutoCorrectionEnabled) }
        set {
            store.set(newValue, forKey: Keys.autoCorrectionEnabled)
        }
    }

    public var autoCorrectionStarterRulesEnabled: Bool {
        get {
            resolver.firstStoredBool(
                keys: [
                    Keys.autoCorrectionStarterRulesEnabled,
                    ImportKeys.switcherUseOldRulesDefaultConf,
                    ImportKeys.switcherUseOldRulesAccessor
                ],
                defaultValue: AutoCorrectionRuleSourcePolicy.defaultStarterRulesEnabled
            )
        }
        set {
            store.set(newValue, forKey: Keys.autoCorrectionStarterRulesEnabled)
        }
    }

    public var autoCorrectOnEnterAndTab: Bool {
        get { resolver.invertedLegacyBool(nativeKey: Keys.autoCorrectOnEnterAndTab, legacyKey: ImportKeys.shouldNotAutoconvertWithTabOrEnter, defaultValue: AutoCorrectionPreflightPolicy.defaultAutoCorrectOnEnterAndTab) }
        set {
            store.set(newValue, forKey: Keys.autoCorrectOnEnterAndTab)
        }
    }

    public var autoCorrectionUndoLearningEnabled: Bool {
        get { resolver.undoLearningEnabled(nativeKey: Keys.autoCorrectionUndoLearningEnabled, legacyKey: ImportKeys.undoLearning, defaultValue: AutoCorrectionUndoLearningPolicy.defaultUndoLearningEnabled) }
        set {
            store.set(newValue, forKey: Keys.autoCorrectionUndoLearningEnabled)
        }
    }

    public var suppressAutoCorrectionAfterManualConversion: Bool {
        get { resolver.invertedLegacyBool(nativeKey: Keys.suppressAutoCorrectionAfterManualConversion, legacyKey: ImportKeys.shouldNotAutoconvertAfterConvertion, defaultValue: TextReplacementCommitPolicy.defaultSuppressAutoCorrectionAfterManualConversion) }
        set {
            store.set(newValue, forKey: Keys.suppressAutoCorrectionAfterManualConversion)
        }
    }

    public var autoCorrectionCancellingKeyNames: Set<String> {
        get { resolver.autoCorrectionCancellingKeyNames(nativeKey: Keys.autoCorrectionCancellingKeyNames, legacyKey: ImportKeys.cancellingKeys) }
        set {
            store.set(
                Array(AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames(newValue)).sorted(),
                forKey: Keys.autoCorrectionCancellingKeyNames
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
        get { resolver.bool(nativeKey: Keys.soundEffectsEnabled, legacyKey: ImportKeys.isSoundOn, defaultValue: SoundFeedbackPolicy.defaultSoundEffectsEnabled) }
        set {
            store.set(newValue, forKey: Keys.soundEffectsEnabled)
        }
    }

    public var enabledSoundResourceNames: Set<String> {
        get {
            resolver.enabledSoundResourceNames(
                nativeKey: Keys.enabledSoundResourceNames,
                legacyBitmaskKey: ImportKeys.enabledSounds,
                legacyToggleKeys: SoundFeedbackPolicy.legacyPerResourceToggleKeys
            )
        }
        set {
            let normalized = SoundFeedbackPolicy.normalizedEnabledResourceNames(newValue)
            store.set(Array(normalized).sorted(), forKey: Keys.enabledSoundResourceNames)
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
        get { resolver.bool(nativeKey: Keys.restorePasteboardAfterConversion, legacyKey: ImportKeys.shouldRestorePasteboard, defaultValue: ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion) }
        set {
            store.set(newValue, forKey: Keys.restorePasteboardAfterConversion)
        }
    }

    public var productStatistics: ProductStatisticsSnapshot {
        get {
            resolver.productStatistics(
                nativeKey: Keys.productStatistics,
                typedWordsKey: ImportKeys.typedWords,
                typedSymbolsKey: ImportKeys.typedSymbols,
                automaticSwitchesKey: ImportKeys.automaticSwitches,
                manualSwitchesKey: ImportKeys.manualSwitches,
                revertsKey: ImportKeys.reverts,
                dayuseSettingsKey: ImportKeys.dayuseSettings
            )
        }
        set {
            let normalized = ProductStatisticsPolicy.normalized(newValue)
            store.encodeAndSet(normalized, forKey: Keys.productStatistics)
        }
    }

    public func recordProductStatisticsEvent(_ event: ProductStatisticsEvent) {
        productStatistics = ProductStatisticsPolicy.snapshot(after: event, current: productStatistics)
    }

    public var applicationUpdateSettings: ApplicationUpdateSettingsSnapshot {
        get { resolver.applicationUpdateSettings(nativeKey: Keys.applicationUpdateSettings) }
        set {
            let normalized = ApplicationUpdateSettingsPolicy.normalized(newValue)
            store.encodeAndSet(normalized, forKey: Keys.applicationUpdateSettings)
        }
    }

    public var autoCorrectionRules: [AutoCorrectionRule] {
        get {
            resolver.autoCorrectionRules(
                nativeKey: Keys.autoCorrectionRules,
                legacyUserRulesKey: ImportKeys.userRulesDictionary,
                useStarterRules: autoCorrectionStarterRulesEnabled
            )
        }
        set {
            guard let data = try? AutoCorrectionRuleStore.encodeRules(newValue) else { return }
            store.set(data, forKey: Keys.autoCorrectionRules)
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
            Keys.isEnabled: SettingsPersistencePolicy.defaultIsEnabled,
            Keys.isFirstLaunch: StartupPresentationPolicy.defaultIsFirstLaunch,
            Keys.showInMenuBar: SettingsPersistencePolicy.defaultShowInMenuBar,
            Keys.showAdvancedSettings: SettingsPersistencePolicy.defaultShowAdvancedSettings,
            Keys.launchAtLogin: LoginItemPolicy.defaultLaunchAtLogin,
            Keys.switchLayoutAfterConversion: LayoutSwitchPolicy.defaultSwitchLayoutAfterConversion,
            Keys.switchLayoutAfterSelectedTextConversion: LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion,
            Keys.russianKeyboardLayoutType: KeyboardLayoutTypePolicy.defaultRussianLayoutTypeRawValue,
            Keys.manualConversionDisabled: TextActionPreflightPolicy.defaultManualConversionDisabled,
            Keys.rememberInputSourceForEachApp: ApplicationLayoutPolicy.defaultRememberInputSourceForEachApp,
            Keys.rememberedApplicationLayouts: ApplicationLayoutMemory.defaultSnapshot,
            Keys.disabledApplicationBundleIDs: ApplicationDisablePolicy.defaultDisabledBundleIDs,
            Keys.completelyDisableInExceptionApplications: ApplicationDisablePolicy.defaultCompletelyDisableInExceptionApplications,
            Keys.autoCorrectionEnabled: AutoCorrectionPreflightPolicy.defaultAutoCorrectionEnabled,
            Keys.autoCorrectOnEnterAndTab: AutoCorrectionPreflightPolicy.defaultAutoCorrectOnEnterAndTab,
            Keys.autoCorrectionUndoLearningEnabled: AutoCorrectionUndoLearningPolicy.defaultUndoLearningEnabled,
            Keys.suppressAutoCorrectionAfterManualConversion: TextReplacementCommitPolicy.defaultSuppressAutoCorrectionAfterManualConversion,
            Keys.autoCorrectionCancellingKeyNames: AutoCorrectionCancellingKeyPolicy.defaultEnabledKeyNameList,
            Keys.soundEffectsEnabled: SoundFeedbackPolicy.defaultSoundEffectsEnabled,
            Keys.restorePasteboardAfterConversion: ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion
        ])
    }

    // MARK: - Reset to Defaults

    public func resetConvertLayoutHotkey() {
        convertLayoutHotkey = Hotkey.defaultConvertLayout
    }

    public func resetToggleCaseHotkey() {
        toggleCaseHotkey = Hotkey.defaultToggleCase
    }

    public func resetToggleAutoCorrectionHotkey() {
        toggleAutoCorrectionHotkey = Hotkey.defaultToggleAutoCorrection
    }

    public func resetCancelLayoutChangeHotkey() {
        cancelLayoutChangeHotkey = Hotkey.defaultCancelLayoutChange
    }

    public func resetFindInYandexHotkey() {
        findInYandexHotkey = Hotkey.defaultFindInYandex
    }

    public func resetFindInSlovariHotkey() {
        findInSlovariHotkey = Hotkey.defaultFindInSlovari
    }

    // MARK: - Launch at Login

    private func updateLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update login item: \(error)")
            }
        } else {
            // For older macOS versions, use the deprecated API
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.rshagiev.Punto"
            SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled)
        }
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
