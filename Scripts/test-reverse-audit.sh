#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUNTO_SWITCHER_APP="${PUNTO_SWITCHER_APP:-/Applications/PuntoSwitcher.app}"
RESOURCES_DIR="$PUNTO_SWITCHER_APP/Contents/Resources"
EXECUTABLE="$PUNTO_SWITCHER_APP/Contents/MacOS/PuntoSwitcher"
DEFAULT_CONF="$RESOURCES_DIR/default-conf.json"

cd "$ROOT_DIR"

if [[ ! -d "$PUNTO_SWITCHER_APP" ]]; then
    echo "reverse audit skipped: PuntoSwitcher.app not found at $PUNTO_SWITCHER_APP"
    exit 0
fi

if [[ ! -f "$DEFAULT_CONF" || ! -x "$EXECUTABLE" ]]; then
    echo "reverse audit failed: expected PuntoSwitcher executable and default-conf.json" >&2
    exit 1
fi

echo "Punto Switcher reverse audit: $PUNTO_SWITCHER_APP"

/usr/bin/python3 - "$DEFAULT_CONF" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as handle:
    data = json.load(handle)

root = data.get("*", {})
accessibility = root.get("accessibility", {})
search = root.get("search", {})
switcher = root.get("switcher", {})

expected_inject = [
    "com.apple.safari",
    "com.google.chrome",
    "org.chromium.chromium",
    "ru.yandex.desktop.yandex-browser",
    "com.operasoftware.Opera",
    "org.mozilla.firefox",
]
expected_eui = [
    "com.google.chrome",
    "com.operasoftware.Opera",
    "org.chromium.chromium",
    "org.mozilla.firefox",
    "ru.yandex.desktop.yandex-browser",
]
expected_searchbar_exceptions = {
    "*": ["AXTextField", "AXTextArea", "AXComboBox", "AXWindow", "AXUnknown", "AXStaticText", "AXPopUpButton", "AXApplication"],
    "com.adobe.acc.AdobeCreativeCloud": [],
    "com.apple.ActivityMonitor": [],
    "com.apple.Aperture": [],
    "com.apple.DiskImageMounter": [],
    "com.apple.FinalCut": [],
    "com.apple.Notes": [],
    "com.apple.Photos": [],
    "com.apple.Preview": [],
    "com.apple.RemoteDesktop": [],
    "com.apple.ScreenSharing": [],
    "com.apple.SystemProfiler": [],
    "com.apple.dock": [],
    "com.apple.dt.Xcode": ["AXGroup"],
    "com.apple.finder": ["AXList", "AXOutline", "AXGrid", "AXImage"],
    "com.apple.garageband10": [],
    "com.apple.iCal": [],
    "com.apple.iTunes": [],
    "com.apple.iWork.Keynote": [],
    "com.apple.iWork.Numbers": [],
    "com.apple.iWork.Pages": [],
    "com.apple.logic10": [],
    "com.apple.loginwindow": [],
    "com.apple.mail": ["AXWebArea"],
    "com.apple.reminders": [],
    "com.apple.storeuid": [],
    "com.apple.talagent": [],
    "com.aspyr": [],
    "com.bittorrent.uTorrent": [],
    "com.blizzard": [],
    "com.bohemiancoding.sketch3": [],
    "com.google.chrome": ["AXGroup", "AXList"],
    "com.microsoft": [],
    "com.mojang": [],
    "com.parallels.desktop": [],
    "com.teamviewer.TeamViewer": [],
    "com.wunderkinder.wunderlistdesktop": [],
    "it.bloop.airmail": [],
    "it.bloop.airmail2": [],
    "org.chromium.chromium": ["AXGroup", "AXList"],
    "org.mozilla.firefox": ["AXMenuItem"],
    "org.telegram.desktop": [],
    "ru.keepcoder.Telegram": [],
    "ru.yandex.desktop.yandex-browser": ["AXGroup", "AXList"],
}
expected_click_exceptions = {
    "*": ["AXTextField", "AXTextArea", "AXComboBox", "AXWindow", "AXUnknown", "AXStaticText", "AXPopUpButton"],
    "com.adobe.acc.AdobeCreativeCloud": [],
    "com.apple.ActivityMonitor": [],
    "com.apple.Aperture": [],
    "com.apple.DiskImageMounter": [],
    "com.apple.DiskUtility": [],
    "com.apple.FinalCut": [],
    "com.apple.Notes": [],
    "com.apple.Photos": [],
    "com.apple.Preview": [],
    "com.apple.RemoteDesktop": [],
    "com.apple.ScreenSharing": [],
    "com.apple.SystemProfiler": [],
    "com.apple.dock": [],
    "com.apple.dt.Xcode": ["AXGroup"],
    "com.apple.finder": ["AXList", "AXOutline", "AXGrid", "AXImage", "AXGroup"],
    "com.apple.garageband10": [],
    "com.apple.iCal": [],
    "com.apple.iTunes": [],
    "com.apple.iWork.Keynote": [],
    "com.apple.iWork.Numbers": [],
    "com.apple.iWork.Pages": [],
    "com.apple.logic10": [],
    "com.apple.loginwindow": [],
    "com.apple.mail": ["AXWebArea"],
    "com.apple.reminders": [],
    "com.apple.storeuid": [],
    "com.apple.talagent": [],
    "com.bittorrent.uTorrent": [],
    "com.bohemiancoding.sketch3": [],
    "com.google.chrome": ["AXGroup", "AXList"],
    "com.microsoft": [],
    "com.parallels.desktop": [],
    "com.teamviewer.TeamViewer": [],
    "com.wunderkinder.wunderlistdesktop": [],
    "it.bloop.airmail": [],
    "it.bloop.airmail2": [],
    "org.chromium.chromium": ["AXGroup", "AXList"],
    "org.mozilla.firefox": ["AXMenuItem"],
    "org.telegram.desktop": [],
    "ru.keepcoder.Telegram": [],
    "ru.yandex.desktop.yandex-browser": ["AXGroup", "AXList"],
}

