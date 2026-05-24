import Foundation
import PuntoCore
import ServiceManagement

extension Notification.Name {
    static let puntoRussianKeyboardLayoutTypeChanged = Notification.Name("puntoRussianKeyboardLayoutTypeChanged")
    static let puntoInputSourcePreferencesChanged = Notification.Name("puntoInputSourcePreferencesChanged")
}

/// Composes application settings from native storage, import fallbacks, and policy-provided base values.
final class SettingsManager {

    // MARK: - Keys

    private enum Keys {
        static let isEnabled = SettingsPersistencePolicy.observedIsEnabledKey
        static let isFirstLaunch = "isFirstLaunch"
        static let showInMenuBar = "showInMenuBar"
        static let showAdvancedSettings = SettingsPersistencePolicy.observedShowAdvancedSettingsKey
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
        static let isFirstInstallation = "isFirstInstallation"
        static let launchesOnStartup = SettingsPersistencePolicy.observedLaunchesOnStartupKey
        static let shortcutChangeLayout = "shortcutChangeLayout"
        static let shortcutChangeCase = "shortcutChangeCase"
        static let shortcutSwitchAutocorrection = "shortcutSwitchAutocorrection"
        static let shortcutCancelLayoutChange = "shortcutCancelLayoutChange"
        static let shortcutFindInYandex = "shortcutFindInYandex"
        static let shortcutFindInSlovari = "shortcutFindInSlovari"
        static let searchbarSettings = SearchbarSettingsPolicy.settingsKey
        static let switchLayoutOnSelectedTextSwitch = SettingsPersistencePolicy.observedSwitchLayoutOnSelectedTextSwitchKey
        static let isManualConversionDisabled = SettingsPersistencePolicy.observedIsManualConversionDisabledKey
        static let kbdLayoutType = "kbdLayoutType"
        static let englishLayoutID = "englishLayoutID"
        static let russianLayoutID = "russianLayoutID"
        static let shouldRememberInputSourceForEachApp = SettingsPersistencePolicy.observedShouldRememberInputSourceForEachAppKey
        static let disabledApps = SettingsPersistencePolicy.observedDisabledAppsKey
        static let completelyDisableInExceptionApps = SettingsPersistencePolicy.observedCompletelyDisableInExceptionApplicationsKey
        static let switcherResetOnReturn = "switcher.reset_on_return"
        static let isAutocorrectionActive = SettingsPersistencePolicy.observedIsAutocorrectionActiveKey
        static let switcherUseOldRulesDefaultConf = AutoCorrectionRuleSourcePolicy.observedUseOldRulesDefaultConfPath
        static let switcherUseOldRulesAccessor = AutoCorrectionRuleSourcePolicy.observedUseOldRulesAccessor
        static let shouldNotAutoconvertWithTabOrEnter = "shouldNotAutoconvertWithTabOrEnter"
        static let undoLearning = UndoLearningSettingsPolicy.settingsKey
        static let shouldNotAutoconvertAfterConvertion = SettingsPersistencePolicy.observedShouldNotAutoconvertAfterConvertionKey
        static let cancellingKeys = "cancellingKeys"
        static let userRulesDictionary = LegacyUserRulePolicy.userRulesDictionaryKey
        static let isSoundOn = SoundFeedbackPolicy.observedIsSoundOnKey
        static let enabledSounds = SoundFeedbackPolicy.legacyEnabledSoundsKey
        static let shouldRestorePasteboard = ClipboardReplacementPolicy.observedShouldRestorePasteboardKey
        static let typedWords = "typedWords"
        static let typedSymbols = "typedSymbols"
        static let automaticSwitches = "automaticSwitches"
        static let manualSwitches = "manualSwitches"
        static let reverts = "reverts"
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

    private let store = SettingsDefaultsStore()

    /// Whether the app functionality is enabled
    var isEnabled: Bool {
        get { persistedBool(forKey: Keys.isEnabled) ?? SettingsPersistencePolicy.defaultIsEnabled }
        set { store.set(newValue, forKey: Keys.isEnabled) }
    }

