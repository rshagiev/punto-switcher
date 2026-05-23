import Foundation

public struct ManualLayoutReplacementRuntimePlan: Equatable {
    public let replacement: LayoutConversionReplacement
    public let captureTimingLabel: String
    public let originalTextLogMessage: String
    public let convertedTextLogMessage: String
    public let replacementTimingLabel: String
    public let failedReplacementLogMessage: String
    public let failedReplacementMethod: TextReplacementMethod
    public let commitPlan: TextReplacementCommitPlan

    public init(
        replacement: LayoutConversionReplacement,
        captureTimingLabel: String,
        originalTextLogMessage: String,
        convertedTextLogMessage: String,
        replacementTimingLabel: String,
        failedReplacementLogMessage: String,
        failedReplacementMethod: TextReplacementMethod,
        commitPlan: TextReplacementCommitPlan
    ) {
        self.replacement = replacement
        self.captureTimingLabel = captureTimingLabel
        self.originalTextLogMessage = originalTextLogMessage
        self.convertedTextLogMessage = convertedTextLogMessage
        self.replacementTimingLabel = replacementTimingLabel
        self.failedReplacementLogMessage = failedReplacementLogMessage
        self.failedReplacementMethod = failedReplacementMethod
        self.commitPlan = commitPlan
    }
}

public enum ManualLayoutConversionRuntimePlan: Equatable {
    case blockedCapture(capturedText: CapturedText, logMessage: String)
    case replace(ManualLayoutReplacementRuntimePlan)
    case clearTrackedText(reason: String, logMessage: String)
    case skip(logMessage: String)
    case noText(logMessage: String)
}

public enum ManualLayoutConversionRuntimePolicy {
    public static func runtimePlan(
        from plan: ManualLayoutConversionPlan,
        suppressAutoCorrectionAfterManualConversion: Bool
    ) -> ManualLayoutConversionRuntimePlan {
        switch plan {
        case .blockedCapture(let capturedText):
            return .blockedCapture(
                capturedText: capturedText,
                logMessage: "Blocked unsafe selection fallback: \(capturedText.source)"
            )

        case .selectedText(let replacement):
            return .replace(ManualLayoutReplacementRuntimePlan(
                replacement: replacement,
                captureTimingLabel: "getSelectedText",
                originalTextLogMessage: "Converting captured text (\(replacement.capturedText.source)): '\(replacement.capturedText.text)'",
                convertedTextLogMessage: "Converted to: '\(replacement.convertedText)'",
                replacementTimingLabel: "setSelectedText",
                failedReplacementLogMessage: "Captured text replacement aborted",
                failedReplacementMethod: replacement.capturedText.replacementMethod,
                commitPlan: TextReplacementCommitPolicy.manualSelectedText(
                    replacement,
                    suppressAutoCorrectionAfterManualConversion: suppressAutoCorrectionAfterManualConversion
                )
            ))

        case .lastWord(let replacement):
            return .replace(ManualLayoutReplacementRuntimePlan(
                replacement: replacement,
                captureTimingLabel: "getSelectedText (empty)",
                originalTextLogMessage: "Converting last word: '\(replacement.capturedText.text)'",
                convertedTextLogMessage: "Converted to: '\(replacement.convertedText)'",
                replacementTimingLabel: "replaceLastWord",
                failedReplacementLogMessage: "Last-word replacement aborted",
                failedReplacementMethod: replacement.capturedText.replacementMethod,
                commitPlan: TextReplacementCommitPolicy.manualLastWord(
                    replacement,
                    suppressAutoCorrectionAfterManualConversion: suppressAutoCorrectionAfterManualConversion
                )
            ))

        case .clearTrackedTextAfterSkippedLastWord:
            return .clearTrackedText(
                reason: "stale last-word tracked tail",
                logMessage: "Last-word conversion skipped: replacement plan could not be derived"
            )

        case .skipped(let reason):
            return .skip(logMessage: "Layout conversion skipped: \(reason)")

        case .noText:
            return .noText(logMessage: "No text to convert")
        }
    }
}
