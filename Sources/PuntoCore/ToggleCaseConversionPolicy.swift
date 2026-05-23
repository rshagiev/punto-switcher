import Foundation

public enum ToggleCaseConversionPlan: Equatable {
    case blockedCapture(CapturedText)
    case capturedText(capture: CapturedText, replacement: ToggleCaseReplacement)
    case skipped(reason: String)
    case noText
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
}
