import Foundation

public enum AccessibilityApplicationPolicy {
    public static let enhancedUserInterfaceAttribute = "AXEnhancedUserInterface"

    public static let browserInjectionBundleIDs: [String] = [
        "com.apple.safari",
        "com.google.chrome",
        "org.chromium.chromium",
        "ru.yandex.desktop.yandex-browser",
        "com.operasoftware.Opera",
        "org.mozilla.firefox"
    ]

    public static let enhancedUserInterfaceBundleIDs: [String] = [
        "com.google.chrome",
        "com.operasoftware.Opera",
        "org.chromium.chromium",
        "org.mozilla.firefox",
        "ru.yandex.desktop.yandex-browser"
    ]

    private static let normalizedBrowserInjectionBundleIDs = ApplicationBundleIDPolicy.normalizedSet(
        Set(browserInjectionBundleIDs)
    )

    private static let normalizedEnhancedUserInterfaceBundleIDs = ApplicationBundleIDPolicy.normalizedSet(
        Set(enhancedUserInterfaceBundleIDs)
    )

    public static func isBrowserInjectionBundleID(_ bundleID: String?) -> Bool {
        guard let bundleID = ApplicationBundleIDPolicy.normalized(bundleID) else {
            return false
        }

        return normalizedBrowserInjectionBundleIDs.contains(bundleID)
    }

    public static func shouldEnableEnhancedUserInterface(bundleID: String?) -> Bool {
        guard let bundleID = ApplicationBundleIDPolicy.normalized(bundleID) else {
            return false
        }

        return normalizedEnhancedUserInterfaceBundleIDs.contains(bundleID)
    }
}
