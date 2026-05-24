import Foundation
import PuntoCore

func runKeyboardReplacementPolicyTests() throws {
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
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldSelectAfterPaste(true, replacementText: "hello"),
        true,
        "selected-text clipboard replacement reselects non-empty pasted text when requested"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldSelectAfterPaste(false, replacementText: "hello"),
        false,
        "selected-text clipboard replacement skips reselection when not requested"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldSelectAfterPaste(true, replacementText: ""),
        false,
        "selected-text clipboard replacement skips reselection for empty text"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldRestoreClipboardAfterPaste(currentChangeCount: 7, replacementChangeCount: 7),
        true,
        "selected-text clipboard replacement restores unchanged replacement clipboard"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.shouldRestoreClipboardAfterPaste(currentChangeCount: 8, replacementChangeCount: 7),
        false,
        "selected-text clipboard replacement preserves externally changed clipboard"
    )
    try expect(
        ClipboardReplacementPolicy.shouldRestoreClipboardAfterReplacementPaste(
            currentChangeCount: 11,
            replacementChangeCount: 11
        ),
        true,
        "shared clipboard replacement policy restores only while replacement paste remains current"
    )
    try expect(
        ClipboardReplacementPolicy.shouldRestoreClipboardAfterReplacementPaste(
            currentChangeCount: 12,
            replacementChangeCount: 11
        ),
        false,
        "shared clipboard replacement policy preserves externally changed clipboard"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.postPasteDelay,
        0.03,
        "selected-text clipboard replacement preserves post-paste delay"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.selectAfterPasteDelay,
        0.02,
        "selected-text clipboard replacement preserves selection delay"
    )
    try expect(
        SelectedTextClipboardReplacementPolicy.clipboardRestoreDelay,
        ClipboardReplacementPolicy.clipboardRestoreDelay,
        "selected-text clipboard replacement shares clipboard restore delay"
    )
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
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "TextEdit",
                role: "AXTextArea",
                isEnabled: true,
                isFocused: true
            )
        ),
        true,
        "keyboard focus policy accepts typed enabled focused target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "Ghostty",
                role: "AXTextArea",
                isEnabled: true,
                isFocused: false
            )
        ),
        true,
        "keyboard focus policy allows typed enabled target with unreliable focused flag"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "TextEdit",
                role: "AXTextArea",
                isEnabled: false,
                isFocused: true
            )
        ),
        false,
        "keyboard focus policy rejects typed disabled target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "Finder",
                role: "AXButton",
                isEnabled: true,
                isFocused: true
            )
        ),
        false,
        "keyboard focus policy rejects typed non-editable focused role"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "UnknownApp",
                role: nil,
                isEnabled: true,
                isFocused: true
            )
        ),
        true,
        "keyboard focus policy keeps unknown roles eligible"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .noFocusedElement(appName: "TextEdit", errorCode: -25205)
        ),
        false,
        "keyboard focus policy rejects typed missing focused element"
    )
    try expect(
        KeyboardFocusEvidence.focusedElement(
            appName: "TextEdit",
            role: "AXTextArea",
            isEnabled: true,
            isFocused: false
        ).logDescription,
        "app='TextEdit' role='AXTextArea' enabled=true focused=false",
        "keyboard focus evidence preserves legacy log shape"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' role='AXTextArea' enabled=true focused=true"
        ),
        true,
        "keyboard focus policy accepts enabled focused target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='Ghostty' role='AXTextArea' enabled=true focused=false"
        ),
        true,
        "keyboard focus policy allows enabled target with unreliable focused flag"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' role='AXTextArea' enabled=false focused=true"
        ),
        false,
        "keyboard focus policy rejects disabled target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='Finder' role='AXButton' enabled=true focused=true"
        ),
        false,
        "keyboard focus policy rejects non-editable focused role"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='UnknownApp' role='?' enabled=true focused=true"
        ),
        true,
        "keyboard focus policy preserves unknown string role eligibility"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' NO_FOCUSED_ELEMENT (error=-25205)"
        ),
        false,
        "keyboard focus policy rejects missing focused element"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(focusDescription: "  "),
        false,
        "keyboard focus policy rejects empty focus evidence"
    )
}

