import Foundation
import PuntoCore

func runAccessibilityPreferencesPolicyTests() throws {
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityPreferences.launchAccessibilityPreferencesSelector,
        "launchAccessibilityPreferences",
        "accessibility preferences policy pins observed launch selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityPreferences.openAccessibilityPrefPaneSelector,
        "openAccesibilityPrefPane:",
        "accessibility preferences policy pins observed Accessibility pane opener selector"
    )
    try expect(
        AccessibilityPreferencesPolicy.securityPrivacyPaneID,
        "com.apple.preference.security",
        "accessibility preferences policy preserves observed security pane id"
    )
    try expect(
        AccessibilityPreferencesPolicy.accessibilityPrivacyAnchor,
        "Privacy_Accessibility",
        "accessibility preferences policy preserves observed accessibility anchor"
    )
    try expect(
        AccessibilityPreferencesPolicy.preferencesURL.absoluteString,
        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
        "accessibility preferences policy builds observed System Settings URL"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityPreferences.accessibilityAlertMessageKey,
        "accessibility-alert-message",
        "accessibility preferences policy preserves observed modern alert message key"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityPreferences.accessibilityAlertLegacyMessageKey,
        "accessibility-alert-messageLegacy",
        "accessibility preferences policy preserves observed legacy alert message key"
    )
    try expect(
        AccessibilityPreferencesPolicy.permissionRequestMessage.contains("System Settings > Privacy & Security > Accessibility"),
        true,
        "accessibility preferences policy keeps native permission copy on the observed Accessibility path"
    )
    try expect(
        AccessibilityPreferencesPolicy.openSettingsButtonTitle,
        "Open System Settings",
        "accessibility preferences policy centralizes open-settings button copy"
    )
    try expect(
        AccessibilityPreferencesPolicy.legacyAppleScriptSource.contains("tell application \"System Preferences\""),
        true,
        "accessibility preferences policy preserves observed System Preferences fallback"
    )
    try expect(
        AccessibilityPreferencesPolicy.legacyAppleScriptSource.contains("reveal anchor \"Privacy_Accessibility\" of pane id \"com.apple.preference.security\""),
        true,
        "accessibility preferences policy reveals observed Accessibility privacy anchor"
    )
    try expect(
        AccessibilityPreferencesPolicy.shouldRunLegacyFallback(openedURL: false),
        true,
        "accessibility preferences policy falls back when URL open fails"
    )
    try expect(
        AccessibilityPreferencesPolicy.shouldRunLegacyFallback(openedURL: true),
        false,
        "accessibility preferences policy skips fallback after successful URL open"
    )
}
