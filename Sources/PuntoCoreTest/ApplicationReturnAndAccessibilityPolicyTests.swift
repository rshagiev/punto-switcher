import Foundation
import PuntoCore

func runApplicationReturnKeyPolicyTests() throws {
    try expect(
        ApplicationReturnKeyPolicy.legacyResetOnReturnKey,
        "switcher.reset_on_return",
        "return policy owns observed reset-on-return import key"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "org.telegram.desktop",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode
        ),
        true,
        "return policy resets text state on Telegram Return"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "ru.keepcoder.Telegram",
            keyCode: ApplicationReturnKeyPolicy.enterKeyCode
        ),
        true,
        "return policy resets text state on Telegram Enter"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.telegram.client",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode
        ),
        true,
        "return policy resets text state for telegram bundle component"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.apple.TextEdit",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode
        ),
        false,
        "return policy keeps ordinary editors eligible for return auto-correction"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.slack.client",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: [" slack "]
        ),
        true,
        "return policy supports configured reset_on_return bundle components"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.slackclient",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: ["slack"]
        ),
        false,
        "return policy rejects glued configured reset_on_return component"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.slack.client",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: [" "]
        ),
        false,
        "return policy ignores blank configured reset_on_return components"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "com.example.nottelegram",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode
        ),
        false,
        "return policy rejects glued telegram suffix"
    )
    try expect(
        ApplicationReturnKeyPolicy.shouldResetTextStateOnReturn(
            bundleID: "org.telegram.desktop",
            keyCode: 49
        ),
        false,
        "return policy ignores non-return keys"
    )
}

func runAccessibilityApplicationPolicyTests() throws {
    try expect(
        AccessibilityApplicationPolicy.browserInjectionBundleIDs,
        PuntoSwitcherObservedSurface.AccessibilityApplications.browserInjectionBundleIDs,
        "accessibility app policy aligns browser injection list to reverse-audit anchor"
    )
    try expect(
        AccessibilityApplicationPolicy.enhancedUserInterfaceBundleIDs,
        PuntoSwitcherObservedSurface.AccessibilityApplications.enhancedUserInterfaceBundleIDs,
        "accessibility app policy aligns enhanced-UI list to reverse-audit anchor"
    )

    for bundleID in [
        "com.apple.Safari",
        "com.google.chrome",
        "com.operasoftware.Opera",
        "org.chromium.chromium",
        "org.mozilla.firefox",
        "ru.yandex.desktop.yandex-browser"
    ] {
        try expect(
            AccessibilityApplicationPolicy.isBrowserInjectionBundleID(bundleID),
            true,
            "accessibility app policy detects observed browser injection bundle \(bundleID)"
        )
    }

    for bundleID in [
        "com.google.chrome",
        "com.operasoftware.Opera",
        "org.chromium.chromium",
        "org.mozilla.firefox",
        "ru.yandex.desktop.yandex-browser"
    ] {
        try expect(
            AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: bundleID),
            true,
            "accessibility app policy enables enhanced UI for observed eui bundle \(bundleID)"
        )
    }

    try expect(
        AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: "com.apple.Safari"),
        false,
        "accessibility app policy keeps Safari out of AXEnhancedUserInterface to match observed eui list"
    )
    try expect(
        AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: " com.google.Chrome "),
        true,
        "accessibility app policy normalizes browser bundle id"
    )
    try expect(
        AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: "com.google.chrome.helper"),
        false,
        "accessibility app policy rejects glued browser bundle suffix"
    )
    try expect(
        AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: nil),
        false,
        "accessibility app policy rejects missing bundle id"
    )
}
