import Foundation
import PuntoCore

import Foundation
import PuntoCore

func runHotkeyPolicyTests() throws {
    try expect(Hotkey.defaultConvertLayout.isModifierOnly, true, "default convert hotkey is modifier-only")
    try expect(Hotkey.defaultConvertLayout.displayString, "\u{2325}\u{21E7}\u{2318}", "default convert hotkey display")
    try expect(Hotkey.defaultToggleCase.displayString, "\u{2325}\u{2318}Z", "default toggle-case hotkey display")
    try expect(Hotkey.defaultToggleAutoCorrection.displayString, "\u{2325}\u{2318}A", "default toggle-auto-correction hotkey display")
    try expect(Hotkey.defaultCancelLayoutChange.displayString, "\u{2325}\u{2318}Delete", "default cancel-layout-change hotkey display")
    try expect(Hotkey.defaultFindInYandex.displayString, "Not Set", "default find-in-Yandex hotkey is unassigned")
    try expect(Hotkey.defaultFindInSlovari.displayString, "Not Set", "default find-in-Slovari hotkey is unassigned")
    try expect(KeyCodeNames.name(for: 49), "Space", "key code name lookup")
    try expectNil(KeyCodeNames.name(for: UInt16.max), "modifier-only key has no key name")

    let encoded = try JSONEncoder().encode(Hotkey.defaultConvertLayout)
    let decoded = try JSONDecoder().decode(Hotkey.self, from: encoded)
    try expect(decoded, Hotkey.defaultConvertLayout, "hotkey codable round-trip")
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey.defaultConvertLayout),
        true,
        "hotkey validation accepts default modifier-only convert hotkey"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey.defaultToggleCase),
        true,
        "hotkey validation accepts default key-based toggle hotkey"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey.defaultToggleAutoCorrection),
        true,
        "hotkey validation accepts default key-based auto-correction toggle hotkey"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey.defaultCancelLayoutChange),
        true,
        "hotkey validation accepts default key-based cancel-layout-change hotkey"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedCharacterKeycode(0),
        true,
        "hotkey validation allows ordinary character keycodes"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedCharacterKeycode(55),
        false,
        "hotkey validation rejects modifier keycodes as raw characters"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedShortcutCharacterKeycode(0),
        true,
        "hotkey validation allows ordinary character shortcut keycodes"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedShortcutCharacterKeycode(51),
        true,
        "hotkey validation allows Delete as a shortcut keycode for cancel-layout-change"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedShortcutCharacterKeycode(55),
        false,
        "hotkey validation rejects modifier keycodes as shortcut characters"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedShortcutCharacterKeycode(57),
        false,
        "hotkey validation rejects Caps Lock as a shortcut character"
    )
    try expect(
        HotkeyValidationPolicy.isAllowedShortcutCharacterKeycode(53),
        false,
        "hotkey validation rejects Escape because it cancels shortcut editing"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey(
            keyCode: 55,
            command: true,
            option: false,
            shift: false,
            control: false
        )),
        false,
        "hotkey validation rejects Command key as a key-based shortcut character"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey.disabled),
        true,
        "hotkey validation accepts explicitly disabled shortcuts"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey(
            keyCode: Hotkey.modifierOnlyKeyCode,
            command: true,
            option: false,
            shift: false,
            control: false
        )),
        false,
        "hotkey validation rejects single-modifier modifier-only hotkey"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey(
            keyCode: 0,
            command: false,
            option: false,
            shift: true,
            control: false
        )),
        false,
        "hotkey validation rejects shift-only key hotkey"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey(
            keyCode: 0,
            command: false,
            option: true,
            shift: false,
            control: false
        )),
        true,
        "hotkey validation accepts option-key shortcut"
    )
    try expect(
        HotkeyValidationPolicy.isValid(Hotkey(
            keyCode: UInt16.max - 2,
            command: true,
            option: false,
            shift: false,
            control: false
        )),
        false,
        "hotkey validation rejects unknown key code"
    )
    try expect(
        HotkeyValidationPolicy.normalized(
            Hotkey(keyCode: 0, command: false, option: false, shift: false, control: false),
            fallback: Hotkey.defaultToggleCase
        ),
        Hotkey.defaultToggleCase,
        "hotkey validation falls back for plain key shortcut"
    )
    try expect(
        LegacyHotkeyPolicy.hotkey(from: [
            "charKeycode": 6,
            "isCommandUsed": true,
            "isAltUsed": NSNumber(value: true),
            "isShiftUsed": false,
            "isControlUsed": false
        ]),
        Hotkey.defaultToggleCase,
        "legacy hotkey policy reads Punto Switcher shortcut dictionaries"
    )
    try expect(
        LegacyHotkeyPolicy.hotkey(from: [
            "charKeycode": " 6 ",
            "isCommandUsed": "yes",
            "isAltUsed": "0",
            "isShiftUsed": "true",
            "isControlUsed": "off"
        ]),
        Hotkey(keyCode: 6, command: true, option: false, shift: true, control: false),
        "legacy hotkey policy reads string-backed shortcut dictionaries"
    )
    try expect(
        LegacyHotkeyPolicy.hotkey(from: [
            "charKeycode": 666,
            "isCommandUsed": true,
            "isAltUsed": true,
            "isShiftUsed": true,
            "isControlUsed": false
        ]),
        Hotkey.defaultConvertLayout,
        "legacy hotkey policy maps Punto Switcher no-key shortcut to modifier-only hotkey"
    )
    try expect(
        LegacyHotkeyPolicy.hotkey(from: [
            "charKeycode": 666,
            "isCommandUsed": false,
            "isAltUsed": false,
            "isShiftUsed": false,
            "isControlUsed": false
        ]),
        Hotkey.disabled,
        "legacy hotkey policy maps Punto Switcher no-key/no-modifier shortcut to disabled"
    )
    try expect(
        LegacyHotkeyPolicy.normalized([
            "charKeycode": 666,
            "isCommandUsed": true,
            "isAltUsed": false,
            "isShiftUsed": false,
            "isControlUsed": false
        ], fallback: Hotkey.defaultToggleCase),
        Hotkey.defaultToggleCase,
        "legacy hotkey policy normalizes invalid single-modifier shortcuts"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShortcutChangeLayoutKey,
        PuntoSwitcherObservedSurface.Hotkeys.shortcutChangeLayoutKey,
        "legacy hotkey policy keeps change-layout import key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShortcutChangeCaseKey,
        PuntoSwitcherObservedSurface.Hotkeys.shortcutChangeCaseKey,
        "legacy hotkey policy keeps change-case import key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShortcutSwitchAutocorrectionKey,
        PuntoSwitcherObservedSurface.Hotkeys.shortcutSwitchAutocorrectionKey,
        "legacy hotkey policy keeps switch-autocorrection import key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShortcutCancelLayoutChangeKey,
        PuntoSwitcherObservedSurface.Hotkeys.shortcutCancelLayoutChangeKey,
        "legacy hotkey policy keeps cancel-layout-change import key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShortcutFindInYandexKey,
        PuntoSwitcherObservedSurface.Hotkeys.shortcutFindInYandexKey,
        "legacy hotkey policy keeps find-in-Yandex import key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShortcutFindInSlovariKey,
        PuntoSwitcherObservedSurface.Hotkeys.shortcutFindInSlovariKey,
        "legacy hotkey policy keeps find-in-Slovari import key aligned with reverse-audit anchor"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutSelector,
        "setShortcut:",
        "legacy hotkey policy preserves observed generic shortcut setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.shortcutWithDictionarySelector,
        "shortcutWithDictionary:",
        "legacy hotkey policy preserves observed dictionary importer selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.resetShortcutsToDefaultsSelector,
        "resetShortcutsToDefaults:",
        "legacy hotkey policy preserves observed reset-shortcuts selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutChangeLayoutSelector,
        "setShortcutChangeLayout:",
        "legacy hotkey policy preserves observed change-layout setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutChangeCaseSelector,
        "setShortcutChangeCase:",
        "legacy hotkey policy preserves observed change-case setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutSwitchAutocorrectionSelector,
        "setShortcutSwitchAutocorrection:",
        "legacy hotkey policy preserves observed switch-autocorrection setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutCancelLayoutChangeSelector,
        "setShortcutCancelLayoutChange:",
        "legacy hotkey policy preserves observed cancel-layout-change setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutFindInYandexSelector,
        "setShortcutFindInYandex:",
        "legacy hotkey policy preserves observed find-in-Yandex setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutFindInSlovariSelector,
        "setShortcutFindInSlovari:",
        "legacy hotkey policy preserves observed find-in-Slovari setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.shortcutsPreferencesControllerKey,
        "shortcutsPreferencesController",
        "legacy hotkey policy preserves observed shortcuts preferences controller key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setShortcutsPreferencesControllerSelector,
        "setShortcutsPreferencesController:",
        "legacy hotkey policy preserves observed shortcuts preferences controller setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.switchAutocorrectionSelector,
        "switchAutocorrection:",
        "legacy hotkey policy preserves observed switch-autocorrection action selector"
    )
    try expect(
        LegacyHotkeyPolicy.legacyCancelLayoutChangeShortcutKey,
        PuntoSwitcherObservedSurface.Hotkeys.cancelLayoutChangeShortcutKey,
        "legacy hotkey policy keeps cancel-layout-change shortcut field key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacySwitchAutocorrectionShortcutKey,
        PuntoSwitcherObservedSurface.Hotkeys.switchAutocorrectionShortcutKey,
        "legacy hotkey policy keeps switch-autocorrection shortcut field key aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyChangeCaseShortcutKey,
        PuntoSwitcherObservedSurface.Hotkeys.changeCaseShortcutKey,
        "legacy hotkey policy keeps change-case shortcut field key aligned with reverse-audit anchor"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.setChangeCaseShortcutSelector,
        "setChangeCaseShortcut:",
        "legacy hotkey policy preserves observed change-case shortcut-field setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Hotkeys.shortcutFieldClassName,
        "ShortcutField",
        "legacy hotkey policy preserves observed shortcut-field class boundary"
    )

    try expect(
        PuntoSwitcherObservedSurface.HotkeyCollision.doesCollideSelector,
        "doesCollideWithExistingShortcuts",
        "hotkey collision policy preserves observed collision selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.HotkeyCollision.canAllowShortcutSelector,
        "shortcutField:canAllowShortcut:",
        "hotkey collision policy preserves observed shortcut-field selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.HotkeyCollision.emptyShortcutSelector,
        "emptyShortcut",
        "hotkey collision policy preserves observed empty-shortcut selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.HotkeyCollision.allowedCharacterKeycodeSelector,
        "isAllowedCharacterKeycode:",
        "hotkey collision policy preserves observed raw allowed-keycode selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.HotkeyCollision.allowedShortcutCharacterKeycodeSelector,
        "isAllowedShortcutCharacterKeycode:",
        "hotkey collision policy preserves observed shortcut allowed-keycode selector"
    )

    let assignments = [
        HotkeyAssignment(slot: .convertLayout, hotkey: Hotkey.defaultConvertLayout),
        HotkeyAssignment(slot: .toggleCase, hotkey: Hotkey.defaultToggleCase),
        HotkeyAssignment(slot: .toggleAutoCorrection, hotkey: Hotkey.defaultToggleAutoCorrection),
        HotkeyAssignment(slot: .cancelLayoutChange, hotkey: Hotkey.defaultCancelLayoutChange),
        HotkeyAssignment(slot: .findInYandex, hotkey: Hotkey.defaultFindInYandex),
        HotkeyAssignment(slot: .findInSlovari, hotkey: Hotkey.defaultFindInSlovari)
    ]
    try expect(
        HotkeyCollisionPolicy.collidingSlot(
            for: Hotkey.defaultToggleCase,
            in: assignments,
            excluding: .findInYandex
        ),
        .toggleCase,
        "hotkey collision policy reports the existing shortcut owner"
    )
    try expect(
        HotkeyCollisionPolicy.doesCollideWithExistingShortcuts(
            Hotkey.defaultToggleCase,
            in: assignments,
            excluding: .toggleCase
        ),
        false,
        "hotkey collision policy ignores the slot being edited"
    )
    try expect(
        HotkeyCollisionPolicy.canAllowShortcut(
            Hotkey(keyCode: 31, command: true, option: true, shift: false, control: false),
            in: assignments,
            excluding: .findInYandex
        ),
        true,
        "hotkey collision policy allows unique shortcuts"
    )
    try expect(
        HotkeyCollisionPolicy.canAllowShortcut(
            Hotkey.disabled,
            in: assignments,
            excluding: .findInYandex
        ),
        true,
        "hotkey collision policy allows multiple empty shortcuts"
    )
    try expect(
        HotkeyCollisionPolicy.canAllowShortcut(
            Hotkey.defaultConvertLayout,
            in: assignments,
            excluding: .findInSlovari
        ),
        false,
        "hotkey collision policy rejects duplicate modifier-only shortcuts"
    )

    let machine = ModifierOnlyHotkeyStateMachine(debounceInterval: 0.5)
    try expect(
        ModifierOnlyHotkeyStateMachine.actionDelay,
        0.15,
        "modifier-only hotkey action is delayed until real HID modifiers settle"
    )
    let hotkey = Hotkey.defaultConvertLayout
    let pressed = ModifierFlagsSnapshot(command: true, option: true, shift: true, control: false)
    let released = ModifierFlagsSnapshot(command: false, option: false, shift: false, control: false)
    let partial = ModifierFlagsSnapshot(command: true, option: true, shift: false, control: false)
    let extra = ModifierFlagsSnapshot(command: true, option: true, shift: true, control: true)
    let now = Date(timeIntervalSince1970: 100)

    try expect(machine.handleFlagsChanged(flags: pressed, hotkey: hotkey, now: now), false, "modifier-only press arms but does not trigger")
    try expect(machine.handleFlagsChanged(flags: released, hotkey: hotkey, now: now.addingTimeInterval(0.1)), true, "modifier-only release triggers")

    try expect(machine.handleFlagsChanged(flags: pressed, hotkey: hotkey, now: now.addingTimeInterval(0.2)), false, "modifier-only second press arms")
    try expect(machine.handleFlagsChanged(flags: released, hotkey: hotkey, now: now.addingTimeInterval(0.3)), false, "modifier-only debounce suppresses repeated release")

    try expect(machine.handleFlagsChanged(flags: pressed, hotkey: hotkey, now: now.addingTimeInterval(1.0)), false, "modifier-only press after debounce arms")
    try expect(machine.handleFlagsChanged(flags: partial, hotkey: hotkey, now: now.addingTimeInterval(1.1)), false, "partial release does not trigger")
    try expect(machine.handleFlagsChanged(flags: released, hotkey: hotkey, now: now.addingTimeInterval(1.2)), true, "full release after partial release triggers")

    try expect(machine.handleFlagsChanged(flags: pressed, hotkey: hotkey, now: now.addingTimeInterval(2.0)), false, "modifier-only arms before keyDown cancel")
    machine.cancelPendingModifierOnlyChord()
    try expect(machine.handleFlagsChanged(flags: released, hotkey: hotkey, now: now.addingTimeInterval(2.1)), false, "keyDown cancel prevents modifier-only trigger")

    try expect(machine.handleFlagsChanged(flags: extra, hotkey: hotkey, now: now.addingTimeInterval(3.0)), false, "extra modifier does not arm modifier-only hotkey")
    try expect(machine.handleFlagsChanged(flags: released, hotkey: hotkey, now: now.addingTimeInterval(3.1)), false, "extra modifier release does not trigger")

    let exactThenExtraMachine = ModifierOnlyHotkeyStateMachine(debounceInterval: 0.5)
    try expect(exactThenExtraMachine.handleFlagsChanged(flags: pressed, hotkey: hotkey, now: now.addingTimeInterval(4.0)), false, "modifier-only arms before extra modifier")
    try expect(exactThenExtraMachine.handleFlagsChanged(flags: extra, hotkey: hotkey, now: now.addingTimeInterval(4.1)), false, "extra modifier cancels armed modifier-only chord")
    try expect(exactThenExtraMachine.handleFlagsChanged(flags: released, hotkey: hotkey, now: now.addingTimeInterval(4.2)), false, "release after extra modifier does not trigger")

    try expect(
        ModifierOnlyHotkeyStateMachine().handleFlagsChanged(
            flags: pressed,
            hotkey: Hotkey.defaultToggleCase,
            now: now
        ),
        false,
        "key-based hotkey is ignored by modifier-only machine"
    )
}

