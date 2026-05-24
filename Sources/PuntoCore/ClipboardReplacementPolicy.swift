import Foundation

public enum ClipboardReplacementPolicy {
    public static let defaultRestorePasteboardAfterConversion = true
    public static let legacyShouldRestorePasteboardKey = "shouldRestorePasteboard"

    public static let clipboardRestoreDelay: TimeInterval = 0.3

    public static func shouldRestoreClipboardAfterReplacementPaste(
        currentChangeCount: Int,
        replacementChangeCount: Int
    ) -> Bool {
        currentChangeCount == replacementChangeCount
    }

    public static func shouldAttemptSelectedTextClipboardReplacement(
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
}
