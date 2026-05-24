import Foundation
import PuntoCore

/// App-side executor for scoped conversion undo.
///
/// PuntoCore derives undo plans and commit effects; this coordinator applies
/// them through the shared text-action runtime so repeat-convert undo and the
/// explicit cancel-layout-change shortcut keep identical behavior.
final class UndoRuntimeCoordinator {
    private let settingsManager: SettingsManager
    private let textState: TextRuntimeStateCoordinator
    private let textAccessor: TextAccessor
    private let textActionRuntime: TextActionRuntimeCoordinator
    private let layoutConverter: LayoutConverter
    private let reloadAutoCorrectionRules: () -> Void

    init(
        settingsManager: SettingsManager,
        textState: TextRuntimeStateCoordinator,
        textAccessor: TextAccessor,
        textActionRuntime: TextActionRuntimeCoordinator,
        layoutConverter: LayoutConverter,
        reloadAutoCorrectionRules: @escaping () -> Void
    ) {
        self.settingsManager = settingsManager
        self.textState = textState
        self.textAccessor = textAccessor
        self.textActionRuntime = textActionRuntime
        self.layoutConverter = layoutConverter
        self.reloadAutoCorrectionRules = reloadAutoCorrectionRules
    }

    func handleCancelLayoutChange(contextID: String?) {
        PuntoLog.info(">>> Cancel layout change triggered <<<")

        guard textActionRuntime.preflightTextAction(.layoutConversion) else {
            return
        }

        _ = textActionRuntime.beginReplacementWindow()
        defer {
            textActionRuntime.finishReplacementWindow()
        }

        guard performUndoIfAvailable(contextID: contextID) else {
            PuntoLog.info("Cancel layout change: no recent conversion to undo")
            return
        }
    }

    @discardableResult
    func performUndoIfAvailable(contextID: String?) -> Bool {
        let plan = UndoRuntimePolicy.plan(
            record: textState.conversionSession.undoCandidate(contextID: contextID),
            autoCorrectionRules: settingsManager.autoCorrectionRules,
            isUndoLearningEnabled: settingsManager.autoCorrectionUndoLearningEnabled
        )

        switch plan {
        case .noCandidate:
            return false

        case .planFailure(let record):
            applyPlanFailure(record)
            return true

        case .replacement(let plan):
            applyReplacement(plan, contextID: contextID)
            return true
        }
    }

    private func applyPlanFailure(_ record: ConversionRecord) {
        let action = UndoRuntimePolicy.planFailureAction(record: record)
        if let logMessage = action.logMessage {
            PuntoLog.info(logMessage)
        }
        if action.clearConversionSession,
           let reason = action.clearConversionSessionReason {
            textState.clearConversionSession(reason: reason)
        }
    }

    private func applyReplacement(_ plan: UndoRuntimeReplacement, contextID: String?) {
        let record = plan.record
        let undoReplacement = plan.undoReplacement
        PuntoLog.info("Undo: reverting '\(record.convertedText)' back to '\(record.originalText)'")

        let undoApplied = textAccessor.replaceCapturedText(
            undoReplacement.capturedText,
            with: undoReplacement.replacementText,
            keepSelection: undoReplacement.keepSelection
        )
        guard undoApplied else {
            PuntoLog.info("Undo aborted: replacement was not applied")
            textActionRuntime.clearStateAfterFailedUndoReplacement(
                method: undoReplacement.capturedText.replacementMethod
            )
            return
        }

        let commitPlan = UndoRuntimePolicy.appliedCommitPlan(for: plan, converter: layoutConverter)
        textActionRuntime.commitSuccessfulUndo(
            commitPlan,
            contextID: contextID,
            reloadAutoCorrectionRules: reloadAutoCorrectionRules
        )
    }
}
