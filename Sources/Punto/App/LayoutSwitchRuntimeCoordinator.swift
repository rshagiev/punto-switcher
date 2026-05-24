import Foundation
import PuntoCore
import PuntoSettings
import PuntoRuntime

/// App-side executor for layout switch side effects after text actions.
///
/// `LayoutSwitchRuntimePolicy` derives the pure switch plan; this coordinator
/// applies the native input-source switch, grace-window protection, switch
/// sound, and per-application layout memory update.
final class LayoutSwitchRuntimeCoordinator {
    private let settingsManager: SettingsManager
    private let textState: TextRuntimeStateCoordinator
    private let inputSourceManager: InputSourceManager
    private let soundFeedbackController: SoundFeedbackController
    private let appRuntime: ApplicationRuntimeCoordinator

    init(
        settingsManager: SettingsManager,
        textState: TextRuntimeStateCoordinator,
        inputSourceManager: InputSourceManager,
        soundFeedbackController: SoundFeedbackController,
        appRuntime: ApplicationRuntimeCoordinator
    ) {
        self.settingsManager = settingsManager
        self.textState = textState
        self.inputSourceManager = inputSourceManager
        self.soundFeedbackController = soundFeedbackController
        self.appRuntime = appRuntime
    }

    func currentEnglishLayoutVariant() -> KeyboardLayoutVariant {
        KeyboardLayoutVariantPolicy.effectiveEnglishLayoutVariant(
            currentSourceID: inputSourceManager.currentLayoutID(),
            selectedEnglishSourceID: inputSourceManager.languageLayoutID(.english),
            preferredEnglishSourceID: settingsManager.preferredEnglishInputSourceID
        )
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
}
