public enum PuntoSwitcherObservedSurface {
    public enum AccessibilityApplications {
        public static let browserInjectionBundleIDs = [
            "com.apple.safari",
            "com.google.chrome",
            "org.chromium.chromium",
            "ru.yandex.desktop.yandex-browser",
            "com.operasoftware.Opera",
            "org.mozilla.firefox"
        ]

        public static let enhancedUserInterfaceBundleIDs = [
            "com.google.chrome",
            "com.operasoftware.Opera",
            "org.chromium.chromium",
            "org.mozilla.firefox",
            "ru.yandex.desktop.yandex-browser"
        ]
    }

    public enum AccessibilityNotifications {
        public static let focusedUIElementChanged = "AXFocusedUIElementChanged"
        public static let focusedWindowChanged = "AXFocusedWindowChanged"
        public static let mainWindowChanged = "AXMainWindowChanged"
        public static let windowCreated = "AXWindowCreated"
        public static let selectedTextChanged = "AXSelectedTextChanged"
        public static let valueChanged = "AXValueChanged"
    }

    public enum AccessibilityRoles {
        public static let mailApplicationToken = "Mail"
        public static let parallelsBundleID = "com.parallels.desktop"
        public static let scrollAreaRole = "AXScrollArea"
    }

    public enum AccessibilityPreferences {
        public static let launchAccessibilityPreferencesSelector = "launchAccessibilityPreferences"
        public static let openAccessibilityPrefPaneSelector = "openAccesibilityPrefPane:"
        public static let preferencesURLString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        public static let legacySystemPreferencesApplicationName = "System Preferences"
        public static let legacyAccessibilityPrivacyAnchor = "Privacy_Accessibility"
        public static let legacySecurityPrivacyPaneID = "com.apple.preference.security"
        public static let accessibilityAlertMessageKey = "accessibility-alert-message"
        public static let accessibilityAlertLegacyMessageKey = "accessibility-alert-messageLegacy"
    }

    public enum AccessibilityMailReplacement {
        public static let fullWordReplacementSelector = "applyMailBehaviourForFullWords:withEvent:withCharsToSelect:withForceWordEndingCharPresent:"
        public static let partialWordReplacementSelector = "applyMailBehaviourForPartialWords:"
        public static let deletionCounterKey = "numberOfDeletionsInMail"
    }

    public enum AutoCorrectionCancellingKeys {
        public static let setCancellingKeyStateSelector = "setCancellingKeyState:doEnable:"
        public static let backspaceName = "dontAutoconvertWordWithBackspace"
        public static let deleteName = "dontAutoconvertWordWithDelete"
        public static let leftArrowName = "dontAutoconvertWordWithLeftArrow"
        public static let rightArrowName = "dontAutoconvertWordWithRightArrow"
        public static let upArrowName = "dontAutoconvertWordWithUpArrow"
        public static let downArrowName = "dontAutoconvertWordWithDownArrow"
        public static let backspaceSelector = "dontAutoconvertWordWithBackspace:"
        public static let deleteSelector = "dontAutoconvertWordWithDelete:"
        public static let leftArrowSelector = "dontAutoconvertWordWithLeftArrow:"
        public static let rightArrowSelector = "dontAutoconvertWordWithRightArrow:"
        public static let upArrowSelector = "dontAutoconvertWordWithUpArrow:"
        public static let downArrowSelector = "dontAutoconvertWordWithDownArrow:"
    }

    public enum ClipboardReplacement {
        public static let previousPasteboardContentsKey = "previousPasteboardContents"
        public static let pasteboardRestoreTimerKey = "pasteboardRestoreTimer"
        public static let generalPasteboardSelector = "generalPasteboard"
        public static let getPasteboardStringSelector = "getPasteboardString"
        public static let setPasteboardStringSelector = "setPasteboardString:"
        public static let restorePasteboardByTimerSelector = "restorePasteboardByTimer:"
        public static let restorePasteboardForKeyboardByTimerSelector = "restorePasteboardForKeyboardByTimer:"
    }

