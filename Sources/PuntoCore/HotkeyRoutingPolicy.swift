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

public enum HotkeyRoutingKind: Equatable {
    case modifierOnlyConvertLayout
    case convertLayout
    case toggleCase
    case toggleAutoCorrection
    case cancelLayoutChange
    case findInYandex
    case findInSlovari
}

public enum HotkeyRoutingAction: Equatable {
    case passThrough(logMessage: String)
    case handle(logMessage: String)
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

    public static func action(
        kind: HotkeyRoutingKind,
        isEnabled: Bool,
        isCurrentApplicationDisabled: Bool,
        keyCode: UInt16? = nil,
        displayString: String? = nil
    ) -> HotkeyRoutingAction {
        guard shouldHandleHotkey(
            isEnabled: isEnabled,
            isCurrentApplicationDisabled: isCurrentApplicationDisabled
        ) else {
            return .passThrough(logMessage: passThroughLogMessage(kind: kind))
        }

        return .handle(logMessage: matchedLogMessage(
            kind: kind,
            keyCode: keyCode,
            displayString: displayString
        ))
    }

    private static func passThroughLogMessage(kind: HotkeyRoutingKind) -> String {
        switch kind {
        case .modifierOnlyConvertLayout:
            return "Modifier-only hotkey ignored by routing policy"
        case .convertLayout:
            return "Convert layout hotkey passed through by routing policy"
        case .toggleCase:
            return "Toggle case hotkey passed through by routing policy"
        case .toggleAutoCorrection:
            return "Toggle auto-correction hotkey passed through by routing policy"
        case .cancelLayoutChange:
            return "Cancel layout change hotkey passed through by routing policy"
        case .findInYandex:
            return "Find in Yandex hotkey passed through by routing policy"
        case .findInSlovari:
            return "Find in Slovari hotkey passed through by routing policy"
        }
    }

    private static func matchedLogMessage(
        kind: HotkeyRoutingKind,
        keyCode: UInt16?,
        displayString: String?
    ) -> String {
        switch kind {
        case .modifierOnlyConvertLayout:
            return "Modifier-only hotkey triggered: \(displayString ?? "?")"
        case .convertLayout:
            return "Convert layout hotkey matched! keyCode=\(keyCode.map(String.init) ?? "?")"
        case .toggleCase:
            return "Toggle case hotkey matched! keyCode=\(keyCode.map(String.init) ?? "?")"
        case .toggleAutoCorrection:
            return "Toggle auto-correction hotkey matched! keyCode=\(keyCode.map(String.init) ?? "?")"
        case .cancelLayoutChange:
            return "Cancel layout change hotkey matched! keyCode=\(keyCode.map(String.init) ?? "?")"
        case .findInYandex:
            return "Find in Yandex hotkey matched! keyCode=\(keyCode.map(String.init) ?? "?")"
        case .findInSlovari:
            return "Find in Slovari hotkey matched! keyCode=\(keyCode.map(String.init) ?? "?")"
        }
    }
}
