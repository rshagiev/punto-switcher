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

func runCaseConverterTests() throws {
    try expect(CaseConverter.toggleCase("hello"), "HELLO", "case converter lower to upper")
    try expect(CaseConverter.toggleCase("HELLO"), "hello", "case converter upper to lower")
    try expect(CaseConverter.toggleCase("Hello"), "hELLO", "case converter inverts title case")
    try expect(CaseConverter.toggleCase("hELLO"), "Hello", "case converter restores inverted title case")
    try expect(CaseConverter.toggleCase("HeLLo WoRLd"), "hEllO wOrlD", "case converter inverts mixed latin text")

    try expect(CaseConverter.toggleCase("привет"), "ПРИВЕТ", "case converter russian lower to upper")
    try expect(CaseConverter.toggleCase("ПРИВЕТ"), "привет", "case converter russian upper to lower")
    try expect(CaseConverter.toggleCase("ПрИвЕт"), "пРиВеТ", "case converter inverts mixed russian text")
    try expect(CaseConverter.toggleCase("Ё"), "ё", "case converter toggles russian yo")

    try expect(CaseConverter.toggleCase("hello123"), "HELLO123", "case converter preserves numbers")
    try expect(CaseConverter.toggleCase(";'[].,"), ";'[].,", "case converter preserves punctuation")
    try expect(CaseConverter.toggleCase(""), "", "case converter empty string")
    try expect(CaseConverter.toggleCase(" "), " ", "case converter whitespace")

    for sample in ["Hello", "WORLD", "привет", "ПРИВЕТ", "MiXeD CaSe", "ПрИвЕт МиР"] {
        try expect(CaseConverter.toggleCase(CaseConverter.toggleCase(sample)), sample, "case converter round-trip \(sample)")
    }
}

func runToggleCasePolicyTests() throws {
    try expect(
        ToggleCasePolicy.replacement(
            for: CapturedText(
                text: "Hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            )
        ),
        ToggleCaseReplacement(
            originalText: "Hello",
            toggledText: "hELLO",
            undoMethod: .accessibilitySelection,
            trackedTailAfterReplacement: nil
        ),
        "toggle-case policy records AX replacement for undo"
    )

    try expect(
        ToggleCasePolicy.replacement(
            for: CapturedText(
                text: "commit",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "AX non-settable command-tail selection"
            )
        ),
        ToggleCaseReplacement(
            originalText: "commit",
            toggledText: "COMMIT",
            undoMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
            trackedTailAfterReplacement: "git COMMIT"
        ),
        "toggle-case policy records terminal tail replacement for undo"
    )

    try expectNil(
        ToggleCasePolicy.replacement(
            for: CapturedText(text: "", replacementMethod: .accessibilitySelection, source: "empty")
        ),
        "toggle-case policy rejects empty capture"
    )

    try expectNil(
        ToggleCasePolicy.replacement(
            for: CapturedText(text: "Hello", replacementMethod: .blocked, source: "blocked")
        ),
        "toggle-case policy rejects blocked capture"
    )
}

func runToggleCaseConversionPolicyTests() throws {
    let axCapture = CapturedText(
        text: "Hello",
        replacementMethod: .accessibilitySelection,
        source: "AX editable selection"
    )
    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: axCapture),
        .capturedText(
            capture: axCapture,
            replacement: ToggleCaseReplacement(
                originalText: "Hello",
                toggledText: "hELLO",
                undoMethod: .accessibilitySelection,
                trackedTailAfterReplacement: nil
            )
        ),
        "toggle-case conversion policy plans editable selected text"
    )

    let tailCapture = CapturedText(
        text: "commit",
        replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
        source: "AX non-settable command-tail selection"
    )
    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: tailCapture),
        .capturedText(
            capture: tailCapture,
            replacement: ToggleCaseReplacement(
                originalText: "commit",
                toggledText: "COMMIT",
                undoMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
                trackedTailAfterReplacement: "git COMMIT"
            )
        ),
        "toggle-case conversion policy plans terminal-tail selected text"
    )

    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: CapturedText(
            text: "Hello",
            replacementMethod: .blocked,
            source: "unsafe stale clipboard fallback"
        )),
        .blockedCapture(CapturedText(
            text: "Hello",
            replacementMethod: .blocked,
            source: "unsafe stale clipboard fallback"
        )),
        "toggle-case conversion policy blocks unsafe capture"
    )
    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: CapturedText(
            text: "",
            replacementMethod: .accessibilitySelection,
            source: "empty selection"
        )),
        .noText,
        "toggle-case conversion policy reports empty capture as no text"
    )
    try expect(
        ToggleCaseConversionPolicy.plan(capturedText: nil),
        .noText,
        "toggle-case conversion policy reports nil capture as no text"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(
            from: ToggleCaseConversionPolicy.plan(capturedText: axCapture)
        ),
        .replace(ToggleCaseReplacementRuntimePlan(
            capturedText: axCapture,
            replacement: ToggleCaseReplacement(
                originalText: "Hello",
                toggledText: "hELLO",
                undoMethod: .accessibilitySelection,
                trackedTailAfterReplacement: nil
            ),
            logMessage: "Toggling case for captured text: 'Hello'",
            keepSelection: true,
            failedReplacementLogMessage: "Toggle case replacement aborted",
            failedReplacementMethod: .accessibilitySelection,
            commitPlan: TextReplacementCommitPlan(
                trackedTailCommit: nil,
                layoutSwitchCommit: nil,
                soundFeedbackEvent: .toggleCase,
                productStatisticsEvent: nil,
                conversionRecordCommit: ConversionRecordCommit(
                    originalText: "Hello",
                    convertedText: "hELLO",
                    replacementMethod: .accessibilitySelection,
                    origin: .toggleCase
                )
            )
        )),
        "toggle-case runtime policy plans editable replacement execution and commit"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(
            from: ToggleCaseConversionPolicy.plan(capturedText: tailCapture)
        ),
        .replace(ToggleCaseReplacementRuntimePlan(
            capturedText: tailCapture,
            replacement: ToggleCaseReplacement(
                originalText: "commit",
                toggledText: "COMMIT",
                undoMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
                trackedTailAfterReplacement: "git COMMIT"
            ),
            logMessage: "Toggling case for captured text: 'commit'",
            keepSelection: false,
            failedReplacementLogMessage: "Toggle case replacement aborted",
            failedReplacementMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
            commitPlan: TextReplacementCommitPlan(
                trackedTailCommit: TrackedTailCommit(text: "git COMMIT", reason: "toggle-case completed"),
                layoutSwitchCommit: nil,
                soundFeedbackEvent: .toggleCase,
                productStatisticsEvent: nil,
                conversionRecordCommit: ConversionRecordCommit(
                    originalText: "commit",
                    convertedText: "COMMIT",
                    replacementMethod: .keyboardRewriteTail(originalTail: "git COMMIT"),
                    origin: .toggleCase
                )
            )
        )),
        "toggle-case runtime policy plans terminal-tail replay and undo record"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(from: .blockedCapture(CapturedText(
            text: "Hello",
            replacementMethod: .blocked,
            source: "unsafe stale clipboard fallback"
        ))),
        .blockedCapture(
            capturedText: CapturedText(
                text: "Hello",
                replacementMethod: .blocked,
                source: "unsafe stale clipboard fallback"
            ),
            logMessage: "Toggle case blocked unsafe selection fallback: unsafe stale clipboard fallback"
        ),
        "toggle-case runtime policy preserves blocked-capture cleanup log"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(from: .skipped(reason: "replacement unavailable")),
        .skipped(logMessage: "Toggle case aborted: replacement plan could not be derived"),
        "toggle-case runtime policy owns skipped log"
    )

    try expect(
        ToggleCaseConversionPolicy.runtimePlan(from: .noText),
        .noText(logMessage: "Toggle case: no selected text"),
        "toggle-case runtime policy owns no-text log"
    )
}

