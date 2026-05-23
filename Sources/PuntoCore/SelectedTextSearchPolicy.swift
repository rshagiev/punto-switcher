import Foundation

public enum SelectedTextSearchPlan: Equatable {
    case blockedCapture(CapturedText)
    case open(URL)
    case skipped(reason: String)
    case noText
}

public enum SelectedTextSearchPolicy {
    public static func plan(
        capturedText: CapturedText?,
        destination: SearchShortcutDestination
    ) -> SelectedTextSearchPlan {
        guard let capturedText, !capturedText.text.isEmpty else {
            return .noText
        }

        if TextCapturePolicy.shouldStopAfterBlockedCapture(capturedText) {
            return .blockedCapture(capturedText)
        }

        guard let url = SearchShortcutPolicy.url(for: capturedText.text, destination: destination) else {
            return .skipped(reason: "empty normalized query")
        }

        return .open(url)
    }
}
