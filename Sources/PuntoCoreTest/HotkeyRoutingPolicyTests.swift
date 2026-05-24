import Foundation
import PuntoCore

func runHotkeyRoutingPolicyTests() throws {
    try expect(
        HotkeyRoutingPolicy.shouldHandleHotkey(isEnabled: true, isCurrentApplicationDisabled: false),
        true,
        "hotkey routing handles enabled active app"
    )
    try expect(
        HotkeyRoutingPolicy.shouldHandleHotkey(isEnabled: false, isCurrentApplicationDisabled: false),
        false,
        "hotkey routing passes through when Punto is disabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldHandleHotkey(isEnabled: true, isCurrentApplicationDisabled: true),
        false,
        "hotkey routing passes through disabled application"
    )
    try expect(
        HotkeyRoutingPolicy.shouldHandleHotkey(isEnabled: false, isCurrentApplicationDisabled: true),
        false,
        "hotkey routing passes through when both global and app disabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldTrackKeyState(isEnabled: true, isCurrentApplicationDisabled: false),
        true,
        "key-state routing tracks enabled active app"
    )
    try expect(
        HotkeyRoutingPolicy.shouldTrackKeyState(isEnabled: false, isCurrentApplicationDisabled: false),
        false,
        "key-state routing skips when Punto is disabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldTrackKeyState(isEnabled: true, isCurrentApplicationDisabled: true),
        false,
        "key-state routing skips disabled application"
    )
    try expect(
        HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(wasEnabled: true, isEnabled: false),
        true,
        "enabled transition clears state when Punto is disabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(wasEnabled: false, isEnabled: true),
        false,
        "enabled transition keeps state when Punto is enabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(wasEnabled: true, isEnabled: true),
        false,
        "enabled transition keeps state when enabled stays enabled"
    )
    try expect(
        HotkeyRoutingPolicy.shouldClearStateAfterEnabledChange(wasEnabled: false, isEnabled: false),
        false,
        "enabled transition keeps state when disabled stays disabled"
    )
    try expect(
        HotkeyRoutingPolicy.stateClearActionAfterEnabledChange(wasEnabled: true, isEnabled: false),
        HotkeyRoutingStateClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "Punto disabled",
            clearConversionSessionReason: "Punto disabled",
            logMessage: "Punto disabled - cleared text state"
        ),
        "hotkey routing owns global-disable state cleanup action"
    )
    try expect(
        HotkeyRoutingPolicy.stateClearActionAfterEnabledChange(wasEnabled: true, isEnabled: true),
        HotkeyRoutingStateClearAction(clearTrackedText: false, clearConversionSession: false),
        "hotkey routing keeps state when enabled state does not transition to disabled"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .modifierOnlyConvertLayout,
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            displayString: "Cmd+Opt+Shift"
        ),
        .handle(logMessage: "Modifier-only hotkey triggered: Cmd+Opt+Shift"),
        "hotkey routing owns modifier-only matched log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .modifierOnlyConvertLayout,
            isEnabled: false,
            isCurrentApplicationDisabled: false,
            displayString: "Cmd+Opt+Shift"
        ),
        .passThrough(logMessage: "Modifier-only hotkey ignored by routing policy"),
        "hotkey routing owns modifier-only pass-through log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .convertLayout,
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            keyCode: 6
        ),
        .handle(logMessage: "Convert layout hotkey matched! keyCode=6"),
        "hotkey routing owns convert hotkey matched log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .toggleCase,
            isEnabled: false,
            isCurrentApplicationDisabled: false,
            keyCode: 6
        ),
        .passThrough(logMessage: "Toggle case hotkey passed through by routing policy"),
        "hotkey routing owns toggle-case pass-through log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .toggleAutoCorrection,
            isEnabled: true,
            isCurrentApplicationDisabled: true,
            keyCode: 0
        ),
        .passThrough(logMessage: "Toggle auto-correction hotkey passed through by routing policy"),
        "hotkey routing owns auto-correction toggle pass-through log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .cancelLayoutChange,
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            keyCode: 51
        ),
        .handle(logMessage: "Cancel layout change hotkey matched! keyCode=51"),
        "hotkey routing owns cancel-layout matched log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .findInYandex,
            isEnabled: false,
            isCurrentApplicationDisabled: true,
            keyCode: 3
        ),
        .passThrough(logMessage: "Find in Yandex hotkey passed through by routing policy"),
        "hotkey routing owns Yandex search pass-through log"
    )
    try expect(
        HotkeyRoutingPolicy.action(
            kind: .findInSlovari,
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            keyCode: 5
        ),
        .handle(logMessage: "Find in Slovari hotkey matched! keyCode=5"),
        "hotkey routing owns Slovari hotkey matched log"
    )
}
