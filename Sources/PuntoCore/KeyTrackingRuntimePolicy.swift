import Foundation

public enum KeyTrackingPreflightPlan: Equatable {
    case skipRouting(logMessage: String)
    case blockSecureInput(context: String, logMessage: String)
    case track
}

public enum KeyTrackingPostTrackRoute: Equatable {
    case resetOnReturn
    case runAutoCorrection
}

public struct KeyTrackingResetPlan: Equatable {
    public let completedTokenStatisticsEvent: ProductStatisticsEvent?
    public let conversionSessionClearReason: String
    public let logMessage: String

    public init(
        completedTokenStatisticsEvent: ProductStatisticsEvent?,
        conversionSessionClearReason: String,
        logMessage: String
    ) {
        self.completedTokenStatisticsEvent = completedTokenStatisticsEvent
        self.conversionSessionClearReason = conversionSessionClearReason
        self.logMessage = logMessage
    }
}

public enum KeyTrackingRuntimePolicy {
    public static func preflightPlan(
        isEnabled: Bool,
        isCurrentApplicationDisabled: Bool,
        isSecureInputEnabled: Bool,
        isPasswordField: Bool
    ) -> KeyTrackingPreflightPlan {
        guard HotkeyRoutingPolicy.shouldTrackKeyState(
            isEnabled: isEnabled,
            isCurrentApplicationDisabled: isCurrentApplicationDisabled
        ) else {
            return .skipRouting(logMessage: "Key tracking skipped by routing policy")
        }

        guard TextTrackingSecurityPolicy.shouldTrackTextInput(
            isSecureInputEnabled: isSecureInputEnabled,
            isPasswordField: isPasswordField
        ) else {
            return .blockSecureInput(
                context: TextTrackingSecurityPolicy.diagnosticContext(
                    isSecureInputEnabled: isSecureInputEnabled,
                    isPasswordField: isPasswordField
                ) ?? "secure input",
                logMessage: "Key tracking skipped for secure/password input"
            )
        }

        return .track
    }

    public static func postTrackRoute(
        bundleID: String?,
        keyCode: UInt16,
        resetBundleComponents: Set<String>
    ) -> KeyTrackingPostTrackRoute {
        if ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: bundleID,
            keyCode: keyCode,
            resetBundleComponents: resetBundleComponents
        ) {
            return .resetOnReturn
        }

        return .runAutoCorrection
    }

    public static func resetOnReturnPlan(
        consumedCompletedToken: Bool,
        bundleID: String?
    ) -> KeyTrackingResetPlan {
        KeyTrackingResetPlan(
            completedTokenStatisticsEvent: ProductStatisticsPolicy.eventAfterCompletedTokenConsumption(consumedCompletedToken),
            conversionSessionClearReason: "return in reset-on-return app",
            logMessage: "Auto-correction skipped and text state reset on Return for app '\(bundleID ?? "?")'"
        )
    }

    public static func conversionSessionClearReasonAfterAutoCorrection(
        isConversionInProgress: Bool
    ) -> String? {
        isConversionInProgress ? nil : "key press"
    }
}