func runAutoCorrectionEngineTests() throws {
    let engine = AutoCorrectionEngine(rules: [
        AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"),
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive)
    ])

    try expect(engine.correction(for: "ghbdtn")?.replacement, "привет", "auto-correction exact rule")
    try expect(engine.correction(for: "Teh")?.replacement, "The", "auto-correction preserves title case")
    try expect(engine.correction(for: "TEH")?.replacement, "THE", "auto-correction preserves uppercase")
    try expect(engine.correction(for: "tEh")?.replacement, "tHe", "auto-correction preserves mixed case by position")
    try expectNil(engine.correction(for: "unknown"), "auto-correction ignores unknown word")

    let symbolRuleEngine = AutoCorrectionEngine(rules: [
        AutoCorrectionRule(trigger: "404", replacement: "not found", matchMode: .caseInsensitive),
        AutoCorrectionRule(trigger: "++", replacement: "increment", matchMode: .caseInsensitive)
    ])
    try expect(
        symbolRuleEngine.correction(for: "404")?.replacement,
        "not found",
        "auto-correction does not uppercase replacement for numeric trigger"
    )
    try expect(
        symbolRuleEngine.correction(for: "++")?.replacement,
        "increment",
        "auto-correction does not uppercase replacement for symbol trigger"
    )

    let normalizedRuleEngine = AutoCorrectionEngine(rules: [
        AutoCorrectionRule(trigger: " ghbdtn ", replacement: " привет\n"),
        AutoCorrectionRule(trigger: " Teh ", replacement: " the ", matchMode: .caseInsensitive)
    ])
    try expect(
        normalizedRuleEngine.correction(for: "ghbdtn")?.replacement,
        "привет",
        "auto-correction trims exact user rule fields"
    )
    try expect(
        normalizedRuleEngine.correction(for: "TEH")?.replacement,
        "THE",
        "auto-correction trims case-insensitive user rule fields"
    )

    let tracker = WordTracker()
    type("ghbdtn ", into: tracker)
    try expect(tracker.consumeCompletedToken(), WordTracker.CompletedToken(word: "ghbdtn", separator: " "), "word tracker exposes completed space token")
    try expectNil(tracker.consumeCompletedToken(), "word tracker consumes completed token once")

    type("teh", into: tracker)
    tracker.trackKeyPress(keyCode: 36, characters: "\r")
    try expect(tracker.consumeCompletedToken(), WordTracker.CompletedToken(word: "teh", separator: "\n"), "word tracker exposes completed return token")
}

