import Foundation
import PuntoCore

func runApplicationSettingsPolicyTests() throws {
    try expect(
        ApplicationLayoutPolicy.defaultRememberInputSourceForEachApp,
        false,
        "settings defaults keep per-app layout memory off"
    )
    try expect(
        ApplicationLayoutPolicy.legacyShouldRememberInputSourceForEachAppKey,
        "shouldRememberInputSourceForEachApp",
        "settings persistence preserves observed per-app layout memory key"
    )
    try expect(
        ApplicationLayoutMemory.defaultSnapshot,
        [:],
        "settings defaults start with empty remembered layout snapshot"
    )
    try expect(
        ApplicationDisablePolicy.defaultDisabledBundleIDs,
        [],
        "settings defaults start with no disabled applications"
    )
    try expect(
        ApplicationDisablePolicy.legacyDisabledAppsKey,
        "disabledApps",
        "settings persistence preserves observed disabled-apps key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setDisabledApplicationsSelector,
        "setDisabledApplications:",
        "settings persistence preserves observed disabled-apps setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.disabledAppsPreferencesControllerKey,
        "disabledAppsPreferencesController",
        "settings persistence preserves observed disabled-apps preferences controller key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setDisabledAppsPreferencesControllerSelector,
        "setDisabledAppsPreferencesController:",
        "settings persistence preserves observed disabled-apps preferences controller setter"
    )
    try expect(
        ApplicationDisablePolicy.defaultCompletelyDisableInExceptionApplications,
        false,
        "settings defaults keep exception apps partially disabled"
    )
    try expect(
        ApplicationDisablePolicy.legacyCompletelyDisableInExceptionApplicationsKey,
        "CompletelyDisableInExceptionApps",
        "settings persistence preserves observed full-disable exception-apps key"
    )
    try expect(
        ApplicationDisablePolicy.normalizedSet([
            " COM.Example.Editor ",
            "",
            "com.example.Terminal"
        ]),
        ["com.example.editor", "com.example.terminal"],
        "settings persistence normalizes disabled app ids"
    )
    try expect(
        ApplicationDisablePolicy.effectiveDisabledBundleIDs(
            hasPersistedValue: false,
            persistedValue: [],
            hasLegacyValue: true,
            legacyValue: [" COM.Example.Legacy ", ""]
        ),
        ["com.example.legacy"],
        "settings persistence reads Punto Switcher-style disabledApps alias"
    )
    try expect(
        ApplicationDisablePolicy.effectiveDisabledBundleIDs(
            hasPersistedValue: true,
            persistedValue: ["com.example.native"],
            hasLegacyValue: true,
            legacyValue: ["com.example.legacy"]
        ),
        ["com.example.native"],
        "settings persistence prefers native disabled app ids over legacy alias"
    )
    let layouts = ApplicationLayoutMemory.normalizedSnapshot([
        " COM.Example.Editor ": " com.apple.keylayout.Russian ",
        "": "ignored",
        "com.example.empty": " ",
        "com.example.Terminal": "com.apple.keylayout.ABC"
    ])
    try expect(
        layouts["com.example.editor"],
        "com.apple.keylayout.Russian",
        "settings persistence normalizes remembered layout app ids"
    )
    try expect(
        layouts["com.example.terminal"],
        "com.apple.keylayout.ABC",
        "settings persistence preserves valid remembered layout ids"
    )
    try expectNil(
        layouts["com.example.empty"],
        "settings persistence drops blank remembered layout ids"
    )
    try expectNil(
        layouts[""],
        "settings persistence drops blank remembered app ids"
    )
}
