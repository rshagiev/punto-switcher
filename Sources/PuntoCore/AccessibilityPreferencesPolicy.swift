import Foundation

public enum AccessibilityPreferencesPolicy {
    public static let observedLaunchAccessibilityPreferencesSelector = "launchAccessibilityPreferences"
    public static let observedOpenAccessibilityPrefPaneSelector = "openAccesibilityPrefPane:"
    public static let observedSecurityPrivacyPaneID = "com.apple.preference.security"
    public static let observedAccessibilityAnchor = "Privacy_Accessibility"
    public static let observedURLString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    public static let observedAccessibilityAlertMessageKey = "accessibility-alert-message"
    public static let observedAccessibilityAlertLegacyMessageKey = "accessibility-alert-messageLegacy"

    public static let permissionRequestTitle = "Punto needs Accessibility access"
    public static let permissionRequestMessage = """
    To convert text in other apps, Punto needs Accessibility access.

    Add Punto to System Settings > Privacy & Security > Accessibility.
    """
    public static let permissionRequiredTitle = "Accessibility Permission Required"
    public static let permissionRequiredMessage = "Punto needs Accessibility access to detect hotkeys and convert text. Add Punto to System Settings > Privacy & Security > Accessibility."
    public static let permissionDeniedTitle = "Accessibility Access Denied"
    public static let permissionDeniedMessage = "Punto cannot function without Accessibility access. Enable Punto in System Settings > Privacy & Security > Accessibility."
    public static let openSettingsButtonTitle = "Open System Settings"
    public static let cancelButtonTitle = "Cancel"
    public static let laterButtonTitle = "Later"
    public static let quitButtonTitle = "Quit"

    public static var preferencesURL: URL {
        URL(string: observedURLString)!
    }

    public static var legacyAppleScriptSource: String {
        """
        tell application "System Preferences"
            activate
            reveal anchor "\(observedAccessibilityAnchor)" of pane id "\(observedSecurityPrivacyPaneID)"
        end tell
        """
    }

    public static func shouldRunLegacyFallback(openedURL: Bool) -> Bool {
        !openedURL
    }
}
