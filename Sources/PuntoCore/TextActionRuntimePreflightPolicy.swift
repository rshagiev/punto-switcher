import Foundation

public enum TextActionRuntimePreflightPolicy {
    public static func routeAction(
        kind: TextActionKind,
        isEnabled: Bool,
        isManualConversionDisabled: Bool = false,
        isConversionInProgress: Bool,
        isCurrentApplicationDisabled: Bool
    ) -> TextActionPreflightAction {
        TextActionPreflightPolicy.action(
            kind: kind,
            isEnabled: isEnabled,
            isManualConversionDisabled: isManualConversionDisabled,
            isConversionInProgress: isConversionInProgress,
            isCurrentApplicationDisabled: isCurrentApplicationDisabled,
            isSecureInputEnabled: false,
            isPasswordField: false
        )
    }

    public static func securityAction(
        kind: TextActionKind,
        isSecureInputEnabled: Bool,
        isPasswordField: Bool
    ) -> TextActionPreflightAction {
        TextActionPreflightPolicy.action(
            kind: kind,
            isEnabled: true,
            isManualConversionDisabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: isSecureInputEnabled,
            isPasswordField: isPasswordField
        )
    }
}
