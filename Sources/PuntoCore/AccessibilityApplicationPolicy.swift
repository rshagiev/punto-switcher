import Foundation

public enum AccessibilityApplicationPolicy {
    public static let enhancedUserInterfaceAttribute = "AXEnhancedUserInterface"

    public static let observedBrowserInjectionBundleIDs: [String] = [
        "com.apple.safari",
        "com.google.chrome",
        "org.chromium.chromium",
        "ru.yandex.desktop.yandex-browser",
        "com.operasoftware.Opera",
        "org.mozilla.firefox"
    ]

    public static let observedEnhancedUserInterfaceBundleIDs: [String] = [
        "com.google.chrome",
        "com.operasoftware.Opera",
        "org.chromium.chromium",
        "org.mozilla.firefox",
        "ru.yandex.desktop.yandex-browser"
    ]

    private static let normalizedObservedBrowserInjectionBundleIDs = ApplicationBundleIDPolicy.normalizedSet(
        Set(observedBrowserInjectionBundleIDs)
    )

    private static let normalizedObservedEnhancedUserInterfaceBundleIDs = ApplicationBundleIDPolicy.normalizedSet(
        Set(observedEnhancedUserInterfaceBundleIDs)
    )

    public static func isObservedBrowserInjectionBundleID(_ bundleID: String?) -> Bool {
        guard let bundleID = ApplicationBundleIDPolicy.normalized(bundleID) else {
            return false
        }

        return normalizedObservedBrowserInjectionBundleIDs.contains(bundleID)
    }

    public static func shouldEnableEnhancedUserInterface(bundleID: String?) -> Bool {
        guard let bundleID = ApplicationBundleIDPolicy.normalized(bundleID) else {
            return false
        }

        return normalizedObservedEnhancedUserInterfaceBundleIDs.contains(bundleID)
    }
}
