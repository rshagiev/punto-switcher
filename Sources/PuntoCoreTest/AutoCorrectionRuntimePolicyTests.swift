import Foundation
import PuntoCore

func runAutoCorrectionRuntimePolicyTests() throws {
    let token = WordTracker.CompletedToken(word: "ghbdtn", separator: " ")
    let suppressedToken = WordTracker.CompletedToken(
        word: "ghbdtn",
        separator: " ",
        isAutoCorrectionSuppressed: true
    )

    try expect(
        AutoCorrectionRuntimePolicy.routePreflightAction(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            token: token
        ),
        .proceed,
        "auto-correction runtime route proceeds for enabled completed token"
    )
    try expect(
        AutoCorrectionRuntimePolicy.routePreflightAction(
            isEnabled: false,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            token: token
        ),
        .consumeTokenAndSkip(reason: "Punto disabled"),
        "auto-correction runtime route consumes token when Punto is disabled"
    )
    try expect(
        AutoCorrectionRuntimePolicy.routePreflightAction(
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            token: suppressedToken
        ),
        .consumeTokenAndSkip(reason: "completed token auto-correction cancelled"),
        "auto-correction runtime route consumes suppressed token"
    )
    try expect(
        AutoCorrectionRuntimePolicy.securityPreflightAction(
            token: token,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "auto-correction runtime security blocks password fields"
    )
    try expect(
        AutoCorrectionRuntimePolicy.securityPreflightAction(
            token: token,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "auto-correction runtime security prioritizes secure input"
    )

    let rule = AutoCorrectionRule(trigger: "ghbdtn", replacement: "привет")
    let engine = AutoCorrectionEngine(rules: [rule])
    try expect(
        AutoCorrectionRuntimePolicy.replacementPlan(
            token: token,
            trackedTailBeforeCorrection: "say ghbdtn ",
            engine: engine
        ),
        .replacement(
            decision: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule),
            replacement: AutoCorrectionReplacement(
                originalText: "ghbdtn ",
                replacementText: "привет ",
                replacementLength: 7,
                undoMethod: .keyboardBackspacePaste,
                trackedTailAfterReplacement: "say привет "
            )
        ),
        "auto-correction runtime derives executable replacement plan"
    )
    try expect(
        AutoCorrectionRuntimePolicy.replacementPlan(
            token: WordTracker.CompletedToken(word: "unknown", separator: " "),
            trackedTailBeforeCorrection: "unknown ",
            engine: engine
        ),
        .noCorrection,
        "auto-correction runtime reports no correction without a matching rule"
    )
    try expect(
        AutoCorrectionRuntimePolicy.replacementPlan(
            token: WordTracker.CompletedToken(word: "ghbdtn", separator: ""),
            trackedTailBeforeCorrection: "ghbdtn",
            engine: engine
        ),
        .planFailure(decision: AutoCorrectionDecision(original: "ghbdtn", replacement: "привет", rule: rule)),
        "auto-correction runtime reports plan failure for invalid completed token boundary"
    )

    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed(completedTokenStatisticsEvent: .completedWord, token: token),
        "auto-correction runtime gate proceeds after route and security checks"
    )
    try expect(
        AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
            token: token,
            completedTokenStatisticsEvent: .completedWord,
            trackedTailBeforeCorrection: "say ghbdtn ",
            engine: engine
        ),
        .replacement(
            completedTokenStatisticsEvent: .completedWord,
            logMessage: "Auto-correcting completed word 'ghbdtn' -> 'привет'",
            replacement: AutoCorrectionReplacement(
                originalText: "ghbdtn ",
                replacementText: "привет ",
                replacementLength: 7,
                undoMethod: .keyboardBackspacePaste,
                trackedTailAfterReplacement: "say привет "
            ),
            commitPlan: TextReplacementCommitPlan(
                trackedTailCommit: TrackedTailCommit(text: "say привет ", reason: "auto-correction completed"),
                layoutSwitchCommit: nil,
                soundFeedbackEvent: .autoCorrection,
                productStatisticsEvent: .automaticSwitch,
                conversionRecordCommit: ConversionRecordCommit(
                    originalText: "ghbdtn ",
                    convertedText: "привет ",
                    replacementMethod: .keyboardBackspacePaste,
                    origin: .autoCorrection(rule: rule)
                )
            )
        ),
        "auto-correction runtime attempt includes statistics, log, replacement, and commit plan"
    )
    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: nil,
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipped(completedTokenStatisticsEvent: nil, logMessage: nil),
        "auto-correction runtime gate skips cleanly without completed token"
    )
    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: false,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipped(
            completedTokenStatisticsEvent: .completedWord,
            logMessage: "Auto-correction skipped: Punto disabled"
        ),
        "auto-correction runtime gate consumes completed-token stats when route skips"
    )
    try expect(
        AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: true,
            autoCorrectionEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(
            completedTokenStatisticsEvent: .completedWord,
            reason: "password field",
            logMessage: "Auto-correction blocked for secure input"
        ),
        "auto-correction runtime gate blocks and clears secure/password input before tail lookup"
    )
    try expect(
        AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
            token: WordTracker.CompletedToken(word: "unknown", separator: " "),
            completedTokenStatisticsEvent: .completedWord,
            trackedTailBeforeCorrection: "unknown ",
            engine: engine
        ),
        .noCorrection(completedTokenStatisticsEvent: .completedWord),
        "auto-correction runtime attempt preserves completed-token stats for no-op rule lookup"
    )
    try expect(
        AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
            token: WordTracker.CompletedToken(word: "ghbdtn", separator: ""),
            completedTokenStatisticsEvent: .completedWord,
            trackedTailBeforeCorrection: "ghbdtn",
            engine: engine
        ),
        .planFailure(
            completedTokenStatisticsEvent: .completedWord,
            logMessage: "Auto-correction aborted: replacement plan could not be derived",
            conversionSessionClearReason: "auto-correction plan derivation failed"
        ),
        "auto-correction runtime attempt owns plan-failure cleanup reason"
    )
}

