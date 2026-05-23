import Foundation

public struct LayoutConversionReplacement: Equatable {
    public let capturedText: CapturedText
    public let convertedText: String
    public let targetLayout: LayoutConverter.DetectedLayout
    public let keepSelection: Bool
    public let undoMethod: TextReplacementMethod
    public let trackedTailAfterReplacement: String?

    public init(
        capturedText: CapturedText,
        convertedText: String,
        targetLayout: LayoutConverter.DetectedLayout,
        keepSelection: Bool,
        undoMethod: TextReplacementMethod,
        trackedTailAfterReplacement: String?
    ) {
        self.capturedText = capturedText
        self.convertedText = convertedText
        self.targetLayout = targetLayout
        self.keepSelection = keepSelection
        self.undoMethod = undoMethod
        self.trackedTailAfterReplacement = trackedTailAfterReplacement
    }
}

public enum LayoutConversionReplacementPolicy {
    public static func replacement(
        for capturedText: CapturedText,
        conversionResult: LayoutConverter.ConversionResult
    ) -> LayoutConversionReplacement? {
        guard conversionResult.shouldApply,
              capturedText.replacementMethod != .blocked,
              !capturedText.text.isEmpty,
              let undoMethod = TextReplacementPolicy.recordedMethodAfterReplacement(
                  capturedText: capturedText.text,
                  replacement: conversionResult.text,
                  method: capturedText.replacementMethod
              ) else {
            return nil
        }

        return LayoutConversionReplacement(
            capturedText: capturedText,
            convertedText: conversionResult.text,
            targetLayout: conversionResult.targetLayout,
            keepSelection: TextReplacementPolicy.shouldKeepSelectionAfterReplacement(method: capturedText.replacementMethod),
            undoMethod: undoMethod,
            trackedTailAfterReplacement: TextReplacementPolicy.trackedTailAfterReplacement(
                capturedText: capturedText.text,
                replacement: conversionResult.text,
                method: capturedText.replacementMethod
            )
        )
    }

    public static func lastWordReplacement(
        lastWord: String,
        conversionResult: LayoutConverter.ConversionResult,
        lastTrackedTail: String?
    ) -> LayoutConversionReplacement? {
        guard conversionResult.shouldApply, !lastWord.isEmpty else {
            return nil
        }

        let trackedTailAfterReplacement = TextReplacementPolicy.trackedTailAfterLastWordReplacement(
            lastTrackedTail: lastTrackedTail,
            lastWord: lastWord,
            replacement: conversionResult.text
        )
        if let lastTrackedTail, !lastTrackedTail.isEmpty, trackedTailAfterReplacement == nil {
            return nil
        }

        return LayoutConversionReplacement(
            capturedText: CapturedText(
                text: lastWord,
                replacementMethod: .keyboardBackspacePaste,
                source: "last word"
            ),
            convertedText: conversionResult.text,
            targetLayout: conversionResult.targetLayout,
            keepSelection: false,
            undoMethod: .keyboardBackspacePaste,
            trackedTailAfterReplacement: trackedTailAfterReplacement
        )
    }

    public static func shouldClearTrackedTextAfterSkippedLastWordReplacement(
        lastWord: String,
        conversionResult: LayoutConverter.ConversionResult,
        lastTrackedTail: String?
    ) -> Bool {
        guard conversionResult.shouldApply,
              !lastWord.isEmpty,
              let lastTrackedTail,
              !lastTrackedTail.isEmpty else {
            return false
        }

        return TextReplacementPolicy.trackedTailAfterLastWordReplacement(
            lastTrackedTail: lastTrackedTail,
            lastWord: lastWord,
            replacement: conversionResult.text
        ) == nil
    }
}