    public enum Hotkeys {
        public static let shortcutChangeLayoutKey = "shortcutChangeLayout"
        public static let shortcutChangeCaseKey = "shortcutChangeCase"
        public static let shortcutSwitchAutocorrectionKey = "shortcutSwitchAutocorrection"
        public static let shortcutCancelLayoutChangeKey = "shortcutCancelLayoutChange"
        public static let shortcutFindInYandexKey = "shortcutFindInYandex"
        public static let shortcutFindInSlovariKey = "shortcutFindInSlovari"
        public static let setShortcutSelector = "setShortcut:"
        public static let shortcutWithDictionarySelector = "shortcutWithDictionary:"
        public static let resetShortcutsToDefaultsSelector = "resetShortcutsToDefaults:"
        public static let setShortcutChangeLayoutSelector = "setShortcutChangeLayout:"
        public static let setShortcutChangeCaseSelector = "setShortcutChangeCase:"
        public static let setShortcutSwitchAutocorrectionSelector = "setShortcutSwitchAutocorrection:"
        public static let setShortcutCancelLayoutChangeSelector = "setShortcutCancelLayoutChange:"
        public static let setShortcutFindInYandexSelector = "setShortcutFindInYandex:"
        public static let setShortcutFindInSlovariSelector = "setShortcutFindInSlovari:"
        public static let shortcutsPreferencesControllerKey = "shortcutsPreferencesController"
        public static let setShortcutsPreferencesControllerSelector = "setShortcutsPreferencesController:"
        public static let switchAutocorrectionSelector = "switchAutocorrection:"
        public static let cancelLayoutChangeShortcutKey = "cancelLayoutChangeShortcut"
        public static let switchAutocorrectionShortcutKey = "switchAutocorrectionShortcut"
        public static let changeCaseShortcutKey = "changeCaseShortcut"
        public static let setChangeCaseShortcutSelector = "setChangeCaseShortcut:"
        public static let shortcutFieldClassName = "ShortcutField"
    }

    public enum HotkeyCollision {
        public static let doesCollideSelector = "doesCollideWithExistingShortcuts"
        public static let canAllowShortcutSelector = "shortcutField:canAllowShortcut:"
        public static let emptyShortcutSelector = "emptyShortcut"
        public static let allowedCharacterKeycodeSelector = "isAllowedCharacterKeycode:"
        public static let allowedShortcutCharacterKeycodeSelector = "isAllowedShortcutCharacterKeycode:"
    }

    public enum SearchShortcuts {
        public static let processSelectedTextWithYandexSelector = "processSelectedTextWithYandex"
        public static let findInYandexSelector = "findInYandex"
        public static let searchInYandexShortcutKey = "searchInYandexShortcut"
        public static let yandexSearchTemplate = "http://yandex.ru/yandsearch?text=%@&clid=141986&yasoft=puntomac"
        public static let yandexSearchParameterizedTemplate = "http://yandex.ru/yandsearch?text=%@&clid=%d"
        public static let yandexTranslateParameterizedTemplate = "http://translate.yandex.ru/?text=%@&clid=%d"
        public static let yandexClid = "141986"
        public static let yandexSoft = "puntomac"
    }

    public enum InputSources {
        public static let undefinedSourceID = "UNDEFINED"
        public static let inputSourceEnabledSelector = "inputSourceEnabled:"
        public static let handleInputSourcesEnabledSelector = "handleInputSourcesEnabled"
        public static let promptUserToInstallLayoutsSelector = "promptUserToInstallLayouts"
        public static let failedToEnableLayoutLogFormat = "Failed to enable layout %@! Error code: %d"
    }

    public enum KeyboardLayoutVariant {
        public static let isAppleLayoutSelector = "isAppleLayout"
        public static let isDvorakSelector = "isDvorak"
        public static let windowsLayoutUsedSelector = "windowsLayoutUsed"
        public static let fixStringSelector = "fixString:isEnglish:isApple:"
        public static let createMacToPcMappingSelector = "createMacToPcMappingWithString:pcLayoutA:pcLayoutB:"
        public static let convertStringLayoutSelector = "convertStringLayout:withMode:isPCLayout:"
    }

