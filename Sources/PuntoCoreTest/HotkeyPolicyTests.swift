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
    try expect(
        HotkeyCommandPolicy.displayOrder,
        [
            HotkeyCommandMetadata(
                slot: .convertLayout,
                title: "Convert Layout",
                systemName: "textformat.abc",
                resetTag: 0,
                defaultHotkey: .defaultConvertLayout,
                routingKind: .convertLayout,
                keyDownAction: .convertLayoutHotkey
            ),
            HotkeyCommandMetadata(
                slot: .toggleCase,
                title: "Toggle Case",
                systemName: "textformat",
                resetTag: 1,
                defaultHotkey: .defaultToggleCase,
                routingKind: .toggleCase,
                keyDownAction: .toggleCaseHotkey
            ),
            HotkeyCommandMetadata(
                slot: .toggleAutoCorrection,
                title: "Toggle Auto-correction",
                systemName: "wand.and.stars",
                resetTag: 2,
                defaultHotkey: .defaultToggleAutoCorrection,
                routingKind: .toggleAutoCorrection,
                keyDownAction: .toggleAutoCorrectionHotkey
            ),
            HotkeyCommandMetadata(
                slot: .cancelLayoutChange,
                title: "Cancel Last Conversion",
                systemName: "arrow.uturn.backward",
                resetTag: 3,
                defaultHotkey: .defaultCancelLayoutChange,
                routingKind: .cancelLayoutChange,
                keyDownAction: .cancelLayoutChangeHotkey
            ),
            HotkeyCommandMetadata(
                slot: .findInYandex,
                title: "Find in Yandex",
                systemName: "magnifyingglass",
                resetTag: 4,
                defaultHotkey: .defaultFindInYandex,
                routingKind: .findInYandex,
                keyDownAction: .findInYandexHotkey
            ),
            HotkeyCommandMetadata(
                slot: .findInSlovari,
                title: "Find in Translate",
                systemName: "character.book.closed",
                resetTag: 5,
                defaultHotkey: .defaultFindInSlovari,
                routingKind: .findInSlovari,
                keyDownAction: .findInSlovariHotkey
            )
        ],
        "hotkey command policy owns settings display order, defaults, routing, and keyDown actions"
    )
    try expect(
        HotkeyCommandPolicy.displayOrder.map(\.slot),
        HotkeySlot.allCases,
        "hotkey command policy lists every supported hotkey slot in UI order"
    )
    try expect(
        Set(HotkeyCommandPolicy.displayOrder.map(\.resetTag)).count,
        HotkeyCommandPolicy.displayOrder.count,
        "hotkey command policy reset tags are unique"
    )
    try expect(
        HotkeyCommandPolicy.defaultHotkey(for: .toggleCase),
        .defaultToggleCase,
        "hotkey command policy resolves default hotkeys by slot"
    )
    try expect(
        HotkeyCommandPolicy.slot(forResetTag: 4),
        .findInYandex,
        "hotkey command policy resolves reset tags back to slots"
    )
    try expectNil(
        HotkeyCommandPolicy.slot(forResetTag: 99),
        "hotkey command policy rejects unknown reset tags"
    )

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
        LegacyHotkeyPolicy.legacyNoKeyCode,
        UInt16(PuntoSwitcherObservedSurface.Hotkeys.noKeyCode),
        "legacy hotkey policy keeps no-key sentinel aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyKeyCodeKey,
        PuntoSwitcherObservedSurface.Hotkeys.keyCodeKey,
        "legacy hotkey policy keeps charKeycode field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyCommandKey,
        PuntoSwitcherObservedSurface.Hotkeys.commandKey,
        "legacy hotkey policy keeps command modifier field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyOptionKey,
        PuntoSwitcherObservedSurface.Hotkeys.optionKey,
        "legacy hotkey policy keeps option modifier field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyShiftKey,
        PuntoSwitcherObservedSurface.Hotkeys.shiftKey,
        "legacy hotkey policy keeps shift modifier field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.legacyControlKey,
        PuntoSwitcherObservedSurface.Hotkeys.controlKey,
        "legacy hotkey policy keeps control modifier field aligned with reverse-audit anchor"
    )
    try expect(
        LegacyHotkeyPolicy.hotkey(from: [
            LegacyHotkeyPolicy.legacyKeyCodeKey: 6,
            LegacyHotkeyPolicy.legacyCommandKey: true,
            LegacyHotkeyPolicy.legacyOptionKey: NSNumber(value: true),
            LegacyHotkeyPolicy.legacyShiftKey: false,
            LegacyHotkeyPolicy.legacyControlKey: false
        ]),
        Hotkey.defaultToggleCase,
        "legacy hotkey policy reads Punto Switcher shortcut dictionaries"
    )
    try expect(
        LegacyHotkeyPolicy.hotkey(from: [
            LegacyHotkeyPolicy.legacyKeyCodeKey: " 6 ",
            LegacyHotkeyPolicy.legacyCommandKey: "yes",
            LegacyHotkeyPolicy.legacyOptionKey: "0",
            LegacyHotkeyPolicy.legacyShiftKey: "true",
            LegacyHotkeyPolicy.legacyControlKey: "off"
        ]),
        Hotkey(keyCode: 6, command: true, option: false, shift: true, control: false),
        "legacy hotkey policy reads string-backed shortcut dictionaries"
    )
    try expect(
        LegacyHotkeyPolicy.hotkey(from: [
            LegacyHotkeyPolicy.legacyKeyCodeKey: LegacyHotkeyPolicy.legacyNoKeyCode,
            LegacyHotkeyPolicy.legacyCommandKey: true,
            LegacyHotkeyPolicy.legacyOptionKey: true,
            LegacyHotkeyPolicy.legacyShiftKey: true,
            LegacyHotkeyPolicy.legacyControlKey: false
        ]),
        Hotkey.defaultConvertLayout,
        "legacy hotkey policy maps Punto Switcher no-key shortcut to modifier-only hotkey"
    )
    try expect(
        LegacyHotkeyPolicy.hotkey(from: [
            LegacyHotkeyPolicy.legacyKeyCodeKey: LegacyHotkeyPolicy.legacyNoKeyCode,
            LegacyHotkeyPolicy.legacyCommandKey: false,
            LegacyHotkeyPolicy.legacyOptionKey: false,
            LegacyHotkeyPolicy.legacyShiftKey: false,
            LegacyHotkeyPolicy.legacyControlKey: false
        ]),
        Hotkey.disabled,
        "legacy hotkey policy maps Punto Switcher no-key/no-modifier shortcut to disabled"
    )
    try expect(
        LegacyHotkeyPolicy.normalized([
            LegacyHotkeyPolicy.legacyKeyCodeKey: LegacyHotkeyPolicy.legacyNoKeyCode,
            LegacyHotkeyPolicy.legacyCommandKey: true,
            LegacyHotkeyPolicy.legacyOptionKey: false,
            LegacyHotkeyPolicy.legacyShiftKey: false,
            LegacyHotkeyPolicy.legacyControlKey: false
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

    let assignments = HotkeyCommandPolicy.displayOrder.map {
        HotkeyAssignment(slot: $0.slot, hotkey: $0.defaultHotkey)
    }
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

    let hotkey = Hotkey.defaultConvertLayout
    let pressed = ModifierFlagsSnapshot(command: true, option: true, shift: true, control: false)
    let released = ModifierFlagsSnapshot(command: false, option: false, shift: false, control: false)
    let partial = ModifierFlagsSnapshot(command: true, option: true, shift: false, control: false)
    let singleModifier = ModifierFlagsSnapshot(command: true, option: false, shift: false, control: false)
    let extra = ModifierFlagsSnapshot(command: true, option: true, shift: true, control: true)
    let commandOption = ModifierFlagsSnapshot(command: true, option: true, shift: false, control: false)
    let now = Date(timeIntervalSince1970: 100)

    let recordingMachine = HotkeyRecordingStateMachine()
    try expect(
        recordingMachine.handleFlagsChanged(flags: pressed),
        .previewModifierOnly(Hotkey.defaultConvertLayout),
        "hotkey recording policy previews modifier-only shortcuts when two or more modifiers are held"
    )
    try expect(
        recordingMachine.handleFlagsChanged(flags: singleModifier),
        .none,
        "hotkey recording policy waits for full modifier release before recording"
    )
    try expect(
        recordingMachine.handleFlagsChanged(flags: released),
        .record(Hotkey.defaultConvertLayout),
        "hotkey recording policy records modifier-only shortcut after full release"
    )
    try expect(
        HotkeyRecordingStateMachine().handleKeyDown(keyCode: 6, flags: commandOption),
        .record(Hotkey.defaultToggleCase),
        "hotkey recording policy records key-based shortcuts"
    )
    try expect(
        HotkeyRecordingStateMachine().handleKeyDown(keyCode: KeyDownEventPolicy.escapeKeyCode, flags: commandOption),
        .cancel,
        "hotkey recording policy cancels on Escape"
    )
    try expect(
        HotkeyRecordingStateMachine().handleKeyDown(keyCode: 55, flags: commandOption),
        .reject,
        "hotkey recording policy rejects modifier keycodes as shortcut keys"
    )
    try expect(
        HotkeyRecordingStateMachine().handleKeyDown(keyCode: 0, flags: ModifierFlagsSnapshot(command: false, option: false, shift: true, control: false)),
        .passThrough,
        "hotkey recording policy lets plain shifted text input pass through"
    )

    let machine = ModifierOnlyHotkeyStateMachine(debounceInterval: 0.5)
    try expect(
        ModifierOnlyHotkeyStateMachine.actionDelay,
        0.15,
        "modifier-only hotkey action is delayed until real HID modifiers settle"
    )

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
