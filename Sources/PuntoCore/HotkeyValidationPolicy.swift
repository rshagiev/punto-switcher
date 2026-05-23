import Foundation

public enum HotkeyValidationPolicy {
    private static let disallowedShortcutCharacterKeyCodes: Set<UInt16> = [
        53, // Escape cancels shortcut editing.
        55, 56, 57, 58, 59, 60, 61, 62, 63 // Modifier, Caps Lock, and Fn keys.
    ]

    public static func normalized(_ hotkey: Hotkey, fallback: Hotkey) -> Hotkey {
        isValid(hotkey) ? hotkey : fallback
    }

    public static func isValid(_ hotkey: Hotkey) -> Bool {
        if hotkey.isDisabled {
            return true
        }

        if hotkey.isModifierOnly {
            return modifierCount(in: hotkey) >= 2
        }

        guard isAllowedShortcutCharacterKeycode(hotkey.keyCode) else {
            return false
        }

        return hotkey.command || hotkey.option || hotkey.control
    }

    public static func isAllowedCharacterKeycode(_ keyCode: UInt16) -> Bool {
        KeyCodeNames.name(for: keyCode) != nil
            && !disallowedShortcutCharacterKeyCodes.contains(keyCode)
    }

    public static func isAllowedShortcutCharacterKeycode(_ keyCode: UInt16) -> Bool {
        isAllowedCharacterKeycode(keyCode)
    }

    private static func modifierCount(in hotkey: Hotkey) -> Int {
        [hotkey.command, hotkey.option, hotkey.shift, hotkey.control].filter { $0 }.count
    }
}
