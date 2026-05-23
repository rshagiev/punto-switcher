import Foundation

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

    private static func isPasswordLikeToken(_ value: String) -> Bool {
        value == "axsecuretextfield" ||
            value == "axsecuretextfieldsubrole" ||
            value.contains("secure") ||
            value.contains("password")
    }
}
