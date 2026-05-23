import Foundation

public enum LayoutConversionSurface: Equatable {
    case selectedText
    case lastWord
    case undo
}

public enum LayoutSwitchPolicy {
    public static func shouldSwitchLayoutAfterConversion(
        surface: LayoutConversionSurface,
        switchLayoutAfterConversion: Bool,
        switchLayoutAfterSelectedTextConversion: Bool
    ) -> Bool {
        guard switchLayoutAfterConversion else {
            return false
        }

        switch surface {
        case .selectedText:
            return switchLayoutAfterSelectedTextConversion
        case .lastWord, .undo:
            return true
        }
    }
}
