import Foundation
import PuntoCore

func runSettingsDefaultsPolicyTests() throws {
    try expect(
        SettingsPersistencePolicy.defaultIsEnabled,
        true,
        "settings defaults keep Punto enabled"
    )
    try expect(
        SettingsPersistencePolicy.nativeIsEnabledKey,
        "isEnabled",
        "settings persistence preserves observed global enable key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setEnabledSelector,
        "setEnabled:",
        "settings persistence preserves observed global enable setter"
    )
    try expect(
        StartupPresentationPolicy.defaultIsFirstLaunch,
        true,
        "settings defaults treat missing first-launch marker as first launch"
    )
    try expect(
        SettingsPersistencePolicy.defaultShowInMenuBar,
        true,
        "settings defaults show menu bar icon"
    )
    try expect(
        SettingsPersistencePolicy.defaultShowAdvancedSettings,
        false,
        "settings defaults hide advanced settings like observed Punto Switcher plist"
    )
    try expect(
        SettingsPersistencePolicy.nativeShowAdvancedSettingsKey,
        "showAdvancedSettings",
        "settings persistence preserves observed advanced-settings key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setShowAdvancedSettingsSelector,
        "setShowAdvancedSettings:",
        "settings persistence preserves observed advanced-settings setter"
    )
    try expect(
        LoginItemPolicy.defaultLaunchAtLogin,
        false,
        "settings defaults do not launch at login"
    )
    try expect(
        LoginItemPolicy.legacyLaunchesOnStartupKey,
        "launchesOnStartup",
        "settings persistence preserves observed launch-at-login alias key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setLaunchesOnStartupSelector,
        "setLaunchesOnStartup:",
        "settings persistence preserves observed launch-at-login setter"
    )
}
