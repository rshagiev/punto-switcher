import Foundation
import PuntoCore
import PuntoSettings

/// App-side executor for successful text replacement commit effects.
///
/// Text action policies build commit plans. This coordinator applies the shared
/// side effects after manual conversion, toggle case, auto-correction, and
/// undo: tracked-tail replay, layout switch, icon flash, sound, statistics,
/// learned rules, and redo/undo session recording.
final class TextReplacementCommitRuntimeCoordinator {
    private let settingsManager: SettingsManager
    private let textState: TextRuntimeStateCoordinator
    private let wordTracker: WordTracker
    private let soundFeedbackController: SoundFeedbackController
    private let layoutSwitchRuntime: LayoutSwitchRuntimeCoordinator
    private let flashStatusIcon: () -> Void

    init(
        settingsManager: SettingsManager,
        textState: TextRuntimeStateCoordinator,
        wordTracker: WordTracker,
        soundFeedbackController: SoundFeedbackController,
        layoutSwitchRuntime: LayoutSwitchRuntimeCoordinator,
        flashStatusIcon: @escaping () -> Void
    ) {
        self.settingsManager = settingsManager
        self.textState = textState
        self.wordTracker = wordTracker
        self.soundFeedbackController = soundFeedbackController
        self.layoutSwitchRuntime = layoutSwitchRuntime
        self.flashStatusIcon = flashStatusIcon
    }

    func commitSuccessfulTextReplacement(_ plan: TextReplacementCommitPlan, contextID: String?) {
        if plan.clearTrackedTextBeforeTailCommit {
            textState.clearTrackedText(reason: "conversion completed")
        }

        commitTrackedTail(plan.trackedTailCommit)

        if let layoutSwitchCommit = plan.layoutSwitchCommit {
            layoutSwitchRuntime.switchLayoutIfEnabled(
                layoutSwitchCommit.targetLayout,
                surface: layoutSwitchCommit.surface
            )
        }

        flashStatusIcon()
        soundFeedbackController.play(plan.soundFeedbackEvent)
        if let productStatisticsEvent = plan.productStatisticsEvent {
            settingsManager.recordProductStatisticsEvent(productStatisticsEvent)
        }

        textState.conversionSession.record(plan.conversionRecordCommit, contextID: contextID)
    }

    func currentEnglishLayoutVariant() -> KeyboardLayoutVariant {
        layoutSwitchRuntime.currentEnglishLayoutVariant()
    }

    func commitSuccessfulUndo(
        _ plan: UndoAppliedCommitPlan,
        contextID: String?,
        reloadAutoCorrectionRules: () -> Void
    ) {
        if let layoutSwitchTarget = plan.layoutSwitchTarget {
            layoutSwitchRuntime.switchLayoutIfEnabled(layoutSwitchTarget, surface: .undo)
        } else if let skippedLayoutSwitchLogMessage = plan.skippedLayoutSwitchLogMessage {
            PuntoLog.info(skippedLayoutSwitchLogMessage)
        }

        flashStatusIcon()
        soundFeedbackController.play(plan.soundFeedbackEvent)
        settingsManager.recordProductStatisticsEvent(plan.productStatisticsEvent)
        commitTrackedTail(plan.trackedTailCommit)

        if let learnedRules = plan.learnedAutoCorrectionRules {
            settingsManager.autoCorrectionRules = learnedRules
            reloadAutoCorrectionRules()
            if let learnedRuleLogMessage = plan.learnedRuleLogMessage {
                PuntoLog.info(learnedRuleLogMessage)
            }
        }

        textState.conversionSession.record(plan.conversionRecordCommit, contextID: contextID)
    }

    private func commitTrackedTail(_ trackedTailCommit: TrackedTailCommit?) {
        guard let trackedTailCommit else {
            return
        }

        wordTracker.replaceTrackedTail(
            with: trackedTailCommit.text,
            reason: trackedTailCommit.reason,
            suppressAutoCorrectionForCurrentToken: trackedTailCommit.suppressAutoCorrectionForCurrentToken,
            englishLayoutVariant: layoutSwitchRuntime.currentEnglishLayoutVariant(),
            russianLayoutType: settingsManager.russianKeyboardLayoutType
        )
    }
}
