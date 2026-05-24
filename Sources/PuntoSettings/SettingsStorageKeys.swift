import Foundation
import PuntoCore

enum SettingsStorageKeys {
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

enum SettingsImportKeys {
    static let isFirstInstallation = ApplicationUpdateSettingsPolicy.legacyIsFirstInstallationKey
    static let launchesOnStartup = LoginItemPolicy.legacyLaunchesOnStartupKey
    static let shortcutChangeLayout = LegacyHotkeyPolicy.legacyShortcutChangeLayoutKey
    static let shortcutChangeCase = LegacyHotkeyPolicy.legacyShortcutChangeCaseKey
    static let shortcutSwitchAutocorrection = LegacyHotkeyPolicy.legacyShortcutSwitchAutocorrectionKey
    static let shortcutCancelLayoutChange = LegacyHotkeyPolicy.legacyShortcutCancelLayoutChangeKey
    static let shortcutFindInYandex = LegacyHotkeyPolicy.legacyShortcutFindInYandexKey
    static let shortcutFindInSlovari = LegacyHotkeyPolicy.legacyShortcutFindInSlovariKey
    static let searchbarSettings = SearchbarSettingsPolicy.legacySettingsKey
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
    static let switcherUseOldRulesDefaultConf = AutoCorrectionRuleSourcePolicy.legacyUseOldRulesDefaultConfPath
    static let switcherUseOldRulesAccessor = AutoCorrectionRuleSourcePolicy.legacyUseOldRulesAccessor
    static let shouldNotAutoconvertWithTabOrEnter = AutoCorrectionPreflightPolicy.legacyShouldNotAutoconvertWithTabOrEnterKey
    static let undoLearning = UndoLearningSettingsPolicy.legacySettingsKey
    static let shouldNotAutoconvertAfterConvertion = TextReplacementCommitPolicy.legacyShouldNotAutoconvertAfterConvertionKey
    static let cancellingKeys = AutoCorrectionCancellingKeyPolicy.legacyCancellingKeysBitmaskKey
    static let userRulesDictionary = LegacyUserRulePolicy.legacyUserRulesDictionaryKey
    static let isSoundOn = SoundFeedbackPolicy.legacyIsSoundOnKey
    static let enabledSounds = SoundFeedbackPolicy.legacyEnabledSoundsKey
    static let shouldRestorePasteboard = ClipboardReplacementPolicy.legacyShouldRestorePasteboardKey
    static let typedWords = ProductStatisticsPolicy.legacyTypedWordsKey
    static let typedSymbols = ProductStatisticsPolicy.legacyTypedSymbolsKey
    static let automaticSwitches = ProductStatisticsPolicy.legacyAutomaticSwitchesKey
    static let manualSwitches = ProductStatisticsPolicy.legacyManualSwitchesKey
    static let reverts = ProductStatisticsPolicy.legacyRevertsKey
    static let dayuseSettings = ProductStatisticsPolicy.legacyDayuseSettingsKey
    static let configVersion = ApplicationUpdateSettingsPolicy.legacyConfigVersionKey
    static let isJustInstalled = ApplicationUpdateSettingsPolicy.legacyIsJustInstalledKey
    static let isJustUpdated = ApplicationUpdateSettingsPolicy.legacyIsJustUpdatedKey
    static let isUpdating = ApplicationUpdateSettingsPolicy.legacyIsUpdatingKey
    static let shouldCheckForUpdatesAutomatically = ApplicationUpdateSettingsPolicy.legacyShouldCheckForUpdatesAutomaticallyKey
    static let updateRequestRateInDays = ApplicationUpdateSettingsPolicy.legacyUpdateRequestRateInDaysKey
    static let lastStatisticsRequestDate = ApplicationUpdateSettingsPolicy.legacyLastStatisticsRequestDateKey
    static let lastUpdateRequestDate = ApplicationUpdateSettingsPolicy.legacyLastUpdateRequestDateKey
    static let lastUpdateShownDate = ApplicationUpdateSettingsPolicy.legacyLastUpdateShownDateKey
}