    /// Whether this is the first launch
    var isFirstLaunch: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.isFirstLaunch),
                persistedValue: persistedBool(forKey: Keys.isFirstLaunch),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.isFirstInstallation),
                legacyValue: persistedBool(forKey: ImportKeys.isFirstInstallation),
                defaultValue: SettingsPersistencePolicy.defaultIsFirstLaunch
            )
        }
        set { store.set(newValue, forKey: Keys.isFirstLaunch) }
    }

    /// Consumes native and imported Punto Switcher first-run flags after onboarding.
    func consumeFirstLaunchPresentationFlags() {
        store.set(false, forKey: Keys.isFirstLaunch)
        store.set(false, forKey: ImportKeys.isFirstInstallation)
        store.set(false, forKey: ImportKeys.isJustInstalled)
    }

    /// Consumes imported Punto Switcher update flags after native update presentation.
    func consumeUpdatePresentationImportFlags() {
        store.set(false, forKey: ImportKeys.isJustUpdated)
        store.set(false, forKey: ImportKeys.isUpdating)
    }

    /// Whether to show the icon in the menu bar
    var showInMenuBar: Bool {
        get {
            SettingsPersistencePolicy.effectiveBool(
                hasPersistedValue: store.object(forKey: Keys.showInMenuBar) != nil,
                persistedValue: persistedBool(forKey: Keys.showInMenuBar),
                defaultValue: SettingsPersistencePolicy.defaultShowInMenuBar
            )
        }
        set { store.set(newValue, forKey: Keys.showInMenuBar) }
    }

    /// Whether advanced settings are visible in the preferences window
    var showAdvancedSettings: Bool {
        get {
            SettingsPersistencePolicy.effectiveBool(
                hasPersistedValue: hasStoredValue(forKey: Keys.showAdvancedSettings),
                persistedValue: persistedBool(forKey: Keys.showAdvancedSettings),
                defaultValue: SettingsPersistencePolicy.defaultShowAdvancedSettings
            )
        }
        set { store.set(newValue, forKey: Keys.showAdvancedSettings) }
    }

    /// Whether to launch at login
    var launchAtLogin: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.launchAtLogin),
                persistedValue: persistedBool(forKey: Keys.launchAtLogin),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.launchesOnStartup),
                legacyValue: persistedBool(forKey: ImportKeys.launchesOnStartup),
                defaultValue: SettingsPersistencePolicy.defaultLaunchAtLogin
            )
        }
        set {
            store.set(newValue, forKey: Keys.launchAtLogin)
            updateLoginItem(enabled: newValue)
        }
    }

    /// Hotkey for converting layout
    var convertLayoutHotkey: Hotkey {
        get {
            persistedHotkey(
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
    var toggleCaseHotkey: Hotkey {
        get {
            persistedHotkey(
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
    var toggleAutoCorrectionHotkey: Hotkey {
        get {
            persistedHotkey(
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
    var cancelLayoutChangeHotkey: Hotkey {
        get {
            persistedHotkey(
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
    var findInYandexHotkey: Hotkey {
        get {
            persistedHotkey(
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
    var findInSlovariHotkey: Hotkey {
        get {
            persistedHotkey(
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

    var searchSelectedTextByDoubleClick: Bool {
        get {
            SearchbarSettingsPolicy.effectiveShouldSearchByDoubleClick(
                hasNativeValue: hasStoredValue(forKey: Keys.searchSelectedTextByDoubleClick),
                nativeValue: persistedBool(forKey: Keys.searchSelectedTextByDoubleClick),
                legacySnapshot: SearchbarSettingsPolicy.snapshot(from: store.dictionary(forKey: ImportKeys.searchbarSettings))
            )
        }
        set {
            store.set(newValue, forKey: Keys.searchSelectedTextByDoubleClick)
        }
    }

    /// Переключать раскладку после конвертации
    var switchLayoutAfterConversion: Bool {
        get { persistedBool(forKey: Keys.switchLayoutAfterConversion) ?? SettingsPersistencePolicy.defaultSwitchLayoutAfterConversion }
        set { store.set(newValue, forKey: Keys.switchLayoutAfterConversion) }
    }

    var switchLayoutAfterSelectedTextConversion: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.switchLayoutAfterSelectedTextConversion),
                persistedValue: persistedBool(forKey: Keys.switchLayoutAfterSelectedTextConversion),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.switchLayoutOnSelectedTextSwitch),
                legacyValue: persistedBool(forKey: ImportKeys.switchLayoutOnSelectedTextSwitch),
                defaultValue: SettingsPersistencePolicy.defaultSwitchLayoutAfterSelectedTextConversion
            )
        }
        set {
            store.set(newValue, forKey: Keys.switchLayoutAfterSelectedTextConversion)
        }
    }

    var manualConversionDisabled: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.manualConversionDisabled),
                persistedValue: persistedBool(forKey: Keys.manualConversionDisabled),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.isManualConversionDisabled),
                legacyValue: persistedBool(forKey: ImportKeys.isManualConversionDisabled),
                defaultValue: SettingsPersistencePolicy.defaultManualConversionDisabled
            )
        }
        set {
            store.set(newValue, forKey: Keys.manualConversionDisabled)
        }
    }

    var russianKeyboardLayoutType: KeyboardLayoutType {
        get {
            SettingsPersistencePolicy.effectiveRussianKeyboardLayoutType(
                hasPersistedValue: hasStoredValue(forKey: Keys.russianKeyboardLayoutType),
                persistedValue: store.string(forKey: Keys.russianKeyboardLayoutType),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.kbdLayoutType),
                legacyValue: store.string(forKey: ImportKeys.kbdLayoutType)
            )
        }
        set {
            store.set(newValue.rawValue, forKey: Keys.russianKeyboardLayoutType)
            NotificationCenter.default.post(name: .puntoRussianKeyboardLayoutTypeChanged, object: self)
            NotificationCenter.default.post(name: .puntoInputSourcePreferencesChanged, object: self)
        }
    }

    var preferredEnglishInputSourceID: String? {
        get {
            SettingsPersistencePolicy.effectiveInputSourceID(
                hasPersistedValue: hasStoredValue(forKey: Keys.preferredEnglishInputSourceID),
                persistedValue: store.string(forKey: Keys.preferredEnglishInputSourceID),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.englishLayoutID),
                legacyValue: store.string(forKey: ImportKeys.englishLayoutID)
            )
        }
        set {
            setPreferredInputSourceID(newValue, nativeKey: Keys.preferredEnglishInputSourceID)
        }
    }

    var preferredRussianInputSourceID: String? {
        get {
            SettingsPersistencePolicy.effectiveInputSourceID(
                hasPersistedValue: hasStoredValue(forKey: Keys.preferredRussianInputSourceID),
                persistedValue: store.string(forKey: Keys.preferredRussianInputSourceID),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.russianLayoutID),
                legacyValue: store.string(forKey: ImportKeys.russianLayoutID)
            )
        }
        set {
            setPreferredInputSourceID(newValue, nativeKey: Keys.preferredRussianInputSourceID)
        }
    }

    /// Punto Switcher-style per-application layout memory.
    var rememberInputSourceForEachApp: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.rememberInputSourceForEachApp),
                persistedValue: persistedBool(forKey: Keys.rememberInputSourceForEachApp),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.shouldRememberInputSourceForEachApp),
                legacyValue: persistedBool(forKey: ImportKeys.shouldRememberInputSourceForEachApp),
                defaultValue: SettingsPersistencePolicy.defaultRememberInputSourceForEachApp
            )
        }
        set {
            store.set(newValue, forKey: Keys.rememberInputSourceForEachApp)
        }
    }

    var rememberedApplicationLayouts: [String: String] {
        get {
            SettingsPersistencePolicy.normalizedRememberedApplicationLayouts(
                store.dictionary(forKey: Keys.rememberedApplicationLayouts) as? [String: String] ?? [:]
            )
        }
        set {
            store.set(
                SettingsPersistencePolicy.normalizedRememberedApplicationLayouts(newValue),
                forKey: Keys.rememberedApplicationLayouts
            )
        }
    }

    var disabledApplicationBundleIDs: Set<String> {
        get {
            SettingsPersistencePolicy.effectiveDisabledApplicationBundleIDs(
                hasPersistedValue: hasStoredValue(forKey: Keys.disabledApplicationBundleIDs),
                persistedValue: Set(store.stringArray(forKey: Keys.disabledApplicationBundleIDs) ?? []),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.disabledApps),
                legacyValue: Set(store.stringArray(forKey: ImportKeys.disabledApps) ?? [])
            )
        }
        set {
            let normalized = Array(SettingsPersistencePolicy.normalizedDisabledApplicationBundleIDs(newValue)).sorted()
            store.set(normalized, forKey: Keys.disabledApplicationBundleIDs)
        }
    }

    func isApplicationDisabled(bundleID: String?) -> Bool {
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: bundleID,
            disabledBundleIDs: disabledApplicationBundleIDs
        )
    }

    var completelyDisableInExceptionApplications: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.completelyDisableInExceptionApplications),
                persistedValue: persistedBool(forKey: Keys.completelyDisableInExceptionApplications),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.completelyDisableInExceptionApps),
                legacyValue: persistedBool(forKey: ImportKeys.completelyDisableInExceptionApps),
                defaultValue: SettingsPersistencePolicy.defaultCompletelyDisableInExceptionApplications
            )
        }
        set {
            store.set(newValue, forKey: Keys.completelyDisableInExceptionApplications)
        }
    }

    func isApplicationCompletelyDisabled(bundleID: String?) -> Bool {
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: bundleID,
            disabledBundleIDs: disabledApplicationBundleIDs,
            completelyDisableInExceptionApplications: completelyDisableInExceptionApplications
        )
    }

    func setApplicationDisabled(bundleID: String?, disabled: Bool) {
        disabledApplicationBundleIDs = ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: bundleID,
            disabled: disabled,
            disabledBundleIDs: disabledApplicationBundleIDs
        )
    }

    var resetOnReturnBundleComponents: Set<String> {
        get {
            SettingsPersistencePolicy.effectiveResetOnReturnBundleComponents(
                hasPersistedComponents: store.object(forKey: Keys.resetOnReturnBundleComponents) != nil,
                persistedComponents: store.stringArray(forKey: Keys.resetOnReturnBundleComponents).map(Set.init),
                hasLegacyComponents: store.object(forKey: ImportKeys.switcherResetOnReturn) != nil,
                legacyComponents: store.stringArray(forKey: ImportKeys.switcherResetOnReturn).map(Set.init)
            )
        }
        set {
            let normalized = Array(SettingsPersistencePolicy.normalizedResetOnReturnBundleComponents(newValue)).sorted()
            store.set(
                normalized,
                forKey: Keys.resetOnReturnBundleComponents
            )
        }
    }

    var autoCorrectionEnabled: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.autoCorrectionEnabled),
                persistedValue: persistedBool(forKey: Keys.autoCorrectionEnabled),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.isAutocorrectionActive),
                legacyValue: persistedBool(forKey: ImportKeys.isAutocorrectionActive),
                defaultValue: SettingsPersistencePolicy.defaultAutoCorrectionEnabled
            )
        }
        set {
            store.set(newValue, forKey: Keys.autoCorrectionEnabled)
        }
    }

    var autoCorrectionStarterRulesEnabled: Bool {
        get {
            if hasStoredValue(forKey: Keys.autoCorrectionStarterRulesEnabled) {
                return persistedBool(forKey: Keys.autoCorrectionStarterRulesEnabled)
                    ?? SettingsPersistencePolicy.defaultAutoCorrectionStarterRulesEnabled
            }

            if hasStoredValue(forKey: ImportKeys.switcherUseOldRulesDefaultConf) {
                return persistedBool(forKey: ImportKeys.switcherUseOldRulesDefaultConf)
                    ?? SettingsPersistencePolicy.defaultAutoCorrectionStarterRulesEnabled
            }

            return SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: false,
                persistedValue: nil,
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.switcherUseOldRulesAccessor),
                legacyValue: persistedBool(forKey: ImportKeys.switcherUseOldRulesAccessor),
                defaultValue: SettingsPersistencePolicy.defaultAutoCorrectionStarterRulesEnabled
            )
        }
        set {
            store.set(newValue, forKey: Keys.autoCorrectionStarterRulesEnabled)
        }
    }

    var autoCorrectOnEnterAndTab: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.autoCorrectOnEnterAndTab),
                persistedValue: persistedBool(forKey: Keys.autoCorrectOnEnterAndTab),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.shouldNotAutoconvertWithTabOrEnter),
                invertedLegacyValue: persistedBool(forKey: ImportKeys.shouldNotAutoconvertWithTabOrEnter),
                defaultValue: SettingsPersistencePolicy.defaultAutoCorrectOnEnterAndTab
            )
        }
        set {
            store.set(newValue, forKey: Keys.autoCorrectOnEnterAndTab)
        }
    }

    var autoCorrectionUndoLearningEnabled: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.autoCorrectionUndoLearningEnabled),
                persistedValue: persistedBool(forKey: Keys.autoCorrectionUndoLearningEnabled),
                hasLegacyValue: SettingsPersistencePolicy.legacyUndoCollectionEnabled(
                    from: store.dictionary(forKey: ImportKeys.undoLearning)
                ) != nil,
                legacyValue: SettingsPersistencePolicy.legacyUndoCollectionEnabled(
                    from: store.dictionary(forKey: ImportKeys.undoLearning)
                ) ?? SettingsPersistencePolicy.defaultAutoCorrectionUndoLearningEnabled,
                defaultValue: SettingsPersistencePolicy.defaultAutoCorrectionUndoLearningEnabled
            )
        }
        set {
            store.set(newValue, forKey: Keys.autoCorrectionUndoLearningEnabled)
        }
    }

    var suppressAutoCorrectionAfterManualConversion: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.suppressAutoCorrectionAfterManualConversion),
                persistedValue: persistedBool(forKey: Keys.suppressAutoCorrectionAfterManualConversion),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.shouldNotAutoconvertAfterConvertion),
                invertedLegacyValue: persistedBool(forKey: ImportKeys.shouldNotAutoconvertAfterConvertion),
                defaultValue: SettingsPersistencePolicy.defaultSuppressAutoCorrectionAfterManualConversion
            )
        }
        set {
            store.set(newValue, forKey: Keys.suppressAutoCorrectionAfterManualConversion)
        }
    }

    var autoCorrectionCancellingKeyNames: Set<String> {
        get {
            SettingsPersistencePolicy.effectiveAutoCorrectionCancellingKeyNames(
                hasPersistedValue: hasStoredValue(forKey: Keys.autoCorrectionCancellingKeyNames),
                persistedValue: Set(store.stringArray(forKey: Keys.autoCorrectionCancellingKeyNames) ?? []),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.cancellingKeys),
                legacyBitmask: persistedInt(forKey: ImportKeys.cancellingKeys)
            )
        }
        set {
            store.set(
                Array(SettingsPersistencePolicy.normalizedAutoCorrectionCancellingKeyNames(newValue)).sorted(),
                forKey: Keys.autoCorrectionCancellingKeyNames
            )
        }
    }

    func isAutoCorrectionCancellingKeyEnabled(_ keyName: String) -> Bool {
        autoCorrectionCancellingKeyNames.contains(
            AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames([keyName]).first ?? ""
        )
    }

    func setAutoCorrectionCancellingKey(_ keyName: String, enabled: Bool) {
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

    var soundEffectsEnabled: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.soundEffectsEnabled),
                persistedValue: persistedBool(forKey: Keys.soundEffectsEnabled),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.isSoundOn),
                legacyValue: persistedBool(forKey: ImportKeys.isSoundOn),
                defaultValue: SettingsPersistencePolicy.defaultSoundEffectsEnabled
            )
        }
        set {
            store.set(newValue, forKey: Keys.soundEffectsEnabled)
        }
    }

    var enabledSoundResourceNames: Set<String> {
        get {
            if store.object(forKey: Keys.enabledSoundResourceNames) != nil {
                return SoundFeedbackPolicy.normalizedEnabledResourceNames(
                    Set(store.stringArray(forKey: Keys.enabledSoundResourceNames) ?? [])
                )
            }
            if store.object(forKey: ImportKeys.enabledSounds) != nil,
               let legacyNames = SoundFeedbackPolicy.enabledResourceNames(
                fromLegacyBitmask: store.integer(forKey: ImportKeys.enabledSounds)
               ) {
                return legacyNames
            }
            if let legacyToggleNames = SoundFeedbackPolicy.enabledResourceNames(
                fromLegacyToggles: legacySoundResourceToggles()
            ) {
                return legacyToggleNames
            }
            return SoundFeedbackPolicy.defaultEnabledResourceNames
        }
        set {
            let normalized = SoundFeedbackPolicy.normalizedEnabledResourceNames(newValue)
            store.set(Array(normalized).sorted(), forKey: Keys.enabledSoundResourceNames)
        }
    }

    func isSoundResourceEnabled(_ resourceName: String) -> Bool {
        enabledSoundResourceNames.contains(resourceName)
    }

    func setSoundResource(_ resourceName: String, enabled: Bool) {
        var enabledNames = enabledSoundResourceNames
        if enabled {
            enabledNames.insert(resourceName)
        } else {
            enabledNames.remove(resourceName)
        }
        enabledSoundResourceNames = enabledNames
    }

    var restorePasteboardAfterConversion: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.restorePasteboardAfterConversion),
                persistedValue: persistedBool(forKey: Keys.restorePasteboardAfterConversion),
                hasLegacyValue: hasStoredValue(forKey: ImportKeys.shouldRestorePasteboard),
                legacyValue: persistedBool(forKey: ImportKeys.shouldRestorePasteboard),
                defaultValue: SettingsPersistencePolicy.defaultRestorePasteboardAfterConversion
            )
        }
        set {
            store.set(newValue, forKey: Keys.restorePasteboardAfterConversion)
        }
    }

    var productStatistics: ProductStatisticsSnapshot {
        get {
            let persistedSnapshot = store.decode(ProductStatisticsSnapshot.self, forKey: Keys.productStatistics)
            let legacyCountersSnapshot = ProductStatisticsPolicy.snapshotFromLegacySources(
                typedWords: persistedInt(forKey: ImportKeys.typedWords),
                typedSymbols: persistedInt(forKey: ImportKeys.typedSymbols),
                automaticSwitches: persistedInt(forKey: ImportKeys.automaticSwitches),
                manualSwitches: persistedInt(forKey: ImportKeys.manualSwitches),
                reverts: persistedInt(forKey: ImportKeys.reverts),
                dayuseSettings: store.dictionary(forKey: ImportKeys.dayuseSettings)
            )
            return ProductStatisticsPolicy.effectiveSnapshot(
                persistedSnapshot: persistedSnapshot,
                legacyCountersSnapshot: legacyCountersSnapshot
            )
        }
        set {
            let normalized = SettingsPersistencePolicy.normalizedProductStatistics(newValue)
            store.encodeAndSet(normalized, forKey: Keys.productStatistics)
        }
    }

    func recordProductStatisticsEvent(_ event: ProductStatisticsEvent) {
        productStatistics = ProductStatisticsPolicy.snapshot(after: event, current: productStatistics)
    }

    var applicationUpdateSettings: ApplicationUpdateSettingsSnapshot {
        get {
            if let snapshot = store.decode(ApplicationUpdateSettingsSnapshot.self, forKey: Keys.applicationUpdateSettings) {
                return ApplicationUpdateSettingsPolicy.normalized(snapshot)
            }
            return ApplicationUpdateSettingsPolicy.snapshot(from: store.storedDefaults)
        }
        set {
            let normalized = ApplicationUpdateSettingsPolicy.normalized(newValue)
            store.encodeAndSet(normalized, forKey: Keys.applicationUpdateSettings)
        }
    }

    private func legacySoundResourceToggles() -> [String: Bool] {
        var toggles: [String: Bool] = [:]
        for key in SoundFeedbackPolicy.legacyPerResourceToggleKeys where hasStoredValue(forKey: key) {
            if let value = persistedBool(forKey: key) {
                toggles[key] = value
            }
        }
        return toggles
    }

    var autoCorrectionRules: [AutoCorrectionRule] {
        get {
            let hasPersistedRules = store.object(forKey: Keys.autoCorrectionRules) != nil
            let rules = store.decode([AutoCorrectionRule].self, forKey: Keys.autoCorrectionRules)
                .map(AutoCorrectionRuleStore.normalizedRules)
            let legacyRules = LegacyUserRulePolicy.rules(from: store.object(forKey: ImportKeys.userRulesDictionary))
            return AutoCorrectionRuleSourcePolicy.effectiveRules(
                hasPersistedRules: hasPersistedRules,
                persistedRules: rules,
                legacyUserRules: legacyRules,
                useStarterRules: autoCorrectionStarterRulesEnabled
            )
        }
        set {
            guard let data = try? AutoCorrectionRuleStore.encodeRules(newValue) else { return }
            store.set(data, forKey: Keys.autoCorrectionRules)
        }
    }

    @discardableResult
    func importAutoCorrectionRules(from data: Data, merge: Bool = true) throws -> AutoCorrectionRuleImportResult {
        let result = try AutoCorrectionRuleStore.decodeRules(from: data)
        autoCorrectionRules = merge
            ? AutoCorrectionRuleStore.mergedRules(existing: autoCorrectionRules, imported: result.rules)
            : result.rules
        return result
    }

    func exportAutoCorrectionRules() throws -> Data {
        try AutoCorrectionRuleStore.encodeRules(autoCorrectionRules)
    }

    // MARK: - Initialization

    init() {
        // Register defaults
        store.register(defaults: [
            Keys.isEnabled: SettingsPersistencePolicy.defaultIsEnabled,
            Keys.isFirstLaunch: SettingsPersistencePolicy.defaultIsFirstLaunch,
            Keys.showInMenuBar: SettingsPersistencePolicy.defaultShowInMenuBar,
            Keys.showAdvancedSettings: SettingsPersistencePolicy.defaultShowAdvancedSettings,
            Keys.launchAtLogin: SettingsPersistencePolicy.defaultLaunchAtLogin,
            Keys.switchLayoutAfterConversion: SettingsPersistencePolicy.defaultSwitchLayoutAfterConversion,
            Keys.switchLayoutAfterSelectedTextConversion: SettingsPersistencePolicy.defaultSwitchLayoutAfterSelectedTextConversion,
            Keys.russianKeyboardLayoutType: SettingsPersistencePolicy.defaultRussianKeyboardLayoutType,
            Keys.manualConversionDisabled: SettingsPersistencePolicy.defaultManualConversionDisabled,
            Keys.rememberInputSourceForEachApp: SettingsPersistencePolicy.defaultRememberInputSourceForEachApp,
            Keys.rememberedApplicationLayouts: SettingsPersistencePolicy.defaultRememberedApplicationLayouts,
            Keys.disabledApplicationBundleIDs: SettingsPersistencePolicy.defaultDisabledApplicationBundleIDs,
            Keys.completelyDisableInExceptionApplications: SettingsPersistencePolicy.defaultCompletelyDisableInExceptionApplications,
            Keys.autoCorrectionEnabled: SettingsPersistencePolicy.defaultAutoCorrectionEnabled,
            Keys.autoCorrectOnEnterAndTab: SettingsPersistencePolicy.defaultAutoCorrectOnEnterAndTab,
            Keys.autoCorrectionUndoLearningEnabled: SettingsPersistencePolicy.defaultAutoCorrectionUndoLearningEnabled,
            Keys.suppressAutoCorrectionAfterManualConversion: SettingsPersistencePolicy.defaultSuppressAutoCorrectionAfterManualConversion,
            Keys.autoCorrectionCancellingKeyNames: SettingsPersistencePolicy.defaultAutoCorrectionCancellingKeyNames,
            Keys.soundEffectsEnabled: SettingsPersistencePolicy.defaultSoundEffectsEnabled,
            Keys.restorePasteboardAfterConversion: SettingsPersistencePolicy.defaultRestorePasteboardAfterConversion
        ])
    }

    // MARK: - Reset to Defaults

    func resetConvertLayoutHotkey() {
        convertLayoutHotkey = Hotkey.defaultConvertLayout
    }

    func resetToggleCaseHotkey() {
        toggleCaseHotkey = Hotkey.defaultToggleCase
    }

    func resetToggleAutoCorrectionHotkey() {
        toggleAutoCorrectionHotkey = Hotkey.defaultToggleAutoCorrection
    }

    func resetCancelLayoutChangeHotkey() {
        cancelLayoutChangeHotkey = Hotkey.defaultCancelLayoutChange
    }

    func resetFindInYandexHotkey() {
        findInYandexHotkey = Hotkey.defaultFindInYandex
    }

    func resetFindInSlovariHotkey() {
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
        if let normalized = SettingsPersistencePolicy.normalizedInputSourceID(sourceID) {
            store.set(normalized, forKey: nativeKey)
        } else {
            store.removeObject(forKey: nativeKey)
        }
        NotificationCenter.default.post(name: .puntoInputSourcePreferencesChanged, object: self)
    }

    private func persistedInt(forKey key: String) -> Int? {
        store.integer(forKey: key)
    }

    private func persistedBool(forKey key: String) -> Bool? {
        store.bool(forKey: key)
    }

    private func hasStoredValue(forKey key: String) -> Bool {
        store.hasStoredValue(forKey: key)
    }

    private func persistedHotkey(nativeKey: String, legacyKey: String, fallback: Hotkey) -> Hotkey {
        if let hotkey = store.decode(Hotkey.self, forKey: nativeKey) {
            return HotkeyValidationPolicy.normalized(hotkey, fallback: fallback)
        }

        if store.object(forKey: legacyKey) != nil {
            return LegacyHotkeyPolicy.normalized(store.dictionary(forKey: legacyKey), fallback: fallback)
        }

        return fallback
    }
}