func runAutoCorrectionPreflightPolicyTests() throws {
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "auto-correction preflight allows eligible completed token"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: "\n",
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "auto-correction on Enter/Tab disabled"),
        "auto-correction preflight consumes Return token when Enter/Tab correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: "\t",
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "auto-correction on Enter/Tab disabled"),
        "auto-correction preflight consumes Tab token when Enter/Tab correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: " ",
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "auto-correction preflight still allows Space token when Enter/Tab correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: " ",
            isCompletedTokenAutoCorrectionSuppressed: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "completed token auto-correction cancelled"),
        "auto-correction preflight consumes edited-token cancellation"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: false,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "Punto disabled"),
        "auto-correction preflight consumes token when Punto is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "auto-correction disabled"),
        "auto-correction preflight consumes token when auto-correction is disabled"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: true,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "conversion in progress"),
        "auto-correction preflight consumes token during conversion window"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: true,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .consumeTokenAndSkip(reason: "current app disabled"),
        "auto-correction preflight consumes token for disabled app"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "no completed token"),
        "auto-correction preflight skips without token"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: true,
            isPasswordField: false
        ),
        .blockAndClear(reason: "secure input"),
        "auto-correction preflight clears state for secure input"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "auto-correction preflight clears state for password field"
    )
    try expect(
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "auto-correction preflight prioritizes secure input"
    )
    try expect(
        AutoCorrectionPreflightPolicy.logMessage(for: .blockAndClear(reason: "password field")),
        "Auto-correction blocked for secure input",
        "auto-correction preflight preserves secure block log"
    )
}

func runAutoCorrectionReplacementPolicyTests() throws {
    let rule = AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    let replacement = AutoCorrectionReplacementPolicy.replacement(
        for: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule),
        completedToken: WordTracker.CompletedToken(word: "ghbdtn", separator: " "),
        trackedTailBeforeCorrection: "say ghbdtn "
    )

    try expect(
        replacement,
        AutoCorrectionReplacement(
            originalText: "ghbdtn ",
            replacementText: "привет ",
            replacementLength: 7,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: "say привет "
        ),
        "auto-correction replacement preserves separator and tracked tail"
    )

    let newlineReplacement = AutoCorrectionReplacementPolicy.replacement(
        for: AutoCorrectionDecision(original: "teh", replacement: "the", rule: rule),
        completedToken: WordTracker.CompletedToken(word: "teh", separator: "\n"),
        trackedTailBeforeCorrection: "teh\n"
    )

    try expect(
        newlineReplacement?.trackedTailAfterReplacement,
        "the\n",
        "auto-correction replacement preserves newline boundary"
    )

    let dashReplacement = AutoCorrectionReplacementPolicy.replacement(
        for: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule),
        completedToken: WordTracker.CompletedToken(word: "ghbdtn", separator: "-"),
        trackedTailBeforeCorrection: "echo ghbdtn-"
    )

    try expect(
        dashReplacement,
        AutoCorrectionReplacement(
            originalText: "ghbdtn-",
            replacementText: "привет-",
            replacementLength: 7,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: "echo привет-"
        ),
        "auto-correction replacement preserves dash suffix boundary"
    )

    let staleTailReplacement = AutoCorrectionReplacementPolicy.replacement(
        for: AutoCorrectionDecision(original: "teh", replacement: "the", rule: rule),
        completedToken: WordTracker.CompletedToken(word: "teh", separator: " "),
        trackedTailBeforeCorrection: "other text "
    )

    try expect(
        staleTailReplacement?.trackedTailAfterReplacement,
        "the ",
        "auto-correction replacement falls back to replacement text for stale tail"
    )

    try expectNil(
        AutoCorrectionReplacementPolicy.replacement(
            for: AutoCorrectionDecision(original: "other", replacement: "the", rule: rule),
            completedToken: WordTracker.CompletedToken(word: "teh", separator: " "),
            trackedTailBeforeCorrection: "teh "
        ),
        "auto-correction replacement rejects mismatched token and decision"
    )

    try expectNil(
        AutoCorrectionReplacementPolicy.replacement(
            for: AutoCorrectionDecision(original: "teh", replacement: "the", rule: rule),
            completedToken: WordTracker.CompletedToken(word: "teh", separator: ""),
            trackedTailBeforeCorrection: "teh"
        ),
        "auto-correction replacement rejects missing boundary separator"
    )

    try expect(
        AutoCorrectionReplacementPolicy.shouldClearConversionSessionAfterPlanFailure(),
        true,
        "auto-correction clears stale undo session after replacement plan failure"
    )
}

