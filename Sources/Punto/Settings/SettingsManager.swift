import Foundation
import PuntoCore
import ServiceManagement

extension Notification.Name {
    static let puntoRussianKeyboardLayoutTypeChanged = Notification.Name("puntoRussianKeyboardLayoutTypeChanged")
    static let puntoInputSourcePreferencesChanged = Notification.Name("puntoInputSourcePreferencesChanged")
}

/// Manages application settings using UserDefaults
final class SettingsManager {

    // MARK: - Keys

    private enum Keys {
        static let isEnabled = SettingsPersistencePolicy.observedIsEnabledKey
        static let isFirstLaunch = "isFirstLaunch"
        static let isFirstInstallation = "isFirstInstallation"
        static let showInMenuBar = "showInMenuBar"
        static let showAdvancedSettings = SettingsPersistencePolicy.observedShowAdvancedSettingsKey
        static let launchAtLogin = "launchAtLogin"
        static let launchesOnStartup = SettingsPersistencePolicy.observedLaunchesOnStartupKey
        static let convertLayoutHotkey = "convertLayoutHotkey"
        static let toggleCaseHotkey = "toggleCaseHotkey"
        static let toggleAutoCorrectionHotkey = "toggleAutoCorrectionHotkey"
        static let cancelLayoutChangeHotkey = "cancelLayoutChangeHotkey"
        static let findInYandexHotkey = "findInYandexHotkey"
        static let findInSlovariHotkey = "findInSlovariHotkey"
        static let shortcutChangeLayout = "shortcutChangeLayout"
        static let shortcutChangeCase = "shortcutChangeCase"
        static let shortcutSwitchAutocorrection = "shortcutSwitchAutocorrection"
        static let shortcutCancelLayoutChange = "shortcutCancelLayoutChange"
        static let shortcutFindInYandex = "shortcutFindInYandex"
        static let shortcutFindInSlovari = "shortcutFindInSlovari"
        static let searchbarSettings = SearchbarSettingsPolicy.settingsKey
        static let switchLayoutAfterConversion = "switchLayoutAfterConversion"
        static let switchLayoutAfterSelectedTextConversion = "switchLayoutAfterSelectedTextConversion"
        static let switchLayoutOnSelectedTextSwitch = SettingsPersistencePolicy.observedSwitchLayoutOnSelectedTextSwitchKey
        static let russianKeyboardLayoutType = "russianKeyboardLayoutType"
        static let kbdLayoutType = "kbdLayoutType"
        static let preferredEnglishInputSourceID = "preferredEnglishInputSourceID"
        static let englishLayoutID = "englishLayoutID"
        static let preferredRussianInputSourceID = "preferredRussianInputSourceID"
        static let russianLayoutID = "russianLayoutID"
        static let manualConversionDisabled = "manualConversionDisabled"
        static let isManualConversionDisabled = SettingsPersistencePolicy.observedIsManualConversionDisabledKey
        static let rememberInputSourceForEachApp = "rememberInputSourceForEachApp"
        static let shouldRememberInputSourceForEachApp = SettingsPersistencePolicy.observedShouldRememberInputSourceForEachAppKey
        static let rememberedApplicationLayouts = "rememberedApplicationLayouts"
        static let disabledApplicationBundleIDs = "disabledApplicationBundleIDs"
        static let disabledApps = SettingsPersistencePolicy.observedDisabledAppsKey
        static let completelyDisableInExceptionApplications = "completelyDisableInExceptionApplications"
        static let completelyDisableInExceptionApps = SettingsPersistencePolicy.observedCompletelyDisableInExceptionApplicationsKey
        static let resetOnReturnBundleComponents = "resetOnReturnBundleComponents"
        static let switcherResetOnReturn = "switcher.reset_on_return"
        static let autoCorrectionEnabled = "autoCorrectionEnabled"
        static let isAutocorrectionActive = SettingsPersistencePolicy.observedIsAutocorrectionActiveKey
        static let autoCorrectionStarterRulesEnabled = "autoCorrectionStarterRulesEnabled"
        static let switcherUseOldRulesDefaultConf = AutoCorrectionRuleSourcePolicy.observedUseOldRulesDefaultConfPath
        static let switcherUseOldRulesAccessor = AutoCorrectionRuleSourcePolicy.observedUseOldRulesAccessor
        static let autoCorrectOnEnterAndTab = "autoCorrectOnEnterAndTab"
        static let shouldNotAutoconvertWithTabOrEnter = "shouldNotAutoconvertWithTabOrEnter"
        static let autoCorrectionUndoLearningEnabled = "autoCorrectionUndoLearningEnabled"
        static let undoLearning = UndoLearningSettingsPolicy.settingsKey
        static let suppressAutoCorrectionAfterManualConversion = "suppressAutoCorrectionAfterManualConversion"
        static let shouldNotAutoconvertAfterConvertion = SettingsPersistencePolicy.observedShouldNotAutoconvertAfterConvertionKey
        static let autoCorrectionCancellingKeyNames = "autoCorrectionCancellingKeyNames"
        static let cancellingKeys = "cancellingKeys"
        static let autoCorrectionRules = "autoCorrectionRules"
        static let userRulesDictionary = LegacyUserRulePolicy.userRulesDictionaryKey
        static let soundEffectsEnabled = "soundEffectsEnabled"
        static let isSoundOn = SoundFeedbackPolicy.observedIsSoundOnKey
        static let enabledSoundResourceNames = "enabledSoundResourceNames"
        static let enabledSounds = SoundFeedbackPolicy.legacyEnabledSoundsKey
        static let useSoundLayoutSwitchToRussian = SoundFeedbackPolicy.legacyUseSoundLayoutSwitchToRussianKey
        static let useSoundLayoutSwitchToEnglish = SoundFeedbackPolicy.legacyUseSoundLayoutSwitchToEnglishKey
        static let useSoundConvertation = SoundFeedbackPolicy.legacyUseSoundConvertationKey
        static let useSoundMisprint = SoundFeedbackPolicy.legacyUseSoundMisprintKey
        static let useSoundAutocorrection = SoundFeedbackPolicy.legacyUseSoundAutocorrectionKey
        static let useSoundUndo = SoundFeedbackPolicy.legacyUseSoundUndoKey
        static let useSoundKeystrokes = SoundFeedbackPolicy.legacyUseSoundKeystrokesKey
        static let restorePasteboardAfterConversion = "restorePasteboardAfterConversion"
        static let shouldRestorePasteboard = ClipboardReplacementPolicy.observedShouldRestorePasteboardKey
        static let productStatistics = "productStatistics"
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

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Whether the app functionality is enabled
    var isEnabled: Bool {
        get { persistedBool(forKey: Keys.isEnabled) ?? SettingsPersistencePolicy.defaultIsEnabled }
        set { defaults.set(newValue, forKey: Keys.isEnabled) }
    }

