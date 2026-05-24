import Foundation

public enum HotkeyRecordingAction: Equatable {
    case none
    case previewModifierOnly(Hotkey)
    case record(Hotkey)
    case cancel
    case reject
    case passThrough
}

public final class HotkeyRecordingStateMachine {
    private var pendingModifierOnlyHotkey: Hotkey?

    public init() {}

    public func reset() {
        pendingModifierOnlyHotkey = nil
    }

    public func handleFlagsChanged(flags: ModifierFlagsSnapshot) -> HotkeyRecordingAction {
        let count = modifierCount(in: flags)

        if count >= 2 {
            let hotkey = Hotkey(
                keyCode: Hotkey.modifierOnlyKeyCode,
                command: flags.command,
                option: flags.option,
                shift: flags.shift,
                control: flags.control
            )
            pendingModifierOnlyHotkey = hotkey
            return .previewModifierOnly(hotkey)
        }

        guard let pendingModifierOnlyHotkey else {
            return .none
        }

        guard flags.noModifiersPressed else {
            return .none
        }

        self.pendingModifierOnlyHotkey = nil
        return .record(pendingModifierOnlyHotkey)
    }

    public func handleKeyDown(keyCode: UInt16, flags: ModifierFlagsSnapshot) -> HotkeyRecordingAction {
        pendingModifierOnlyHotkey = nil

        if keyCode == KeyDownEventPolicy.escapeKeyCode {
            return .cancel
        }

        guard HotkeyValidationPolicy.isAllowedShortcutCharacterKeycode(keyCode) else {
            return .reject
        }

        guard flags.command || flags.option || flags.control else {
            return .passThrough
        }

        return .record(Hotkey(
            keyCode: keyCode,
            command: flags.command,
            option: flags.option,
            shift: flags.shift,
            control: flags.control
        ))
    }

    private func modifierCount(in flags: ModifierFlagsSnapshot) -> Int {
        [flags.command, flags.option, flags.shift, flags.control].filter { $0 }.count
    }
}
