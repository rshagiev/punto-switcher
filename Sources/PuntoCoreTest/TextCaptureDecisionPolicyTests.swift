import Foundation
import PuntoCore

func runTextCaptureDecisionPolicyTests() throws {
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("hello", replacementSupported: true),
            activeClipboardText: nil,
            passiveClipboardText: nil,
            lastTrackedWord: nil,
            lastTrackedTail: nil
        ),
        CapturedText(text: "hello", replacementMethod: .accessibilitySelection, source: "AX editable selection"),
        "capture policy accepts editable AX selection"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("commit", replacementSupported: false),
            activeClipboardText: nil,
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "AX non-settable command-tail selection"),
        "capture policy rewrites non-settable AX command tail"
    )
    let terminalToggleCapture = try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("hello", replacementSupported: false),
            activeClipboardText: nil,
            passiveClipboardText: nil,
            lastTrackedWord: "hello",
            lastTrackedTail: "git hello"
        ),
        CapturedText(text: "hello", replacementMethod: .keyboardRewriteTail(originalTail: "git hello"), source: "AX non-settable command-tail selection"),
        "capture policy supports terminal tail capture for toggle-case"
    )
    guard let terminalToggleCapture else {
        throw TestFailure(description: "capture policy supports terminal tail capture for toggle-case: expected non-nil capture")
    }
    try expect(
        TextReplacementPolicy.trackedTailAfterReplacement(
            capturedText: terminalToggleCapture.text,
            replacement: CaseConverter.toggleCase(terminalToggleCapture.text),
            method: terminalToggleCapture.replacementMethod
        ),
        "git HELLO",
        "capture policy updates terminal tail after toggle-case replacement"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("user@host % git commit\n", replacementSupported: false),
            activeClipboardText: nil,
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "AX non-settable command-tail selection"),
        "capture policy extracts prompt-prefixed AX command tail"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("old scrollback", replacementSupported: false),
            activeClipboardText: "git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "clipboard command-tail selection"),
        "capture policy uses active clipboard command tail after non-settable AX mismatch"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("old scrollback", replacementSupported: false),
            activeClipboardText: nil,
            passiveClipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardBackspacePaste, source: "passive clipboard tail selection"),
        "capture policy accepts passive clipboard command tail"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .selectedText("old scrollback", replacementSupported: false),
            activeClipboardText: "prompt % old",
            passiveClipboardText: "prompt % old",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "", replacementMethod: .blocked, source: "unsafe non-settable selection"),
        "capture policy blocks unsafe non-settable fallback"
    )
    try expect(
        TextCapturePolicy.shouldStopAfterBlockedCapture(
            CapturedText(text: "", replacementMethod: .blocked, source: "unsafe non-settable selection")
        ),
        true,
        "capture policy stops conversion after blocked capture"
    )
    try expect(
        TextCapturePolicy.actionAfterBlockedCapture(
            CapturedText(text: "", replacementMethod: .blocked, source: "unsafe non-settable selection")
        ),
        BlockedCaptureAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "blocked unsafe text capture",
            clearConversionSessionReason: "blocked unsafe text capture"
        ),
        "capture policy clears stale state after blocked capture"
    )
    try expect(
        TextCapturePolicy.shouldStopAfterBlockedCapture(
            CapturedText(text: "hello", replacementMethod: .accessibilitySelection, source: "AX editable selection")
        ),
        false,
        "capture policy continues after safe capture"
    )
    try expect(
        TextCapturePolicy.actionAfterBlockedCapture(
            CapturedText(text: "hello", replacementMethod: .accessibilitySelection, source: "AX editable selection")
        ),
        BlockedCaptureAction(clearTrackedText: false, clearConversionSession: false),
        "capture policy preserves state after safe capture"
    )
    try expect(
        TextCapturePolicy.shouldStopAfterBlockedCapture(nil),
        false,
        "capture policy continues when nothing was captured"
    )
    try expect(
        TextCapturePolicy.actionAfterBlockedCapture(nil),
        BlockedCaptureAction(clearTrackedText: false, clearConversionSession: false),
        "capture policy preserves state when nothing was captured"
    )

}