    public enum ProductStatistics {
        public static let dayuseSettingsKey = "PSDayuseSettings"
        public static let dayuseTypedWordsKey = "TypedWords"
        public static let dayuseTypedSymbolsKey = "TypedSymbols"
        public static let dayuseAutoSwitchesKey = "AutoSwitches"
        public static let dayuseManualSwitchesKey = "ManualSwitches"
        public static let dayuseRevertsKey = "Reverts"
        public static let dayuseLastDayuseDateKey = "LastDayuseDate"
        public static let dayuseLastProductStatDateKey = "LastProductStatDate"
        public static let dayuseStatClassName = "PSDayuseStat"
        public static let setDayuseSelector = "setDayuse:"
        public static let typedWordsAccessor = "typedWords"
        public static let typedSymbolsAccessor = "typedSymbols"
        public static let automaticSwitchesAccessor = "automaticSwitches"
        public static let manualSwitchesAccessor = "manualSwitches"
        public static let revertsAccessor = "reverts"
        public static let lastDayuseDateAccessor = "lastDayuseDate"
        public static let lastProductStatDateAccessor = "lastProductStatDate"
        public static let setTypedWordsSelector = "setTypedWords:"
        public static let setTypedSymbolsSelector = "setTypedSymbols:"
        public static let setAutomaticSwitchesSelector = "setAutomaticSwitches:"
        public static let setManualSwitchesSelector = "setManualSwitches:"
        public static let setRevertsSelector = "setReverts:"
        public static let setLastDayuseDateSelector = "setLastDayuseDate:"
        public static let setLastProductStatDateSelector = "setLastProductStatDate:"
        public static let typedSymbolMetricName = "product.typed.symbol"
        public static let typedWordMetricName = "product.typed.word"
        public static let automaticSwitchMetricName = "product.switch.auto"
        public static let manualSwitchMetricName = "product.switch.manual"
        public static let revertMetricName = "product.switch.reverse"
    }

    public enum SearchClick {
        public static let canDoSearchClickSelector = "canDoSearchClick"
        public static let showSearchWindowAutomaticallySelector = "showSearchWindowAutomatically"
        public static let showSearchWindowSelectedTextSelector = "showSearchWindowSelectedText"
        public static let setIsClickSearchSelector = "setIsClickSearch:"
    }

    public enum SearchbarSettings {
        public static let settingsKey = "PSSearchbarSettings"
        public static let activationShortcutKey = "ActivationShortcut"
        public static let autoactivationKey = "Autoactivation"
        public static let autoactivationExceptionsKey = "AutoactivationExceptions"
        public static let alertShownInKey = "AlertShownIn"
        public static let shouldSearchByDoubleClickKey = "ShouldSearchByDoubleClick"
        public static let sitesearchPromptCounterKey = "SitesearchPromptCounter"
    }

    public enum SecureInputDiagnostics {
        public static let plistFilename = "punto.SecureInput.plist"
        public static let secureInputStateKey = "SecureInputState"
        public static let contextKey = "Context"
        public static let currentAppKey = "currentApp"
        public static let runningAppsKey = "runningApps"
        public static let enabledLayoutsKey = "enabledLayouts"
    }

    public enum Settings {
        public static let setEnabledSelector = "setEnabled:"
        public static let setShowAdvancedSettingsSelector = "setShowAdvancedSettings:"
        public static let setLaunchesOnStartupSelector = "setLaunchesOnStartup:"
        public static let setSwitchLanguageWhenChangingSelectionLayoutSelector = "setSwitchLanguageWhenChangingSelectionLayout:"
        public static let setIsManualConversionDisabledSelector = "setIsManualConversionDisabled:"
        public static let setDisabledApplicationsSelector = "setDisabledApplications:"
        public static let disabledAppsPreferencesControllerKey = "disabledAppsPreferencesController"
        public static let setDisabledAppsPreferencesControllerSelector = "setDisabledAppsPreferencesController:"
        public static let setDontAutoconvertWithEnterOrTabSelector = "setDontAutoconvertWithEnterOrTab:"
        public static let dontAutoconvertWordAfterConvertionSelector = "dontAutoconvertWordAfterConvertion:"
    }

    public enum ApplicationUpdateSettings {
        public static let configVersionKey = "configVersion"
        public static let isFirstInstallationKey = "isFirstInstallation"
        public static let isJustInstalledKey = "isJustInstalled"
        public static let isJustUpdatedKey = "isJustUpdated"
        public static let isUpdatingKey = "isUpdating"
        public static let shouldCheckForUpdatesAutomaticallyKey = "shouldCheckForUpdatesAutomatically"
        public static let updateRequestRateInDaysKey = "updateRequestRateInDays"
        public static let lastStatisticsRequestDateKey = "lastStatisticsRequestDate"
        public static let lastUpdateRequestDateKey = "lastUpdateRequestDate"
        public static let lastUpdateShownDateKey = "lastUpdateShownDate"
        public static let defaultConfigVersion = 8
        public static let initialDateUnixTimestamp: Double = 1_230_757_200
    }

