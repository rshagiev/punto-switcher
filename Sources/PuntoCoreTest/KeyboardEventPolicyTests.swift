import Foundation
import PuntoCore

func runKeyboardEventPolicyTests() throws {
    try expect(
        KeyboardEventKeyCodePolicy.pasteKeyCode,
        9,
        "keyboard event key code policy uses V key for paste"
    )
    try expect(
        KeyboardEventKeyCodePolicy.backspaceKeyCode,
        51,
        "keyboard event key code policy uses Backspace for exact tail deletion"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftArrowKeyCode,
        123,
        "keyboard event key code policy uses Left Arrow for reselection"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftCommandKeyCode,
        55,
        "keyboard event key code policy exposes left Command for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.rightCommandKeyCode,
        54,
        "keyboard event key code policy exposes right Command for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftShiftKeyCode,
        56,
        "keyboard event key code policy exposes left Shift for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.rightShiftKeyCode,
        60,
        "keyboard event key code policy exposes right Shift for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftOptionKeyCode,
        58,
        "keyboard event key code policy exposes left Option for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.rightOptionKeyCode,
        61,
        "keyboard event key code policy exposes right Option for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.leftControlKeyCode,
        59,
        "keyboard event key code policy exposes left Control for modifier cleanup"
    )
    try expect(
        KeyboardEventKeyCodePolicy.rightControlKeyCode,
        62,
        "keyboard event key code policy exposes right Control for modifier cleanup"
    )
    try expect(
        KeyDownEventPolicy.copyKeyCode,
        KeyboardEventKeyCodePolicy.copyKeyCode,
        "key down policy shares copy key code policy"
    )
    try expect(
        KeyDownEventPolicy.pasteKeyCode,
        KeyboardEventKeyCodePolicy.pasteKeyCode,
        "key down policy shares paste key code policy"
    )
    try expect(
        KeyDownEventPolicy.deleteKeyCode,
        KeyboardEventKeyCodePolicy.backspaceKeyCode,
        "key down policy shares backspace key code policy"
    )
    try expect(
        WordTrackingPolicy.deleteKeyCode,
        KeyboardEventKeyCodePolicy.backspaceKeyCode,
        "word tracking policy shares backspace key code policy"
    )
    try expect(
        KeyboardEventTimingPolicy.selectionSettleDelay,
        0.02,
        "keyboard event timing policy keeps selection settle delay"
    )
    try expect(
        KeyboardEventTimingPolicy.commandKeyUpDelay,
        0.02,
        "keyboard event timing policy keeps command key-up delay"
    )
}
