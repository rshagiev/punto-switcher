import Foundation
import PuntoCore

func runClipboardReplacementPolicyTests() throws {
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
        ClipboardReplacementPolicy.shouldAttemptSelectedTextClipboardReplacement(
            focusEvidence: .focusedElement(
                appName: "TextEdit",
                role: "AXTextArea",
                isEnabled: true,
                isFocused: true
            )
        ),
        true,
        "selected-text clipboard replacement accepts a verified focused application and element"
    )
    try expect(
        ClipboardReplacementPolicy.shouldAttemptSelectedTextClipboardReplacement(
            focusEvidence: .noFocusedElement(appName: "Safari", errorCode: -25205)
        ),
        true,
        "selected-text clipboard replacement allows content fallbacks with focused app but no focused element"
    )
    try expect(
        ClipboardReplacementPolicy.shouldAttemptSelectedTextClipboardReplacement(
            focusEvidence: .noFocusedApplication(errorCode: -25212)
        ),
        false,
        "selected-text clipboard replacement rejects NO_FOCUSED_APP evidence before sending Cmd+V"
    )
    try expect(
        ClipboardReplacementPolicy.shouldAttemptSelectedTextClipboardReplacement(
            focusEvidence: .focusedElement(
                appName: "TextEdit",
                role: "AXTextArea",
                isEnabled: false,
                isFocused: true
            )
        ),
        false,
        "selected-text clipboard replacement rejects disabled focused elements"
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
}
