import Foundation

public enum ToggleCaseConversionPlan: Equatable {
    case blockedCapture(CapturedText)
    case capturedText(capture: CapturedText, replacement: ToggleCaseReplacement)
    case skipped(reason: String)
    case noText
}

public struct ToggleCaseReplacementRuntimePlan: Equatable {
    public let capturedText: CapturedText
    public let replacement: ToggleCaseReplacement
    public let logMessage: String
    public let keepSelection: Bool
    public let failedReplacementLogMessage: String
    public let failedReplacementMethod: TextReplacementMethod
    public let commitPlan: TextReplacementCommitPlan

    public init(
        capturedText: CapturedText,
        replacement: ToggleCaseReplacement,
        logMessage: String,
        keepSelection: Bool,
        failedReplacementLogMessage: String,
        failedReplacementMethod: TextReplacementMethod,
        commitPlan: TextReplacementCommitPlan
    ) {
        self.capturedText = capturedText
        self.replacement = replacement
        self.logMessage = logMessage
        self.keepSelection = keepSelection
        self.failedReplacementLogMessage = failedReplacementLogMessage
        self.failedReplacementMethod = failedReplacementMethod
        self.commitPlan = commitPlan
    }
}

public enum ToggleCaseRuntimePlan: Equatable {
    case blockedCapture(capturedText: CapturedText, logMessage: String)
    case replace(ToggleCaseReplacementRuntimePlan)
    case skipped(logMessage: String)
    case noText(logMessage: String)
}

public enum ToggleCaseConversionPolicy {
    public static func plan(capturedText: CapturedText?) -> ToggleCaseConversionPlan {
        if let capturedText, TextCapturePolicy.shouldStopAfterBlockedCapture(capturedText) {
            return .blockedCapture(capturedText)
        }

        guard let capturedText, !capturedText.text.isEmpty else {
            return .noText
        }

        guard let replacement = ToggleCasePolicy.replacement(for: capturedText) else {
            return .skipped(reason: "replacement unavailable")
        }

        return .capturedText(capture: capturedText, replacement: replacement)
    }

    public static func runtimePlan(from plan: ToggleCaseConversionPlan) -> ToggleCaseRuntimePlan {
        switch plan {
        case .blockedCapture(let capturedText):
            return .blockedCapture(
                capturedText: capturedText,
                logMessage: "Toggle case blocked unsafe selection fallback: \(capturedText.source)"
            )

        case .capturedText(let capturedText, let replacement):
            return .replace(ToggleCaseReplacementRuntimePlan(
                capturedText: capturedText,
                replacement: replacement,
                logMessage: "Toggling case for captured text: '\(replacement.originalText)'",
                keepSelection: TextReplacementPolicy.shouldKeepSelectionAfterReplacement(
                    method: capturedText.replacementMethod
                ),
                failedReplacementLogMessage: "Toggle case replacement aborted",
                failedReplacementMethod: replacement.undoMethod,
                commitPlan: TextReplacementCommitPolicy.toggleCase(replacement)
            ))

        case .skipped:
            return .skipped(logMessage: "Toggle case aborted: replacement plan could not be derived")

        case .noText:
            return .noText(logMessage: "Toggle case: no selected text")
        }
    }
}
