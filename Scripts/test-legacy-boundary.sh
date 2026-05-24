#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

echo "Legacy boundary audit"

removed_symbols=(
    "LegacyHotkeyPolicy.dictionary"
    "LegacyUserRulePolicy.dictionaries"
    "SearchbarSettingsPolicy.dictionary"
    "SettingsPersistencePolicy.undoLearningDictionary"
    "ProductStatisticsPolicy.dayuseSettings("
    "SoundFeedbackPolicy.legacyBitmask(fromEnabledResourceNames"
    "SoundFeedbackPolicy.legacyToggleValues(fromEnabledResourceNames"
    "UndoLearningSettingsPolicy.dictionary"
    "ApplicationUpdateSettingsPolicy.dictionary"
)

for symbol in "${removed_symbols[@]}"; do
    if rg --fixed-strings --quiet "$symbol" Sources Tests; then
        echo "legacy boundary failed: removed export helper still referenced: $symbol" >&2
        exit 1
    fi
    echo "PASS removed helper absent: $symbol"
done

debug_inline_core_symbols=(
    "final class LayoutConverter"
    "final class WordTracker"
    "private let enToRu:"
    "private let wordBoundaries:"
)

for symbol in "${debug_inline_core_symbols[@]}"; do
    if rg --fixed-strings --quiet "$symbol" Scripts/debug.sh; then
        echo "legacy boundary failed: debug script contains inline duplicate core implementation: $symbol" >&2
        exit 1
    fi
    echo "PASS debug inline duplicate absent: $symbol"
done

layout_detection_duplicate_files=(
    Sources/PuntoCore/LayoutConverter.swift
    Sources/PuntoCore/WordTracker.swift
)
layout_detection_duplicate_patterns=(
    "private func isEnglishLetter"
    "private func isRussianLetter"
    "var englishCount"
    "var russianCount"
)

for pattern in "${layout_detection_duplicate_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" "${layout_detection_duplicate_files[@]}"; then
        echo "legacy boundary failed: layout detection reopened outside LayoutDetectionPolicy: $pattern" >&2
        exit 1
    fi
    echo "PASS layout detection duplicate absent: $pattern"
done

text_accessor_transport_patterns=(
    "CGEvent(keyboardEventSource:"
    "simulatePaste"
    "selectBackwardsFast"
    "NSWorkspace.shared.frontmostApplication"
)

for pattern in "${text_accessor_transport_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoRuntime/TextAccessor.swift; then
        echo "legacy boundary failed: TextAccessor reopened low-level keyboard transport: $pattern" >&2
        exit 1
    fi
    echo "PASS TextAccessor low-level keyboard transport absent: $pattern"
done

text_accessor_ax_client_patterns=(
    "kAXFocusedApplicationAttribute"
    "AXEnhancedUserInterface"
    "elementOrDescendantIsPasswordField"
    "rolesFromElementToAncestors"
)

for pattern in "${text_accessor_ax_client_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoRuntime/TextAccessor.swift; then
        echo "legacy boundary failed: TextAccessor reopened live AX focus/client plumbing: $pattern" >&2
        exit 1
    fi
    echo "PASS TextAccessor live AX client plumbing absent: $pattern"
done

text_accessor_clipboard_transport_patterns=(
    "NSPasteboard"
    "PasteboardSnapshot"
    "restorePasteboardIfEnabled"
    "pasteboard.clearContents"
    "pasteboard.setString"
)

for pattern in "${text_accessor_clipboard_transport_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoRuntime/TextAccessor.swift; then
        echo "legacy boundary failed: TextAccessor reopened pasteboard transport: $pattern" >&2
        exit 1
    fi
    echo "PASS TextAccessor pasteboard transport absent: $pattern"
done

text_accessor_ax_selection_transport_patterns=(
    "AXUIElementSetAttributeValue"
    "kAXSelectedTextAttribute"
    "kAXSelectedTextRangeAttribute"
    "AXValueCreate"
    "AccessibilitySelectionSearchPolicy"
    "lastEditableSelectionElement"
    "TextCapturePolicy."
    "TextReplacementPolicy."
    "replaceSelection(with:"
    "pasteSelectedText("
    "clearCachedEditableElement"
)

for pattern in "${text_accessor_ax_selection_transport_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoRuntime/TextAccessor.swift; then
        echo "legacy boundary failed: TextAccessor reopened AX selected-text transport: $pattern" >&2
        exit 1
    fi
    echo "PASS TextAccessor AX selected-text transport absent: $pattern"
done

text_accessor_runtime_graph_patterns=(
    "KeyboardEventTransport("
    "AccessibilityElementClient("
    "AccessibilityTextSelectionTransport("
    "ClipboardTransport("
    "TextCaptureRuntime("
    "KeyboardTextReplacementRuntime("
    "TextReplacementRuntime("
)

for pattern in "${text_accessor_runtime_graph_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoRuntime/TextAccessor.swift; then
        echo "legacy boundary failed: TextAccessor reopened text runtime dependency graph: $pattern" >&2
        exit 1
    fi
    echo "PASS TextAccessor runtime dependency graph absent: $pattern"
done

app_target_live_transport_patterns=(
    "AXUIElementCopyAttributeValue"
    "AXUIElementSetAttributeValue"
    "AXObserverCreate"
    "NSPasteboard.general"
    "CGEvent(keyboardEventSource:"
    "TISSelectInputSource"
    "TISCreateInputSourceList"
)

