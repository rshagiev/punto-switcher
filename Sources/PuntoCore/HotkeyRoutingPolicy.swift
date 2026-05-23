import Foundation

public struct HotkeyRoutingStateClearAction: Equatable {
    public let clearTrackedText: Bool
    public let clearConversionSession: Bool
    public let clearTrackedTextReason: String?
    public let clearConversionSessionReason: String?
    public let logMessage: String?

    public init(
        clearTrackedText: Bool,
        clearConversionSession: Bool,
        clearTrackedTextReason: String? = nil,
        clearConversionSessionReason: String? = nil,
        logMessage: String? = nil
    ) {
        self.clearTrackedText = clearTrackedText
        self.clearConversionSession = clearConversionSession
        self.clearTrackedTextReason = clearTrackedTextReason
        self.clearConversionSessionReason = clearConversionSessionReason
        self.logMessage = logMessage
    }
}

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

    public static func stateClearActionAfterEnabledChange(
        wasEnabled: Bool,
        isEnabled: Bool
    ) -> HotkeyRoutingStateClearAction {
        guard shouldClearStateAfterEnabledChange(wasEnabled: wasEnabled, isEnabled: isEnabled) else {
            return HotkeyRoutingStateClearAction(
                clearTrackedText: false,
                clearConversionSession: false
            )
        }

        return HotkeyRoutingStateClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "Punto disabled",
            clearConversionSessionReason: "Punto disabled",
            logMessage: "Punto disabled - cleared text state"
        )
    }
}
