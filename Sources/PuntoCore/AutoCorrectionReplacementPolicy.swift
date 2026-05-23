import Foundation

public struct AutoCorrectionReplacement: Equatable {
    public let originalText: String
    public let replacementText: String
    public let replacementLength: Int
    public let undoMethod: TextReplacementMethod
    public let trackedTailAfterReplacement: String

    public init(
        originalText: String,
        replacementText: String,
        replacementLength: Int,
        undoMethod: TextReplacementMethod,
        trackedTailAfterReplacement: String
    ) {
        self.originalText = originalText
        self.replacementText = replacementText
        self.replacementLength = replacementLength
        self.undoMethod = undoMethod
        self.trackedTailAfterReplacement = trackedTailAfterReplacement
    }
}

public enum AutoCorrectionReplacementPolicy {
    public static func shouldClearConversionSessionAfterPlanFailure() -> Bool {
        true
    }

    public static func replacement(
        for decision: AutoCorrectionDecision,
        completedToken: WordTracker.CompletedToken,
        trackedTailBeforeCorrection: String?
    ) -> AutoCorrectionReplacement? {
        guard decision.original == completedToken.word else {
            return nil
        }
        guard !completedToken.separator.isEmpty else {
            return nil
        }

        let originalText = decision.original + completedToken.separator
        let replacementText = decision.replacement + completedToken.separator
        guard !originalText.isEmpty, originalText != replacementText else {
            return nil
        }

        return AutoCorrectionReplacement(
            originalText: originalText,
            replacementText: replacementText,
            replacementLength: originalText.count,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: TextReplacementPolicy.trackedTailAfterRecentTextReplacement(
                lastTrackedTail: trackedTailBeforeCorrection,
                original: originalText,
                replacement: replacementText
            )
        )
    }
}