    public enum SoundFeedback {
        public static let skipNextLanguageChangeSoundSelector = "shouldSkipNextLanguageChangeSound"
        public static let isSoundOnKey = "isSoundOn"
        public static let enabledSoundsKey = "enabledSounds"
        public static let useSoundLayoutSwitchToRussianKey = "useSoundLayoutSwitchToRussian"
        public static let useSoundLayoutSwitchToEnglishKey = "useSoundLayoutSwitchToEnglish"
        public static let useSoundConvertationKey = "useSoundConvertation"
        public static let useSoundMisprintKey = "useSoundMisprint"
        public static let useSoundAutocorrectionKey = "useSoundAutocorrection"
        public static let useSoundUndoKey = "useSoundUndo"
        public static let useSoundKeystrokesKey = "useSoundKeystrokes"
        public static let setSoundStateSelector = "setSoundState:isSoundOn:"
        public static let resourceNames = [
            "replace",
            "reverse",
            "misprint",
            "switch",
            "en",
            "ru",
            "typeeng",
            "typerus"
        ]
    }

    public enum StartupPresentation {
        public static let installArgument = "--install"
        public static let handleInstallArgumentSelector = "handleInstallArgument"
        public static let openWindowAfterInstallerSelector = "openWindowAfterInstaller"
        public static let showInstallationFinishedTooltipSelector = "showInstallationFinishedTooltip"
        public static let showUpdateFinishedTooltipSelector = "showUpdateFinishedTooltip"
        public static let installedTooltipKey = "tooltip-app-installed"
        public static let shouldDisplayWelcomeSelector = "shouldDisplayWelcome"
        public static let welcomeLogMessage = "Displaying welcome screen..."
        public static let accessibilityEnabledLogMessage = "Accessibility API enabled. Initializing services."
        public static let accessibilityDisabledLogMessage = "Accessibility API disabled. Showing accessibility preference window."
    }

    public enum AutoCorrectionRuleSource {
        public static let useOldRulesDefaultConfPath = "switcher.use_old_rules"
        public static let useOldRulesAccessor = "switcherUseOldRules"
    }

    public enum StatusIcon {
        public static let updateMenubarIconSelector = "updateMenubarIcon:"
        public static let resourceNames = [
            "icon_active",
            "icon_inactive",
            "icon_disabled",
            "icon_active_w",
            "icon_inactive_w",
            "icon_disabled_w"
        ]
    }

    public enum SystemApplications {
        public static let screenSaverEngineBundleID = "com.apple.screensaver.engine"
    }

    public enum UndoLearning {
        public static let settingsKey = "undoLearning"
        public static let undoCollectionEnabledKey = "undoCollectionEnabled"
        public static let mustShowUndoWindowKey = "mustShowUndoWindow"
        public static let undoDictionaryKey = "undoDictionary"
        public static let setUndoCollectionEnabledSelector = "setUndoCollectionEnabled:"
        public static let setMustShowUndoWindowSelector = "setMustShowUndoWindow:"
        public static let setUndoDictionarySelector = "setUndoDictionary:"
        public static let undoWindowControllerClassName = "UndoWindowController"
        public static let undoWindowDelegateProtocolName = "UndoWindowDelegate"
        public static let undoWindowResourceName = "UndoWindow"
        public static let undoAlertFormatKey = "PMUserRuleUndoAlertFormat"
        public static let showUndoLearningWindowCheckboxChangedSelector = "showUndoLearningWindowCheckboxChanged:"
        public static let undoLearningCheckboxChangedSelector = "undoLearningCheckboxChanged:"
        public static let undoLearningCheckboxKey = "undoLearningCheckbox"
        public static let showUndoLearningWindowCheckboxKey = "showUndoLearningWindowCheckbox"
        public static let undoTriesKey = "undoTries"
        public static let undoPersistsKey = "undoPersists"
        public static let undoWasDoneKey = "undoWasDone"
        public static let undoConvertionSelector = "undoConvertion"
        public static let resetUndoBufferSelector = "resetUndoBuffer"
    }

    public enum UserRules {
        public static let createUserRuleSelector = "createUserRule"
        public static let modifyUserRuleSelector = "modifyUserRule"
        public static let removeUserRuleWithIndexSelector = "removeUserRuleWithIndex:"
        public static let addUserRuleSelector = "addUserRuleWithString:rule:shouldSwitchLayout:isRuleActive:isRegExp:"
        public static let modifyUserRuleWithIndexSelector = "modifyUserRuleWithIndex:string:rule:shouldSwitchLayout:isRuleActive:isRegExp:"
        public static let showWordAddedTooltipSelector = "showWordAddedTooltip:"
    }
}
