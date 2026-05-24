import Foundation
import PuntoCore

func runTextCaptureFallbackPolicyTests() throws {
    try expectNil(
        TextCapturePolicy.captureDecision(
            observation: .emptySelection,
            activeClipboardText: "ignored",
            passiveClipboardText: "ignored",
            lastTrackedWord: "ignored",
            lastTrackedTail: "ignored"
        ),
        "capture policy returns nil for empty AX selection"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: "browser selection",
            passiveClipboardText: nil,
            lastTrackedWord: nil,
            lastTrackedTail: nil
        ),
        CapturedText(
            text: "browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard fallback",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy uses active clipboard for no-focus fallback"
    )
    try expectNil(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: " \n\t ",
            passiveClipboardText: nil,
            lastTrackedWord: nil,
            lastTrackedTail: nil
        ),
        "capture policy rejects whitespace-only no-focus active clipboard fallback"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: "user@host % git commit\n",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "active clipboard command-tail selection"),
        "capture policy extracts prompt-prefixed command tail after no-focus active clipboard"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: "old > scrollback git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "", replacementMethod: .blocked, source: "unsafe active clipboard terminal tail"),
        "capture policy blocks prompt-like scrollback before no-focus active clipboard fallback"
    )
    try expect(
        TextCapturePolicy.shouldStopAfterBlockedCapture(
            TextCapturePolicy.captureDecision(
                observation: .noFocusedElement,
                activeClipboardText: "old > scrollback git commit",
                passiveClipboardText: nil,
                lastTrackedWord: "commit",
                lastTrackedTail: "git commit"
            )
        ),
        true,
        "capture policy stops after unsafe no-focus terminal clipboard"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .noFocusedElement,
            activeClipboardText: "git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(
            text: "git commit",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard fallback",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy keeps exact no-focus active clipboard as selected-text fallback"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "browser selection",
            passiveClipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(
            text: "browser selection",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard fallback",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy prefers fresh active clipboard selection over stale passive tail after AX failure"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: " \n\t ",
            passiveClipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardBackspacePaste, source: "passive clipboard tail selection"),
        "capture policy ignores whitespace-only active clipboard and uses valid passive tail after AX failure"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "user@host % git commit\n",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardRewriteTail(originalTail: "git commit"), source: "active clipboard command-tail selection"),
        "capture policy extracts terminal command tail from active clipboard after AX failure"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(
            text: "git commit",
            replacementMethod: .accessibilitySelection,
            source: "active clipboard fallback",
            selectedTextReplacementTransport: .clipboard
        ),
        "capture policy keeps exact AX-failed active clipboard as selected-text fallback"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "old > scrollback git commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "", replacementMethod: .blocked, source: "unsafe active clipboard terminal tail"),
        "capture policy blocks prompt-like scrollback after AX failure"
    )
    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: "old scrollback\ngit commit",
            passiveClipboardText: nil,
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "", replacementMethod: .blocked, source: "unsafe active clipboard terminal tail"),
        "capture policy blocks promptless multiline scrollback after AX failure"
    )

    try expect(
        TextCapturePolicy.captureDecision(
            observation: .failed,
            activeClipboardText: nil,
            passiveClipboardText: "git commit",
            lastTrackedWord: "commit",
            lastTrackedTail: "git commit"
        ),
        CapturedText(text: "git commit", replacementMethod: .keyboardBackspacePaste, source: "passive clipboard tail selection"),
        "capture policy uses passive command tail only when active clipboard is unavailable"
    )
}
