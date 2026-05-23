import Foundation

public enum SelectedTextClipboardReplacementPolicy {
    public static let postPasteDelay: TimeInterval = 0.03
    public static let selectAfterPasteDelay: TimeInterval = 0.02
    public static let clipboardRestoreDelay: TimeInterval = ClipboardReplacementPolicy.clipboardRestoreDelay

    public static func shouldSelectAfterPaste(_ selectAfterPaste: Bool, replacementText: String) -> Bool {
        selectAfterPaste && !replacementText.isEmpty
    }

    public static func shouldRestoreClipboardAfterPaste(currentChangeCount: Int, replacementChangeCount: Int) -> Bool {
        ClipboardReplacementPolicy.shouldRestoreClipboardAfterReplacementPaste(
            currentChangeCount: currentChangeCount,
            replacementChangeCount: replacementChangeCount
        )
    }
}