func runTextReplacementPolicyTests() throws {
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .keyboardBackspacePaste),
        ReplacementFailureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "failed keyboard replacement",
            clearConversionSessionReason: "failed keyboard replacement"
        ),
        "replacement failure action clears tracked text and undo after failed keyboard replacement"
    )
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        ReplacementFailureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "failed keyboard replacement",
            clearConversionSessionReason: "failed keyboard replacement"
        ),
        "replacement failure action clears tracked text and undo after failed terminal-tail replacement"
    )
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .accessibilitySelection),
        ReplacementFailureAction(clearTrackedText: false, clearConversionSession: false),
        "replacement failure action preserves state after failed AX replacement"
    )
    try expect(
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: .blocked),
        ReplacementFailureAction(clearTrackedText: false, clearConversionSession: false),
        "replacement failure action ignores blocked plans"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .keyboardBackspacePaste),
        true,
        "replacement failure policy clears tracked text after failed keyboard replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        true,
        "replacement failure policy clears tracked text after failed terminal-tail replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .accessibilitySelection),
        false,
        "replacement failure policy keeps tracked text after failed AX selection replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearTrackedTextAfterFailedReplacement(method: .blocked),
        false,
        "replacement failure policy ignores blocked replacement plans"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .keyboardBackspacePaste),
        true,
        "replacement failure policy clears undo session after failed keyboard replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .keyboardRewriteTail(originalTail: "git commit")),
        true,
        "replacement failure policy clears undo session after failed terminal-tail replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .accessibilitySelection),
        false,
        "replacement failure policy keeps undo session after failed AX selection replacement"
    )
    try expect(
        ReplacementFailurePolicy.shouldClearConversionSessionAfterFailedReplacement(method: .blocked),
        false,
        "replacement failure policy keeps undo session for blocked plans"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "hello",
                replacementMethod: .accessibilitySelection,
                source: "AX editable selection"
            ),
            replacement: "привет",
            keepSelection: true
        ),
        .accessibilitySelection(text: "привет", keepSelection: true),
        "replacement policy keeps AX selection replacement as AX plan"
    )
    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "browser selection",
                replacementMethod: .accessibilitySelection,
                source: "active clipboard fallback",
                selectedTextReplacementTransport: .clipboard
            ),
            replacement: "браузер",
            keepSelection: true
        ),
        .clipboardSelection(text: "браузер", selectAfterPaste: true),
        "replacement policy routes clipboard selected-text capture directly to clipboard plan"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "hello",
                replacementMethod: .keyboardBackspacePaste,
                source: "passive clipboard tail selection"
            ),
            replacement: "привет",
            keepSelection: true
        ),
        .keyboardBackspacePaste(deleteLength: 5, text: "привет"),
        "replacement policy uses captured length for keyboard replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "",
                replacementMethod: .keyboardBackspacePaste,
                source: "empty keyboard capture"
            ),
            replacement: "привет",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks empty keyboard replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "commit",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "AX non-settable command-tail selection"
            ),
            replacement: "COMMIT",
            keepSelection: false
        ),
        .keyboardBackspacePaste(deleteLength: 10, text: "git COMMIT"),
        "replacement policy rewrites full terminal tail before keyboard replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "missing",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "stale tail"
            ),
            replacement: "MISSING",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks unrewritable terminal tail"
    )
    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(
                text: "mit",
                replacementMethod: .keyboardRewriteTail(originalTail: "git commit"),
                source: "stale tail"
            ),
            replacement: "ьше",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks partial-word terminal tail replacement"
    )

    try expect(
        TextReplacementPolicy.plan(
            for: CapturedText(text: "", replacementMethod: .blocked, source: "blocked"),
            replacement: "ignored",
            keepSelection: false
        ),
        .blocked,
        "replacement policy blocks unsafe capture"
    )
}

func runAccessibilityReplacementPolicyTests() throws {
    try expect(
        AccessibilityReplacementPolicy.selectedTextVerificationDelay,
        0.05,
        "AX replacement policy keeps selected text verification delay"
    )
    try expect(
        AccessibilityReplacementPolicy.focusedApplicationRetryAttempts,
        3,
        "AX replacement policy keeps focused application retry attempts"
    )
    try expect(
        AccessibilityReplacementPolicy.focusedApplicationRetryDelay,
        0.05,
        "AX replacement policy keeps focused application retry delay"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: false,
            originalSelectedText: "hello",
            observedSelectedText: "руддщ",
            replacement: "руддщ"
        ),
        false,
        "AX replacement policy rejects failed set call"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: "hello",
            replacement: "руддщ"
        ),
        false,
        "AX replacement policy rejects silent no-op"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: "руддщ",
            replacement: "руддщ"
        ),
        true,
        "AX replacement policy accepts observed replacement"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: nil,
            replacement: "руддщ"
        ),
        true,
        "AX replacement policy accepts deselected changed state"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: nil,
            observedSelectedText: nil,
            replacement: "руддщ"
        ),
        false,
        "AX replacement policy rejects success without before or after text evidence"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: true,
            originalSelectedText: "hello",
            observedSelectedText: "hello",
            replacement: "hello"
        ),
        true,
        "AX replacement policy accepts idempotent replacement"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: 1),
        true,
        "AX replacement policy retries before final focused application attempt"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: 2),
        true,
        "AX replacement policy retries on penultimate focused application attempt"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: 3),
        false,
        "AX replacement policy does not sleep after final focused application attempt"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldReadOriginalSelectionRange(keepSelection: true),
        true,
        "AX replacement policy reads original selection range only when selection should be retained"
    )
    try expect(
        AccessibilityReplacementPolicy.shouldReadOriginalSelectionRange(keepSelection: false),
        false,
        "AX replacement policy skips original selection range when selection retention is not needed"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: 4, length: 5),
        4,
        "AX replacement policy accepts valid original selection range location"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: 4, length: 0),
        4,
        "AX replacement policy accepts collapsed valid selection range location"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: -1, length: 5),
        nil,
        "AX replacement policy rejects negative original selection location"
    )
    try expect(
        AccessibilityReplacementPolicy.originalSelectionLocation(location: 4, length: -1),
        nil,
        "AX replacement policy rejects negative original selection length"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: 4,
            replacement: "руддщ",
            keepSelection: true
        ),
        AccessibilityReplacementPolicy.SelectionRange(location: 4, length: 5),
        "AX replacement policy reselects replacement at original selection location"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: 4,
            replacement: "a😀",
            keepSelection: true
        ),
        AccessibilityReplacementPolicy.SelectionRange(location: 4, length: 3),
        "AX replacement policy uses UTF-16 length for AX selection range"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: nil,
            replacement: "руддщ",
            keepSelection: true
        ),
        nil,
        "AX replacement policy does not guess a selection location when AX range is unavailable"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: 4,
            replacement: "руддщ",
            keepSelection: false
        ),
        nil,
        "AX replacement policy skips reselection when selection retention is disabled"
    )
    try expect(
        AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: -1,
            replacement: "руддщ",
            keepSelection: true
        ),
        nil,
        "AX replacement policy rejects invalid negative selection locations"
    )
}