checks = [
    ("accessibility.inject", accessibility.get("inject"), expected_inject),
    ("accessibility.eui", accessibility.get("eui"), expected_eui),
    ("search.bar.offer", search.get("bar", {}).get("offer"), True),
    ("search.click.offer", search.get("click", {}).get("offer"), False),
    ("search.bar.sitesearch_prompt_cnt", search.get("bar", {}).get("sitesearch_prompt_cnt"), 3),
    ("search.bar.exceptions", search.get("bar", {}).get("exceptions"), expected_searchbar_exceptions),
    ("search.click.exceptions", search.get("click", {}).get("exceptions"), expected_click_exceptions),
    ("switcher.reset_on_return", switcher.get("reset_on_return"), ["telegram"]),
    ("switcher.use_old_rules", switcher.get("use_old_rules"), True),
]

for name, actual, expected in checks:
    if actual != expected:
        raise SystemExit(f"reverse audit failed: {name}: expected {expected!r}, got {actual!r}")
    print(f"PASS {name}")
PY

for sound in replace reverse misprint switch en ru typeeng typerus; do
    if [[ ! -f "$RESOURCES_DIR/$sound.wav" ]]; then
        echo "reverse audit failed: missing observed sound resource $sound.wav" >&2
        exit 1
    fi
    echo "PASS sound resource $sound.wav"
done

for icon in icon_active icon_inactive icon_disabled icon_active_w icon_inactive_w icon_disabled_w; do
    if [[ ! -f "$RESOURCES_DIR/$icon.tiff" ]]; then
        echo "reverse audit failed: missing observed status icon resource $icon.tiff" >&2
        exit 1
    fi
    echo "PASS status icon resource $icon.tiff"
done