    /// Whether this is the first launch
    var isFirstLaunch: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.isFirstLaunch),
                persistedValue: persistedBool(forKey: Keys.isFirstLaunch),
                hasLegacyValue: hasStoredValue(forKey: Keys.isFirstInstallation),
                legacyValue: persistedBool(forKey: Keys.isFirstInstallation),
                defaultValue: SettingsPersistencePolicy.defaultIsFirstLaunch
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.isFirstLaunch)
            defaults.set(newValue, forKey: Keys.isFirstInstallation)
        }
    }

    /// Whether to show the icon in the menu bar
    var showInMenuBar: Bool {
        get {
            SettingsPersistencePolicy.effectiveBool(
                hasPersistedValue: defaults.object(forKey: Keys.showInMenuBar) != nil,
                persistedValue: persistedBool(forKey: Keys.showInMenuBar),
                defaultValue: SettingsPersistencePolicy.defaultShowInMenuBar
            )
        }
        set { defaults.set(newValue, forKey: Keys.showInMenuBar) }
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
        set { defaults.set(newValue, forKey: Keys.showAdvancedSettings) }
    }

    /// Whether to launch at login
    var launchAtLogin: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.launchAtLogin),
                persistedValue: persistedBool(forKey: Keys.launchAtLogin),
                hasLegacyValue: hasStoredValue(forKey: Keys.launchesOnStartup),
                legacyValue: persistedBool(forKey: Keys.launchesOnStartup),
                defaultValue: SettingsPersistencePolicy.defaultLaunchAtLogin
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
            updateLoginItem(enabled: newValue)
        }
    }

    /// Hotkey for converting layout
    var convertLayoutHotkey: Hotkey {
        get {
            persistedHotkey(
                nativeKey: Keys.convertLayoutHotkey,
                legacyKey: Keys.shortcutChangeLayout,
                fallback: Hotkey.defaultConvertLayout
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultConvertLayout)
            if let data = try? encoder.encode(normalized) {
                defaults.set(data, forKey: Keys.convertLayoutHotkey)
            }
        }
    }

    /// Hotkey for toggling case
    var toggleCaseHotkey: Hotkey {
        get {
            persistedHotkey(
                nativeKey: Keys.toggleCaseHotkey,
                legacyKey: Keys.shortcutChangeCase,
                fallback: Hotkey.defaultToggleCase
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultToggleCase)
            if let data = try? encoder.encode(normalized) {
                defaults.set(data, forKey: Keys.toggleCaseHotkey)
            }
        }
    }

    /// Hotkey for toggling auto-correction
    var toggleAutoCorrectionHotkey: Hotkey {
        get {
            persistedHotkey(
                nativeKey: Keys.toggleAutoCorrectionHotkey,
                legacyKey: Keys.shortcutSwitchAutocorrection,
                fallback: Hotkey.defaultToggleAutoCorrection
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultToggleAutoCorrection)
            if let data = try? encoder.encode(normalized) {
                defaults.set(data, forKey: Keys.toggleAutoCorrectionHotkey)
            }
        }
    }

    /// Hotkey for cancelling the last layout change.
    var cancelLayoutChangeHotkey: Hotkey {
        get {
            persistedHotkey(
                nativeKey: Keys.cancelLayoutChangeHotkey,
                legacyKey: Keys.shortcutCancelLayoutChange,
                fallback: Hotkey.defaultCancelLayoutChange
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultCancelLayoutChange)
            if let data = try? encoder.encode(normalized) {
                defaults.set(data, forKey: Keys.cancelLayoutChangeHotkey)
            }
        }
    }

    /// Hotkey for opening selected text in Yandex search.
    var findInYandexHotkey: Hotkey {
        get {
            persistedHotkey(
                nativeKey: Keys.findInYandexHotkey,
                legacyKey: Keys.shortcutFindInYandex,
                fallback: Hotkey.defaultFindInYandex
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultFindInYandex)
            if let data = try? encoder.encode(normalized) {
                defaults.set(data, forKey: Keys.findInYandexHotkey)
            }
        }
    }

    /// Hotkey for opening selected text in Yandex Translate/Slovari flow.
    var findInSlovariHotkey: Hotkey {
        get {
            persistedHotkey(
                nativeKey: Keys.findInSlovariHotkey,
                legacyKey: Keys.shortcutFindInSlovari,
                fallback: Hotkey.defaultFindInSlovari
            )
        }
        set {
            let normalized = HotkeyValidationPolicy.normalized(newValue, fallback: Hotkey.defaultFindInSlovari)
            if let data = try? encoder.encode(normalized) {
                defaults.set(data, forKey: Keys.findInSlovariHotkey)
            }
        }
    }

    var searchbarSettings: SearchbarSettingsSnapshot {
        get {
            SearchbarSettingsPolicy.snapshot(from: defaults.dictionary(forKey: Keys.searchbarSettings))
                ?? SearchbarSettingsPolicy.defaultSnapshot
        }
        set {
            defaults.set(SearchbarSettingsPolicy.dictionary(from: newValue), forKey: Keys.searchbarSettings)
        }
    }

    var searchSelectedTextByDoubleClick: Bool {
        get {
            searchbarSettings.shouldSearchByDoubleClick
        }
        set {
            searchbarSettings = SearchbarSettingsPolicy.snapshot(
                searchbarSettings,
                settingDoubleClickSearch: newValue
            )
        }
    }

    /// Переключать раскладку после конвертации
    var switchLayoutAfterConversion: Bool {
        get { persistedBool(forKey: Keys.switchLayoutAfterConversion) ?? SettingsPersistencePolicy.defaultSwitchLayoutAfterConversion }
        set { defaults.set(newValue, forKey: Keys.switchLayoutAfterConversion) }
    }

    var switchLayoutAfterSelectedTextConversion: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.switchLayoutAfterSelectedTextConversion),
                persistedValue: persistedBool(forKey: Keys.switchLayoutAfterSelectedTextConversion),
                hasLegacyValue: hasStoredValue(forKey: Keys.switchLayoutOnSelectedTextSwitch),
                legacyValue: persistedBool(forKey: Keys.switchLayoutOnSelectedTextSwitch),
                defaultValue: SettingsPersistencePolicy.defaultSwitchLayoutAfterSelectedTextConversion
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.switchLayoutAfterSelectedTextConversion)
        }
    }

    var manualConversionDisabled: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.manualConversionDisabled),
                persistedValue: persistedBool(forKey: Keys.manualConversionDisabled),
                hasLegacyValue: hasStoredValue(forKey: Keys.isManualConversionDisabled),
                legacyValue: persistedBool(forKey: Keys.isManualConversionDisabled),
                defaultValue: SettingsPersistencePolicy.defaultManualConversionDisabled
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.manualConversionDisabled)
        }
    }

    var russianKeyboardLayoutType: KeyboardLayoutType {
        get {
            SettingsPersistencePolicy.effectiveRussianKeyboardLayoutType(
                hasPersistedValue: hasStoredValue(forKey: Keys.russianKeyboardLayoutType),
                persistedValue: defaults.string(forKey: Keys.russianKeyboardLayoutType),
                hasLegacyValue: hasStoredValue(forKey: Keys.kbdLayoutType),
                legacyValue: defaults.string(forKey: Keys.kbdLayoutType)
            )
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.russianKeyboardLayoutType)
            NotificationCenter.default.post(name: .puntoRussianKeyboardLayoutTypeChanged, object: self)
            NotificationCenter.default.post(name: .puntoInputSourcePreferencesChanged, object: self)
        }
    }

    var preferredEnglishInputSourceID: String? {
        get {
            SettingsPersistencePolicy.effectiveInputSourceID(
                hasPersistedValue: hasStoredValue(forKey: Keys.preferredEnglishInputSourceID),
                persistedValue: defaults.string(forKey: Keys.preferredEnglishInputSourceID),
                hasLegacyValue: hasStoredValue(forKey: Keys.englishLayoutID),
                legacyValue: defaults.string(forKey: Keys.englishLayoutID)
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
                persistedValue: defaults.string(forKey: Keys.preferredRussianInputSourceID),
                hasLegacyValue: hasStoredValue(forKey: Keys.russianLayoutID),
                legacyValue: defaults.string(forKey: Keys.russianLayoutID)
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
                hasLegacyValue: hasStoredValue(forKey: Keys.shouldRememberInputSourceForEachApp),
                legacyValue: persistedBool(forKey: Keys.shouldRememberInputSourceForEachApp),
                defaultValue: SettingsPersistencePolicy.defaultRememberInputSourceForEachApp
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.rememberInputSourceForEachApp)
        }
    }

    var rememberedApplicationLayouts: [String: String] {
        get {
            SettingsPersistencePolicy.normalizedRememberedApplicationLayouts(
                defaults.dictionary(forKey: Keys.rememberedApplicationLayouts) as? [String: String] ?? [:]
            )
        }
        set {
            defaults.set(
                SettingsPersistencePolicy.normalizedRememberedApplicationLayouts(newValue),
                forKey: Keys.rememberedApplicationLayouts
            )
        }
    }

    var disabledApplicationBundleIDs: Set<String> {
        get {
            SettingsPersistencePolicy.effectiveDisabledApplicationBundleIDs(
                hasPersistedValue: hasStoredValue(forKey: Keys.disabledApplicationBundleIDs),
                persistedValue: Set(defaults.stringArray(forKey: Keys.disabledApplicationBundleIDs) ?? []),
                hasLegacyValue: hasStoredValue(forKey: Keys.disabledApps),
                legacyValue: Set(defaults.stringArray(forKey: Keys.disabledApps) ?? [])
            )
        }
        set {
            let normalized = Array(SettingsPersistencePolicy.normalizedDisabledApplicationBundleIDs(newValue)).sorted()
            defaults.set(normalized, forKey: Keys.disabledApplicationBundleIDs)
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
                hasLegacyValue: hasStoredValue(forKey: Keys.completelyDisableInExceptionApps),
                legacyValue: persistedBool(forKey: Keys.completelyDisableInExceptionApps),
                defaultValue: SettingsPersistencePolicy.defaultCompletelyDisableInExceptionApplications
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.completelyDisableInExceptionApplications)
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
                hasPersistedComponents: defaults.object(forKey: Keys.resetOnReturnBundleComponents) != nil,
                persistedComponents: defaults.stringArray(forKey: Keys.resetOnReturnBundleComponents).map(Set.init),
                hasLegacyComponents: defaults.object(forKey: Keys.switcherResetOnReturn) != nil,
                legacyComponents: defaults.stringArray(forKey: Keys.switcherResetOnReturn).map(Set.init)
            )
        }
        set {
            let normalized = Array(SettingsPersistencePolicy.normalizedResetOnReturnBundleComponents(newValue)).sorted()
            defaults.set(
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
                hasLegacyValue: hasStoredValue(forKey: Keys.isAutocorrectionActive),
                legacyValue: persistedBool(forKey: Keys.isAutocorrectionActive),
                defaultValue: SettingsPersistencePolicy.defaultAutoCorrectionEnabled
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.autoCorrectionEnabled)
        }
    }

    var autoCorrectionStarterRulesEnabled: Bool {
        get {
            if hasStoredValue(forKey: Keys.autoCorrectionStarterRulesEnabled) {
                return persistedBool(forKey: Keys.autoCorrectionStarterRulesEnabled)
                    ?? SettingsPersistencePolicy.defaultAutoCorrectionStarterRulesEnabled
            }

            if hasStoredValue(forKey: Keys.switcherUseOldRulesDefaultConf) {
                return persistedBool(forKey: Keys.switcherUseOldRulesDefaultConf)
                    ?? SettingsPersistencePolicy.defaultAutoCorrectionStarterRulesEnabled
            }

            return SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: false,
                persistedValue: nil,
                hasLegacyValue: hasStoredValue(forKey: Keys.switcherUseOldRulesAccessor),
                legacyValue: persistedBool(forKey: Keys.switcherUseOldRulesAccessor),
                defaultValue: SettingsPersistencePolicy.defaultAutoCorrectionStarterRulesEnabled
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.autoCorrectionStarterRulesEnabled)
        }
    }

    var autoCorrectOnEnterAndTab: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.autoCorrectOnEnterAndTab),
                persistedValue: persistedBool(forKey: Keys.autoCorrectOnEnterAndTab),
                hasLegacyValue: hasStoredValue(forKey: Keys.shouldNotAutoconvertWithTabOrEnter),
                invertedLegacyValue: persistedBool(forKey: Keys.shouldNotAutoconvertWithTabOrEnter),
                defaultValue: SettingsPersistencePolicy.defaultAutoCorrectOnEnterAndTab
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.autoCorrectOnEnterAndTab)
        }
    }

    var autoCorrectionUndoLearningEnabled: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.autoCorrectionUndoLearningEnabled),
                persistedValue: persistedBool(forKey: Keys.autoCorrectionUndoLearningEnabled),
                hasLegacyValue: SettingsPersistencePolicy.legacyUndoCollectionEnabled(
                    from: defaults.dictionary(forKey: Keys.undoLearning)
                ) != nil,
                legacyValue: SettingsPersistencePolicy.legacyUndoCollectionEnabled(
                    from: defaults.dictionary(forKey: Keys.undoLearning)
                ) ?? SettingsPersistencePolicy.defaultAutoCorrectionUndoLearningEnabled,
                defaultValue: SettingsPersistencePolicy.defaultAutoCorrectionUndoLearningEnabled
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.autoCorrectionUndoLearningEnabled)
        }
    }

    var suppressAutoCorrectionAfterManualConversion: Bool {
        get {
            SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
                hasPersistedValue: hasStoredValue(forKey: Keys.suppressAutoCorrectionAfterManualConversion),
                persistedValue: persistedBool(forKey: Keys.suppressAutoCorrectionAfterManualConversion),
                hasLegacyValue: hasStoredValue(forKey: Keys.shouldNotAutoconvertAfterConvertion),
                invertedLegacyValue: persistedBool(forKey: Keys.shouldNotAutoconvertAfterConvertion),
                defaultValue: SettingsPersistencePolicy.defaultSuppressAutoCorrectionAfterManualConversion
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.suppressAutoCorrectionAfterManualConversion)
        }
    }

    var autoCorrectionCancellingKeyNames: Set<String> {
        get {
            SettingsPersistencePolicy.effectiveAutoCorrectionCancellingKeyNames(
                hasPersistedValue: hasStoredValue(forKey: Keys.autoCorrectionCancellingKeyNames),
                persistedValue: Set(defaults.stringArray(forKey: Keys.autoCorrectionCancellingKeyNames) ?? []),
                hasLegacyValue: hasStoredValue(forKey: Keys.cancellingKeys),
                legacyBitmask: persistedInt(forKey: Keys.cancellingKeys)
            )
        }
        set {
            defaults.set(
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
                hasLegacyValue: hasStoredValue(forKey: Keys.isSoundOn),
                legacyValue: persistedBool(forKey: Keys.isSoundOn),
                defaultValue: SettingsPersistencePolicy.defaultSoundEffectsEnabled
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.soundEffectsEnabled)
        }
    }

    var enabledSoundResourceNames: Set<String> {
        get {
            if defaults.object(forKey: Keys.enabledSoundResourceNames) != nil {
                return SoundFeedbackPolicy.normalizedEnabledResourceNames(
                    Set(defaults.stringArray(forKey: Keys.enabledSoundResourceNames) ?? [])
                )
            }
            if defaults.object(forKey: Keys.enabledSounds) != nil,
               let legacyNames = SoundFeedbackPolicy.enabledResourceNames(
                fromLegacyBitmask: defaults.integer(forKey: Keys.enabledSounds)
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
            defaults.set(Array(normalized).sorted(), forKey: Keys.enabledSoundResourceNames)
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
                hasLegacyValue: hasStoredValue(forKey: Keys.shouldRestorePasteboard),
                legacyValue: persistedBool(forKey: Keys.shouldRestorePasteboard),
                defaultValue: SettingsPersistencePolicy.defaultRestorePasteboardAfterConversion
            )
        }
        set {
            defaults.set(newValue, forKey: Keys.restorePasteboardAfterConversion)
        }
    }

    var productStatistics: ProductStatisticsSnapshot {
        get {
            let persistedSnapshot = defaults.data(forKey: Keys.productStatistics)
                .flatMap { try? decoder.decode(ProductStatisticsSnapshot.self, from: $0) }
            let legacyCountersSnapshot = ProductStatisticsPolicy.snapshotFromLegacySources(
                typedWords: persistedInt(forKey: Keys.typedWords),
                typedSymbols: persistedInt(forKey: Keys.typedSymbols),
                automaticSwitches: persistedInt(forKey: Keys.automaticSwitches),
                manualSwitches: persistedInt(forKey: Keys.manualSwitches),
                reverts: persistedInt(forKey: Keys.reverts),
                dayuseSettings: defaults.dictionary(forKey: Keys.dayuseSettings)
            )
            return ProductStatisticsPolicy.effectiveSnapshot(
                persistedSnapshot: persistedSnapshot,
                legacyCountersSnapshot: legacyCountersSnapshot
            )
        }
        set {
            let normalized = SettingsPersistencePolicy.normalizedProductStatistics(newValue)
            guard let data = try? encoder.encode(normalized) else {
                return
            }
            defaults.set(data, forKey: Keys.productStatistics)
        }
    }

    func recordProductStatisticsEvent(_ event: ProductStatisticsEvent) {
        productStatistics = ProductStatisticsPolicy.snapshot(after: event, current: productStatistics)
    }

    var applicationUpdateSettings: ApplicationUpdateSettingsSnapshot {
        get {
            ApplicationUpdateSettingsPolicy.snapshot(from: storedDefaults)
        }
        set {
            let dictionary = ApplicationUpdateSettingsPolicy.dictionary(from: newValue)
            for (key, value) in dictionary {
                defaults.set(value, forKey: key)
            }
            if newValue.lastStatisticsRequestDate == nil {
                defaults.removeObject(forKey: Keys.lastStatisticsRequestDate)
            }
            if newValue.lastUpdateRequestDate == nil {
                defaults.removeObject(forKey: Keys.lastUpdateRequestDate)
            }
            if newValue.lastUpdateShownDate == nil {
                defaults.removeObject(forKey: Keys.lastUpdateShownDate)
            }
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
            let hasPersistedRules = defaults.object(forKey: Keys.autoCorrectionRules) != nil
            let rules = defaults.data(forKey: Keys.autoCorrectionRules)
                .flatMap { try? decoder.decode([AutoCorrectionRule].self, from: $0) }
                .map(AutoCorrectionRuleStore.normalizedRules)
            let legacyRules = LegacyUserRulePolicy.rules(from: defaults.object(forKey: Keys.userRulesDictionary))
            return AutoCorrectionRuleSourcePolicy.effectiveRules(
                hasPersistedRules: hasPersistedRules,
                persistedRules: rules,
                legacyUserRules: legacyRules,
                useStarterRules: autoCorrectionStarterRulesEnabled
            )
        }
        set {
            guard let data = try? AutoCorrectionRuleStore.encodeRules(newValue) else { return }
            defaults.set(data, forKey: Keys.autoCorrectionRules)
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
        defaults.register(defaults: [
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
            defaults.set(normalized, forKey: nativeKey)
        } else {
            defaults.removeObject(forKey: nativeKey)
        }
        NotificationCenter.default.post(name: .puntoInputSourcePreferencesChanged, object: self)
    }

    private func persistedInt(forKey key: String) -> Int? {
        guard hasStoredValue(forKey: key) else {
            return nil
        }
        return defaults.integer(forKey: key)
    }

    private func persistedBool(forKey key: String) -> Bool? {
        guard hasStoredValue(forKey: key) else {
            return nil
        }
        return SettingsPersistencePolicy.boolValue(storedDefaults[key])
    }

    private func hasStoredValue(forKey key: String) -> Bool {
        storedDefaults[key] != nil
    }

    private var storedDefaults: [String: Any] {
        guard let domainName = Bundle.main.bundleIdentifier else {
            return [:]
        }
        return defaults.persistentDomain(forName: domainName) ?? [:]
    }

    private func persistedHotkey(nativeKey: String, legacyKey: String, fallback: Hotkey) -> Hotkey {
        if let data = defaults.data(forKey: nativeKey),
           let hotkey = try? decoder.decode(Hotkey.self, from: data) {
            return HotkeyValidationPolicy.normalized(hotkey, fallback: fallback)
        }

        if defaults.object(forKey: legacyKey) != nil {
            return LegacyHotkeyPolicy.normalized(defaults.dictionary(forKey: legacyKey), fallback: fallback)
        }

        return fallback
    }
}