for pattern in "${app_target_live_transport_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App Sources/Punto/UI Sources/Punto/main.swift; then
        echo "legacy boundary failed: app shell reopened live transport instead of PuntoRuntime: $pattern" >&2
        exit 1
    fi
    echo "PASS app shell live transport absent: $pattern"
done

if rg -n "PuntoSwitcherObservedSurface" Sources/Punto/App Sources/Punto/UI Sources/Punto/main.swift; then
    echo "legacy boundary failed: app shell depends directly on reverse-audit-only observed surface" >&2
    exit 1
fi
echo "PASS app shell has no direct reverse-audit-only observed surface dependency"

core_live_transport_patterns=(
    "import AppKit"
    "import Cocoa"
    "NSPasteboard"
    "AXUIElement"
    "CGEvent(keyboardEventSource:"
    "TISSelectInputSource"
    "TISCreateInputSourceList"
)

for pattern in "${core_live_transport_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoCore; then
        echo "legacy boundary failed: PuntoCore reopened live macOS transport: $pattern" >&2
        exit 1
    fi
    echo "PASS PuntoCore live macOS transport absent: $pattern"
done

runtime_owned_key_policy_files=(
    Sources/PuntoCore/ApplicationDisablePolicy.swift
    Sources/PuntoCore/ApplicationLayoutPolicy.swift
    Sources/PuntoCore/ApplicationReturnKeyPolicy.swift
    Sources/PuntoCore/AutoCorrectionCancellingKeyPolicy.swift
    Sources/PuntoCore/LoginItemPolicy.swift
    Sources/PuntoCore/InputSourceSelectionPolicy.swift
    Sources/PuntoCore/KeyboardLayoutTypePolicy.swift
    Sources/PuntoCore/ProductStatisticsPolicy.swift
    Sources/PuntoCore/SettingsPersistencePolicy.swift
    Sources/PuntoCore/SoundFeedbackPolicy.swift
    Sources/PuntoCore/ClipboardReplacementPolicy.swift
)

if rg -n "observed[A-Za-z0-9]*Key" "${runtime_owned_key_policy_files[@]}"; then
    echo "legacy boundary failed: runtime-owned setting/import key constants use reverse-audit observed naming" >&2
    exit 1
fi
echo "PASS runtime-owned setting/import key constants are named by native-vs-legacy role"

settings_persistence_role_specific_patterns=(
    "legacyDisabledAppsKey"
    "legacyCompletelyDisableInExceptionApplicationsKey"
    "legacyShouldRememberInputSourceForEachAppKey"
    "legacyAutoCorrectionCancellingKeysBitmaskKey"
    "legacyRussianKeyboardLayoutTypeKey"
    "legacyEnglishInputSourceIDKey"
    "legacyRussianInputSourceIDKey"
    "legacyLaunchesOnStartupKey"
    "legacySwitchLayoutOnSelectedTextSwitchKey"
    "legacyIsManualConversionDisabledKey"
    "legacyIsAutocorrectionActiveKey"
    "legacyShouldNotAutoconvertWithTabOrEnterKey"
    "legacyShouldNotAutoconvertAfterConvertionKey"
    "defaultLaunchAtLogin"
    "defaultSwitchLayoutAfterConversion"
    "defaultSwitchLayoutAfterSelectedTextConversion"
    "defaultManualConversionDisabled"
    "defaultAutoCorrectionEnabled"
    "defaultAutoCorrectOnEnterAndTab"
    "defaultSuppressAutoCorrectionAfterManualConversion"
    "defaultRememberInputSourceForEachApp"
    "defaultRememberedApplicationLayouts"
    "defaultDisabledApplicationBundleIDs"
    "defaultDisabledBundleIDs"
    "defaultCompletelyDisableInExceptionApplications"
    "defaultAutoCorrectionStarterRulesEnabled"
    "defaultStarterRulesEnabled"
    "defaultAutoCorrectionUndoLearningEnabled"
    "defaultUndoLearningEnabled"
    "defaultAutoCorrectionCancellingKeyNames"
    "defaultEnabledKeyNameList"
    "defaultSoundEffectsEnabled"
    "defaultRestorePasteboardAfterConversion"
    "defaultIsFirstLaunch"
    "defaultRussianKeyboardLayoutType"
    "defaultProductStatistics"
    "normalizedProductStatistics"
    "legacyUndoCollectionEnabled"
    "normalizedDisabledApplicationBundleIDs"
    "effectiveDisabledApplicationBundleIDs"
    "normalizedResetOnReturnBundleComponents"
    "effectiveResetOnReturnBundleComponents"
    "normalizedAutoCorrectionCancellingKeyNames"
    "legacyAutoCorrectionCancellingKeyNames"
    "effectiveAutoCorrectionCancellingKeyNames"
    "normalizedRussianKeyboardLayoutType"
    "effectiveRussianKeyboardLayoutType"
    "normalizedInputSourceID"
    "effectiveInputSourceID"
    "normalizedRememberedApplicationLayouts"
)

for pattern in "${settings_persistence_role_specific_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoCore/SettingsPersistencePolicy.swift; then
        echo "legacy boundary failed: SettingsPersistencePolicy owns role-specific import behavior: $pattern" >&2
        exit 1
    fi
    echo "PASS SettingsPersistencePolicy role-specific behavior absent: $pattern"
done

