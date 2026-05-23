public enum EventTapLifecycleAction: Equatable {
    case reenableTap(reason: String)
    case ignore
}

public enum EventTapLifecyclePolicy {
    public static func action(
        isDisabledByTimeout: Bool,
        isDisabledByUserInput: Bool
    ) -> EventTapLifecycleAction {
        if isDisabledByTimeout {
            return .reenableTap(reason: "tap disabled by timeout")
        }

        if isDisabledByUserInput {
            return .reenableTap(reason: "tap disabled by user input")
        }

        return .ignore
    }
}
