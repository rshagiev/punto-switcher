import Foundation

public enum AutoCorrectionRuntimePlan: Equatable {
    case noCorrection
    case replacement(decision: AutoCorrectionDecision, replacement: AutoCorrectionReplacement)
    case planFailure(decision: AutoCorrectionDecision)
}

public enum AutoCorrectionRuntimeGatePlan: Equatable {
    case skipped(
        completedTokenStatisticsEvent: ProductStatisticsEvent?,
        logMessage: String?
    )
    case blockAndClear(
        completedTokenStatisticsEvent: ProductStatisticsEvent?,
        reason: String,
        logMessage: String?
    )
    case proceed(
        completedTokenStatisticsEvent: ProductStatisticsEvent?,
        token: WordTracker.CompletedToken
    )
}

public enum AutoCorrectionRuntimeAttemptPlan: Equatable {
    case noCorrection(completedTokenStatisticsEvent: ProductStatisticsEvent?)
    case planFailure(
        completedTokenStatisticsEvent: ProductStatisticsEvent?,
        logMessage: String,
        conversionSessionClearReason: String?
    )
    case replacement(
        completedTokenStatisticsEvent: ProductStatisticsEvent?,
        logMessage: String,
        replacement: AutoCorrectionReplacement,
        commitPlan: TextReplacementCommitPlan
    )
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

    public static func gatePlan(
        token: WordTracker.CompletedToken?,
        isEnabled: Bool,
        autoCorrectionEnabled: Bool,
        autoCorrectOnEnterAndTab: Bool = true,
        isConversionInProgress: Bool,
        isCurrentApplicationDisabled: Bool,
        isSecureInputEnabled: Bool,
        isPasswordField: Bool
    ) -> AutoCorrectionRuntimeGatePlan {
        let completedTokenStatisticsEvent = ProductStatisticsPolicy.eventAfterCompletedTokenConsumption(token != nil)

        let routePreflight = routePreflightAction(
            isEnabled: isEnabled,
            autoCorrectionEnabled: autoCorrectionEnabled,
            autoCorrectOnEnterAndTab: autoCorrectOnEnterAndTab,
            isConversionInProgress: isConversionInProgress,
            isCurrentApplicationDisabled: isCurrentApplicationDisabled,
            token: token
        )

        switch routePreflight {
        case .proceed:
            break
        case .consumeTokenAndSkip, .skip:
            return .skipped(
                completedTokenStatisticsEvent: completedTokenStatisticsEvent,
                logMessage: AutoCorrectionPreflightPolicy.logMessage(for: routePreflight)
            )
        case .blockAndClear(let reason):
            return .blockAndClear(
                completedTokenStatisticsEvent: completedTokenStatisticsEvent,
                reason: reason,
                logMessage: AutoCorrectionPreflightPolicy.logMessage(for: routePreflight)
            )
        }

        guard let token else {
            return .skipped(completedTokenStatisticsEvent: completedTokenStatisticsEvent, logMessage: nil)
        }

        let securityPreflight = securityPreflightAction(
            token: token,
            autoCorrectOnEnterAndTab: autoCorrectOnEnterAndTab,
            isSecureInputEnabled: isSecureInputEnabled,
            isPasswordField: isPasswordField
        )

        switch securityPreflight {
        case .proceed:
            break
        case .consumeTokenAndSkip, .skip:
            return .skipped(
                completedTokenStatisticsEvent: completedTokenStatisticsEvent,
                logMessage: AutoCorrectionPreflightPolicy.logMessage(for: securityPreflight)
            )
        case .blockAndClear(let reason):
            return .blockAndClear(
                completedTokenStatisticsEvent: completedTokenStatisticsEvent,
                reason: reason,
                logMessage: AutoCorrectionPreflightPolicy.logMessage(for: securityPreflight)
            )
        }

        return .proceed(
            completedTokenStatisticsEvent: completedTokenStatisticsEvent,
            token: token
        )
    }

    public static func runtimeAttemptPlan(
        token: WordTracker.CompletedToken,
        completedTokenStatisticsEvent: ProductStatisticsEvent?,
        trackedTailBeforeCorrection: String?,
        engine: AutoCorrectionEngine
    ) -> AutoCorrectionRuntimeAttemptPlan {
        switch replacementPlan(
            token: token,
            trackedTailBeforeCorrection: trackedTailBeforeCorrection,
            engine: engine
        ) {
        case .noCorrection:
            return .noCorrection(completedTokenStatisticsEvent: completedTokenStatisticsEvent)

        case .planFailure:
            return .planFailure(
                completedTokenStatisticsEvent: completedTokenStatisticsEvent,
                logMessage: "Auto-correction aborted: replacement plan could not be derived",
                conversionSessionClearReason: AutoCorrectionReplacementPolicy.shouldClearConversionSessionAfterPlanFailure()
                    ? "auto-correction plan derivation failed"
                    : nil
            )

        case .replacement(let decision, let replacement):
            return .replacement(
                completedTokenStatisticsEvent: completedTokenStatisticsEvent,
                logMessage: "Auto-correcting completed word '\(decision.original)' -> '\(decision.replacement)'",
                replacement: replacement,
                commitPlan: TextReplacementCommitPolicy.autoCorrection(decision: decision, replacement: replacement)
            )
        }
    }
}
