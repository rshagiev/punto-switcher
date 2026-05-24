import Foundation
import PuntoCore

func runSearchShortcutPolicyTests() throws {
    try expectNil(
        SearchShortcutPolicy.normalizedQuery(" \n\t "),
        "search shortcut policy rejects empty normalized query"
    )
    try expect(
        SearchShortcutPolicy.normalizedQuery("  привет мир  "),
        "привет мир",
        "search shortcut policy trims query"
    )

    try expect(
        SearchShortcutPolicy.url(for: "привет мир", destination: .yandexSearch)?.absoluteString,
        "http://yandex.ru/yandsearch?text=%D0%BF%D1%80%D0%B8%D0%B2%D0%B5%D1%82%20%D0%BC%D0%B8%D1%80&clid=141986&yasoft=puntomac",
        "search shortcut policy builds Punto Switcher-style Yandex search URL"
    )
    try expect(
        SearchShortcutPolicy.url(for: "привет мир", destination: .yandexSearch)?.absoluteString.contains("yasoft=puntomac") == true,
        true,
        "search shortcut policy preserves yasoft marker"
    )

    try expect(
        SearchShortcutPolicy.url(for: "hello", destination: .yandexTranslate)?.absoluteString,
        "http://translate.yandex.ru/?text=hello&clid=141986",
        "search shortcut policy builds Yandex translate URL"
    )
}

func runSelectedTextSearchPolicyTests() throws {
    let editableCapture = CapturedText(
        text: " привет мир ",
        replacementMethod: .accessibilitySelection,
        source: "AX editable selection"
    )
    try expect(
        SelectedTextSearchPolicy.plan(capturedText: editableCapture, destination: .yandexSearch),
        .open(URL(string: "http://yandex.ru/yandsearch?text=%D0%BF%D1%80%D0%B8%D0%B2%D0%B5%D1%82%20%D0%BC%D0%B8%D1%80&clid=141986&yasoft=puntomac")!),
        "selected-text search policy opens normalized Yandex search URL"
    )

    let terminalTailCapture = CapturedText(
        text: "hello",
        replacementMethod: .keyboardRewriteTail(originalTail: "echo hello"),
        source: "terminal command-tail selection"
    )
    try expect(
        SelectedTextSearchPolicy.plan(capturedText: terminalTailCapture, destination: .yandexTranslate),
        .open(URL(string: "http://translate.yandex.ru/?text=hello&clid=141986")!),
        "selected-text search policy allows safe terminal-tail selected text"
    )

    let blockedCapture = CapturedText(
        text: "stale",
        replacementMethod: .blocked,
        source: "unsafe stale clipboard fallback"
    )
    try expect(
        SelectedTextSearchPolicy.plan(capturedText: blockedCapture, destination: .yandexSearch),
        .blockedCapture(blockedCapture),
        "selected-text search policy blocks unsafe capture"
    )

    try expect(
        SelectedTextSearchPolicy.plan(capturedText: nil, destination: .yandexSearch),
        .noText,
        "selected-text search policy reports nil capture as no text"
    )
    try expect(
        SelectedTextSearchPolicy.plan(
            capturedText: CapturedText(text: "", replacementMethod: .accessibilitySelection, source: "empty"),
            destination: .yandexSearch
        ),
        .noText,
        "selected-text search policy reports empty selected text as no text"
    )
    try expect(
        SelectedTextSearchPolicy.plan(
            capturedText: CapturedText(text: " \n\t ", replacementMethod: .accessibilitySelection, source: "blank"),
            destination: .yandexSearch
        ),
        .skipped(reason: "empty normalized query"),
        "selected-text search policy skips blank normalized query"
    )

    let searchURL = URL(string: "http://yandex.ru/yandsearch?text=%D0%BF%D1%80%D0%B8%D0%B2%D0%B5%D1%82%20%D0%BC%D0%B8%D1%80&clid=141986&yasoft=puntomac")!
    try expect(
        SelectedTextSearchPolicy.runtimePlan(from: .open(searchURL)),
        .open(
            url: searchURL,
            logMessage: "Opening selected text search URL: \(searchURL.absoluteString)",
            shouldFlashIcon: true
        ),
        "selected-text search runtime policy owns URL opening log and icon flash"
    )

    try expect(
        SelectedTextSearchPolicy.runtimePlan(from: .blockedCapture(blockedCapture)),
        .blockedCapture(
            capturedText: blockedCapture,
            logMessage: "Selected text search blocked unsafe selection fallback: unsafe stale clipboard fallback"
        ),
        "selected-text search runtime policy owns blocked-capture cleanup log"
    )

    try expect(
        SelectedTextSearchPolicy.runtimePlan(from: .skipped(reason: "empty normalized query")),
        .skipped(logMessage: "Selected text search skipped: empty normalized query"),
        "selected-text search runtime policy owns skipped log"
    )

    try expect(
        SelectedTextSearchPolicy.runtimePlan(from: .noText),
        .noText(logMessage: "Selected text search skipped: no selected text"),
        "selected-text search runtime policy owns no-text log"
    )
}