func runAutoCorrectionRuntimePolicyTests() throws {
    let token = WordTracker.CompletedToken(word: "ghbdtn", separator: " ")
    let suppressedToken = WordTracker.CompletedToken(
        word: "ghbdtn",
        separator: " ",
        isAutoCorrectionSuppressed: true
    )

    try expect(
        AutoCorrectionRuntimePolicy.routePreflightAction(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            token: token
        ),
        .proceed,
        "auto-correction runtime route proceeds for enabled completed token"
    )
    try expect(
        AutoCorrectionRuntimePolicy.routePreflightAction(
            isEnabled: false,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            token: token
        ),
        .consumeTokenAndSkip(reason: "Punto disabled"),
        "auto-correction runtime route consumes token when Punto is disabled"
    )
    try expect(
        AutoCorrectionRuntimePolicy.routePreflightAction(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            token: suppressedToken
        ),
        .consumeTokenAndSkip(reason: "completed token auto-correction cancelled"),
        "auto-correction runtime route consumes suppressed token"
    )
    try expect(
        AutoCorrectionRuntimePolicy.securityPreflightAction(
            token: token,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "auto-correction runtime security blocks password fields"
    )
    try expect(
        AutoCorrectionRuntimePolicy.securityPreflightAction(
            token: token,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "auto-correction runtime security prioritizes secure input"
    )

    let rule = AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    let engine = AutoCorrectionEngine(rules: [rule])
    try expect(
        AutoCorrectionRuntimePolicy.replacementPlan(
            token: token,
            trackedTailBeforeCorrection: "say ghbdtn ",
            engine: engine
        ),
        .replacement(
            decision: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule),
            replacement: AutoCorrectionReplacement(
                originalText: "ghbdtn ",
                replacementText: "привет ",
                replacementLength: 7,
                undoMethod: .keyboardBackspacePaste,
                trackedTailAfterReplacement: "say привет "
            )
        ),
        "auto-correction runtime derives executable replacement plan"
    )
    try expect(
        AutoCorrectionRuntimePolicy.replacementPlan(
            token: WordTracker.CompletedToken(word: "unknown", separator: " "),
            trackedTailBeforeCorrection: "unknown ",
            engine: engine
        ),
        .noCorrection,
        "auto-correction runtime reports no correction without a matching rule"
    )
    try expect(
        AutoCorrectionRuntimePolicy.replacementPlan(
            token: WordTracker.CompletedToken(word: "ghbdtn", separator: ""),
            trackedTailBeforeCorrection: "ghbdtn",
            engine: engine
        ),
        .planFailure(decision: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule)),
        "auto-correction runtime reports plan failure for invalid completed token boundary"
    )

    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed(completedTokenStatisticsEvent: .completedWord, token: token),
        "auto-correction runtime gate proceeds after route and security checks"
    )
    try expect(
        AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
            token: token,
            completedTokenStatisticsEvent: .completedWord,
            trackedTailBeforeCorrection: "say ghbdtn ",
            engine: engine
        ),
        .replacement(
            completedTokenStatisticsEvent: .completedWord,
            logMessage: "Auto-correcting completed word 'ghbdtn' -> 'привет'",
            replacement: AutoCorrectionReplacement(
                originalText: "ghbdtn ",
                replacementText: "привет ",
                replacementLength: 7,
                undoMethod: .keyboardBackspacePaste,
                trackedTailAfterReplacement: "say привет "
            ),
            commitPlan: TextReplacementCommitPlan(
                trackedTailCommit: TrackedTailCommit(text: "say привет ", reason: "auto-correction completed"),
                layoutSwitchCommit: nil,
                soundFeedbackEvent: .autoCorrection,
                productStatisticsEvent: .automaticSwitch,
                conversionRecordCommit: ConversionRecordCommit(
                    originalText: "ghbdtn ",
                    convertedText: "привет ",
                    replacementMethod: .keyboardBackspacePaste,
                    origin: .autoCorrection(rule: rule)
                )
            )
        ),
        "auto-correction runtime attempt includes statistics, log, replacement, and commit plan"
    )
    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: nil,
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipped(completedTokenStatisticsEvent: nil, logMessage: nil),
        "auto-correction runtime gate skips cleanly without completed token"
    )
    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: false,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipped(
            completedTokenStatisticsEvent: .completedWord,
            logMessage: "Auto-correction skipped: Punto disabled"
        ),
        "auto-correction runtime gate consumes completed-token stats when route skips"
    )
    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(
            completedTokenStatisticsEvent: .completedWord,
            reason: "password field",
            logMessage: "Auto-correction blocked for secure input"
        ),
        "auto-correction runtime gate blocks and clears secure/password input before tail lookup"
    )
    try expect(
        AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
            token: WordTracker.CompletedToken(word: "unknown", separator: " "),
            completedTokenStatisticsEvent: .completedWord,
            trackedTailBeforeCorrection: "unknown ",
            engine: engine
        ),
        .noCorrection(completedTokenStatisticsEvent: .completedWord),
        "auto-correction runtime attempt preserves completed-token stats for no-op rule lookup"
    )
    try expect(
        AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
            token: WordTracker.CompletedToken(word: "ghbdtn", separator: ""),
            completedTokenStatisticsEvent: .completedWord,
            trackedTailBeforeCorrection: "ghbdtn",
            engine: engine
        ),
        .planFailure(
            completedTokenStatisticsEvent: .completedWord,
            logMessage: "Auto-correction aborted: replacement plan could not be derived",
            conversionSessionClearReason: "auto-correction plan derivation failed"
        ),
        "auto-correction runtime attempt owns plan-failure cleanup reason"
    )
}

