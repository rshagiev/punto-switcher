import Foundation

public enum AutoCorrectionPreflightAction: Equatable {
    case proceed
    case consumeTokenAndSkip(reason: String)
    case skip(reason: String)
    case blockAndClear(reason: String)
}

public enum AutoCorrectionPreflightPolicy {
    public static func action(
        isEnabled: Bool,
        autoCorrectionEnabled: Bool,
        autoCorrectOnEnterAndTab: Bool = true,
        isConversionInProgress: Bool,
        isCurrentApplicationDisabled: Bool,
        hasCompletedToken: Bool,
        completedTokenSeparator: String? = nil,
        isCompletedTokenAutoCorrectionSuppressed: Bool = false,
        isSecureInputEnabled: Bool,
        isPasswordField: Bool
    ) -> AutoCorrectionPreflightAction {
        guard isEnabled else {
            return .consumeTokenAndSkip(reason: "Punto disabled")
        }

        guard autoCorrectionEnabled else {
            return .consumeTokenAndSkip(reason: "auto-correction disabled")
        }

        guard !isConversionInProgress else {
            return .consumeTokenAndSkip(reason: "conversion in progress")
        }

        guard !isCurrentApplicationDisabled else {
            return .consumeTokenAndSkip(reason: "current app disabled")
        }

        guard hasCompletedToken else {
            return .skip(reason: "no completed token")
        }

        guard !isCompletedTokenAutoCorrectionSuppressed else {
            return .consumeTokenAndSkip(reason: "completed token auto-correction cancelled")
        }

        if !autoCorrectOnEnterAndTab, isEnterOrTabSeparator(completedTokenSeparator) {
            return .consumeTokenAndSkip(reason: "auto-correction on Enter/Tab disabled")
        }

        if isSecureInputEnabled {
            return .blockAndClear(reason: "secure input")
        }

        if isPasswordField {
            return .blockAndClear(reason: "password field")
        }

        return .proceed
    }

    private static func isEnterOrTabSeparator(_ separator: String?) -> Bool {
        separator == "\n" || separator == "\r" || separator == "\t"
    }

    public static func logMessage(for action: AutoCorrectionPreflightAction) -> String? {
        switch action {
        case .proceed, .skip:
            return nil
        case .consumeTokenAndSkip(let reason):
            return "Auto-correction skipped: \(reason)"
        case .blockAndClear(let reason):
            switch reason {
            case "secure input", "password field":
                return "Auto-correction blocked for secure input"
            default:
                return "Auto-correction blocked: \(reason)"
            }
        }
    }
}
