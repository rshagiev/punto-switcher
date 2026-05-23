import Foundation

public struct ReplacementFailureAction: Equatable {
    public let clearTrackedText: Bool
    public let clearConversionSession: Bool
    public let clearTrackedTextReason: String?
    public let clearConversionSessionReason: String?

    public init(
        clearTrackedText: Bool,
        clearConversionSession: Bool,
        clearTrackedTextReason: String? = nil,
        clearConversionSessionReason: String? = nil
    ) {
        self.clearTrackedText = clearTrackedText
        self.clearConversionSession = clearConversionSession
        self.clearTrackedTextReason = clearTrackedTextReason
        self.clearConversionSessionReason = clearConversionSessionReason
    }
}

public enum ReplacementFailurePolicy {
    public static func actionAfterFailedReplacement(
        method: TextReplacementMethod,
        clearReason: String = "failed keyboard replacement"
    ) -> ReplacementFailureAction {
        switch method {
        case .keyboardBackspacePaste, .keyboardRewriteTail:
            return ReplacementFailureAction(
                clearTrackedText: true,
                clearConversionSession: true,
                clearTrackedTextReason: clearReason,
                clearConversionSessionReason: clearReason
            )
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
