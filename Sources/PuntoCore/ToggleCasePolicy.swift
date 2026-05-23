import Foundation

public struct ToggleCaseReplacement: Equatable {
    public let originalText: String
    public let toggledText: String
    public let undoMethod: TextReplacementMethod
    public let trackedTailAfterReplacement: String?

    public init(
        originalText: String,
        toggledText: String,
        undoMethod: TextReplacementMethod,
        trackedTailAfterReplacement: String?
    ) {
        self.originalText = originalText
        self.toggledText = toggledText
        self.undoMethod = undoMethod
        self.trackedTailAfterReplacement = trackedTailAfterReplacement
    }
}

public enum ToggleCasePolicy {
    public static func replacement(for capturedText: CapturedText) -> ToggleCaseReplacement? {
        guard !capturedText.text.isEmpty,
              capturedText.replacementMethod != .blocked else {
            return nil
        }

        let toggled = CaseConverter.toggleCase(capturedText.text)
        guard let undoMethod = TextReplacementPolicy.recordedMethodAfterReplacement(
            capturedText: capturedText.text,
            replacement: toggled,
            method: capturedText.replacementMethod
        ) else {
            return nil
        }

        return ToggleCaseReplacement(
            originalText: capturedText.text,
            toggledText: toggled,
            undoMethod: undoMethod,
            trackedTailAfterReplacement: TextReplacementPolicy.trackedTailAfterReplacement(
                capturedText: capturedText.text,
                replacement: toggled,
                method: capturedText.replacementMethod
            )
        )
    }
}
