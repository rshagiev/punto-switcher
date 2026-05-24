import Foundation
import PuntoCore

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
