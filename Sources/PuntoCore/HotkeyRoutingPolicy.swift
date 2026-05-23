import Foundation

public enum HotkeyRoutingPolicy {
    public static func shouldHandleHotkey(
        isEnabled: Bool,
        isCurrentApplicationDisabled: Bool
    ) -> Bool {
        isEnabled && !isCurrentApplicationDisabled
    }

    public static func shouldTrackKeyState(
        isEnabled: Bool,
        isCurrentApplicationDisabled: Bool
    ) -> Bool {
        isEnabled && !isCurrentApplicationDisabled
    }

    public static func shouldClearStateAfterEnabledChange(
        wasEnabled: Bool,
        isEnabled: Bool
    ) -> Bool {
        wasEnabled && !isEnabled
    }
}
