import Foundation
import PuntoCore

func runKeyboardReplacementPolicyTests() throws {
    try expect(
        KeyboardReplacementPolicy.shouldAttemptKeyboardReplacement(deleteLength: 1),
        true,
        "keyboard replacement attempts positive delete length"
    )
    try expect(
        KeyboardReplacementPolicy.shouldAttemptKeyboardReplacement(deleteLength: 0),
        false,
        "keyboard replacement rejects zero delete length before events"
    )
    try expect(
        KeyboardReplacementPolicy.shouldAttemptKeyboardReplacement(deleteLength: -1),
        false,
        "keyboard replacement rejects negative delete length before events"
    )
    try expect(
        KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: 6, sentCount: 6),
        true,
        "keyboard replacement proceeds after complete backspace sequence"
    )
    try expect(
        KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: 6, sentCount: 5),
        false,
        "keyboard replacement aborts after partial backspace sequence"
    )
    try expect(
        KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: 0, sentCount: 0),
        false,
        "keyboard replacement rejects zero-length delete before paste"
    )
    try expect(
        KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: -1, sentCount: -1),
        false,
        "keyboard replacement rejects invalid negative counts"
    )
    try expect(
        KeyboardReplacementPolicy.shouldRestoreClipboardAfterPaste(currentChangeCount: 42, replacementChangeCount: 42),
        true,
        "keyboard replacement restores clipboard when replacement remains current"
    )
    try expect(
        KeyboardReplacementPolicy.shouldRestoreClipboardAfterPaste(currentChangeCount: 43, replacementChangeCount: 42),
        false,
        "keyboard replacement keeps clipboard when another app changed it after paste"
    )
    try expect(
        KeyboardReplacementPolicy.modifierReleaseSettleDelay,
        0.05,
        "keyboard replacement preserves modifier release settle delay"
    )
    try expect(
        KeyboardReplacementPolicy.modifierReleaseMaxWait,
        0.35,
        "keyboard replacement waits briefly for real HID modifier release before destructive keys"
    )
    try expect(
        KeyboardReplacementPolicy.modifierReleasePollInterval,
        0.01,
        "keyboard replacement polls modifier release at short intervals"
    )
    try expect(
        KeyboardReplacementPolicy.shouldStartKeyboardEventsAfterModifierWait(modifiersArePressed: false),
        true,
        "keyboard replacement starts destructive events when modifiers are released"
    )
    try expect(
        KeyboardReplacementPolicy.shouldStartKeyboardEventsAfterModifierWait(modifiersArePressed: true),
        false,
        "keyboard replacement refuses destructive events while modifiers remain pressed"
    )
    try expect(
        KeyboardModifierCleanupPolicy.shouldPostCleanup(
            for: ModifierFlagsSnapshot(command: false, option: false, shift: false, control: false)
        ),
        false,
        "keyboard modifier cleanup skips empty modifier state"
    )
    try expect(
        KeyboardModifierCleanupPolicy.description(
            for: ModifierFlagsSnapshot(command: false, option: false, shift: false, control: false)
        ),
        "none",
        "keyboard modifier cleanup describes empty modifier state"
    )
    try expect(
        KeyboardModifierCleanupPolicy.description(
            for: ModifierFlagsSnapshot(command: true, option: true, shift: true, control: true)
        ),
        "⌘⌥⇧⌃",
        "keyboard modifier cleanup describes latched modifiers in stable order"
    )
    try expect(
        KeyboardModifierCleanupPolicy.keyUpCodes(
            for: ModifierFlagsSnapshot(command: true, option: false, shift: false, control: false)
        ),
        [
            KeyboardEventKeyCodePolicy.leftCommandKeyCode,
            KeyboardEventKeyCodePolicy.rightCommandKeyCode
        ],
        "keyboard modifier cleanup releases both Command keys for a latched Command flag"
    )
    try expect(
        KeyboardModifierCleanupPolicy.keyUpCodes(
            for: ModifierFlagsSnapshot(command: false, option: true, shift: true, control: true)
        ),
        [
            KeyboardEventKeyCodePolicy.leftOptionKeyCode,
            KeyboardEventKeyCodePolicy.rightOptionKeyCode,
            KeyboardEventKeyCodePolicy.leftShiftKeyCode,
            KeyboardEventKeyCodePolicy.rightShiftKeyCode,
            KeyboardEventKeyCodePolicy.leftControlKeyCode,
            KeyboardEventKeyCodePolicy.rightControlKeyCode
        ],
        "keyboard modifier cleanup releases all latched non-command modifier sides in stable order"
    )
    try expect(
        KeyboardReplacementPolicy.backspaceInterval,
        0.02,
        "keyboard replacement preserves backspace interval"
    )
    try expect(
        KeyboardReplacementPolicy.prePasteDelay,
        0.02,
        "keyboard replacement preserves pre-paste delay"
    )
    try expect(
        KeyboardReplacementPolicy.postPasteDelay,
        0.03,
        "keyboard replacement preserves post-paste delay"
    )
    try expect(
        KeyboardReplacementPolicy.clipboardRestoreDelay,
        ClipboardReplacementPolicy.clipboardRestoreDelay,
        "keyboard replacement shares async clipboard restore delay"
    )
}
