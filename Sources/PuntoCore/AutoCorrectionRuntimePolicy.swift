import Foundation

public enum AutoCorrectionRuntimePlan: Equatable {
    case noCorrection
    case replacement(decision: AutoCorrectionDecision, replacement: AutoCorrectionReplacement)
    case planFailure(decision: AutoCorrectionDecision)
}

public enum AutoCorrectionRuntimePolicy {
    public static func routePreflightAction(
        isEnabled: Bool,
        autoCorrectionEnabled: Bool,
        autoCorrectOnEnterAndTab: Bool = true,
        isConversionInProgress: Bool,
        isCurrentApplicationDisabled: Bool,
        token: WordTracker.CompletedToken?
    ) -> AutoCorrectionPreflightAction {
        AutoCorrectionPreflightPolicy.action(
            isEnabled: isEnabled,
            autoCorrectionEnabled: autoCorrectionEnabled,
            autoCorrectOnEnterAndTab: autoCorrectOnEnterAndTab,
            isConversionInProgress: isConversionInProgress,
            isCurrentApplicationDisabled: isCurrentApplicationDisabled,
            hasCompletedToken: token != nil,
            completedTokenSeparator: token?.separator,
            isCompletedTokenAutoCorrectionSuppressed: token?.isAutoCorrectionSuppressed == true,
            isSecureInputEnabled: false,
            isPasswordField: false
        )
    }

    public static func securityPreflightAction(
        token: WordTracker.CompletedToken,
        autoCorrectOnEnterAndTab: Bool = true,
        isSecureInputEnabled: Bool,
        isPasswordField: Bool
    ) -> AutoCorrectionPreflightAction {
        AutoCorrectionPreflightPolicy.action(
            isEnabled: true,
            autoCorrectionEnabled: true,
            autoCorrectOnEnterAndTab: autoCorrectOnEnterAndTab,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            hasCompletedToken: true,
            completedTokenSeparator: token.separator,
            isCompletedTokenAutoCorrectionSuppressed: token.isAutoCorrectionSuppressed,
            isSecureInputEnabled: isSecureInputEnabled,
            isPasswordField: isPasswordField
        )
    }

    public static func replacementPlan(
        token: WordTracker.CompletedToken,
        trackedTailBeforeCorrection: String?,
        engine: AutoCorrectionEngine
    ) -> AutoCorrectionRuntimePlan {
        guard let decision = engine.correction(for: token.word) else {
            return .noCorrection
        }

        guard let replacement = AutoCorrectionReplacementPolicy.replacement(
            for: decision,
            completedToken: token,
            trackedTailBeforeCorrection: trackedTailBeforeCorrection
        ) else {
            return .planFailure(decision: decision)
        }

        return .replacement(decision: decision, replacement: replacement)
    }
}
