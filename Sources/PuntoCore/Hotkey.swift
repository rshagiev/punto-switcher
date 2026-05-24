import Foundation

/// Represents a keyboard shortcut.
public struct Hotkey: Codable, Equatable {
    public var keyCode: UInt16
    public var command: Bool
    public var option: Bool
    public var shift: Bool
    public var control: Bool

    public init(keyCode: UInt16, command: Bool, option: Bool, shift: Bool, control: Bool) {
        self.keyCode = keyCode
        self.command = command
        self.option = option
        self.shift = shift
        self.control = control
    }

    /// Special keyCode value indicating modifier-only hotkey.
    public static let modifierOnlyKeyCode: UInt16 = UInt16.max
    public static let disabledKeyCode: UInt16 = UInt16.max - 1

    public var isModifierOnly: Bool {
        keyCode == Self.modifierOnlyKeyCode
    }

    public var isDisabled: Bool {
        keyCode == Self.disabledKeyCode
    }

    public static let defaultConvertLayout = Hotkey(
        keyCode: modifierOnlyKeyCode,
        command: true,
        option: true,
        shift: true,
        control: false
    )

    public static let defaultToggleCase = Hotkey(
        keyCode: 6,
        command: true,
        option: true,
        shift: false,
        control: false
    )

    public static let defaultToggleAutoCorrection = Hotkey(
        keyCode: 0,
        command: true,
        option: true,
        shift: false,
        control: false
    )

    public static let defaultCancelLayoutChange = Hotkey(
        keyCode: 51,
        command: true,
        option: true,
        shift: false,
        control: false
    )

    public static let disabled = Hotkey(
        keyCode: disabledKeyCode,
        command: false,
        option: false,
        shift: false,
        control: false
    )

    public static let defaultFindInYandex = Hotkey.disabled

    public static let defaultFindInSlovari = Hotkey.disabled

    public var displayString: String {
        if isDisabled {
            return "Not Set"
        }

        var parts: [String] = []

        if control { parts.append("\u{2303}") }
        if option { parts.append("\u{2325}") }
        if shift { parts.append("\u{21E7}") }
        if command { parts.append("\u{2318}") }

        if !isModifierOnly, let keyName = KeyCodeNames.name(for: keyCode) {
            parts.append(keyName)
        }

        return parts.joined(separator: "")
    }
}

public enum KeyCodeNames {
    private static let names: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
        44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space",
        50: "`", 51: "Delete", 53: "Escape", 55: "Command", 56: "Shift",
        57: "Caps Lock", 58: "Option", 59: "Control", 60: "Right Shift",
        61: "Right Option", 62: "Right Control", 63: "Function",
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
        103: "F11", 105: "F13", 107: "F14", 109: "F10", 111: "F12",
        113: "F15", 114: "Help", 115: "Home", 116: "Page Up", 117: "Forward Delete",
        118: "F4", 119: "End", 120: "F2", 121: "Page Down", 122: "F1", 123: "Left",
        124: "Right", 125: "Down", 126: "Up"
    ]

    public static func name(for keyCode: UInt16) -> String? {
        names[keyCode]
    }
}

public enum LegacyHotkeyPolicy {
    public static let noKeyCode: UInt16 = 666
    public static let keyCodeKey = "charKeycode"
    public static let commandKey = "isCommandUsed"
    public static let optionKey = "isAltUsed"
    public static let shiftKey = "isShiftUsed"
    public static let controlKey = "isControlUsed"
    public static let observedShortcutChangeLayoutKey = "shortcutChangeLayout"
    public static let observedShortcutChangeCaseKey = "shortcutChangeCase"
    public static let observedShortcutSwitchAutocorrectionKey = "shortcutSwitchAutocorrection"
    public static let observedShortcutCancelLayoutChangeKey = "shortcutCancelLayoutChange"
    public static let observedShortcutFindInYandexKey = "shortcutFindInYandex"
    public static let observedShortcutFindInSlovariKey = "shortcutFindInSlovari"
    public static let observedCancelLayoutChangeShortcutKey = "cancelLayoutChangeShortcut"
    public static let observedSwitchAutocorrectionShortcutKey = "switchAutocorrectionShortcut"
    public static let observedChangeCaseShortcutKey = "changeCaseShortcut"

    public static func hotkey(from dictionary: [String: Any]?) -> Hotkey? {
        guard let dictionary,
              let rawKeyCode = intValue(dictionary[keyCodeKey]),
              rawKeyCode >= 0,
              rawKeyCode <= Int(UInt16.max) else {
            return nil
        }

        let command = boolValue(dictionary[commandKey]) ?? false
        let option = boolValue(dictionary[optionKey]) ?? false
        let shift = boolValue(dictionary[shiftKey]) ?? false
        let control = boolValue(dictionary[controlKey]) ?? false
        let legacyKeyCode = UInt16(rawKeyCode)

        if legacyKeyCode == noKeyCode {
            if [command, option, shift, control].contains(true) {
                return Hotkey(
                    keyCode: Hotkey.modifierOnlyKeyCode,
                    command: command,
                    option: option,
                    shift: shift,
                    control: control
                )
            }
            return Hotkey.disabled
        }

        return Hotkey(
            keyCode: legacyKeyCode,
            command: command,
            option: option,
            shift: shift,
            control: control
        )
    }

    public static func normalized(_ dictionary: [String: Any]?, fallback: Hotkey) -> Hotkey {
        guard let hotkey = hotkey(from: dictionary) else {
            return fallback
        }
        return HotkeyValidationPolicy.normalized(hotkey, fallback: fallback)
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let value = value as? UInt16 {
            return Int(value)
        }
        return LegacyValuePolicy.int(value)
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        LegacyValuePolicy.bool(value)
    }
}
