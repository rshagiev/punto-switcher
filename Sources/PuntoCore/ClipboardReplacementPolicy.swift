import Foundation

public enum ClipboardReplacementPolicy {
    public static let observedShouldRestorePasteboardKey = "shouldRestorePasteboard"

    public static let clipboardRestoreDelay: TimeInterval = 0.3

    public static func shouldRestoreClipboardAfterReplacementPaste(
        currentChangeCount: Int,
        replacementChangeCount: Int
    ) -> Bool {
        currentChangeCount == replacementChangeCount
    }
}
