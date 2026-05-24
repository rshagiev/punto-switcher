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
        PuntoSwitcherObservedSurface.AccessibilityPreferences.legacySecurityPrivacyPaneID,
        "accessibility preferences policy keeps security pane id aligned with reverse-audit anchor"
    )
    try expect(
        AccessibilityPreferencesPolicy.accessibilityPrivacyAnchor,
        PuntoSwitcherObservedSurface.AccessibilityPreferences.legacyAccessibilityPrivacyAnchor,
        "accessibility preferences policy keeps accessibility anchor aligned with reverse-audit anchor"
    )
    try expect(
        AccessibilityPreferencesPolicy.preferencesURL.absoluteString,
        PuntoSwitcherObservedSurface.AccessibilityPreferences.preferencesURLString,
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
        AccessibilityPreferencesPolicy.legacyAppleScriptSource.contains(
            "tell application \"\(PuntoSwitcherObservedSurface.AccessibilityPreferences.legacySystemPreferencesApplicationName)\""
        ),
        true,
        "accessibility preferences policy preserves observed System Preferences fallback"
    )
    try expect(
        AccessibilityPreferencesPolicy.legacyAppleScriptSource.contains(
            "reveal anchor \"\(PuntoSwitcherObservedSurface.AccessibilityPreferences.legacyAccessibilityPrivacyAnchor)\" of pane id \"\(PuntoSwitcherObservedSurface.AccessibilityPreferences.legacySecurityPrivacyPaneID)\""
        ),
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
