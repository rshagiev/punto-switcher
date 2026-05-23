import Foundation

public enum ManualLayoutConversionPlan: Equatable {
    case blockedCapture(CapturedText)
    case selectedText(LayoutConversionReplacement)
    case lastWord(LayoutConversionReplacement)
    case clearTrackedTextAfterSkippedLastWord
    case skipped(reason: String)
    case noText
}

public enum ManualLayoutConversionPolicy {
    public static func plan(
        capturedText: CapturedText?,
        lastWord: String?,
        lastTrackedTail: String?,
        russianLayoutType: KeyboardLayoutType = .windows,
        converter: LayoutConverter = LayoutConverter()
    ) -> ManualLayoutConversionPlan {
        if let capturedText, TextCapturePolicy.shouldStopAfterBlockedCapture(capturedText) {
            return .blockedCapture(capturedText)
        }

        if let capturedText, !capturedText.text.isEmpty {
            let result = converter.convertWithResult(capturedText.text, russianLayoutType: russianLayoutType)
            guard let replacement = LayoutConversionReplacementPolicy.replacement(
                for: capturedText,
                conversionResult: result
            ) else {
                return .skipped(reason: "captured text replacement unavailable")
            }
            return .selectedText(replacement)
        }

        guard let lastWord, !lastWord.isEmpty else {
            return .noText
        }

        let result = converter.convertWithResult(lastWord, russianLayoutType: russianLayoutType)
        guard let replacement = LayoutConversionReplacementPolicy.lastWordReplacement(
            lastWord: lastWord,
            conversionResult: result,
            lastTrackedTail: lastTrackedTail
        ) else {
            if LayoutConversionReplacementPolicy.shouldClearTrackedTextAfterSkippedLastWordReplacement(
                lastWord: lastWord,
                conversionResult: result,
                lastTrackedTail: lastTrackedTail
            ) {
                return .clearTrackedTextAfterSkippedLastWord
            }
            return .skipped(reason: "last-word replacement unavailable")
        }

        return .lastWord(replacement)
    }
}
