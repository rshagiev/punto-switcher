import Foundation
import PuntoCore
import PuntoSettings

/// App-side executor for completed-token auto-correction.
///
/// Pure PuntoCore policies decide routing, security, rule lookup and replacement
/// planning. This coordinator owns the live rule engine and applies those plans
/// through TextAccessor and TextActionRuntimeCoordinator.
final class AutoCorrectionRuntimeCoordinator {
    private let settingsManager: SettingsManager
    private let wordTracker: WordTracker
    private let textState: TextRuntimeStateCoordinator
    private let textAccessor: TextAccessor
    private let textActionRuntime: TextActionRuntimeCoordinator
    private let currentApplicationBundleID: () -> String?
    private let isCurrentApplicationDisabled: () -> Bool

    private var autoCorrectionEngine = AutoCorrectionEngine(rules: [])

    init(
        settingsManager: SettingsManager,
        wordTracker: WordTracker,
        textState: TextRuntimeStateCoordinator,
        textAccessor: TextAccessor,
        textActionRuntime: TextActionRuntimeCoordinator,
        currentApplicationBundleID: @escaping () -> String?,
        isCurrentApplicationDisabled: @escaping () -> Bool
    ) {
        self.settingsManager = settingsManager
        self.wordTracker = wordTracker
        self.textState = textState
        self.textAccessor = textAccessor
        self.textActionRuntime = textActionRuntime
        self.currentApplicationBundleID = currentApplicationBundleID
        self.isCurrentApplicationDisabled = isCurrentApplicationDisabled
        reloadRules()
    }

    func reloadRules() {
        autoCorrectionEngine = AutoCorrectionEngine(rules: settingsManager.autoCorrectionRules)
    }

    func handleAutoCorrectionIfNeeded() {
        let token = wordTracker.consumeCompletedToken()
        let gatePlan = AutoCorrectionRuntimePolicy.gatePlan(
            token: token,
            isEnabled: settingsManager.isEnabled,
            autoCorrectionEnabled: settingsManager.autoCorrectionEnabled,
            autoCorrectOnEnterAndTab: settingsManager.autoCorrectOnEnterAndTab,
            isConversionInProgress: textState.isConversionInProgress,
            isCurrentApplicationDisabled: isCurrentApplicationDisabled(),
            isSecureInputEnabled: textAccessor.isSecureInputEnabled(),
            isPasswordField: textAccessor.isPasswordField()
        )

        let plan: AutoCorrectionRuntimeAttemptPlan
        switch gatePlan {
        case .skipped(let completedTokenStatisticsEvent, let logMessage):
            recordCompletedTokenStatistics(completedTokenStatisticsEvent)
            if let logMessage {
                PuntoLog.info(logMessage)
            }
            return

        case .blockAndClear(let completedTokenStatisticsEvent, let reason, let logMessage):
            recordCompletedTokenStatistics(completedTokenStatisticsEvent)
            textActionRuntime.clearTextStateForSecureInput(context: reason)
            if let logMessage {
                PuntoLog.info(logMessage)
            }
            return

        case .proceed(let completedTokenStatisticsEvent, let token):
            reloadRules()
            plan = AutoCorrectionRuntimePolicy.runtimeAttemptPlan(
                token: token,
                completedTokenStatisticsEvent: completedTokenStatisticsEvent,
                trackedTailBeforeCorrection: wordTracker.getTypedTailPreservingBoundaryWhitespace(),
                engine: autoCorrectionEngine
            )
        }

        switch plan {
        case .noCorrection(let completedTokenStatisticsEvent):
            recordCompletedTokenStatistics(completedTokenStatisticsEvent)

        case .planFailure(let completedTokenStatisticsEvent, let logMessage, let conversionSessionClearReason):
            recordCompletedTokenStatistics(completedTokenStatisticsEvent)
            PuntoLog.info(logMessage)
            if let conversionSessionClearReason {
                textState.clearConversionSession(reason: conversionSessionClearReason)
            }

        case .replacement(let completedTokenStatisticsEvent, let logMessage, let replacement, let commitPlan):
            recordCompletedTokenStatistics(completedTokenStatisticsEvent)
            PuntoLog.info(logMessage)
            applyReplacement(replacement, commitPlan: commitPlan)
        }
    }

    private func applyReplacement(
        _ replacement: AutoCorrectionReplacement,
        commitPlan: TextReplacementCommitPlan
    ) {
        _ = textActionRuntime.beginReplacementWindow()
        defer {
            textActionRuntime.finishReplacementWindow()
        }

        let applied = textAccessor.replaceRecentText(
            length: replacement.replacementLength,
            with: replacement.replacementText
        )
        if applied {
            textActionRuntime.commitSuccessfulTextReplacement(
                commitPlan,
                contextID: currentApplicationBundleID()
            )
        } else {
            PuntoLog.info("Auto-correction replacement aborted")
            textActionRuntime.clearTrackedTextAfterFailedReplacement(method: replacement.undoMethod)
        }
    }

    private func recordCompletedTokenStatistics(_ event: ProductStatisticsEvent?) {
        if let event {
            settingsManager.recordProductStatisticsEvent(event)
        }
    }
}
