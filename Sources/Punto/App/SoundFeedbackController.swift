import AppKit
import PuntoCore
import PuntoSettings

final class SoundFeedbackController {
    private let settingsManager: SettingsManager
    private var missingResources = Set<String>()
    private var soundsByResourceName = [String: NSSound]()

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }

    func play(_ event: SoundFeedbackEvent) {
        guard let resourceName = SoundFeedbackPolicy.resourceName(
            for: event,
            soundEffectsEnabled: settingsManager.soundEffectsEnabled,
            enabledResourceNames: settingsManager.enabledSoundResourceNames
        ) else {
            return
        }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "wav", subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "wav") else {
            if !missingResources.contains(resourceName) {
                missingResources.insert(resourceName)
                PuntoLog.debug("Sound feedback resource '\(resourceName).wav' not bundled")
            }
            return
        }

        if let sound = soundsByResourceName[resourceName] {
            sound.play()
            return
        }

        guard let sound = NSSound(contentsOf: url, byReference: true) else {
            PuntoLog.info("Sound feedback could not load '\(resourceName).wav'")
            return
        }

        soundsByResourceName[resourceName] = sound
        sound.play()
    }
}
