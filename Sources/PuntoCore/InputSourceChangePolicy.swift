import Foundation

public enum InputSourceChangeAction: Equatable {
    case ignoreProgrammaticSwitch
    case ignoreConversionInProgress
    case rememberLayoutAndClearTextState
}

public enum InputSourceChangePolicy {
    public static func action(
        now: Date,
        ignoreChangesUntil: Date?,
        isConversionInProgress: Bool
    ) -> InputSourceChangeAction {
        if let ignoreChangesUntil, now < ignoreChangesUntil {
            return .ignoreProgrammaticSwitch
        }

        if isConversionInProgress {
            return .ignoreConversionInProgress
        }

        return .rememberLayoutAndClearTextState
    }

    public static func nextIgnoreChangesUntil(
        now: Date,
        currentIgnoreChangesUntil: Date?
    ) -> Date? {
        guard let currentIgnoreChangesUntil else {
            return nil
        }

        return now < currentIgnoreChangesUntil ? currentIgnoreChangesUntil : nil
    }
}
