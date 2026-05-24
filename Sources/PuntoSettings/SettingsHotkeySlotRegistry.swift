import Foundation
import PuntoCore

struct SettingsHotkeySlotDescriptor {
    let slot: HotkeySlot
    let nativeKey: String
    let legacyKey: String
    let fallback: Hotkey
}

enum SettingsHotkeySlotRegistry {
    static let descriptors: [SettingsHotkeySlotDescriptor] = [
        SettingsHotkeySlotDescriptor(
            slot: .convertLayout,
            nativeKey: SettingsStorageKeys.convertLayoutHotkey,
            legacyKey: SettingsImportKeys.shortcutChangeLayout,
            fallback: Hotkey.defaultConvertLayout
        ),
        SettingsHotkeySlotDescriptor(
            slot: .toggleCase,
            nativeKey: SettingsStorageKeys.toggleCaseHotkey,
            legacyKey: SettingsImportKeys.shortcutChangeCase,
            fallback: Hotkey.defaultToggleCase
        ),
        SettingsHotkeySlotDescriptor(
            slot: .toggleAutoCorrection,
            nativeKey: SettingsStorageKeys.toggleAutoCorrectionHotkey,
            legacyKey: SettingsImportKeys.shortcutSwitchAutocorrection,
            fallback: Hotkey.defaultToggleAutoCorrection
        ),
        SettingsHotkeySlotDescriptor(
            slot: .cancelLayoutChange,
            nativeKey: SettingsStorageKeys.cancelLayoutChangeHotkey,
            legacyKey: SettingsImportKeys.shortcutCancelLayoutChange,
            fallback: Hotkey.defaultCancelLayoutChange
        ),
        SettingsHotkeySlotDescriptor(
            slot: .findInYandex,
            nativeKey: SettingsStorageKeys.findInYandexHotkey,
            legacyKey: SettingsImportKeys.shortcutFindInYandex,
            fallback: Hotkey.defaultFindInYandex
        ),
        SettingsHotkeySlotDescriptor(
            slot: .findInSlovari,
            nativeKey: SettingsStorageKeys.findInSlovariHotkey,
            legacyKey: SettingsImportKeys.shortcutFindInSlovari,
            fallback: Hotkey.defaultFindInSlovari
        )
    ]

    static func descriptor(for slot: HotkeySlot) -> SettingsHotkeySlotDescriptor {
        guard let descriptor = descriptors.first(where: { $0.slot == slot }) else {
            preconditionFailure("Missing settings hotkey slot descriptor for \(slot.rawValue)")
        }
        return descriptor
    }
}
