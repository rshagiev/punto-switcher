import Foundation
import PuntoCore

enum SettingsDefaultRegistry {
    static var registeredDefaults: [String: Any] {
        [
            SettingsStorageKeys.isEnabled: SettingsPersistencePolicy.defaultIsEnabled,
            SettingsStorageKeys.isFirstLaunch: StartupPresentationPolicy.defaultIsFirstLaunch,
            SettingsStorageKeys.russianKeyboardLayoutType: KeyboardLayoutTypePolicy.defaultRussianLayoutTypeRawValue,
            SettingsStorageKeys.rememberedApplicationLayouts: ApplicationLayoutMemory.defaultSnapshot,
            SettingsStorageKeys.disabledApplicationBundleIDs: ApplicationDisablePolicy.defaultDisabledBundleIDs,
            SettingsStorageKeys.autoCorrectionCancellingKeyNames: AutoCorrectionCancellingKeyPolicy.defaultEnabledKeyNameList
        ].merging(SettingsBoolSlotRegistry.nativeDefaultValues) { nativeValue, _ in nativeValue }
    }
}
