public enum KeyboardModifierCleanupPolicy {
    public static func description(for flags: ModifierFlagsSnapshot) -> String {
        var parts: [String] = []
        if flags.command { parts.append("⌘") }
        if flags.option { parts.append("⌥") }
        if flags.shift { parts.append("⇧") }
        if flags.control { parts.append("⌃") }
        return parts.isEmpty ? "none" : parts.joined()
    }

    public static func keyUpCodes(for flags: ModifierFlagsSnapshot) -> [UInt16] {
        var keyCodes: [UInt16] = []

        if flags.command {
            keyCodes.append(contentsOf: [
                KeyboardEventKeyCodePolicy.leftCommandKeyCode,
                KeyboardEventKeyCodePolicy.rightCommandKeyCode
            ])
        }
        if flags.option {
            keyCodes.append(contentsOf: [
                KeyboardEventKeyCodePolicy.leftOptionKeyCode,
                KeyboardEventKeyCodePolicy.rightOptionKeyCode
            ])
        }
        if flags.shift {
            keyCodes.append(contentsOf: [
                KeyboardEventKeyCodePolicy.leftShiftKeyCode,
                KeyboardEventKeyCodePolicy.rightShiftKeyCode
            ])
        }
        if flags.control {
            keyCodes.append(contentsOf: [
                KeyboardEventKeyCodePolicy.leftControlKeyCode,
                KeyboardEventKeyCodePolicy.rightControlKeyCode
            ])
        }

        return keyCodes
    }

    public static func shouldPostCleanup(for flags: ModifierFlagsSnapshot) -> Bool {
        !keyUpCodes(for: flags).isEmpty
    }
}
