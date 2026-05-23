import Foundation

public struct TextTrackingSecurityClearAction: Equatable {
    public let clearTrackedText: Bool
    public let clearConversionSession: Bool
    public let clearTrackedTextReason: String?
    public let clearConversionSessionReason: String?
    public let shouldWriteDiagnostics: Bool
    public let diagnosticContext: String?
    public let logMessage: String?

    public init(
        clearTrackedText: Bool,
        clearConversionSession: Bool,
        clearTrackedTextReason: String? = nil,
        clearConversionSessionReason: String? = nil,
        shouldWriteDiagnostics: Bool = false,
        diagnosticContext: String? = nil,
        logMessage: String? = nil
    ) {
        self.clearTrackedText = clearTrackedText
        self.clearConversionSession = clearConversionSession
        self.clearTrackedTextReason = clearTrackedTextReason
        self.clearConversionSessionReason = clearConversionSessionReason
        self.shouldWriteDiagnostics = shouldWriteDiagnostics
        self.diagnosticContext = diagnosticContext
        self.logMessage = logMessage
    }
}

public enum TextTrackingSecurityPolicy {
    public static func isPasswordLikeAccessibilityElement(role: String?, subrole: String?) -> Bool {
        AccessibilityRolePolicy.normalizedRole(role).map(isPasswordLikeToken) == true ||
            AccessibilityRolePolicy.normalizedRole(subrole).map(isPasswordLikeToken) == true
    }

    public static func shouldTrackTextInput(
        isSecureInputEnabled: Bool,
        isPasswordField: Bool
    ) -> Bool {
        !isSecureInputEnabled && !isPasswordField
    }

    public static func shouldClearTrackedState(
        isSecureInputEnabled: Bool,
        isPasswordField: Bool
    ) -> Bool {
        isSecureInputEnabled || isPasswordField
    }

    public static func shouldWriteSecureInputDiagnostics(
        isSecureInputEnabled: Bool,
        isPasswordField: Bool
    ) -> Bool {
        shouldClearTrackedState(
            isSecureInputEnabled: isSecureInputEnabled,
            isPasswordField: isPasswordField
        )
    }

    public static func diagnosticContext(
        isSecureInputEnabled: Bool,
        isPasswordField: Bool
    ) -> String? {
        if isSecureInputEnabled {
            return "secure input"
        }
        if isPasswordField {
            return "password field"
        }
        return nil
    }

    public static func clearAction(
        isSecureInputEnabled: Bool,
        isPasswordField: Bool
    ) -> TextTrackingSecurityClearAction {
        guard shouldClearTrackedState(
            isSecureInputEnabled: isSecureInputEnabled,
            isPasswordField: isPasswordField
        ) else {
            return TextTrackingSecurityClearAction(
                clearTrackedText: false,
                clearConversionSession: false
            )
        }

        let context = diagnosticContext(
            isSecureInputEnabled: isSecureInputEnabled,
            isPasswordField: isPasswordField
        )

        return TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: shouldWriteSecureInputDiagnostics(
                isSecureInputEnabled: isSecureInputEnabled,
                isPasswordField: isPasswordField
            ),
            diagnosticContext: context,
            logMessage: "Secure/password input - cleared text state"
        )
    }

    private static func isPasswordLikeToken(_ value: String) -> Bool {
        value == "axsecuretextfield" ||
            value == "axsecuretextfieldsubrole" ||
            value.contains("secure") ||
            value.contains("password")
    }
}
