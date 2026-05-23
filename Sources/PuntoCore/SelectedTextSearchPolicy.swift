import Foundation

public enum SelectedTextSearchPlan: Equatable {
    case blockedCapture(CapturedText)
    case open(URL)
    case skipped(reason: String)
    case noText
}

public enum SelectedTextSearchRuntimePlan: Equatable {
    case blockedCapture(capturedText: CapturedText, logMessage: String)
    case open(url: URL, logMessage: String, shouldFlashIcon: Bool)
    case skipped(logMessage: String)
    case noText(logMessage: String)
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

    public static func runtimePlan(from plan: SelectedTextSearchPlan) -> SelectedTextSearchRuntimePlan {
        switch plan {
        case .blockedCapture(let capturedText):
            return .blockedCapture(
                capturedText: capturedText,
                logMessage: "Selected text search blocked unsafe selection fallback: \(capturedText.source)"
            )

        case .open(let url):
            return .open(
                url: url,
                logMessage: "Opening selected text search URL: \(url.absoluteString)",
                shouldFlashIcon: true
            )

        case .skipped:
            return .skipped(logMessage: "Selected text search skipped: empty normalized query")

        case .noText:
            return .noText(logMessage: "Selected text search skipped: no selected text")
        }
    }
}
