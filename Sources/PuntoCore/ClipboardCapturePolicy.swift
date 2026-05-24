import Foundation

public enum ClipboardCapturePolicy {
    public static let copyKeyCode = KeyboardEventKeyCodePolicy.copyKeyCode
    public static let keyUpDelay: TimeInterval = 0.01
    public static let pollInterval: TimeInterval = 0.02
    public static let maxPollAttempts = 10
    public static let hidFallbackAttempt = 3

    public static func shouldAttemptHIDFallback(pollAttempt: Int, pasteboardChanged: Bool) -> Bool {
        !pasteboardChanged && pollAttempt == hidFallbackAttempt
    }

    public static func shouldStopPolling(pasteboardChanged: Bool) -> Bool {
        pasteboardChanged
    }

    public static func shouldAttemptActiveClipboardCapture(
        focusEvidence: KeyboardFocusEvidence
    ) -> Bool {
        guard focusEvidence.hasFocusedApplication else {
            return false
        }

        if focusEvidence.hasFocusedElement,
           focusEvidence.isEnabled == false {
            return false
        }

        return true
    }

    public static func capturedTextAfterCopy(
        pasteboardText: String?,
        pasteboardChanged: Bool,
        previousClipboardText: String?
    ) -> String? {
        guard let pasteboardText,
              !pasteboardText.isEmpty,
              !pasteboardText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        if pasteboardChanged {
            return pasteboardText
        }

        guard let previousClipboardText,
              pasteboardText == previousClipboardText else {
            return nil
        }

        return pasteboardText
    }
}
