public enum StatusIconState: String, Equatable {
    case active
    case inactive
    case disabled
}

public enum StatusIconPolicy {
    public static let observedResourceNames = [
        "icon_active",
        "icon_inactive",
        "icon_disabled",
        "icon_active_w",
        "icon_inactive_w",
        "icon_disabled_w"
    ]

    public static func state(isEnabled: Bool, isCurrentApplicationDisabled: Bool) -> StatusIconState {
        if !isEnabled {
            return .inactive
        }

        if isCurrentApplicationDisabled {
            return .disabled
        }

        return .active
    }

    public static func accessibilityDescription(for state: StatusIconState) -> String {
        switch state {
        case .active:
            return "Punto active"
        case .inactive:
            return "Punto inactive"
        case .disabled:
            return "Punto disabled in current app"
        }
    }
}
