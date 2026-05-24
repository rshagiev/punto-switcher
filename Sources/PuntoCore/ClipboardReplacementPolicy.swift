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
}