func runSearchClickPolicyTests() throws {
    try expect(
        PuntoSwitcherObservedSurface.SearchClick.canDoSearchClickSelector,
        "canDoSearchClick",
        "search click policy pins observed Punto Switcher click capability selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.SearchClick.showSearchWindowAutomaticallySelector,
        "showSearchWindowAutomatically",
        "search click policy pins observed Punto Switcher automatic search window selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.SearchClick.showSearchWindowSelectedTextSelector,
        "showSearchWindowSelectedText",
        "search click policy pins observed Punto Switcher selected-text search window selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.SearchClick.setIsClickSearchSelector,
        "setIsClickSearch:",
        "search click policy pins observed Punto Switcher click-search state setter"
    )
    try expect(
        SearchClickPolicy.canDoSearchClick(role: "AXWebArea", bundleID: "com.example.browser"),
        true,
        "search click policy allows click search outside observed click exception roles"
    )
    try expect(
        SearchClickPolicy.canDoSearchClick(role: "AXTextField", bundleID: "com.example.editor"),
        false,
        "search click policy rejects observed global editable click exception role"
    )
    try expect(
        SearchClickPolicy.canDoSearchClick(role: "AXGroup", bundleID: "com.apple.finder"),
        false,
        "search click policy rejects observed app-specific click exception role"
    )
    try expect(
        SearchClickPolicy.canDoSearchClick(role: nil, bundleID: "com.example.editor"),
        false,
        "search click policy rejects missing focused role"
    )
    try expect(
        SearchClickPolicy.shouldSearchSelectedTextAfterClick(
            eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue,
            clickCount: 2,
            shouldSearchByDoubleClick: true,
            canDoSearchClick: true
        ),
        true,
        "search click policy allows selected-text search after eligible double click"
    )
    try expect(
        SearchClickPolicy.shouldScheduleSelectedTextSearchAfterClick(
            eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue,
            clickCount: 2,
            shouldSearchByDoubleClick: true
        ),
        true,
        "search click policy schedules live capability check after eligible left double click"
    )
    try expect(
        SearchClickPolicy.shouldScheduleSelectedTextSearchAfterClick(
            eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue,
            clickCount: 2,
            shouldSearchByDoubleClick: false
        ),
        false,
        "search click policy does not schedule capability check when double-click search is disabled"
    )
    try expect(
        SearchClickPolicy.shouldScheduleSelectedTextSearchAfterClick(
            eventTypeRawValue: PointerEventPolicy.rightMouseDownRawValue,
            clickCount: 2,
            shouldSearchByDoubleClick: true
        ),
        false,
        "search click policy keeps right double click out of delayed search handling"
    )
    try expect(
        SearchClickPolicy.shouldSearchSelectedTextAfterClick(
            eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue,
            clickCount: 1,
            shouldSearchByDoubleClick: true,
            canDoSearchClick: true
        ),
        false,
        "search click policy rejects single click"
    )
    try expect(
        SearchClickPolicy.shouldScheduleSelectedTextSearchAfterClick(
            eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue,
            clickCount: 3,
            shouldSearchByDoubleClick: true
        ),
        false,
        "search click policy rejects triple click instead of treating every multi-click as double click"
    )
    try expect(
        SearchClickPolicy.shouldSearchSelectedTextAfterClick(
            eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue,
            clickCount: 3,
            shouldSearchByDoubleClick: true,
            canDoSearchClick: true
        ),
        false,
        "search click policy keeps triple click out of selected-text search"
    )
    try expect(
        SearchClickPolicy.shouldSearchSelectedTextAfterClick(
            eventTypeRawValue: PointerEventPolicy.rightMouseDownRawValue,
            clickCount: 2,
            shouldSearchByDoubleClick: true,
            canDoSearchClick: true
        ),
        false,
        "search click policy rejects right double click"
    )
    try expect(
        SearchClickPolicy.shouldSearchSelectedTextAfterClick(
            eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue,
            clickCount: 2,
            shouldSearchByDoubleClick: false,
            canDoSearchClick: true
        ),
        false,
        "search click policy rejects double click when setting is disabled"
    )
    try expect(
        SearchClickPolicy.shouldSearchSelectedTextAfterClick(
            eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue,
            clickCount: 2,
            shouldSearchByDoubleClick: true,
            canDoSearchClick: false
        ),
        false,
        "search click policy rejects double click without live click-search capability"
    )
}

