import Foundation
import PuntoCore

final class SettingsSlotStore {
    private let store: SettingsDefaultsStore
    private let resolver: SettingsValueResolver

    init(store: SettingsDefaultsStore, resolver: SettingsValueResolver) {
        self.store = store
        self.resolver = resolver
    }

    var hotkeyAssignments: [HotkeyAssignment] {
        HotkeyCommandPolicy.displayOrder.map {
            HotkeyAssignment(slot: $0.slot, hotkey: hotkey(for: $0.slot))
        }
    }

    func hotkey(for slot: HotkeySlot) -> Hotkey {
        resolver.hotkeySlot(SettingsHotkeySlotRegistry.descriptor(for: slot))
    }

    func setHotkey(_ hotkey: Hotkey, for slot: HotkeySlot) {
        let descriptor = SettingsHotkeySlotRegistry.descriptor(for: slot)
        let normalized = HotkeyValidationPolicy.normalized(hotkey, fallback: descriptor.fallback)
        store.encodeAndSet(normalized, forKey: descriptor.nativeKey)
    }

    func resetHotkey(for slot: HotkeySlot) {
        setHotkey(HotkeyCommandPolicy.defaultHotkey(for: slot), for: slot)
    }

    func bool(for slot: SettingsToggleSlot) -> Bool {
        resolver.boolSlot(SettingsBoolSlotRegistry.descriptor(for: slot))
    }

    func setBool(_ isEnabled: Bool, for slot: SettingsToggleSlot) {
        store.set(isEnabled, forKey: SettingsBoolSlotRegistry.descriptor(for: slot).nativeKey)
    }
}
