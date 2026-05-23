import Foundation

public struct UndoReplacement: Equatable {
    public let capturedText: CapturedText
    public let replacementText: String
    public let keepSelection: Bool
    public let nextReplacementMethod: TextReplacementMethod
    public let trackedTailAfterUndo: String?

    public init(
        capturedText: CapturedText,
        replacementText: String,
        keepSelection: Bool,
        nextReplacementMethod: TextReplacementMethod,
        trackedTailAfterUndo: String?
    ) {
        self.capturedText = capturedText
        self.replacementText = replacementText
        self.keepSelection = keepSelection
        self.nextReplacementMethod = nextReplacementMethod
        self.trackedTailAfterUndo = trackedTailAfterUndo
    }
}

public enum UndoReplacementPolicy {
    public static func actionAfterFailedReplacement(method: TextReplacementMethod) -> ReplacementFailureAction {
        ReplacementFailurePolicy.actionAfterFailedReplacement(method: method)
    }

    public static func shouldClearSessionAfterFailedReplacement() -> Bool {
        actionAfterFailedReplacement(method: .keyboardBackspacePaste).clearConversionSession
    }

    public static func shouldClearTrackedTextAfterFailedReplacement(method: TextReplacementMethod) -> Bool {
        actionAfterFailedReplacement(method: method).clearTrackedText
    }

    public static func replacement(for record: ConversionRecord) -> UndoReplacement? {
        let capturedText = CapturedText(
            text: record.convertedText,
            replacementMethod: record.replacementMethod,
            source: "undo"
        )

        guard let nextMethod = TextReplacementPolicy.recordedMethodAfterUndo(
            convertedText: record.convertedText,
            originalText: record.originalText,
            method: record.replacementMethod
        ) else {
            return nil
        }

        return UndoReplacement(
            capturedText: capturedText,
            replacementText: record.originalText,
            keepSelection: TextReplacementPolicy.shouldKeepSelectionAfterReplacement(method: record.replacementMethod),
            nextReplacementMethod: nextMethod,
            trackedTailAfterUndo: TextReplacementPolicy.trackedTailAfterUndo(
                convertedText: record.convertedText,
                originalText: record.originalText,
                method: record.replacementMethod
            )
        )
    }
}