func runSearchbarSettingsPolicyTests() throws {
    try expect(
        SearchbarSettingsPolicy.defaultSnapshot,
        SearchbarSettingsSnapshot(
            activationShortcut: Hotkey.disabled,
            shouldOfferSearchbarAutoactivation: true,
            autoactivationExceptions: [],
            alertShownIn: SearchbarSettingsPolicy.legacyInitialDate,
            shouldSearchByDoubleClick: false,
            sitesearchPromptCounter: 3
        ),
        "searchbar settings policy mirrors Punto Switcher default-conf search bar/click offers and observed unset fields"
    )

    try expect(
        SearchbarSettingsPolicy.snapshot(from: nil),
        nil,
        "searchbar settings policy rejects missing dictionary"
    )

    try expect(
        SearchbarSettingsPolicy.snapshot(from: [
            SearchbarSettingsPolicy.activationShortcutKey: [
                LegacyHotkeyPolicy.keyCodeKey: NSNumber(value: 6),
                LegacyHotkeyPolicy.commandKey: NSNumber(value: true),
                LegacyHotkeyPolicy.optionKey: NSNumber(value: false),
                LegacyHotkeyPolicy.shiftKey: NSNumber(value: true),
                LegacyHotkeyPolicy.controlKey: NSNumber(value: false)
            ],
            SearchbarSettingsPolicy.autoactivationKey: NSNumber(value: false),
            SearchbarSettingsPolicy.autoactivationExceptionsKey: [
                " COM.Example.App ",
                "",
                "com.example.app",
                "org.example.Editor"
            ],
            SearchbarSettingsPolicy.alertShownInKey: NSNumber(value: 1_230_757_260),
            SearchbarSettingsPolicy.shouldSearchByDoubleClickKey: NSNumber(value: true),
            SearchbarSettingsPolicy.sitesearchPromptCounterKey: NSNumber(value: 7)
        ]),
        SearchbarSettingsSnapshot(
            activationShortcut: Hotkey(keyCode: 6, command: true, option: false, shift: true, control: false),
            shouldOfferSearchbarAutoactivation: false,
            autoactivationExceptions: ["com.example.app", "org.example.editor"],
            alertShownIn: Date(timeIntervalSince1970: 1_230_757_260),
            shouldSearchByDoubleClick: true,
            sitesearchPromptCounter: 7
        ),
        "searchbar settings policy parses NSNumber-backed legacy plist values and normalizes exception apps"
    )

    try expect(
        SearchbarSettingsPolicy.snapshot(from: [
            SearchbarSettingsPolicy.activationShortcutKey: [
                LegacyHotkeyPolicy.keyCodeKey: LegacyHotkeyPolicy.noKeyCode,
                LegacyHotkeyPolicy.commandKey: true,
                LegacyHotkeyPolicy.optionKey: true,
                LegacyHotkeyPolicy.shiftKey: false,
                LegacyHotkeyPolicy.controlKey: false
            ],
            SearchbarSettingsPolicy.autoactivationKey: "yes",
            SearchbarSettingsPolicy.alertShownInKey: "2009-01-01 00:00:00 +0300",
            SearchbarSettingsPolicy.shouldSearchByDoubleClickKey: "0",
            SearchbarSettingsPolicy.sitesearchPromptCounterKey: " 4 "
        ]),
        SearchbarSettingsSnapshot(
            activationShortcut: Hotkey(
                keyCode: Hotkey.modifierOnlyKeyCode,
                command: true,
                option: true,
                shift: false,
                control: false
            ),
            shouldOfferSearchbarAutoactivation: true,
            alertShownIn: SearchbarSettingsPolicy.legacyInitialDate,
            shouldSearchByDoubleClick: false,
            sitesearchPromptCounter: 4
        ),
        "searchbar settings policy parses string-backed imported values and observed alert date"
    )

    try expect(
        SearchbarSettingsPolicy.snapshot(from: [
            SearchbarSettingsPolicy.sitesearchPromptCounterKey: -2
        ]),
        SearchbarSettingsSnapshot(
            activationShortcut: Hotkey.disabled,
            shouldOfferSearchbarAutoactivation: true,
            autoactivationExceptions: [],
            alertShownIn: SearchbarSettingsPolicy.legacyInitialDate,
            shouldSearchByDoubleClick: false,
            sitesearchPromptCounter: 0
        ),
        "searchbar settings policy clamps negative prompt counters"
    )

    try expect(
        SearchbarSettingsPolicy.effectiveShouldSearchByDoubleClick(
            hasNativeValue: true,
            nativeValue: false,
            legacySnapshot: SearchbarSettingsSnapshot(
                shouldOfferSearchbarAutoactivation: true,
                shouldSearchByDoubleClick: true,
                sitesearchPromptCounter: 3
            )
        ),
        false,
        "searchbar settings policy lets native double-click search setting override imported PSSearchbarSettings"
    )
    try expect(
        SearchbarSettingsPolicy.effectiveShouldSearchByDoubleClick(
            hasNativeValue: false,
            nativeValue: nil,
            legacySnapshot: SearchbarSettingsSnapshot(
                shouldOfferSearchbarAutoactivation: true,
                shouldSearchByDoubleClick: true,
                sitesearchPromptCounter: 3
            )
        ),
        true,
        "searchbar settings policy imports legacy ShouldSearchByDoubleClick when native setting is absent"
    )
    try expect(
        SearchbarSettingsPolicy.effectiveShouldSearchByDoubleClick(
            hasNativeValue: false,
            nativeValue: nil,
            legacySnapshot: nil
        ),
        false,
        "searchbar settings policy defaults double-click search off without native or legacy settings"
    )
}
