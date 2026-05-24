import AppKit
import Foundation
import PuntoCore
import PuntoSettings
import PuntoRuntime

/// App-side executor for shared text-action runtime effects.
///
/// PuntoCore policies still decide what should happen. This coordinator applies
/// those decisions to replacement-window state, tracked text, undo records,
/// layout switching, sound feedback, statistics, and secure-input diagnostics.
final class TextActionRuntimeCoordinator {
    private let settingsManager: SettingsManager
    private let textState: TextRuntimeStateCoordinator
    private let textAccessor: TextAccessor
    private let inputSourceManager: InputSourceManager
    private let wordTracker: WordTracker
    private let soundFeedbackController: SoundFeedbackController
    private let appRuntime: ApplicationRuntimeCoordinator
    private let currentApplicationBundleID: () -> String?
    private let runningApplicationBundleIDs: () -> [String?]
    private let isCurrentApplicationCompletelyDisabled: () -> Bool
    private let flashStatusIcon: () -> Void

    init(
        settingsManager: SettingsManager,
        textState: TextRuntimeStateCoordinator,
        textAccessor: TextAccessor,
        inputSourceManager: InputSourceManager,
        wordTracker: WordTracker,
        soundFeedbackController: SoundFeedbackController,
        appRuntime: ApplicationRuntimeCoordinator,
        currentApplicationBundleID: @escaping () -> String?,
        runningApplicationBundleIDs: @escaping () -> [String?],
        isCurrentApplicationCompletelyDisabled: @escaping () -> Bool,
        flashStatusIcon: @escaping () -> Void
    ) {
        self.settingsManager = settingsManager
        self.textState = textState
        self.textAccessor = textAccessor
        self.inputSourceManager = inputSourceManager
        self.wordTracker = wordTracker
        self.soundFeedbackController = soundFeedbackController
        self.appRuntime = appRuntime
        self.currentApplicationBundleID = currentApplicationBundleID
        self.runningApplicationBundleIDs = runningApplicationBundleIDs
        self.isCurrentApplicationCompletelyDisabled = isCurrentApplicationCompletelyDisabled
        self.flashStatusIcon = flashStatusIcon
    }

    func beginReplacementWindow() -> ReplacementWindowAction {
        textState.beginReplacementWindow()
    }

    func finishReplacementWindow() {
        textState.finishReplacementWindow()
    }

    func currentEnglishLayoutVariant() -> KeyboardLayoutVariant {
        KeyboardLayoutVariantPolicy.effectiveEnglishLayoutVariant(
            currentSourceID: inputSourceManager.currentLayoutID(),
            selectedEnglishSourceID: inputSourceManager.languageLayoutID(.english),
            preferredEnglishSourceID: settingsManager.preferredEnglishInputSourceID
        )
    }

    func preflightTextAction(_ kind: TextActionKind) -> Bool {
        func handle(_ action: TextActionPreflightAction) -> Bool {
            switch action {
            case .proceed:
                return true

            case .skip:
                if let message = TextActionPreflightPolicy.logMessage(action: action, kind: kind) {
                    PuntoLog.info(message)
                }
                return false

            case .blockAndClear(let reason):
                clearTextStateForSecureInput(context: reason)
                if let message = TextActionPreflightPolicy.logMessage(action: action, kind: kind) {
                    PuntoLog.info(message)
                }
                return false
            }
        }

        let routeAction = TextActionRuntimePreflightPolicy.routeAction(
            kind: kind,
            isEnabled: settingsManager.isEnabled,
            isManualConversionDisabled: settingsManager.manualConversionDisabled,
            isConversionInProgress: textState.isConversionInProgress,
            isCurrentApplicationDisabled: isCurrentApplicationCompletelyDisabled()
        )
        guard handle(routeAction) else {
            return false
        }

        if textAccessor.isSecureInputEnabled() {
            return handle(TextActionRuntimePreflightPolicy.securityAction(
                kind: kind,
                isSecureInputEnabled: true,
                isPasswordField: false
            ))
        }

        if textAccessor.isPasswordField() {
            return handle(TextActionRuntimePreflightPolicy.securityAction(
                kind: kind,
                isSecureInputEnabled: false,
                isPasswordField: true
            ))
        }

        return true
    }

    func commitSuccessfulTextReplacement(_ plan: TextReplacementCommitPlan, contextID: String?) {
        if plan.clearTrackedTextBeforeTailCommit {
            textState.clearTrackedText(reason: "conversion completed")
        }

        if let trackedTailCommit = plan.trackedTailCommit {
            wordTracker.replaceTrackedTail(
                with: trackedTailCommit.text,
                reason: trackedTailCommit.reason,
                suppressAutoCorrectionForCurrentToken: trackedTailCommit.suppressAutoCorrectionForCurrentToken,
                englishLayoutVariant: currentEnglishLayoutVariant(),
                russianLayoutType: settingsManager.russianKeyboardLayoutType
            )
        }

        if let layoutSwitchCommit = plan.layoutSwitchCommit {
            switchLayoutIfEnabled(layoutSwitchCommit.targetLayout, surface: layoutSwitchCommit.surface)
        }

        flashStatusIcon()
        soundFeedbackController.play(plan.soundFeedbackEvent)
        if let productStatisticsEvent = plan.productStatisticsEvent {
            settingsManager.recordProductStatisticsEvent(productStatisticsEvent)
        }

        textState.conversionSession.record(plan.conversionRecordCommit, contextID: contextID)
    }

