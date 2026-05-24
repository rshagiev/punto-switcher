import AppKit
import Foundation
import PuntoCore
import PuntoSettings

/// App-side executor for manual text actions that capture and replace text.
///
/// Core policies own route and replacement planning. This coordinator applies
/// layout conversion and toggle-case plans through the shared text-action
/// runtime so AppDelegate stays at the hotkey/lifecycle wiring boundary.
final class ManualTextActionRuntimeCoordinator {
    private let settingsManager: SettingsManager
    private let wordTracker: WordTracker
    private let textState: TextRuntimeStateCoordinator
    private let textAccessor: TextAccessor
    private let textActionRuntime: TextActionRuntimeCoordinator
    private let undoRuntime: UndoRuntimeCoordinator
    private let layoutConverter: LayoutConverter
    private let currentApplicationBundleID: () -> String?

    init(
        settingsManager: SettingsManager,
        wordTracker: WordTracker,
        textState: TextRuntimeStateCoordinator,
        textAccessor: TextAccessor,
        textActionRuntime: TextActionRuntimeCoordinator,
        undoRuntime: UndoRuntimeCoordinator,
        layoutConverter: LayoutConverter,
        currentApplicationBundleID: @escaping () -> String?
    ) {
        self.settingsManager = settingsManager
        self.wordTracker = wordTracker
        self.textState = textState
        self.textAccessor = textAccessor
        self.textActionRuntime = textActionRuntime
        self.undoRuntime = undoRuntime
        self.layoutConverter = layoutConverter
        self.currentApplicationBundleID = currentApplicationBundleID
    }

    func handleConvertLayout() {
        let startTime = CFAbsoluteTimeGetCurrent()
        let contextID = currentApplicationBundleID()
        logConvertTrigger()

        guard textActionRuntime.preflightTextAction(.layoutConversion) else {
            return
        }

        _ = textActionRuntime.beginReplacementWindow()
        defer {
            let totalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            PuntoLog.info("⏱️ TOTAL conversion time: \(String(format: "%.1f", totalTime))ms")
        }
        defer {
            textActionRuntime.finishReplacementWindow()
        }

        if undoRuntime.performUndoIfAvailable(contextID: contextID) {
            return
        }

        let captureStart = CFAbsoluteTimeGetCurrent()
        let lastTrackedWord = wordTracker.getLastWord()
        let lastTrackedTail = wordTracker.getTypedTail()
        let capturedText = textAccessor.captureSelectedText(
            lastTrackedWord: lastTrackedWord,
            lastTrackedTail: lastTrackedTail
        )
        let captureTime = (CFAbsoluteTimeGetCurrent() - captureStart) * 1000

        let plan = ManualLayoutConversionPolicy.plan(
            capturedText: capturedText,
            lastWord: lastTrackedWord,
            lastTrackedTail: lastTrackedTail,
            russianLayoutType: settingsManager.russianKeyboardLayoutType,
            converter: layoutConverter
        )

        let runtimePlan = ManualLayoutConversionRuntimePolicy.runtimePlan(
            from: plan,
            suppressAutoCorrectionAfterManualConversion: settingsManager.suppressAutoCorrectionAfterManualConversion
        )
        applyManualLayoutRuntimePlan(runtimePlan, captureTime: captureTime, contextID: contextID)
    }

    func handleToggleCase() {
        PuntoLog.info(">>> Toggle case triggered <<<")
        let contextID = currentApplicationBundleID()

        guard textActionRuntime.preflightTextAction(.toggleCase) else {
            return
        }

        _ = textActionRuntime.beginReplacementWindow()
        defer {
            textActionRuntime.finishReplacementWindow()
        }

        let capturedText = textAccessor.captureSelectedText(
            lastTrackedWord: wordTracker.getLastWord(),
            lastTrackedTail: wordTracker.getTypedTail()
        )
        let runtimePlan = ToggleCaseConversionPolicy.runtimePlan(
            from: ToggleCaseConversionPolicy.plan(capturedText: capturedText)
        )
        applyToggleCaseRuntimePlan(runtimePlan, contextID: contextID)
    }

