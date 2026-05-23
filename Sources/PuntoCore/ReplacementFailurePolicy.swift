import Foundation

public struct ReplacementFailureAction: Equatable {
    public let clearTrackedText: Bool
    public let clearConversionSession: Bool

    public init(clearTrackedText: Bool, clearConversionSession: Bool) {
        self.clearTrackedText = clearTrackedText
        self.clearConversionSession = clearConversionSession
    }
}

public enum ReplacementFailurePolicy {
    public static func actionAfterFailedReplacement(method: TextReplacementMethod) -> ReplacementFailureAction {
        switch method {
        case .keyboardBackspacePaste, .keyboardRewriteTail:
            return ReplacementFailureAction(clearTrackedText: true, clearConversionSession: true)
        case .accessibilitySelection, .blocked:
            return ReplacementFailureAction(clearTrackedText: false, clearConversionSession: false)
        }
    }

    public static func shouldClearTrackedTextAfterFailedReplacement(method: TextReplacementMethod) -> Bool {
        actionAfterFailedReplacement(method: method).clearTrackedText
    }

    public static func shouldClearConversionSessionAfterFailedReplacement(method: TextReplacementMethod) -> Bool {
        actionAfterFailedReplacement(method: method).clearConversionSession
    }
}
