import Foundation

public enum KeyDownAction: Equatable {
    case convertLayoutHotkey
    case toggleCaseHotkey
    case toggleAutoCorrectionHotkey
    case cancelLayoutChangeHotkey
    case findInYandexHotkey
    case findInSlovariHotkey
    case clearTrackedText(reason: String)
    case trackKeyPress
    case ignore
}

public enum KeyDownEventPolicy {
    public static let keyBasedHotkeyActionDelay: TimeInterval = 0.15
    public static let pasteKeyCode = KeyboardEventKeyCodePolicy.pasteKeyCode
    public static let copyKeyCode = KeyboardEventKeyCodePolicy.copyKeyCode
    public static let undoKeyCode: UInt16 = 6
    public static let cutKeyCode: UInt16 = 7
    public static let selectAllKeyCode: UInt16 = 0
    public static let deleteKeyCode = KeyboardEventKeyCodePolicy.backspaceKeyCode
    public static let escapeKeyCode: UInt16 = 53
    public static let forwardDeleteKeyCode: UInt16 = 117
    public static let navigationKeyCodes: Set<UInt16> = [
        123, 124, 125, 126,
        115, 119, 116, 121
    ]

    public static func action(
        keyCode: UInt16,
        flags: ModifierFlagsSnapshot,
        convertHotkey: Hotkey,
        toggleCaseHotkey: Hotkey,
        toggleAutoCorrectionHotkey: Hotkey = .defaultToggleAutoCorrection,
        cancelLayoutChangeHotkey: Hotkey = .defaultCancelLayoutChange,
        findInYandexHotkey: Hotkey = .defaultFindInYandex,
        findInSlovariHotkey: Hotkey = .defaultFindInSlovari
    ) -> KeyDownAction {
        if matchesHotkey(keyCode: keyCode, flags: flags, hotkey: convertHotkey) {
            return .convertLayoutHotkey
        }

        if matchesHotkey(keyCode: keyCode, flags: flags, hotkey: toggleCaseHotkey) {
            return .toggleCaseHotkey
        }

        if matchesHotkey(keyCode: keyCode, flags: flags, hotkey: toggleAutoCorrectionHotkey) {
            return .toggleAutoCorrectionHotkey
        }

        if matchesHotkey(keyCode: keyCode, flags: flags, hotkey: cancelLayoutChangeHotkey) {
            return .cancelLayoutChangeHotkey
        }

        if matchesHotkey(keyCode: keyCode, flags: flags, hotkey: findInYandexHotkey) {
            return .findInYandexHotkey
        }

        if matchesHotkey(keyCode: keyCode, flags: flags, hotkey: findInSlovariHotkey) {
            return .findInSlovariHotkey
        }

        if flags.command && !flags.option && !flags.control && keyCode == pasteKeyCode {
            return .clearTrackedText(reason: "paste")
        }

        if flags.command && !flags.option && !flags.control && keyCode == copyKeyCode {
            return .clearTrackedText(reason: "copy")
        }

        if flags.command && !flags.option && !flags.control && keyCode == undoKeyCode {
            return .clearTrackedText(reason: "undo")
        }

        if flags.command && !flags.option && !flags.control && keyCode == cutKeyCode {
            return .clearTrackedText(reason: "cut")
        }

        if flags.command && !flags.option && !flags.control && keyCode == selectAllKeyCode {
            return .clearTrackedText(reason: "selection")
        }

        if isModifiedDeletion(keyCode: keyCode, flags: flags) {
            return .clearTrackedText(reason: "modified deletion")
        }

        if isModifiedNavigation(keyCode: keyCode, flags: flags) {
            return .clearTrackedText(reason: "modified navigation")
        }

        if isModifiedShortcut(flags: flags) {
            return .clearTrackedText(reason: "modified shortcut")
        }

        if shouldTrackOrdinaryKeyPress(flags: flags) {
            return .trackKeyPress
        }

        return .ignore
    }

    public static func matchesHotkey(keyCode: UInt16, flags: ModifierFlagsSnapshot, hotkey: Hotkey) -> Bool {
        guard !hotkey.isDisabled else {
            return false
        }

        guard !hotkey.isModifierOnly, keyCode == hotkey.keyCode else {
            return false
        }

        return flags.exactlyMatches(hotkey)
    }

    public static func shouldTrackOrdinaryKeyPress(flags: ModifierFlagsSnapshot) -> Bool {
        !flags.command && !flags.option && !flags.control
    }

    private static func isModifiedDeletion(keyCode: UInt16, flags: ModifierFlagsSnapshot) -> Bool {
        guard keyCode == deleteKeyCode || keyCode == forwardDeleteKeyCode else {
            return false
        }

        return flags.command || flags.option || flags.control
    }

    private static func isModifiedNavigation(keyCode: UInt16, flags: ModifierFlagsSnapshot) -> Bool {
        guard navigationKeyCodes.contains(keyCode) else {
            return false
        }

        return flags.command || flags.option || flags.control
    }

    private static func isModifiedShortcut(flags: ModifierFlagsSnapshot) -> Bool {
        flags.command || flags.option || flags.control
    }
}
