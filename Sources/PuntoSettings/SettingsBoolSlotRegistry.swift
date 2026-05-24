import Foundation
import PuntoCore

enum SettingsBoolSlotResolution {
    case nativeOnly
    case legacyAlias
    case invertedLegacyAlias
    case undoLearningDictionary
    case searchbarDictionary
}

struct SettingsBoolSlotDescriptor {
    let slot: SettingsToggleSlot
    let nativeKey: String
    let legacyKey: String?
    let defaultValue: Bool
    let resolution: SettingsBoolSlotResolution
}

enum SettingsBoolSlotRegistry {
    static let descriptors: [SettingsBoolSlotDescriptor] = [
        SettingsBoolSlotDescriptor(
            slot: .launchAtLogin,
            nativeKey: SettingsStorageKeys.launchAtLogin,
            legacyKey: SettingsImportKeys.launchesOnStartup,
            defaultValue: LoginItemPolicy.defaultLaunchAtLogin,
            resolution: .legacyAlias
        ),
        SettingsBoolSlotDescriptor(
            slot: .showInMenuBar,
            nativeKey: SettingsStorageKeys.showInMenuBar,
            legacyKey: nil,
            defaultValue: SettingsPersistencePolicy.defaultShowInMenuBar,
            resolution: .nativeOnly
        ),
        SettingsBoolSlotDescriptor(
            slot: .switchLayoutAfterConversion,
            nativeKey: SettingsStorageKeys.switchLayoutAfterConversion,
            legacyKey: nil,
            defaultValue: LayoutSwitchPolicy.defaultSwitchLayoutAfterConversion,
            resolution: .nativeOnly
        ),
        SettingsBoolSlotDescriptor(
            slot: .autoCorrectionEnabled,
            nativeKey: SettingsStorageKeys.autoCorrectionEnabled,
            legacyKey: SettingsImportKeys.isAutocorrectionActive,
            defaultValue: AutoCorrectionPreflightPolicy.defaultAutoCorrectionEnabled,
            resolution: .legacyAlias
        ),
        SettingsBoolSlotDescriptor(
            slot: .soundEffectsEnabled,
            nativeKey: SettingsStorageKeys.soundEffectsEnabled,
            legacyKey: SettingsImportKeys.isSoundOn,
            defaultValue: SoundFeedbackPolicy.defaultSoundEffectsEnabled,
            resolution: .legacyAlias
        ),
        SettingsBoolSlotDescriptor(
            slot: .showAdvancedSettings,
            nativeKey: SettingsStorageKeys.showAdvancedSettings,
            legacyKey: nil,
            defaultValue: SettingsPersistencePolicy.defaultShowAdvancedSettings,
            resolution: .nativeOnly
        ),
        SettingsBoolSlotDescriptor(
            slot: .switchLayoutAfterSelectedTextConversion,
            nativeKey: SettingsStorageKeys.switchLayoutAfterSelectedTextConversion,
            legacyKey: SettingsImportKeys.switchLayoutOnSelectedTextSwitch,
            defaultValue: LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion,
            resolution: .legacyAlias
        ),
        SettingsBoolSlotDescriptor(
            slot: .searchSelectedTextByDoubleClick,
            nativeKey: SettingsStorageKeys.searchSelectedTextByDoubleClick,
            legacyKey: SettingsImportKeys.searchbarSettings,
            defaultValue: SearchbarSettingsPolicy.defaultSnapshot.shouldSearchByDoubleClick,
            resolution: .searchbarDictionary
        ),
        SettingsBoolSlotDescriptor(
            slot: .manualConversionDisabled,
            nativeKey: SettingsStorageKeys.manualConversionDisabled,
            legacyKey: SettingsImportKeys.isManualConversionDisabled,
            defaultValue: TextActionPreflightPolicy.defaultManualConversionDisabled,
            resolution: .legacyAlias
        ),
        SettingsBoolSlotDescriptor(
            slot: .rememberInputSourceForEachApp,
            nativeKey: SettingsStorageKeys.rememberInputSourceForEachApp,
            legacyKey: SettingsImportKeys.shouldRememberInputSourceForEachApp,
            defaultValue: ApplicationLayoutPolicy.defaultRememberInputSourceForEachApp,
            resolution: .legacyAlias
        ),
        SettingsBoolSlotDescriptor(
            slot: .autoCorrectOnEnterAndTab,
            nativeKey: SettingsStorageKeys.autoCorrectOnEnterAndTab,
            legacyKey: SettingsImportKeys.shouldNotAutoconvertWithTabOrEnter,
            defaultValue: AutoCorrectionPreflightPolicy.defaultAutoCorrectOnEnterAndTab,
            resolution: .invertedLegacyAlias
        ),
        SettingsBoolSlotDescriptor(
            slot: .autoCorrectionUndoLearningEnabled,
            nativeKey: SettingsStorageKeys.autoCorrectionUndoLearningEnabled,
            legacyKey: SettingsImportKeys.undoLearning,
            defaultValue: AutoCorrectionUndoLearningPolicy.defaultUndoLearningEnabled,
            resolution: .undoLearningDictionary
        ),
        SettingsBoolSlotDescriptor(
            slot: .suppressAutoCorrectionAfterManualConversion,
            nativeKey: SettingsStorageKeys.suppressAutoCorrectionAfterManualConversion,
            legacyKey: SettingsImportKeys.shouldNotAutoconvertAfterConvertion,
            defaultValue: TextReplacementCommitPolicy.defaultSuppressAutoCorrectionAfterManualConversion,
            resolution: .invertedLegacyAlias
        ),
        SettingsBoolSlotDescriptor(
            slot: .completelyDisableInExceptionApplications,
            nativeKey: SettingsStorageKeys.completelyDisableInExceptionApplications,
            legacyKey: SettingsImportKeys.completelyDisableInExceptionApps,
            defaultValue: ApplicationDisablePolicy.defaultCompletelyDisableInExceptionApplications,
            resolution: .legacyAlias
        )
    ]

    static func descriptor(for slot: SettingsToggleSlot) -> SettingsBoolSlotDescriptor {
        guard let descriptor = descriptors.first(where: { $0.slot == slot }) else {
            preconditionFailure("Missing settings boolean slot descriptor for \(slot.rawValue)")
        }
        return descriptor
    }
}