settings_import_alias_patterns=(
    "\\bKeys\\.isFirstInstallation"
    "\\bKeys\\.launchesOnStartup"
    "\\bKeys\\.shortcutChangeLayout"
    "\\bKeys\\.shortcutChangeCase"
    "\\bKeys\\.shortcutSwitchAutocorrection"
    "\\bKeys\\.shortcutCancelLayoutChange"
    "\\bKeys\\.shortcutFindInYandex"
    "\\bKeys\\.shortcutFindInSlovari"
    "\\bKeys\\.searchbarSettings"
    "\\bKeys\\.switchLayoutOnSelectedTextSwitch"
    "\\bKeys\\.isManualConversionDisabled"
    "\\bKeys\\.kbdLayoutType"
    "\\bKeys\\.englishLayoutID"
    "\\bKeys\\.russianLayoutID"
    "\\bKeys\\.shouldRememberInputSourceForEachApp"
    "\\bKeys\\.disabledApps"
    "\\bKeys\\.completelyDisableInExceptionApps"
    "\\bKeys\\.switcherResetOnReturn"
    "\\bKeys\\.isAutocorrectionActive"
    "\\bKeys\\.switcherUseOldRulesDefaultConf"
    "\\bKeys\\.switcherUseOldRulesAccessor"
    "\\bKeys\\.shouldNotAutoconvertWithTabOrEnter"
    "\\bKeys\\.undoLearning"
    "\\bKeys\\.shouldNotAutoconvertAfterConvertion"
    "\\bKeys\\.cancellingKeys"
    "\\bKeys\\.userRulesDictionary"
    "\\bKeys\\.isSoundOn"
    "\\bKeys\\.enabledSounds"
    "\\bKeys\\.shouldRestorePasteboard"
    "\\bKeys\\.typedWords"
    "\\bKeys\\.typedSymbols"
    "\\bKeys\\.automaticSwitches"
    "\\bKeys\\.manualSwitches"
    "\\bKeys\\.reverts"
    "\\bKeys\\.dayuseSettings"
    "\\bKeys\\.configVersion"
    "\\bKeys\\.isJustInstalled"
    "\\bKeys\\.isJustUpdated"
    "\\bKeys\\.isUpdating"
    "\\bKeys\\.shouldCheckForUpdatesAutomatically"
    "\\bKeys\\.updateRequestRateInDays"
    "\\bKeys\\.lastStatisticsRequestDate"
    "\\bKeys\\.lastUpdateRequestDate"
    "\\bKeys\\.lastUpdateShownDate"
)

for pattern in "${settings_import_alias_patterns[@]}"; do
    if rg --quiet "$pattern" Sources/PuntoSettings/SettingsManager.swift; then
        echo "legacy boundary failed: SettingsManager routine key namespace contains import alias: $pattern" >&2
        exit 1
    fi
    echo "PASS SettingsManager import alias separated: $pattern"
done

settings_manager_inline_import_keys=(
    '"isFirstInstallation"'
    '"kbdLayoutType"'
    '"englishLayoutID"'
    '"russianLayoutID"'
    '"switcher.reset_on_return"'
    '"shouldNotAutoconvertWithTabOrEnter"'
    '"cancellingKeys"'
    '"typedWords"'
    '"typedSymbols"'
    '"automaticSwitches"'
    '"manualSwitches"'
    '"reverts"'
)

for pattern in "${settings_manager_inline_import_keys[@]}"; do
    if rg --fixed-strings --quiet "static let " Sources/PuntoSettings/SettingsManager.swift &&
        rg --fixed-strings --quiet "$pattern" Sources/PuntoSettings/SettingsManager.swift; then
        echo "legacy boundary failed: SettingsManager.ImportKeys keeps owned import key inline: $pattern" >&2
        exit 1
    fi
    echo "PASS SettingsManager imports owned key constant instead of inline string: $pattern"
done

