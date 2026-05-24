import Foundation
import PuntoCore

func runStatusIconPolicyTests() throws {
    try expect(
        PuntoSwitcherObservedSurface.StatusIcon.updateMenubarIconSelector,
        "updateMenubarIcon:",
        "status icon policy preserves observed Punto Switcher menu bar update selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.StatusIcon.resourceNames,
        [
            "icon_active",
            "icon_inactive",
            "icon_disabled",
            "icon_active_w",
            "icon_inactive_w",
            "icon_disabled_w"
        ],
        "status icon policy preserves observed Punto Switcher resource names"
    )
    try expect(
        StatusIconPolicy.state(isEnabled: true, isCurrentApplicationDisabled: false),
        .active,
        "status icon policy marks enabled external app as active"
    )
    try expect(
        StatusIconPolicy.state(isEnabled: false, isCurrentApplicationDisabled: false),
        .inactive,
        "status icon policy marks globally disabled Punto as inactive"
    )
    try expect(
        StatusIconPolicy.state(isEnabled: true, isCurrentApplicationDisabled: true),
        .disabled,
        "status icon policy marks disabled current app separately"
    )
    try expect(
        StatusIconPolicy.state(isEnabled: false, isCurrentApplicationDisabled: true),
        .inactive,
        "status icon policy gives global inactive state priority over app exception"
    )
    try expect(
        StatusIconPolicy.accessibilityDescription(for: .disabled),
        "Punto disabled in current app",
        "status icon policy exposes disabled state description"
    )
}