    func switchLayoutIfEnabled(
        _ targetLayout: LayoutConverter.DetectedLayout,
        surface: LayoutConversionSurface
    ) {
        let plan = LayoutSwitchRuntimePolicy.plan(
            targetLayout: targetLayout,
            surface: surface,
            switchLayoutAfterConversion: settingsManager.switchLayoutAfterConversion,
            switchLayoutAfterSelectedTextConversion: settingsManager.switchLayoutAfterSelectedTextConversion
        )

        switch plan {
        case .skip:
            return

        case .unsupportedTarget(let clearInputSourceIgnoreDeadline):
            if clearInputSourceIgnoreDeadline {
                textState.ignoreInputSourceChangesUntil = nil
            }

        case .switchTo(let request):
            textState.ignoreInputSourceChangesUntil = request.ignoreInputSourceChangesUntil
            PuntoLog.debug("ignoreInputSourceChangesUntil set (switching to \(request.targetLayout))")
            let language = keyboardLanguage(for: request.language)
            let targetLayoutID = inputSourceManager.languageLayoutID(language)
            let didSwitch = inputSourceManager.switchTo(language)
            playInputSourceSwitchSound(
                targetLayout: request.targetLayout,
                didSwitch: didSwitch,
                context: .textReplacement
            )
            appRuntime.rememberProgrammaticLayoutSwitch(targetLayoutID: targetLayoutID, didSwitch: didSwitch)
        }
    }

    func clearTextStateForSecureInput(context: String = "secure input") {
        let action = TextTrackingSecurityPolicy.clearAction(
            isSecureInputEnabled: context == "secure input",
            isPasswordField: context == "password field"
        )

        textState.apply(action)
        if action.shouldWriteDiagnostics, let diagnosticContext = action.diagnosticContext {
            writeSecureInputDiagnostics(context: diagnosticContext)
        }
        if let logMessage = action.logMessage {
            PuntoLog.info(logMessage)
        }
    }

    func clearTrackedTextAfterFailedReplacement(method: TextReplacementMethod) {
        let action = ReplacementFailurePolicy.actionAfterFailedReplacement(method: method)
        textState.apply(action)
    }

    func clearStateAfterFailedUndoReplacement(method: TextReplacementMethod) {
        let action = UndoReplacementPolicy.actionAfterFailedReplacement(method: method)
        textState.apply(action)
    }

    func clearStateAfterBlockedCapture(_ capturedText: CapturedText?) {
        let action = TextCapturePolicy.actionAfterBlockedCapture(capturedText)
        textState.apply(action)
    }

    func commitSuccessfulUndo(
        _ plan: UndoAppliedCommitPlan,
        contextID: String?,
        reloadAutoCorrectionRules: () -> Void
    ) {
        if let layoutSwitchTarget = plan.layoutSwitchTarget {
            switchLayoutIfEnabled(layoutSwitchTarget, surface: .undo)
        } else if let skippedLayoutSwitchLogMessage = plan.skippedLayoutSwitchLogMessage {
            PuntoLog.info(skippedLayoutSwitchLogMessage)
        }

        flashStatusIcon()
        soundFeedbackController.play(plan.soundFeedbackEvent)
        settingsManager.recordProductStatisticsEvent(plan.productStatisticsEvent)
        if let trackedTailCommit = plan.trackedTailCommit {
            wordTracker.replaceTrackedTail(
                with: trackedTailCommit.text,
                reason: trackedTailCommit.reason,
                suppressAutoCorrectionForCurrentToken: trackedTailCommit.suppressAutoCorrectionForCurrentToken,
                englishLayoutVariant: currentEnglishLayoutVariant(),
                russianLayoutType: settingsManager.russianKeyboardLayoutType
            )
        }

        if let learnedRules = plan.learnedAutoCorrectionRules {
            settingsManager.autoCorrectionRules = learnedRules
            reloadAutoCorrectionRules()
            if let learnedRuleLogMessage = plan.learnedRuleLogMessage {
                PuntoLog.info(learnedRuleLogMessage)
            }
        }

        textState.conversionSession.record(plan.conversionRecordCommit, contextID: contextID)
    }

    private func keyboardLanguage(for language: LayoutSwitchTargetLanguage) -> KeyboardLanguage {
        switch language {
        case .english:
            return .english
        case .russian:
            return .russian
        }
    }

    private func playInputSourceSwitchSound(
        targetLayout: LayoutConverter.DetectedLayout,
        didSwitch: Bool,
        context: InputSourceSwitchSoundContext
    ) {
        guard let event = SoundFeedbackPolicy.eventAfterInputSourceSwitch(
            targetLayout: targetLayout,
            didSwitch: didSwitch,
            context: context
        ) else {
            return
        }
        soundFeedbackController.play(event)
    }

    private func writeSecureInputDiagnostics(context: String) {
        let snapshot = SecureInputDiagnosticsPolicy.snapshot(
            secureInputState: textAccessor.isSecureInputEnabled(),
            context: context,
            currentApp: currentApplicationBundleID(),
            runningApps: runningApplicationBundleIDs(),
            enabledLayouts: [
                inputSourceManager.languageLayoutID(.english),
                inputSourceManager.languageLayoutID(.russian),
                inputSourceManager.currentLayoutID()
            ]
        )
        let dictionary = SecureInputDiagnosticsPolicy.plistDictionary(from: snapshot)
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(SecureInputDiagnosticsPolicy.secureInputDiagnosticsPlistFilename)

        do {
            let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
            try data.write(to: url, options: .atomic)
            PuntoLog.info("Wrote secure input diagnostics to \(url.path)")
        } catch {
            PuntoLog.error("Failed to write secure input diagnostics: \(error)")
        }
    }
}
