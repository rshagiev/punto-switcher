import Foundation

public enum ClipboardFocusPolicy {
    public static func shouldAttemptFocusedClipboardKeyEvent(
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