func runKeyDownEventPolicyTests() throws {
    let none = ModifierFlagsSnapshot(command: false, option: false, shift: false, control: false)
    let shift = ModifierFlagsSnapshot(command: false, option: false, shift: true, control: false)
    let command = ModifierFlagsSnapshot(command: true, option: false, shift: false, control: false)
    let commandOption = ModifierFlagsSnapshot(command: true, option: true, shift: false, control: false)
    let commandOptionShift = ModifierFlagsSnapshot(command: true, option: true, shift: true, control: false)
    let commandControl = ModifierFlagsSnapshot(command: true, option: false, shift: false, control: true)
    let optionOnly = ModifierFlagsSnapshot(command: false, option: true, shift: false, control: false)
    let controlOnly = ModifierFlagsSnapshot(command: false, option: false, shift: false, control: true)
    let findInYandexHotkey = Hotkey(keyCode: 3, command: true, option: true, shift: false, control: false)
    let findInSlovariHotkey = Hotkey(keyCode: 3, command: true, option: true, shift: true, control: false)

    try expect(
        KeyDownEventPolicy.keyBasedHotkeyActionDelay,
        0.15,
        "keyDown policy delays key-based hotkey actions until modifiers are released"
    )
    try expect(
        KeyDownEventPolicy.action(
            keyCode: 6,
            flags: commandOption,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .toggleCaseHotkey,
        "keyDown policy detects toggle-case hotkey"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 0,
            flags: commandOption,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase,
            toggleAutoCorrectionHotkey: Hotkey.defaultToggleAutoCorrection
        ),
        .toggleAutoCorrectionHotkey,
        "keyDown policy detects toggle-auto-correction hotkey"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 51,
            flags: commandOption,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase,
            toggleAutoCorrectionHotkey: Hotkey.defaultToggleAutoCorrection,
            cancelLayoutChangeHotkey: Hotkey.defaultCancelLayoutChange
        ),
        .cancelLayoutChangeHotkey,
        "keyDown policy detects cancel-layout-change hotkey before modified deletion"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 3,
            flags: commandOption,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase,
            toggleAutoCorrectionHotkey: Hotkey.defaultToggleAutoCorrection,
            cancelLayoutChangeHotkey: Hotkey.defaultCancelLayoutChange,
            findInYandexHotkey: findInYandexHotkey,
            findInSlovariHotkey: findInSlovariHotkey
        ),
        .findInYandexHotkey,
        "keyDown policy detects find-in-Yandex hotkey before modified shortcut clearing"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 3,
            flags: commandOptionShift,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase,
            toggleAutoCorrectionHotkey: Hotkey.defaultToggleAutoCorrection,
            cancelLayoutChangeHotkey: Hotkey.defaultCancelLayoutChange,
            findInYandexHotkey: findInYandexHotkey,
            findInSlovariHotkey: findInSlovariHotkey
        ),
        .findInSlovariHotkey,
        "keyDown policy detects find-in-Slovari hotkey before modified shortcut clearing"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 3,
            flags: commandOption,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase,
            findInYandexHotkey: Hotkey.disabled,
            findInSlovariHotkey: Hotkey.disabled
        ),
        .clearTrackedText(reason: "modified shortcut"),
        "keyDown policy treats disabled search shortcut as ordinary modified shortcut"
    )

    let keyBasedConvert = Hotkey(keyCode: 49, command: true, option: true, shift: false, control: false)
    try expect(
        KeyDownEventPolicy.action(
            keyCode: 49,
            flags: commandOption,
            convertHotkey: keyBasedConvert,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .convertLayoutHotkey,
        "keyDown policy detects key-based convert hotkey"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 6,
            flags: commandOptionShift,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "modified shortcut"),
        "keyDown policy clears tracker for non-exact modified hotkey chord"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 9,
            flags: command,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "paste"),
        "keyDown policy clears tracker for Cmd+V"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 8,
            flags: command,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "copy"),
        "keyDown policy clears tracker for Cmd+C"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 6,
            flags: command,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "undo"),
        "keyDown policy clears tracker for Cmd+Z"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 9,
            flags: commandOption,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "modified shortcut"),
        "keyDown policy clears tracker for Cmd+Opt+V as modified shortcut"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 7,
            flags: command,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "cut"),
        "keyDown policy clears tracker for Cmd+X"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 0,
            flags: command,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "selection"),
        "keyDown policy clears tracker for Cmd+A"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 51,
            flags: optionOnly,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "modified deletion"),
        "keyDown policy clears tracker for Option+Delete"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 123,
            flags: command,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .clearTrackedText(reason: "modified navigation"),
        "keyDown policy clears tracker for Cmd+Left"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 0,
            flags: none,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .trackKeyPress,
        "keyDown policy tracks plain key press"
    )

    try expect(
        KeyDownEventPolicy.action(
            keyCode: 0,
            flags: shift,
            convertHotkey: Hotkey.defaultConvertLayout,
            toggleCaseHotkey: Hotkey.defaultToggleCase
        ),
        .trackKeyPress,
        "keyDown policy tracks shifted key press"
    )

    for (flags, label) in [(command, "command"), (optionOnly, "option"), (controlOnly, "control"), (commandControl, "command-control")] {
        try expect(
            KeyDownEventPolicy.action(
                keyCode: 11,
                flags: flags,
                convertHotkey: Hotkey.defaultConvertLayout,
                toggleCaseHotkey: Hotkey.defaultToggleCase
            ),
            .clearTrackedText(reason: "modified shortcut"),
            "keyDown policy clears tracker for \(label)-modified shortcut"
        )
    }
}