func runAutoCorrectionUndoLearningPolicyTests() throws {
    let undoneRule = AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    let rules = [
        undoneRule,
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive),
        AutoCorrectionRule(trigger: "gjrf", replacement: "пока")
    ]
    let record = ConversionRecord(
        originalText: "ghbdtn ",
        convertedText: "привет ",
        timestamp: Date(timeIntervalSince1970: 100),
        replacementMethod: .keyboardBackspacePaste,
        origin: .autoCorrection(rule: undoneRule)
    )

    let learnedRules = try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: record,
            isUndoLearningEnabled: true
        ),
        [
            AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive),
            AutoCorrectionRule(trigger: "gjrf", replacement: "пока")
        ],
        "auto-correction undo learning removes undone rule"
    )
    guard let learnedRules else {
        throw TestFailure(description: "auto-correction undo learning removes undone rule: expected updated rules")
    }
    let engine = AutoCorrectionEngine(rules: learnedRules)
    try expectNil(engine.correction(for: "ghbdtn"), "auto-correction undo learning suppresses repeated correction")
    try expect(engine.correction(for: "Teh")?.replacement, "The", "auto-correction undo learning keeps unrelated rules")
    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: record,
            isUndoLearningEnabled: false
        ),
        "auto-correction undo learning setting can disable learned rule removal"
    )

    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: ConversionRecord(
                originalText: "hello",
                convertedText: "руддщ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .layoutConversion
            )
        ),
        "auto-correction undo learning ignores manual layout conversion undo"
    )
    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: [AutoCorrectionRule(trigger: "other", replacement: "другое")],
            record: record
        ),
        "auto-correction undo learning ignores already removed rule"
    )

    let preserveCaseVariant = AutoCorrectionRule(
        trigger: "teh",
        replacement: "the",
        matchMode: .caseInsensitive,
        preserveCase: false
    )
    let caseSensitiveRules = [
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive, preserveCase: true),
        preserveCaseVariant
    ]
    try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: caseSensitiveRules,
            record: ConversionRecord(
                originalText: "teh ",
                convertedText: "the ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: AutoCorrectionRule(
                    trigger: "teh",
                    replacement: "the",
                    matchMode: .caseInsensitive,
                    preserveCase: true
                ))
            )
        ),
        [preserveCaseVariant],
        "auto-correction undo learning preserves same trigger rule with different case behavior"
    )
    try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: [
                AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive),
                AutoCorrectionRule(trigger: "other", replacement: "другое")
            ],
            record: ConversionRecord(
                originalText: "TEH ",
                convertedText: "THE ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: AutoCorrectionRule(
                    trigger: "TEH",
                    replacement: "the",
                    matchMode: .caseInsensitive
                ))
            )
        ),
        [AutoCorrectionRule(trigger: "other", replacement: "другое")],
        "auto-correction undo learning matches case-insensitive trigger case-insensitively"
    )
    try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: [
                AutoCorrectionRule(trigger: "Teh", replacement: "The"),
                AutoCorrectionRule(trigger: "teh", replacement: "the")
            ],
            record: ConversionRecord(
                originalText: "Teh ",
                convertedText: "The ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: AutoCorrectionRule(trigger: "Teh", replacement: "The"))
            )
        ),
        [AutoCorrectionRule(trigger: "teh", replacement: "the")],
        "auto-correction undo learning keeps exact trigger case-sensitive"
    )

    try expect(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: [
                AutoCorrectionRule(trigger: " ghbdtn ", replacement: " привет\n"),
                AutoCorrectionRule(trigger: "gjrf", replacement: "пока")
            ],
            record: ConversionRecord(
                originalText: "ghbdtn ",
                convertedText: "привет ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrection(rule: AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"))
            )
        ),
        [AutoCorrectionRule(trigger: "gjrf", replacement: "пока")],
        "auto-correction undo learning matches normalized rule fields"
    )

    try expect(
        AutoCorrectionUndoLearningPolicy.originAfterUndo(record: record),
        .autoCorrectionRedo(rule: undoneRule),
        "auto-correction undo learning preserves auto-correction redo origin"
    )
    try expect(
        AutoCorrectionUndoLearningPolicy.originAfterUndo(record: ConversionRecord(
            originalText: "hello",
            convertedText: "руддщ",
            timestamp: Date(timeIntervalSince1970: 100),
            replacementMethod: .keyboardBackspacePaste,
            origin: .layoutConversion
        )),
        .manualRedo,
        "auto-correction undo learning delegates manual redo origin"
    )
    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: ConversionRecord(
                originalText: "привет ",
                convertedText: "ghbdtn ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .manualRedo
            )
        ),
        "auto-correction undo learning ignores manual redo record"
    )
    try expectNil(
        AutoCorrectionUndoLearningPolicy.learnedRulesAfterUndo(
            rules: rules,
            record: ConversionRecord(
                originalText: "привет ",
                convertedText: "ghbdtn ",
                timestamp: Date(timeIntervalSince1970: 100),
                replacementMethod: .keyboardBackspacePaste,
                origin: .autoCorrectionRedo(rule: undoneRule)
            )
        ),
        "auto-correction undo learning ignores auto-correction redo record"
    )
}

