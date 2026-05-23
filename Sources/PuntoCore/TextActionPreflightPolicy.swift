import Foundation

public enum TextActionKind: Equatable {
    case layoutConversion
    case toggleCase
    case selectedTextSearch
}

public enum TextActionPreflightAction: Equatable {
    case proceed
    case skip(reason: String)
    case blockAndClear(reason: String)
}

public enum TextActionPreflightPolicy {
    public static func action(
        kind: TextActionKind,
        isEnabled: Bool,
        isManualConversionDisabled: Bool = false,
        isConversionInProgress: Bool,
        isCurrentApplicationDisabled: Bool,
        isSecureInputEnabled: Bool,
        isPasswordField: Bool
    ) -> TextActionPreflightAction {
        guard isEnabled else {
            return .skip(reason: "\(label(for: kind)) disabled")
        }

        if kind == .layoutConversion, isManualConversionDisabled {
            return .skip(reason: "manual conversion disabled")
        }

        guard !isConversionInProgress else {
            return .skip(reason: "\(label(for: kind)) already in progress")
        }

        guard !isCurrentApplicationDisabled else {
            return .skip(reason: "current app disabled")
        }

        if isSecureInputEnabled {
            return .blockAndClear(reason: "secure input")
        }

        if isPasswordField {
            return .blockAndClear(reason: "password field")
        }

        return .proceed
    }

    public static func logMessage(action: TextActionPreflightAction, kind: TextActionKind) -> String? {
        switch action {
        case .proceed:
            return nil
        case .skip(let reason):
            switch reason {
            case "\(label(for: kind)) disabled":
                switch kind {
                case .layoutConversion:
                    return "Disabled, skipping conversion"
                case .toggleCase:
                    return "Disabled, skipping toggle case"
                case .selectedTextSearch:
                    return "Disabled, skipping selected text search"
                }
            case "current app disabled":
                switch kind {
                case .layoutConversion:
                    return "Current app disabled, skipping conversion"
                case .toggleCase:
                    return "Current app disabled, skipping toggle case"
                case .selectedTextSearch:
                    return "Current app disabled, skipping selected text search"
                }
            case "manual conversion disabled":
                return "Manual conversion disabled, skipping conversion"
            case "\(label(for: kind)) already in progress":
                switch kind {
                case .layoutConversion:
                    return "Conversion already in progress, skipping conversion"
                case .toggleCase:
                    return "Conversion already in progress, skipping toggle case"
                case .selectedTextSearch:
                    return "Conversion already in progress, skipping selected text search"
                }
            default:
                return "Skipping \(label(for: kind)): \(reason)"
            }
        case .blockAndClear(let reason):
            switch (kind, reason) {
            case (.layoutConversion, "secure input"):
                return "Secure Input enabled - conversion blocked for security"
            case (.layoutConversion, "password field"):
                return "Password field detected - conversion blocked"
            case (.toggleCase, "secure input"):
                return "Secure Input enabled - toggle case blocked for security"
            case (.toggleCase, "password field"):
                return "Password field detected - toggle case blocked"
            case (.selectedTextSearch, "secure input"):
                return "Secure Input enabled - selected text search blocked for security"
            case (.selectedTextSearch, "password field"):
                return "Password field detected - selected text search blocked"
            default:
                return "\(label(for: kind)) blocked: \(reason)"
            }
        }
    }

    private static func label(for kind: TextActionKind) -> String {
        switch kind {
        case .layoutConversion:
            return "conversion"
        case .toggleCase:
            return "toggle case"
        case .selectedTextSearch:
            return "selected text search"
        }
    }
}
