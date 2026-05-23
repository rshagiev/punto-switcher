import Foundation

public enum WordTrackingAction: Equatable {
    case clear(reason: String)
    case removeLastCharacter
    case completeToken(separator: String, reason: String)
    case trackProducedCharacters
    case ignore
}

public enum WordTrackingPolicy {
    public static let deleteKeyCode = KeyboardEventKeyCodePolicy.backspaceKeyCode
    public static let returnKeyCode: UInt16 = 36
    public static let enterKeyCode: UInt16 = 76
    public static let tabKeyCode: UInt16 = 48
    public static let escapeKeyCode: UInt16 = 53
    public static let forwardDeleteKeyCode: UInt16 = 117
    public static let leftArrowKeyCode: UInt16 = 123
    public static let rightArrowKeyCode: UInt16 = 124
    public static let downArrowKeyCode: UInt16 = 125
    public static let upArrowKeyCode: UInt16 = 126

    public static let navigationKeyCodes: Set<UInt16> = [
        leftArrowKeyCode, rightArrowKeyCode, downArrowKeyCode, upArrowKeyCode,
        115, 119, 116, 121,
        forwardDeleteKeyCode
    ]

    public static func action(keyCode: UInt16, characters: String?) -> WordTrackingAction {
        if keyCode == escapeKeyCode {
            return .clear(reason: "escape")
        }

        if characters == nil && keyCode != deleteKeyCode {
            return .clear(reason: "external command (keyCode=\(keyCode))")
        }

        if keyCode == deleteKeyCode {
            return .removeLastCharacter
        }

        if navigationKeyCodes.contains(keyCode) {
            return .clear(reason: "navigation key \(keyCode)")
        }

        if keyCode == returnKeyCode || keyCode == enterKeyCode {
            return .completeToken(separator: "\n", reason: "return/enter")
        }

        if keyCode == tabKeyCode {
            return .completeToken(separator: "\t", reason: "tab")
        }

        guard let characters, !characters.isEmpty else {
            return .ignore
        }

        return .trackProducedCharacters
    }
}