func runAutoCorrectionRuleStoreTests() throws {
    let tsv = """
    # trigger replacement
    ghbdtn\tпривет
    teh\tthe\tcaseInsensitive\ttrue
    invalid-only
    ghbdtn\tздравствуйте
    typo\tfixed\tcaseinsensitive\ttrue
    maybe\tperhaps\tcaseInsensitive\tmaybe
    """

    let importResult = try AutoCorrectionRuleStore.decodeRules(from: Data(tsv.utf8))
    try expect(importResult.rules.count, 2, "rule store parses and deduplicates tsv rules")
    try expect(importResult.rules[0].replacement, "здравствуйте", "rule store last duplicate wins")
    try expect(importResult.rules[1].matchMode, .caseInsensitive, "rule store parses match mode")
    try expect(importResult.skippedLines[4], "invalid-only", "rule store reports malformed line")
    try expect(importResult.skippedLines[6], "typo\tfixed\tcaseinsensitive\ttrue", "rule store reports invalid match mode")
    try expect(importResult.skippedLines[7], "maybe\tperhaps\tcaseInsensitive\tmaybe", "rule store reports invalid preserveCase flag")

    let sparseImport = try AutoCorrectionRuleStore.decodeRules(from: Data("good\tok\n\nbroken-only\nnext\tfine\n".utf8))
    try expect(sparseImport.skippedLines[3], "broken-only", "rule store preserves physical line numbers across blank lines")

    let quotedCommaImport = try AutoCorrectionRuleStore.decodeRules(from: Data("\"cgfcb,j\",спасибо,exact,true\n".utf8))
    try expect(
        quotedCommaImport.rules.first,
        AutoCorrectionRule(trigger: "cgfcb,j", replacement: "спасибо"),
        "rule store parses quoted comma trigger"
    )

    let escapedQuoteImport = try AutoCorrectionRuleStore.decodeRules(from: Data("\"say \"\"hi\"\"\",hello\n".utf8))
    try expect(
        escapedQuoteImport.rules.first,
        AutoCorrectionRule(trigger: "say \"hi\"", replacement: "hello"),
        "rule store parses escaped quotes in quoted csv trigger"
    )

    let malformedCSVImport = try AutoCorrectionRuleStore.decodeRules(from: Data("good,ok\nbad,\"unterminated\nnext,fine\n".utf8))
    try expect(
        malformedCSVImport.skippedLines[2],
        "bad,\"unterminated",
        "rule store reports unterminated quoted csv line"
    )
    try expect(
        malformedCSVImport.rules,
        [
            AutoCorrectionRule(trigger: "good", replacement: "ok"),
            AutoCorrectionRule(trigger: "next", replacement: "fine")
        ],
        "rule store keeps valid csv lines around malformed quoted line"
    )

    let misplacedQuoteImport = try AutoCorrectionRuleStore.decodeRules(from: Data("good,ok\nbad\"quote,value\nnext,fine\n".utf8))
    try expect(
        misplacedQuoteImport.skippedLines[2],
        "bad\"quote,value",
        "rule store reports misplaced csv quote"
    )
    try expect(
        misplacedQuoteImport.rules,
        [
            AutoCorrectionRule(trigger: "good", replacement: "ok"),
            AutoCorrectionRule(trigger: "next", replacement: "fine")
        ],
        "rule store keeps valid csv lines around misplaced quote"
    )

    let jsonData = try AutoCorrectionRuleStore.encodeRules(importResult.rules)
    let jsonResult = try AutoCorrectionRuleStore.decodeRules(from: jsonData)
    try expect(jsonResult.rules, importResult.rules, "rule store json round-trip")
    try expect(
        AutoCorrectionRuleStore.normalizedRules([
            AutoCorrectionRule(trigger: " ", replacement: "ignored"),
            AutoCorrectionRule(trigger: " teh ", replacement: " the ", matchMode: .caseInsensitive),
            AutoCorrectionRule(trigger: "TEH", replacement: "THE", matchMode: .caseInsensitive),
            AutoCorrectionRule(trigger: "empty", replacement: " ")
        ]),
        [AutoCorrectionRule(trigger: "TEH", replacement: "THE", matchMode: .caseInsensitive)],
        "rule store normalizes decoded persisted rules"
    )

    let merged = AutoCorrectionRuleStore.mergedRules(
        existing: [AutoCorrectionRule(trigger: "teh", replacement: "old", matchMode: .caseInsensitive)],
        imported: [AutoCorrectionRule(trigger: "TEH", replacement: "the", matchMode: .caseInsensitive)]
    )
    try expect(merged.count, 1, "rule store merges case-insensitive duplicates")
    try expect(merged[0].replacement, "the", "rule store imported duplicate overrides")

    let legacyRules = LegacyUserRulePolicy.rules(from: [
        [
            "rule_string": " ghbdtn ",
            "rule": " привет ",
            "is_active": NSNumber(value: true),
            "is_regexp": NSNumber(value: false),
            "do_replace": NSNumber(value: true)
        ],
        [
            "string": "teh",
            "rule": "the",
            "isRuleActive": "yes",
            "isRegExp": "no",
            "shouldSwitchLayout": "true"
        ],
        [
            "rule_string": "inactive",
            "rule": "ignored",
            "is_active": NSNumber(value: false)
        ],
        [
            "rule_string": "regexp",
            "rule": "ignored",
            "is_regexp": NSNumber(value: true)
        ],
        [
            "rule_string": "switchOnly",
            "rule": "ignored",
            "do_replace": NSNumber(value: false)
        ]
    ])
    try expect(
        legacyRules,
        [
            AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"),
            AutoCorrectionRule(trigger: "teh", replacement: "the")
        ],
        "legacy user rule policy imports active non-regexp Punto Switcher replacement rules"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.createUserRuleSelector,
        "createUserRule",
        "observed surface preserves user-rule create selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.modifyUserRuleSelector,
        "modifyUserRule",
        "observed surface preserves user-rule modify selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.removeUserRuleWithIndexSelector,
        "removeUserRuleWithIndex:",
        "observed surface preserves user-rule remove selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.addUserRuleSelector,
        "addUserRuleWithString:rule:shouldSwitchLayout:isRuleActive:isRegExp:",
        "observed surface preserves user-rule add selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.modifyUserRuleWithIndexSelector,
        "modifyUserRuleWithIndex:string:rule:shouldSwitchLayout:isRuleActive:isRegExp:",
        "observed surface preserves user-rule indexed modify selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UserRules.showWordAddedTooltipSelector,
        "showWordAddedTooltip:",
        "observed surface preserves user-rule word-added tooltip selector"
    )
    try expect(
        LegacyUserRulePolicy.rules(from: []),
        [],
        "legacy user rule policy preserves observed empty userRulesDictionary as empty"
    )
    try expectNil(
        LegacyUserRulePolicy.rules(from: ["not": "array"]),
        "legacy user rule policy ignores unexpected userRulesDictionary shape"
    )

    let catalogRules = [
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive),
        AutoCorrectionRule(trigger: "", replacement: "missing"),
        AutoCorrectionRule(trigger: "same", replacement: "same"),
        AutoCorrectionRule(trigger: "TEH", replacement: "THE", matchMode: .caseInsensitive),
        AutoCorrectionRule(trigger: "  ghbdtn  ", replacement: "  привет  ")
    ]
    try expect(
        AutoCorrectionRuleCatalog.filteredRuleIndexes(in: catalogRules, query: "the"),
        [0, 3],
        "rule catalog filters by replacement"
    )
    try expect(
        AutoCorrectionRuleCatalog.filteredRuleIndexes(in: catalogRules, query: "привет"),
        [4],
        "rule catalog filters by normalized replacement"
    )
    try expect(
        AutoCorrectionRuleCatalog.filteredRuleIndexes(in: catalogRules, query: "ghbdtn"),
        [4],
        "rule catalog filters by normalized trigger"
    )
    let issues = AutoCorrectionRuleCatalog.validationIssues(for: catalogRules)
    try expect(issues.contains { $0.severity == .error && $0.ruleIndex == 1 }, true, "rule catalog flags empty trigger")
    try expect(issues.contains { $0.severity == .warning && $0.ruleIndex == 2 }, true, "rule catalog warns identical replacement")
    try expect(issues.contains { $0.severity == .warning && $0.ruleIndex == 3 }, true, "rule catalog warns duplicate trigger")
    try expect(AutoCorrectionRuleCatalog.hasBlockingIssues(catalogRules), true, "rule catalog reports blocking issues")
}

