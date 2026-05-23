import Foundation

public enum ClipboardReplacementPolicy {
    public static let observedShouldRestorePasteboardKey = "shouldRestorePasteboard"
    public static let observedPreviousPasteboardContentsKey = "previousPasteboardContents"
    public static let observedPasteboardRestoreTimerKey = "pasteboardRestoreTimer"
    public static let observedGeneralPasteboardSelector = "generalPasteboard"
    public static let observedGetPasteboardStringSelector = "getPasteboardString"
    public static let observedSetPasteboardStringSelector = "setPasteboardString:"
    public static let observedRestorePasteboardByTimerSelector = "restorePasteboardByTimer:"
    public static let observedRestorePasteboardForKeyboardByTimerSelector = "restorePasteboardForKeyboardByTimer:"

    public static let clipboardRestoreDelay: TimeInterval = 0.3

    public static func shouldRestoreClipboardAfterReplacementPaste(
        currentChangeCount: Int,
        replacementChangeCount: Int
    ) -> Bool {
        currentChangeCount == replacementChangeCount
    }
}