required_strings=(
    "maximumNumberOfLogFiles"
    "!!! Tried to switch to layout '%@' from '%@', but layout stayed the same!"
    "AXEnhancedUserInterface"
    "punto.SecureInput.plist"
    "SecureInputState: %hhu"
    "Context: %@"
    "currentApp: %@"
    "runningApps: %@"
    "enabledLayouts: %@"
    "applyMailBehaviourForFullWords:withEvent:withCharsToSelect:withForceWordEndingCharPresent:"
    "applyMailBehaviourForPartialWords:"
    "numberOfDeletionsInMail"
    "com.apple.ScreenSaver.Engine"
    "UNDEFINED"
    "shouldRestorePasteboard"
    "previousPasteboardContents"
    "pasteboardRestoreTimer"
    "generalPasteboard"
    "getPasteboardString"
    "setPasteboardString:"
    "restorePasteboardByTimer:"
    "restorePasteboardForKeyboardByTimer:"
    "useSoundLayoutSwitchToRussian"
    "useSoundLayoutSwitchToEnglish"
    "useSoundConvertation"
    "useSoundMisprint"
    "useSoundAutocorrection"
    "useSoundUndo"
    "useSoundKeystrokes"
    "undoLearning"
    "undoCollectionEnabled"
    "mustShowUndoWindow"
    "undoDictionary"
    "setUndoCollectionEnabled:"
    "setMustShowUndoWindow:"
    "setUndoDictionary:"
    "UndoWindowController"
    "UndoWindowDelegate"
    "UndoWindow"
    "PMUserRuleUndoAlertFormat"
    "showUndoLearningWindowCheckboxChanged:"
    "undoLearningCheckboxChanged:"
    "undoLearningCheckbox"
    "showUndoLearningWindowCheckbox"
    "undoTries"
    "undoPersists"
    "undoWasDone"
    "undoConvertion"
    "resetUndoBuffer"
    "switcher.use_old_rules"
    "switcherUseOldRules"
    "switcher.reset_on_return"
    "switchLayoutOnSelectedTextSwitch"
    "setSwitchLanguageWhenChangingSelectionLayout:"
    "isManualConversionDisabled"
    "setIsManualConversionDisabled:"
    "shouldRememberInputSourceForEachApp"
    "disabledApps"
    "setDisabledApplications:"
    "disabledAppsPreferencesController"
    "setDisabledAppsPreferencesController:"
    "CompletelyDisableInExceptionApps"
    "PSDayuseSettings"
    "PSDayuseStat"
    "TypedWords"
    "TypedSymbols"
    "AutoSwitches"
    "ManualSwitches"
    "Reverts"
    "LastDayuseDate"
    "LastProductStatDate"
    "setDayuse:"
    "typedWords"
    "typedSymbols"
    "lastDayuseDate"
    "lastProductStatDate"
    "setTypedWords:"
    "setTypedSymbols:"
    "setAutomaticSwitches:"
    "setManualSwitches:"
    "setReverts:"
    "setLastDayuseDate:"
    "setLastProductStatDate:"
    "product.typed.symbol"
    "product.typed.word"
    "product.switch.auto"
    "product.switch.manual"
    "product.switch.reverse"
    "shouldNotAutoconvertWithTabOrEnter"
    "setDontAutoconvertWithEnterOrTab:"
    "shouldNotAutoconvertAfterConvertion"
    "dontAutoconvertWordAfterConvertion:"
    "AXFocusedUIElementChanged"
    "AXFocusedWindowChanged"
    "AXMainWindowChanged"
    "AXWindowCreated"
    "AXSelectedTextChanged"
    "AXValueChanged"
    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    "tell application \"System Preferences\""
    "reveal anchor \"Privacy_Accessibility\" of pane id \"com.apple.preference.security\""
    "accessibility-alert-message"
    "accessibility-alert-messageLegacy"
    "canDoSearchClick"
    "showSearchWindowAutomatically"
    "showSearchWindowSelectedText"
    "setIsClickSearch:"
    "--install"
    "handleInstallArgument"
    "openWindowAfterInstaller"
    "showInstallationFinishedTooltip"
    "showUpdateFinishedTooltip"
    "tooltip-app-installed"
    "shouldDisplayWelcome"
    "Displaying welcome screen..."
    "Accessibility API enabled. Initializing services."
    "Accessibility API disabled. Showing accessibility preference window."
    "inputSourceEnabled:"
    "handleInputSourcesEnabled"
    "promptUserToInstallLayouts"
    "Failed to enable layout %@! Error code: %d"
    "isAppleLayout"
    "isDvorak"
    "windowsLayoutUsed"
    "fixString:isEnglish:isApple:"
    "createMacToPcMappingWithString:pcLayoutA:pcLayoutB:"
    "convertStringLayout:withMode:isPCLayout:"
    "shortcutChangeLayout"
    "shortcutChangeCase"
    "shortcutSwitchAutocorrection"
    "shortcutCancelLayoutChange"
    "shortcutFindInYandex"
    "shortcutFindInSlovari"
    "setShortcut:"
    "shortcutWithDictionary:"
    "resetShortcutsToDefaults:"
    "setShortcutChangeLayout:"
    "setShortcutChangeCase:"
    "setShortcutSwitchAutocorrection:"
    "setShortcutCancelLayoutChange:"
    "setShortcutFindInYandex:"
    "setShortcutFindInSlovari:"
    "shortcutsPreferencesController"
    "setShortcutsPreferencesController:"
    "doesCollideWithExistingShortcuts"
    "shortcutField:canAllowShortcut:"
    "emptyShortcut"
    "isAllowedCharacterKeycode:"
    "isAllowedShortcutCharacterKeycode:"
    "setCancellingKeyState:doEnable:"
    "dontAutoconvertWordWithBackspace"
    "dontAutoconvertWordWithDelete"
    "dontAutoconvertWordWithLeftArrow"
    "dontAutoconvertWordWithRightArrow"
    "dontAutoconvertWordWithUpArrow"
    "dontAutoconvertWordWithDownArrow"
    "dontAutoconvertWordWithBackspace:"
    "dontAutoconvertWordWithDelete:"
    "dontAutoconvertWordWithLeftArrow:"
    "dontAutoconvertWordWithRightArrow:"
    "dontAutoconvertWordWithUpArrow:"
    "dontAutoconvertWordWithDownArrow:"
    "userRulesDictionary"
    "rule_string"
    "createUserRule"
    "modifyUserRule"
    "removeUserRuleWithIndex:"
    "addUserRuleWithString:rule:shouldSwitchLayout:isRuleActive:isRegExp:"
    "modifyUserRuleWithIndex:string:rule:shouldSwitchLayout:isRuleActive:isRegExp:"
    "showWordAddedTooltip:"
)

strings_snapshot="$(mktemp -t punto-switcher-strings.XXXXXX)"
trap 'rm -f "$strings_snapshot"' EXIT
strings "$EXECUTABLE" > "$strings_snapshot"

for pattern in "${required_strings[@]}"; do
    if ! grep -Fq -- "$pattern" "$strings_snapshot"; then
        echo "reverse audit failed: missing observed binary string: $pattern" >&2
        exit 1
    fi
    echo "PASS binary string $pattern"
done

echo "Punto Switcher reverse audit passed"