func runAutoCorrectionRuleSourcePolicyTests() throws {
    let starterRules = [
        AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    ]
    let persistedRules = [
        AutoCorrectionRule(trigger: "teh", replacement: "the", matchMode: .caseInsensitive)
    ]

    try expect(
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesDefaultConfPath,
        "switcher.use_old_rules",
        "observed surface pins Punto Switcher default-conf old-rules path"
    )
    try expect(
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesAccessor,
        "switcherUseOldRules",
        "observed surface pins Punto Switcher old-rules accessor"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.useOldRulesDefaultConfPath,
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesDefaultConfPath,
        "rule source policy keeps default-conf old-rules path aligned with reverse-audit anchor"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.useOldRulesAccessor,
        PuntoSwitcherObservedSurface.AutoCorrectionRuleSource.useOldRulesAccessor,
        "rule source policy keeps old-rules accessor aligned with reverse-audit anchor"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
            starterRules: starterRules
        ),
        [
            AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет"),
            AutoCorrectionRule(trigger: "custom", replacement: "замена")
        ],
        "rule source policy adds Punto Switcher userRulesDictionary rules to starter catalog"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [],
            starterRules: starterRules
        ),
        starterRules,
        "rule source policy keeps starter catalog when Punto Switcher userRulesDictionary is empty"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [],
            starterRules: starterRules,
            useStarterRules: false
        ),
        [],
        "rule source policy disables starter catalog when switcher.use_old_rules is false"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            legacyUserRules: [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
            starterRules: starterRules,
            useStarterRules: false
        ),
        [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
        "rule source policy keeps user rules when old starter rules are disabled"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: persistedRules,
            legacyUserRules: [AutoCorrectionRule(trigger: "custom", replacement: "замена")],
            starterRules: starterRules
        ),
        persistedRules,
        "rule source policy prefers native saved rules over Punto Switcher userRulesDictionary"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: false,
            persistedRules: nil,
            starterRules: starterRules
        ),
        starterRules,
        "rule source policy uses starter catalog before rules are saved"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: persistedRules,
            starterRules: starterRules
        ),
        persistedRules,
        "rule source policy uses persisted user rules"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: [],
            starterRules: starterRules
        ),
        [],
        "rule source policy preserves intentionally empty persisted rules"
    )
    try expect(
        AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: true,
            persistedRules: nil,
            starterRules: starterRules
        ),
        starterRules,
        "rule source policy falls back to starter catalog for unreadable persisted rules"
    )
}

