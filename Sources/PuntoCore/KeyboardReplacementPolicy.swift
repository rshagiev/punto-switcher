import Foundation

public enum KeyboardReplacementPolicy {
    public static let modifierReleaseSettleDelay: TimeInterval = 0.05
    public static let modifierReleaseMaxWait: TimeInterval = 0.35
    public static let modifierReleasePollInterval: TimeInterval = 0.01
    public static let backspaceInterval: TimeInterval = 0.05
    public static let prePasteDelay: TimeInterval = 0.06
    public static let postPasteDelay: TimeInterval = 0.03
    public static let clipboardRestoreDelay: TimeInterval = ClipboardReplacementPolicy.clipboardRestoreDelay

    public static func shouldAttemptKeyboardReplacement(deleteLength: Int) -> Bool {
        deleteLength > 0
    }

    public static func shouldPasteReplacementAfterBackspaces(expectedCount: Int, sentCount: Int) -> Bool {
        expectedCount > 0 && sentCount == expectedCount
    }

    public static func shouldStartKeyboardEventsAfterModifierWait(modifiersArePressed: Bool) -> Bool {
        !modifiersArePressed
    }

    public static func shouldRestoreClipboardAfterPaste(currentChangeCount: Int, replacementChangeCount: Int) -> Bool {
        ClipboardReplacementPolicy.shouldRestoreClipboardAfterReplacementPaste(
            currentChangeCount: currentChangeCount,
            replacementChangeCount: replacementChangeCount
        )
    }
}
