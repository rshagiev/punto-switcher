import Foundation
import PuntoCore

func runClipboardCapturePolicyTests() throws {
    try expect(
        KeyboardEventKeyCodePolicy.copyKeyCode,
        8,
        "keyboard event key code policy uses C key for copy"
    )
    try expect(
        ClipboardCapturePolicy.copyKeyCode,
        KeyboardEventKeyCodePolicy.copyKeyCode,
        "clipboard capture shares copy key code policy"
    )
    try expect(
        ClipboardCapturePolicy.keyUpDelay,
        0.01,
        "clipboard capture preserves copy key-up delay"
    )
    try expect(
        ClipboardCapturePolicy.pollInterval,
        0.02,
        "clipboard capture preserves polling interval"
    )
    try expect(
        ClipboardCapturePolicy.maxPollAttempts,
        10,
        "clipboard capture preserves max poll attempts"
    )
    try expect(
        ClipboardCapturePolicy.shouldAttemptHIDFallback(pollAttempt: 3, pasteboardChanged: false),
        true,
        "clipboard capture tries HID fallback on third unchanged poll"
    )
    try expect(
        ClipboardCapturePolicy.shouldAttemptHIDFallback(pollAttempt: 3, pasteboardChanged: true),
        false,
        "clipboard capture skips HID fallback after pasteboard change"
    )
    try expect(
        ClipboardCapturePolicy.shouldAttemptHIDFallback(pollAttempt: 2, pasteboardChanged: false),
        false,
        "clipboard capture waits before HID fallback"
    )
    try expect(
        ClipboardCapturePolicy.shouldStopPolling(pasteboardChanged: true),
        true,
        "clipboard capture stops polling after pasteboard change"
    )
    try expect(
        ClipboardCapturePolicy.shouldStopPolling(pasteboardChanged: false),
        false,
        "clipboard capture continues polling while pasteboard is unchanged"
    )
    try expect(
        ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: "browser selection",
            pasteboardChanged: true,
            previousClipboardText: nil
        ),
        "browser selection",
        "clipboard capture accepts changed non-empty copied text"
    )
    try expect(
        ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: "browser selection",
            pasteboardChanged: false,
            previousClipboardText: "browser selection"
        ),
        "browser selection",
        "clipboard capture accepts unchanged text when it matches previous clipboard"
    )
    try expectNil(
        ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: "stale clipboard",
            pasteboardChanged: false,
            previousClipboardText: "different previous"
        ),
        "clipboard capture rejects unchanged stale clipboard mismatch"
    )
    try expectNil(
        ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: " \n\t ",
            pasteboardChanged: true,
            previousClipboardText: nil
        ),
        "clipboard capture rejects whitespace-only copied text"
    )
}