func runAutoCorrectionStarterCatalogTests() throws {
    let rules = AutoCorrectionStarterCatalog.rules
    try expect(rules.isEmpty, false, "starter catalog is not empty")
    try expect(AutoCorrectionRuleCatalog.hasBlockingIssues(rules), false, "starter catalog has no blocking issues")

    let converter = LayoutConverter()
    for rule in rules.prefix(36) {
        try expect(converter.convert(rule.trigger), rule.replacement, "starter wrong-layout rule \(rule.trigger)")
    }

    let engine = AutoCorrectionEngine(rules: rules)
    try expect(engine.correction(for: "ghbdtn")?.replacement, "привет", "starter catalog fixes wrong-layout привет")
    try expect(engine.correction(for: "cgfcb,j")?.replacement, "спасибо", "starter catalog fixes wrong-layout спасибо")
    try expect(engine.correction(for: "Teh")?.replacement, "The", "starter catalog fixes english typo with title case")
    try expect(engine.correction(for: "ADN")?.replacement, "AND", "starter catalog fixes english typo with uppercase")
}

func runApplicationReturnKeyPolicyTests() throws {
    try expect(
        ApplicationReturnKeyPolicy.legacyResetOnReturnKey,
        "switcher.reset_on_return",
        "return policy owns observed reset-on-return import key"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "org.telegram.desktop",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode
        ),
        true,
        "return policy resets text state on Telegram Return"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "ru.keepcoder.Telegram",
            keyCode: ApplicationReturnKeyPolicy.enterKeyCode
        ),
        true,
        "return policy resets text state on Telegram Enter"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.telegram.client",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode
        ),
        true,
        "return policy resets text state for telegram bundle component"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.apple.TextEdit",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode
        ),
        false,
        "return policy keeps ordinary editors eligible for return auto-correction"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.slack.client",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: [" slack "]
        ),
        true,
        "return policy supports configured reset_on_return bundle components"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.slackclient",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: ["slack"]
        ),
        false,
        "return policy rejects glued configured reset_on_return component"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.slack.client",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: [" "]
        ),
        false,
        "return policy ignores blank configured reset_on_return components"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.nottelegram",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode
        ),
        false,
        "return policy rejects glued telegram suffix"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "org.telegram.desktop",
            keyCode: 49
        ),
        false,
        "return policy ignores non-return keys"
    )
}

func runAccessibilityApplicationPolicyTests() throws {
    try expect(
        AccessibilityApplicationPolicy.browserInjectionBundleIDs,
        PuntoSwitcherObservedSurface.AccessibilityApplications.browserInjectionBundleIDs,
        "accessibility app policy aligns browser injection list to reverse-audit anchor"
    )
    try expect(
        AccessibilityApplicationPolicy.enhancedUserInterfaceBundleIDs,
        PuntoSwitcherObservedSurface.AccessibilityApplications.enhancedUserInterfaceBundleIDs,
        "accessibility app policy aligns enhanced-UI list to reverse-audit anchor"
    )

    for bundleID in [
        "com.apple.Safari",
        "com.google.chrome",
        "com.operasoftware.Opera",
        "org.chromium.chromium",
        "org.mozilla.firefox",
        "ru.yandex.desktop.yandex-browser"
    ] {
        try expect(
            AccessibilityApplicationPolicy.isBrowserInjectionBundleID(bundleID),
            true,
            "accessibility app policy detects observed browser injection bundle \(bundleID)"
        )
    }

    for bundleID in [
        "com.google.chrome",
        "com.operasoftware.Opera",
        "org.chromium.chromium",
        "org.mozilla.firefox",
        "ru.yandex.desktop.yandex-browser"
    ] {
        try expect(
            AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: bundleID),
            true,
            "accessibility app policy enables enhanced UI for observed eui bundle \(bundleID)"
        )
    }

    try expect(
        AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: "com.apple.Safari"),
        false,
        "accessibility app policy keeps Safari out of AXEnhancedUserInterface to match observed eui list"
    )
    try expect(
        AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: " com.google.Chrome "),
        true,
        "accessibility app policy normalizes browser bundle id"
    )
    try expect(
        AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: "com.google.chrome.helper"),
        false,
        "accessibility app policy rejects glued browser bundle suffix"
    )
    try expect(
        AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: nil),
        false,
        "accessibility app policy rejects missing bundle id"
    )
}
