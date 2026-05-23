import Foundation

public struct ModifierFlagsSnapshot: Equatable {
    public let command: Bool
    public let option: Bool
    public let shift: Bool
    public let control: Bool

    public init(command: Bool, option: Bool, shift: Bool, control: Bool) {
        self.command = command
        self.option = option
        self.shift = shift
        self.control = control
    }

    public var noModifiersPressed: Bool {
        !command && !option && !shift && !control
    }

    public func exactlyMatches(_ hotkey: Hotkey) -> Bool {
        command == hotkey.command &&
            option == hotkey.option &&
            shift == hotkey.shift &&
            control == hotkey.control
    }
}

public final class ModifierOnlyHotkeyStateMachine {
    public static let actionDelay: TimeInterval = 0.15

    public let debounceInterval: TimeInterval
    private var modifiersWerePressed = false
    private var lastTriggerTime: Date

    public init(debounceInterval: TimeInterval = 0.5, lastTriggerTime: Date = .distantPast) {
        self.debounceInterval = debounceInterval
        self.lastTriggerTime = lastTriggerTime
    }

    public func handleFlagsChanged(flags: ModifierFlagsSnapshot, hotkey: Hotkey, now: Date = Date()) -> Bool {
        guard hotkey.isModifierOnly else {
            modifiersWerePressed = false
            return false
        }

        if flags.exactlyMatches(hotkey) {
            modifiersWerePressed = true
            return false
        }

        if modifiersWerePressed, containsDisallowedModifier(flags: flags, hotkey: hotkey) {
            modifiersWerePressed = false
            return false
        }

        guard modifiersWerePressed, flags.noModifiersPressed else {
            return false
        }

        defer {
            modifiersWerePressed = false
        }

        guard now.timeIntervalSince(lastTriggerTime) > debounceInterval else {
            return false
        }

        lastTriggerTime = now
        return true
    }

    public func cancelPendingModifierOnlyChord() {
        modifiersWerePressed = false
    }

    private func containsDisallowedModifier(flags: ModifierFlagsSnapshot, hotkey: Hotkey) -> Bool {
        (flags.command && !hotkey.command) ||
            (flags.option && !hotkey.option) ||
            (flags.shift && !hotkey.shift) ||
            (flags.control && !hotkey.control)
    }
}