settings_import_writes="$(rg "(defaults|store)\\.(set|removeObject)\\([^\\n]*forKey: ImportKeys\\." Sources/PuntoSettings/SettingsManager.swift || true)"
unexpected_import_writes="$(printf '%s\n' "$settings_import_writes" | rg -v --fixed-strings "ImportKeys.isFirstInstallation" | rg -v --fixed-strings "ImportKeys.isJustInstalled" | rg -v --fixed-strings "ImportKeys.isJustUpdated" | rg -v --fixed-strings "ImportKeys.isUpdating" || true)"
if [[ -n "$unexpected_import_writes" ]]; then
    echo "legacy boundary failed: routine write to import-only key:" >&2
    printf '%s\n' "$unexpected_import_writes" >&2
    exit 1
fi
echo "PASS SettingsManager import-only writes limited to first-run/update consumption"

settings_manager_direct_storage_patterns=(
    "UserDefaults."
    "UserDefaults("
    "JSONEncoder"
    "JSONDecoder"
    "persistentDomain"
    "defaults."
)

for pattern in "${settings_manager_direct_storage_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoSettings/SettingsManager.swift; then
        echo "legacy boundary failed: SettingsManager reopened direct storage access: $pattern" >&2
        exit 1
    fi
    echo "PASS SettingsManager direct storage absent: $pattern"
done

settings_manager_direct_resolution_patterns=(
    "SettingsPersistencePolicy.effectiveBool("
    "SettingsPersistencePolicy.effectiveBoolWithLegacyAlias"
    "SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias"
    "SearchbarSettingsPolicy.effectiveShouldSearchByDoubleClick"
    "SearchbarSettingsPolicy.snapshot(from:"
    "SoundFeedbackPolicy.enabledResourceNames("
    "ProductStatisticsPolicy.snapshotFromLegacySources"
    "ProductStatisticsPolicy.effectiveSnapshot"
    "ApplicationUpdateSettingsPolicy.snapshot(from:"
    "LegacyUserRulePolicy.rules(from:"
    "AutoCorrectionRuleSourcePolicy.effectiveRules("
    "private func persistedBool"
    "private func persistedInt"
    "private func persistedHotkey"
    "private func hasStoredValue"
    "SettingsHotkeySlotRegistry.descriptor("
    "SettingsBoolSlotRegistry.descriptor("
    "HotkeyValidationPolicy.normalized("
    "HotkeyCommandPolicy.defaultHotkey("
    "SettingsBoolSlotRegistry.nativeDefaultValues"
    "ApplicationLayoutMemory.normalizedSnapshot("
    "ApplicationDisablePolicy.normalizedSet("
    "ApplicationDisablePolicy.disabledBundleIDsAfterSet("
    "ApplicationReturnKeyPolicy.normalizedResetBundleComponents("
    "InputSourceSelectionPolicy.normalizedSourceID("
    "NotificationCenter.default.post"
)

for pattern in "${settings_manager_direct_resolution_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoSettings/SettingsManager.swift; then
        echo "legacy boundary failed: SettingsManager reopened direct native/import resolution: $pattern" >&2
        exit 1
    fi
    echo "PASS SettingsManager direct native/import resolution absent: $pattern"
done

settings_manager_boolean_slot_cases=(
    "case .launchAtLogin:"
    "case .showInMenuBar:"
    "case .switchLayoutAfterConversion:"
    "case .autoCorrectionEnabled:"
    "case .soundEffectsEnabled:"
    "case .showAdvancedSettings:"
    "case .switchLayoutAfterSelectedTextConversion:"
    "case .searchSelectedTextByDoubleClick:"
    "case .manualConversionDisabled:"
    "case .rememberInputSourceForEachApp:"
    "case .autoCorrectOnEnterAndTab:"
    "case .autoCorrectionUndoLearningEnabled:"
    "case .suppressAutoCorrectionAfterManualConversion:"
    "case .completelyDisableInExceptionApplications:"
)

for pattern in "${settings_manager_boolean_slot_cases[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoSettings/SettingsManager.swift; then
        echo "legacy boundary failed: SettingsManager reopened boolean toggle slot switch: $pattern" >&2
        exit 1
    fi
    echo "PASS SettingsManager boolean toggle slot switch absent: $pattern"
done

settings_manager_hotkey_slot_cases=(
    "case .convertLayout:"
    "case .toggleCase:"
    "case .toggleAutoCorrection:"
    "case .cancelLayoutChange:"
    "case .findInYandex:"
    "case .findInSlovari:"
)

for pattern in "${settings_manager_hotkey_slot_cases[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoSettings/SettingsManager.swift; then
        echo "legacy boundary failed: SettingsManager reopened hotkey slot switch: $pattern" >&2
        exit 1
    fi
    echo "PASS SettingsManager hotkey slot switch absent: $pattern"
done

settings_manager_inline_boolean_defaults=(
    "SettingsStorageKeys.showInMenuBar:"
    "SettingsStorageKeys.showAdvancedSettings:"
    "SettingsStorageKeys.launchAtLogin:"
    "SettingsStorageKeys.switchLayoutAfterConversion:"
    "SettingsStorageKeys.switchLayoutAfterSelectedTextConversion:"
    "SettingsStorageKeys.manualConversionDisabled:"
    "SettingsStorageKeys.rememberInputSourceForEachApp:"
    "SettingsStorageKeys.completelyDisableInExceptionApplications:"
    "SettingsStorageKeys.autoCorrectionEnabled:"
    "SettingsStorageKeys.autoCorrectOnEnterAndTab:"
    "SettingsStorageKeys.autoCorrectionUndoLearningEnabled:"
    "SettingsStorageKeys.suppressAutoCorrectionAfterManualConversion:"
    "SettingsStorageKeys.soundEffectsEnabled:"
    "SettingsStorageKeys.restorePasteboardAfterConversion:"
)

for pattern in "${settings_manager_inline_boolean_defaults[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoSettings/SettingsManager.swift; then
        echo "legacy boundary failed: SettingsManager reopened inline boolean default registration: $pattern" >&2
        exit 1
    fi
    echo "PASS SettingsManager inline boolean default registration absent: $pattern"
done

if rg --fixed-strings --quiet "ServiceManagement" Sources/PuntoSettings; then
    echo "legacy boundary failed: settings module reopened live login-item side effects" >&2
    exit 1
fi
echo "PASS settings module live login-item side effects absent"

app_delegate_runtime_state_patterns=(
    "private let conversionSession = ConversionSession()"
    "private var isConversionInProgress ="
    "private var ignoreInputSourceChangesUntil: Date?  //"
    "private var ignoreAccessibilityNotificationsUntil: Date?  //"
    "private var lastKeyPressTime: Date?  //"
)

for pattern in "${app_delegate_runtime_state_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/AppDelegate.swift; then
        echo "legacy boundary failed: AppDelegate reopened mutable text runtime state: $pattern" >&2
        exit 1
    fi
    echo "PASS AppDelegate mutable text runtime state absent: $pattern"
done

app_delegate_application_runtime_patterns=(
    "TextAccessor("
    "InputSourceManager("
    "HotkeyManager("
    "TextActionRuntimeCoordinator("
    "ManualTextActionRuntimeCoordinator("
    "AutoCorrectionRuntimeCoordinator("
    "UndoRuntimeCoordinator("
    "ApplicationCommandRuntimeCoordinator("
    "KeyPressRuntimeCoordinator("
    "AccessibilityStateObserver {"
    "ApplicationLayoutMemory()"
    "ApplicationContextPolicy.activationAction"
    "ApplicationLayoutPolicy.restoreActionOnActivation"
    "ApplicationLayoutPolicy.layoutMemoryUpdateAfterObservedInputSourceChange"
    "ApplicationLayoutPolicy.layoutMemoryUpdateAfterProgrammaticSwitch"
    "InputSourceChangePolicy.action("
    "InputSourceChangePolicy.preferencesChangeAction"
)

for pattern in "${app_delegate_application_runtime_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/AppDelegate.swift; then
        echo "legacy boundary failed: AppDelegate reopened application runtime coordination: $pattern" >&2
        exit 1
    fi
    echo "PASS AppDelegate application runtime coordination absent: $pattern"
done

hotkey_manager_policy_patterns=(
    "ModifierOnlyHotkeyStateMachine("
    "PointerEventPolicy.action("
    "SearchClickPolicy.shouldScheduleSelectedTextSearchAfterClick"
    "KeyDownEventPolicy.action("
    "HotkeyRoutingPolicy.action("
    "keyboardGetUnicodeString"
)

for pattern in "${hotkey_manager_policy_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/PuntoRuntime/HotkeyManager.swift; then
        echo "legacy boundary failed: HotkeyManager reopened hotkey routing internals: $pattern" >&2
        exit 1
    fi
    echo "PASS HotkeyManager hotkey routing internals absent: $pattern"
done

app_delegate_key_press_runtime_patterns=(
    "KeyTrackingRuntimePolicy."
    ".trackKeyPress("
    "recordProductStatisticsEvent(.typedText"
    "playTextInputSound(characters:"
)

for pattern in "${app_delegate_key_press_runtime_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/AppDelegate.swift; then
        echo "legacy boundary failed: AppDelegate reopened key-press runtime coordination: $pattern" >&2
        exit 1
    fi
    echo "PASS AppDelegate key-press runtime coordination absent: $pattern"
done

app_delegate_text_action_runtime_patterns=(
    "TextActionRuntimePreflightPolicy."
    "TextActionPreflightPolicy.logMessage"
    "LayoutSwitchRuntimePolicy.plan"
    "SoundFeedbackPolicy.eventAfterInputSourceSwitch"
    "SecureInputDiagnosticsPolicy.snapshot"
    "ReplacementFailurePolicy.actionAfterFailedReplacement"
    "UndoReplacementPolicy.actionAfterFailedReplacement"
    "TextCapturePolicy.actionAfterBlockedCapture"
)

for pattern in "${app_delegate_text_action_runtime_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/AppDelegate.swift; then
        echo "legacy boundary failed: AppDelegate reopened text-action runtime coordination: $pattern" >&2
        exit 1
    fi
    echo "PASS AppDelegate text-action runtime coordination absent: $pattern"
done

text_action_layout_switch_patterns=(
    "LayoutSwitchRuntimePolicy.plan"
    "KeyboardLayoutVariantPolicy.effectiveEnglishLayoutVariant"
    "SoundFeedbackPolicy.eventAfterInputSourceSwitch"
    "inputSourceManager.switchTo("
    "rememberProgrammaticLayoutSwitch("
)

for pattern in "${text_action_layout_switch_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/TextActionRuntimeCoordinator.swift; then
        echo "legacy boundary failed: TextActionRuntimeCoordinator reopened layout-switch runtime coordination: $pattern" >&2
        exit 1
    fi
    echo "PASS TextActionRuntimeCoordinator layout-switch runtime coordination absent: $pattern"
done

text_action_commit_runtime_patterns=(
    "replaceTrackedTail("
    "recordProductStatisticsEvent("
    "conversionSession.record("
    "soundFeedbackController.play("
    "settingsManager.autoCorrectionRules ="
)

for pattern in "${text_action_commit_runtime_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/TextActionRuntimeCoordinator.swift; then
        echo "legacy boundary failed: TextActionRuntimeCoordinator reopened text replacement commit coordination: $pattern" >&2
        exit 1
    fi
    echo "PASS TextActionRuntimeCoordinator text replacement commit coordination absent: $pattern"
done

app_delegate_auto_correction_runtime_patterns=(
    "AutoCorrectionEngine("
    "AutoCorrectionRuntimePolicy."
    "AutoCorrectionRuntimeAttemptPlan"
    "consumeCompletedToken()"
    "getTypedTailPreservingBoundaryWhitespace()"
    "replaceRecentText("
)

for pattern in "${app_delegate_auto_correction_runtime_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/AppDelegate.swift; then
        echo "legacy boundary failed: AppDelegate reopened auto-correction runtime coordination: $pattern" >&2
        exit 1
    fi
    echo "PASS AppDelegate auto-correction runtime coordination absent: $pattern"
done

app_delegate_undo_runtime_patterns=(
    "UndoRuntimePolicy."
    "undoCandidate("
    "clearStateAfterFailedUndoReplacement("
    "switchLayoutIfEnabled(layoutSwitchTarget, surface: .undo)"
    "record(commitPlan.conversionRecordCommit"
)

for pattern in "${app_delegate_undo_runtime_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/AppDelegate.swift; then
        echo "legacy boundary failed: AppDelegate reopened undo runtime coordination: $pattern" >&2
        exit 1
    fi
    echo "PASS AppDelegate undo runtime coordination absent: $pattern"
done

app_delegate_manual_text_action_patterns=(
    "ManualLayoutConversionPolicy."
    "ManualLayoutConversionRuntimePolicy."
    "ToggleCaseConversionPolicy."
    "replaceCapturedText("
    "getLastWord()"
    "getTypedTail()"
)

for pattern in "${app_delegate_manual_text_action_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/AppDelegate.swift; then
        echo "legacy boundary failed: AppDelegate reopened manual text-action runtime coordination: $pattern" >&2
        exit 1
    fi
    echo "PASS AppDelegate manual text-action runtime coordination absent: $pattern"
done

app_delegate_command_runtime_patterns=(
    "SelectedTextSearchPolicy."
    "AutoCorrectionTogglePolicy."
    "ApplicationDisablePolicy."
    "HotkeyRoutingPolicy.stateClearActionAfterEnabledChange"
    "NSWorkspace.shared.open(url)"
    "captureSelectedText(lastTrackedWord: nil"
    "textAccessor?.canDoSearchClick("
    "textAccessor.canDoSearchClick("
)

for pattern in "${app_delegate_command_runtime_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/AppDelegate.swift; then
        echo "legacy boundary failed: AppDelegate reopened command runtime coordination: $pattern" >&2
        exit 1
    fi
    echo "PASS AppDelegate command runtime coordination absent: $pattern"
done

app_delegate_startup_runtime_patterns=(
    "StartupPresentationPolicy."
    "AccessibilityPreferencesPolicy."
    "AXIsProcessTrusted"
    "permissionCheckTimer"
    "showPermissionAlert"
    "showOnboardingAlert"
    "openAccessibilitySettings"
)

for pattern in "${app_delegate_startup_runtime_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/AppDelegate.swift; then
        echo "legacy boundary failed: AppDelegate reopened startup/accessibility runtime coordination: $pattern" >&2
        exit 1
    fi
    echo "PASS AppDelegate startup/accessibility runtime coordination absent: $pattern"
done

app_delegate_accessibility_notification_patterns=(
    "AccessibilityNotificationPolicy."
    "ignoreAccessibilityNotificationsUntil"
    "accessibilityStateChanged("
)

for pattern in "${app_delegate_accessibility_notification_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/AppDelegate.swift; then
        echo "legacy boundary failed: AppDelegate reopened accessibility notification runtime coordination: $pattern" >&2
        exit 1
    fi
    echo "PASS AppDelegate accessibility notification runtime coordination absent: $pattern"
done

app_delegate_log_lifecycle_patterns=(
    "PuntoLog.clear()"
    "LogRetentionPolicy."
)

for pattern in "${app_delegate_log_lifecycle_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/App/AppDelegate.swift; then
        echo "legacy boundary failed: AppDelegate reopened log lifecycle internals: $pattern" >&2
        exit 1
    fi
    echo "PASS AppDelegate log lifecycle internals absent: $pattern"
done

settings_window_hotkey_patterns=(
    "HotkeyCollisionPolicy."
    "HotkeyValidationPolicy."
    "private func recordHotkey"
    "private func resetHotkey"
    "convertLayoutRecorder"
    "toggleCaseRecorder"
    "toggleAutoCorrectionRecorder"
    "cancelLayoutChangeRecorder"
    "findInYandexRecorder"
    "findInSlovariRecorder"
)

for pattern in "${settings_window_hotkey_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/UI/SettingsWindowController.swift; then
        echo "legacy boundary failed: SettingsWindowController reopened hotkey recorder internals: $pattern" >&2
        exit 1
    fi
    echo "PASS SettingsWindowController hotkey recorder internals absent: $pattern"
done

settings_window_general_patterns=(
    "private func createGeneralSection"
    "private func createToggleRow"
    "private func createSoundResourceTogglesGrid"
    "private func createCancellingKeyTogglesGrid"
    "private func createRussianKeyboardLayoutTypeRow"
    "private func createPreferredInputSourceIDRow"
    "toggleLaunchAtLogin"
    "toggleShowAdvancedSettings"
    "toggleAutoCorrectionCancellingKey"
    "toggleSoundResource"
    "advancedSettingsStack"
    "preferredEnglishInputSourceIDField"
    "preferredRussianInputSourceIDField"
)

for pattern in "${settings_window_general_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/UI/SettingsWindowController.swift; then
        echo "legacy boundary failed: SettingsWindowController reopened general setting row internals: $pattern" >&2
        exit 1
    fi
    echo "PASS SettingsWindowController general setting row internals absent: $pattern"
done

general_settings_row_factory_patterns=(
    "NSImageView()"
    "NSSwitch()"
    "NSSegmentedControl("
    "checkboxWithTitle:"
    "monospacedDigitSystemFont"
    "bezelStyle = .rounded"
)

for pattern in "${general_settings_row_factory_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" Sources/Punto/UI/GeneralSettingsController.swift; then
        echo "legacy boundary failed: GeneralSettingsController reopened settings row factory internals: $pattern" >&2
        exit 1
    fi
    echo "PASS GeneralSettingsController row factory internals absent: $pattern"
done

if rg --fixed-strings --quiet "Placeholder - actual tests" Tests 2>/dev/null; then
    echo "legacy boundary failed: placeholder SwiftPM test target returned" >&2
    exit 1
fi
echo "PASS placeholder SwiftPM tests absent"

if rg --fixed-strings --quiet "PuntoTest" \
    Package.swift \
    Scripts/test-cycle.sh \
    Scripts/test-background-loop.sh \
    Scripts/debug.sh; then
    echo "legacy boundary failed: retired PuntoTest target or script reference returned" >&2
    exit 1
fi
if [ -e Sources/PuntoTest ]; then
    echo "legacy boundary failed: retired Sources/PuntoTest directory returned" >&2
    exit 1
fi
echo "PASS retired PuntoTest target absent"

puntotest_copy_heavy_patterns=(
    "Repeated Undo Toggle State"
    "var undoOriginal"
    "var undoConverted"
    "TestPassiveClipboardTailPolicy"
    "runTextAccessStrategyTests"
    "TEXT ACCESS STRATEGY TESTS"
    "class TestWordTracker"
    "legacy test adapter"
    "trackKeyPress(character:"
    "runMultipleConversionTests"
    "MULTIPLE CONVERSION TESTS"
    "runRapidConversionTests"
    "RAPID CONVERSION SIMULATION TESTS"
    "runClipboardSimulationTests"
    "CLIPBOARD SIMULATION TESTS"
    "runHotkeyTests"
    "HOTKEY TESTS"
    "runShiftNumberTests"
    "SHIFT+NUMBER MAPPING TESTS"
    "runToggleCaseTests"
    "TOGGLE CASE TESTS"
    "private func toggleCase(_ text: String) -> String"
)

for pattern in "${puntotest_copy_heavy_patterns[@]}"; do
    if rg --fixed-strings --quiet "$pattern" \
        Sources \
        Package.swift \
        Scripts/debug.sh \
        Scripts/test-cycle.sh \
        Scripts/test-background-loop.sh; then
        echo "legacy boundary failed: copy-heavy legacy simulation returned: $pattern" >&2
        exit 1
    fi
    echo "PASS copy-heavy legacy simulation absent: $pattern"
done

/usr/bin/python3 - "$ROOT_DIR/Sources/PuntoSettings/SettingsManager.swift" <<'PY'
import re
import sys

path = sys.argv[1]

forbidden_legacy_write_keys = {
    "shortcutChangeLayout",
    "shortcutChangeCase",
    "shortcutSwitchAutocorrection",
    "shortcutCancelLayoutChange",
    "shortcutFindInYandex",
    "shortcutFindInSlovari",
    "searchbarSettings",
    "switchLayoutOnSelectedTextSwitch",
    "kbdLayoutType",
    "englishLayoutID",
    "russianLayoutID",
    "isManualConversionDisabled",
    "shouldRememberInputSourceForEachApp",
    "disabledApps",
    "completelyDisableInExceptionApps",
    "switcherResetOnReturn",
    "isAutocorrectionActive",
    "switcherUseOldRulesDefaultConf",
    "switcherUseOldRulesAccessor",
    "shouldNotAutoconvertWithTabOrEnter",
    "undoLearning",
    "shouldNotAutoconvertAfterConvertion",
    "cancellingKeys",
    "userRulesDictionary",
    "isSoundOn",
    "enabledSounds",
    "useSoundLayoutSwitchToRussian",
    "useSoundLayoutSwitchToEnglish",
    "useSoundConvertation",
    "useSoundMisprint",
    "useSoundAutocorrection",
    "useSoundUndo",
    "useSoundKeystrokes",
    "shouldRestorePasteboard",
    "typedWords",
    "typedSymbols",
    "automaticSwitches",
    "manualSwitches",
    "reverts",
    "dayuseSettings",
    "isFirstInstallation",
    "configVersion",
    "isJustInstalled",
    "isJustUpdated",
    "isUpdating",
    "shouldCheckForUpdatesAutomatically",
    "updateRequestRateInDays",
    "lastStatisticsRequestDate",
    "lastUpdateRequestDate",
    "lastUpdateShownDate",
}

with open(path, "r", encoding="utf-8") as handle:
    lines = handle.readlines()

violations = []
for index, line in enumerate(lines):
    if not any(pattern in line for pattern in ("defaults.set", "defaults.removeObject", "store.set", "store.removeObject")):
        continue

    call_lines = []
    depth = 0
    started = False
    for offset, call_line in enumerate(lines[index:], start=index + 1):
        call_lines.append(call_line.rstrip("\n"))
        depth += call_line.count("(") - call_line.count(")")
        if "(" in call_line:
            started = True
        if started and depth <= 0:
            break

    call = "\n".join(call_lines)
    allowed_one_shot_calls = {
        "isFirstInstallation": "consumeFirstLaunchPresentationFlags",
        "isJustInstalled": "consumeFirstLaunchPresentationFlags",
        "isJustUpdated": "consumeUpdatePresentationImportFlags",
        "isUpdating": "consumeUpdatePresentationImportFlags",
    }

    for key in sorted(forbidden_legacy_write_keys):
        if re.search(rf"\b(?:Keys|ImportKeys)\.{re.escape(key)}\b", call):
            allowed_method = allowed_one_shot_calls.get(key)
            if allowed_method:
                prefix = "".join(lines[max(0, index - 8):index + 1])
                if allowed_method in prefix:
                    continue
            violations.append((index + 1, key, call))

if violations:
    print("legacy boundary failed: SettingsManager writes native-owned legacy keys", file=sys.stderr)
    for line_number, key, call in violations:
        compact = " ".join(part.strip() for part in call.splitlines())
        print(f"{path}:{line_number}: writes Keys.{key}: {compact}", file=sys.stderr)
    sys.exit(1)

print("PASS SettingsManager has no native-owned legacy key writes")
PY

behavior_policy_observed_surface_files=(
    Sources/PuntoCore/AccessibilityPreferencesPolicy.swift \
    Sources/PuntoCore/AccessibilityRolePolicy.swift \
    Sources/PuntoCore/AutoCorrectionCancellingKeyPolicy.swift \
    Sources/PuntoCore/AutoCorrectionRuleSourcePolicy.swift \
    Sources/PuntoCore/ClipboardReplacementPolicy.swift \
    Sources/PuntoCore/Hotkey.swift \
    Sources/PuntoCore/HotkeyCollisionPolicy.swift \
    Sources/PuntoCore/InputSourceSelectionPolicy.swift \
    Sources/PuntoCore/KeyboardLayoutVariantPolicy.swift \
    Sources/PuntoCore/ProductStatisticsPolicy.swift \
    Sources/PuntoCore/SearchClickPolicy.swift \
    Sources/PuntoCore/SettingsPersistencePolicy.swift \
    Sources/PuntoCore/SoundFeedbackPolicy.swift \
    Sources/PuntoCore/StartupPresentationPolicy.swift \
    Sources/PuntoCore/StatusIconPolicy.swift \
    Sources/PuntoCore/UndoLearningSettingsPolicy.swift \
    Sources/PuntoCore/LegacyUserRulePolicy.swift
)

if rg -n "observed[A-Za-z0-9]*(Selector|ClassName|ProtocolName|ResourceName|FormatKey|Controller|Field|MetricName|Accessor|Checkbox|TooltipKey|Tries|Persists|WasDone|Name|Key)" \
    "${behavior_policy_observed_surface_files[@]}"; then
    echo "legacy boundary failed: reverse-audit-only observed surface leaked back into behavior policy" >&2
    exit 1
fi

runtime_owned_policy_files=(
    Sources/PuntoCore/AccessibilityPreferencesPolicy.swift \
    Sources/PuntoCore/ApplicationUpdateSettingsPolicy.swift \
    Sources/PuntoCore/InputSourceSelectionPolicy.swift \
    Sources/PuntoCore/SearchbarSettingsPolicy.swift \
    Sources/PuntoCore/StartupPresentationPolicy.swift
)

if rg -n "observed[A-Za-z0-9]*(Message|URLString|Anchor|PaneID|Legacy|SourceID)" \
    "${runtime_owned_policy_files[@]}"; then
    echo "legacy boundary failed: runtime-owned policy constants use reverse-audit observed naming" >&2
    exit 1
fi

runtime_accessibility_policy_files=(
    Sources/PuntoCore/AccessibilityApplicationPolicy.swift \
    Sources/PuntoCore/AccessibilityNotificationPolicy.swift \
    Sources/PuntoCore/AccessibilityRolePolicy.swift \
    Sources/PuntoCore/ApplicationBundleIDPolicy.swift \
    Sources/PuntoCore/SecureInputDiagnosticsPolicy.swift
)

if rg -n "observed[A-Za-z0-9]*(BundleID|Role|Roles|Notification|Notifications|Application|Applications|Plist|Filename|Token)" \
    "${runtime_accessibility_policy_files[@]}"; then
    echo "legacy boundary failed: runtime accessibility policy constants use reverse-audit observed naming" >&2
    exit 1
fi
echo "PASS runtime accessibility policy constants use native names"

legacy_import_key_name_files=(
    Sources/PuntoCore/ApplicationUpdateSettingsPolicy.swift
    Sources/PuntoCore/AutoCorrectionRuleSourcePolicy.swift
    Sources/PuntoCore/SearchbarSettingsPolicy.swift
)
legacy_import_key_generic_names=(
    "configVersionKey"
    "isFirstInstallationKey"
    "isJustInstalledKey"
    "isJustUpdatedKey"
    "isUpdatingKey"
    "shouldCheckForUpdatesAutomaticallyKey"
    "updateRequestRateInDaysKey"
    "lastStatisticsRequestDateKey"
    "lastUpdateRequestDateKey"
    "lastUpdateShownDateKey"
    "useOldRulesDefaultConfPath"
    "useOldRulesAccessor"
    "settingsKey"
    "activationShortcutKey"
    "autoactivationKey"
    "autoactivationExceptionsKey"
    "alertShownInKey"
    "shouldSearchByDoubleClickKey"
    "sitesearchPromptCounterKey"
)

for name in "${legacy_import_key_generic_names[@]}"; do
    if rg --quiet "\\bpublic static let ${name}\\b" "${legacy_import_key_name_files[@]}"; then
        echo "legacy boundary failed: import-only key lacks legacy prefix: $name" >&2
        exit 1
    fi
    echo "PASS import-only key uses legacy prefix: $name"
done

if rg -n "PuntoSwitcherObservedSurface" "${behavior_policy_observed_surface_files[@]}"; then
    echo "legacy boundary failed: behavior policy depends directly on reverse-audit-only observed surface" >&2
    exit 1
fi
echo "PASS reverse-audit-only observed surface stays outside selected behavior policies"

echo "Legacy boundary audit passed"