    private func applyManualLayoutRuntimePlan(
        _ runtimePlan: ManualLayoutConversionRuntimePlan,
        captureTime: Double,
        contextID: String?
    ) {
        switch runtimePlan {
        case .blockedCapture(let capturedText, let logMessage):
            PuntoLog.info(logMessage)
            textActionRuntime.clearStateAfterBlockedCapture(capturedText)

        case .replace(let replacementPlan):
            PuntoLog.info("⏱️ \(replacementPlan.captureTimingLabel): \(String(format: "%.1f", captureTime))ms")
            PuntoLog.info(replacementPlan.originalTextLogMessage)
            PuntoLog.info(replacementPlan.convertedTextLogMessage)
            applyManualLayoutReplacement(replacementPlan, contextID: contextID)

        case .clearTrackedText(let reason, let logMessage):
            PuntoLog.info(logMessage)
            textState.clearTrackedText(reason: reason)

        case .skip(let logMessage):
            PuntoLog.info(logMessage)

        case .noText(let logMessage):
            PuntoLog.info(logMessage)
        }
    }

    private func applyManualLayoutReplacement(
        _ replacementPlan: ManualLayoutReplacementRuntimePlan,
        contextID: String?
    ) {
        let replaceStart = CFAbsoluteTimeGetCurrent()
        let replacementApplied = textAccessor.replaceCapturedText(
            replacementPlan.replacement.capturedText,
            with: replacementPlan.replacement.convertedText,
            keepSelection: replacementPlan.replacement.keepSelection
        )
        let replaceTime = (CFAbsoluteTimeGetCurrent() - replaceStart) * 1000
        PuntoLog.info("⏱️ \(replacementPlan.replacementTimingLabel): \(String(format: "%.1f", replaceTime))ms")

        guard replacementApplied else {
            PuntoLog.info(replacementPlan.failedReplacementLogMessage)
            textActionRuntime.clearTrackedTextAfterFailedReplacement(method: replacementPlan.failedReplacementMethod)
            return
        }

        textActionRuntime.commitSuccessfulTextReplacement(
            replacementPlan.commitPlan,
            contextID: contextID
        )
    }

    private func applyToggleCaseRuntimePlan(_ runtimePlan: ToggleCaseRuntimePlan, contextID: String?) {
        switch runtimePlan {
        case .blockedCapture(let capturedText, let logMessage):
            PuntoLog.info(logMessage)
            textActionRuntime.clearStateAfterBlockedCapture(capturedText)

        case .replace(let replacementPlan):
            PuntoLog.info(replacementPlan.logMessage)
            let replacementApplied = textAccessor.replaceCapturedText(
                replacementPlan.capturedText,
                with: replacementPlan.replacement.toggledText,
                keepSelection: replacementPlan.keepSelection
            )
            if replacementApplied {
                textActionRuntime.commitSuccessfulTextReplacement(
                    replacementPlan.commitPlan,
                    contextID: contextID
                )
            } else {
                PuntoLog.info(replacementPlan.failedReplacementLogMessage)
                textActionRuntime.clearTrackedTextAfterFailedReplacement(method: replacementPlan.failedReplacementMethod)
            }

        case .skipped(let logMessage):
            PuntoLog.info(logMessage)

        case .noText(let logMessage):
            PuntoLog.info(logMessage)
        }
    }

    private func logConvertTrigger() {
        let timeSinceLastKey: String
        if let lastKey = textState.lastKeyPressTime {
            let elapsed = Date().timeIntervalSince(lastKey) * 1000
            timeSinceLastKey = String(format: "%.0fms", elapsed)
        } else {
            timeSinceLastKey = "n/a"
        }

        if let frontApp = NSWorkspace.shared.frontmostApplication {
            PuntoLog.info(">>> Convert triggered <<< app='\(frontApp.localizedName ?? "?")' sinceLastKey=\(timeSinceLastKey)")
        } else {
            PuntoLog.info(">>> Convert triggered <<< (no frontmost app) sinceLastKey=\(timeSinceLastKey)")
        }
    }
}
