import Foundation
import PuntoCore
import PuntoSettings
import PuntoRuntime

/// App-side owner for ordinary key-press tracking runtime.
///
/// HotkeyManager owns event-tap classification; PuntoCore owns pure routing
/// decisions. This coordinator applies the key-tracking plan to live settings,
/// text state, statistics, sound feedback, and auto-correction routing.
final class KeyPressRuntimeCoordinator {
    private let settingsManager: SettingsManager
    private let wordTracker: WordTracker
    private let textState: TextRuntimeStateCoordinator
    private let textAccessor: TextAccessor
    private let layoutConverter: LayoutConverter
    private let soundFeedbackController: SoundFeedbackController
    private let currentEnglishLayoutVariant: () -> KeyboardLayoutVariant
    private let currentApplicationBundleID: () -> String?
    private let isCurrentApplicationDisabled: () -> Bool
    private let clearTextStateForSecureInput: (String) -> Void
    private let runAutoCorrectionIfNeeded: () -> Void

    init(
        settingsManager: SettingsManager,
        wordTracker: WordTracker,
        textState: TextRuntimeStateCoordinator,
        textAccessor: TextAccessor,
        layoutConverter: LayoutConverter,
        soundFeedbackController: SoundFeedbackController,
        currentEnglishLayoutVariant: @escaping () -> KeyboardLayoutVariant,
        currentApplicationBundleID: @escaping () -> String?,
        isCurrentApplicationDisabled: @escaping () -> Bool,
        clearTextStateForSecureInput: @escaping (String) -> Void,
        runAutoCorrectionIfNeeded: @escaping () -> Void
    ) {
        self.settingsManager = settingsManager
        self.wordTracker = wordTracker
        self.textState = textState
        self.textAccessor = textAccessor
        self.layoutConverter = layoutConverter
        self.soundFeedbackController = soundFeedbackController
        self.currentEnglishLayoutVariant = currentEnglishLayoutVariant
        self.currentApplicationBundleID = currentApplicationBundleID
        self.isCurrentApplicationDisabled = isCurrentApplicationDisabled
        self.clearTextStateForSecureInput = clearTextStateForSecureInput
        self.runAutoCorrectionIfNeeded = runAutoCorrectionIfNeeded
    }

    func handleKeyPress(keyCode: UInt16, characters: String?) {
        textState.lastKeyPressTime = Date()

        switch KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: settingsManager.isEnabled,
            isCurrentApplicationDisabled: isCurrentApplicationDisabled(),
            isSecureInputEnabled: textAccessor.isSecureInputEnabled(),
            isPasswordField: textAccessor.isPasswordFieldFast()
        ) {
        case .skipRouting(let logMessage):
            PuntoLog.info(logMessage)
            return

        case .blockSecureInput(let context, let logMessage):
            clearTextStateForSecureInput(context)
            PuntoLog.info(logMessage)
            return

        case .track:
            break
        }

        wordTracker.trackKeyPress(
            keyCode: keyCode,
            characters: characters,
            autoCorrectionCancellingKeyNames: settingsManager.autoCorrectionCancellingKeyNames,
            englishLayoutVariant: currentEnglishLayoutVariant(),
            russianLayoutType: settingsManager.russianKeyboardLayoutType
        )
        settingsManager.recordProductStatisticsEvent(.typedText(characters))
        playTextInputSound(characters: characters)

        switch KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: currentApplicationBundleID(),
            keyCode: keyCode,
            resetBundleComponents: settingsManager.resetOnReturnBundleComponents
        ) {
        case .resetOnReturn:
            handleResetOnReturn()

        case .runAutoCorrection:
            runAutoCorrectionIfNeeded()
        }

        if let clearReason = KeyTrackingRuntimePolicy.conversionSessionClearReasonAfterAutoCorrection(
            isConversionInProgress: textState.isConversionInProgress
        ) {
            textState.clearConversionSession(reason: clearReason)
        }
    }

    private func handleResetOnReturn() {
        let consumedCompletedToken = wordTracker.consumeCompletedToken() != nil
        let resetPlan = KeyTrackingRuntimePolicy.resetOnReturnPlan(
            consumedCompletedToken: consumedCompletedToken,
            bundleID: currentApplicationBundleID()
        )
        if let statisticsEvent = resetPlan.completedTokenStatisticsEvent {
            settingsManager.recordProductStatisticsEvent(statisticsEvent)
        }
        textState.clearConversionSession(reason: resetPlan.conversionSessionClearReason)
        PuntoLog.info(resetPlan.logMessage)
    }

    private func playTextInputSound(characters: String?) {
        guard let event = SoundFeedbackPolicy.eventAfterTextInput(
            characters: characters,
            detectedLayout: layoutConverter.detectLayout(characters ?? "")
        ) else {
            return
        }
        soundFeedbackController.play(event)
    }
}
