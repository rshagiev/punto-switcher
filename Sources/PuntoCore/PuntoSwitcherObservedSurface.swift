public enum PuntoSwitcherObservedSurface {
    public enum AccessibilityPreferences {
        public static let launchAccessibilityPreferencesSelector = "launchAccessibilityPreferences"
        public static let openAccessibilityPrefPaneSelector = "openAccesibilityPrefPane:"
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

    public enum InputSources {
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
        public static let dayuseStatClassName = "PSDayuseStat"
        public static let setDayuseSelector = "setDayuse:"
        public static let typedWordsAccessor = "typedWords"
        public static let typedSymbolsAccessor = "typedSymbols"
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

    public enum SoundFeedback {
        public static let skipNextLanguageChangeSoundSelector = "shouldSkipNextLanguageChangeSound"
        public static let setSoundStateSelector = "setSoundState:isSoundOn:"
    }

    public enum StartupPresentation {
        public static let handleInstallArgumentSelector = "handleInstallArgument"
        public static let openWindowAfterInstallerSelector = "openWindowAfterInstaller"
        public static let showInstallationFinishedTooltipSelector = "showInstallationFinishedTooltip"
        public static let showUpdateFinishedTooltipSelector = "showUpdateFinishedTooltip"
        public static let installedTooltipKey = "tooltip-app-installed"
        public static let shouldDisplayWelcomeSelector = "shouldDisplayWelcome"
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

    public enum UndoLearning {
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
