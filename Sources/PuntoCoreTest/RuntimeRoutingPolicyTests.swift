import Foundation
import PuntoCore

func runApplicationContextPolicyTests() throws {
    try expect(
        ApplicationContextPolicy.activationAction(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto"
        ),
        .preserveCurrentExternalContext(
            logMessage: "Punto window activated - preserving last external app 'com.example.editor'"
        ),
        "app context policy preserves external context when Punto activates"
    )
    try expect(
        ApplicationContextPolicy.activationAction(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.chat",
            ownBundleID: "com.example.punto"
        ),
        .activateExternal(ApplicationContextActivationPlan(
            shouldResetTextState: true,
            clearTrackedTextReason: "active application changed",
            clearConversionSessionReason: "active application changed"
        )),
        "app context policy plans external app-switch cleanup"
    )
    try expect(
        ApplicationContextPolicy.activationAction(
            previousBundleID: nil,
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        .activateExternal(ApplicationContextActivationPlan(
            shouldResetTextState: false,
            clearTrackedTextReason: nil,
            clearConversionSessionReason: nil
        )),
        "app context policy keeps initial external activation clean"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: nil,
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy keeps empty initial context"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy keeps same app context"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: " COM.Example.Editor ",
            newBundleID: "com.example.editor",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy normalizes app context ids"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.chat",
            ownBundleID: "com.example.punto"
        ),
        true,
        "app context policy resets text state on external app switch"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: "com.example.punto",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy preserves state when Punto window activates"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: " COM.EXAMPLE.PUNTO ",
            ownBundleID: "com.example.punto"
        ),
        false,
        "app context policy normalizes own app id"
    )
    try expect(
        ApplicationContextPolicy.shouldResetTextState(
            previousBundleID: "com.example.editor",
            newBundleID: nil,
            ownBundleID: "com.example.punto"
        ),
        true,
        "app context policy resets when external app context is lost"
    )
}

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

func runKeyTrackingRuntimePolicyTests() throws {
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .track,
        "key tracking runtime tracks normal enabled input"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipRouting(logMessage: "Key tracking skipped by routing policy"),
        "key tracking runtime skips when Punto is disabled"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skipRouting(logMessage: "Key tracking skipped by routing policy"),
        "key tracking runtime skips disabled applications"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockSecureInput(context: "secure input", logMessage: "Key tracking skipped for secure/password input"),
        "key tracking runtime blocks secure input before tracking text"
    )
    try expect(
        KeyTrackingRuntimePolicy.preflightPlan(
            isEnabled: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockSecureInput(context: "password field", logMessage: "Key tracking skipped for secure/password input"),
        "key tracking runtime blocks password fields before tracking text"
    )
    try expect(
        KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: "org.telegram.desktop",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: ApplicationReturnKeyPolicy.defaultResetBundleComponents
        ),
        .resetOnReturn,
        "key tracking runtime routes reset-on-return apps away from auto-correction"
    )
    try expect(
        KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: "com.apple.TextEdit",
            keyCode: ApplicationReturnKeyPolicy.returnKeyCode,
            resetBundleComponents: ApplicationReturnKeyPolicy.defaultResetBundleComponents
        ),
        .runAutoCorrection,
        "key tracking runtime keeps ordinary editors eligible for return auto-correction"
    )
    try expect(
        KeyTrackingRuntimePolicy.postTrackRoute(
            bundleID: "org.telegram.desktop",
            keyCode: 49,
            resetBundleComponents: ApplicationReturnKeyPolicy.defaultResetBundleComponents
        ),
        .runAutoCorrection,
        "key tracking runtime ignores non-return keys for reset-on-return apps"
    )
    try expect(
        KeyTrackingRuntimePolicy.resetOnReturnPlan(
            consumedCompletedToken: true,
            bundleID: "org.telegram.desktop"
        ),
        KeyTrackingResetPlan(
            completedTokenStatisticsEvent: .completedWord,
            conversionSessionClearReason: "return in reset-on-return app",
            logMessage: "Auto-correction skipped and text state reset on Return for app 'org.telegram.desktop'"
        ),
        "key tracking runtime records completed word and clears undo for reset-on-return"
    )
    try expect(
        KeyTrackingRuntimePolicy.resetOnReturnPlan(
            consumedCompletedToken: false,
            bundleID: nil
        ),
        KeyTrackingResetPlan(
            completedTokenStatisticsEvent: nil,
            conversionSessionClearReason: "return in reset-on-return app",
            logMessage: "Auto-correction skipped and text state reset on Return for app '?'"
        ),
        "key tracking runtime handles reset-on-return without completed token"
    )
    try expect(
        KeyTrackingRuntimePolicy.conversionSessionClearReasonAfterAutoCorrection(isConversionInProgress: false),
        "key press",
        "key tracking runtime clears stale undo after ordinary non-converting key press"
    )
    try expectNil(
        KeyTrackingRuntimePolicy.conversionSessionClearReasonAfterAutoCorrection(isConversionInProgress: true),
        "key tracking runtime preserves undo while auto-correction conversion window is active"
    )
}

func runTextActionPreflightPolicyTests() throws {
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "text action preflight allows normal conversion"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "toggle case disabled"),
        "text action preflight skips disabled toggle case"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "manual conversion disabled"),
        "text action preflight skips manual layout conversion when manually disabled"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .proceed,
        "text action preflight keeps toggle-case available when manual conversion is disabled"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: true,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "conversion already in progress"),
        "text action preflight skips nested conversion"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: true,
            isSecureInputEnabled: false,
            isPasswordField: false
        ),
        .skip(reason: "current app disabled"),
        "text action preflight skips disabled application"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: true,
            isPasswordField: false
        ),
        .blockAndClear(reason: "secure input"),
        "text action preflight clears state for secure input"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .toggleCase,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "text action preflight clears state for password fields"
    )
    try expect(
        TextActionPreflightPolicy.action(
            kind: .layoutConversion,
            isEnabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "text action preflight gives secure input priority over password field"
    )
    try expect(
        TextActionPreflightPolicy.logMessage(
            action: .blockAndClear(reason: "password field"),
            kind: .toggleCase
        ),
        "Password field detected - toggle case blocked",
        "text action preflight preserves toggle-case password log"
    )
    try expect(
        TextActionPreflightPolicy.logMessage(
            action: .skip(reason: "manual conversion disabled"),
            kind: .layoutConversion
        ),
        "Manual conversion disabled, skipping conversion",
        "text action preflight preserves manual-conversion-disabled log"
    )
    try expect(
        TextActionPreflightPolicy.logMessage(
            action: .skip(reason: "current app disabled"),
            kind: .layoutConversion
        ),
        "Current app disabled, skipping conversion",
        "text action preflight preserves conversion disabled-app log"
    )
}

func runTextActionRuntimePreflightPolicyTests() throws {
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .layoutConversion,
            isEnabled: true,
            isManualConversionDisabled: false,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false
        ),
        .proceed,
        "text action runtime preflight route allows normal conversion"
    )
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .layoutConversion,
            isEnabled: true,
            isManualConversionDisabled: true,
            isConversionInProgress: false,
            isCurrentApplicationDisabled: false
        ),
        .skip(reason: "manual conversion disabled"),
        "text action runtime preflight route keeps manual-conversion setting in route phase"
    )
    try expect(
        TextActionRuntimePreflightPolicy.routeAction(
            kind: .selectedTextSearch,
            isEnabled: true,
            isConversionInProgress: true,
            isCurrentApplicationDisabled: false
        ),
        .skip(reason: "selected text search already in progress"),
        "text action runtime preflight route blocks nested selected-text search"
    )
    try expect(
        TextActionRuntimePreflightPolicy.securityAction(
            kind: .selectedTextSearch,
            isSecureInputEnabled: true,
            isPasswordField: true
        ),
        .blockAndClear(reason: "secure input"),
        "text action runtime preflight security gives secure input priority"
    )
    try expect(
        TextActionRuntimePreflightPolicy.securityAction(
            kind: .toggleCase,
            isSecureInputEnabled: false,
            isPasswordField: true
        ),
        .blockAndClear(reason: "password field"),
        "text action runtime preflight security blocks password fields"
    )
}

func runPointerEventPolicyTests() throws {
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue),
        .clearTrackedText(reason: "pointer click"),
        "pointer event policy clears tracked text on left mouse down"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: PointerEventPolicy.rightMouseDownRawValue),
        .clearTrackedText(reason: "pointer click"),
        "pointer event policy clears tracked text on right mouse down"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: PointerEventPolicy.otherMouseDownRawValue),
        .clearTrackedText(reason: "pointer click"),
        "pointer event policy clears tracked text on other mouse down"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: 2),
        .ignore,
        "pointer event policy ignores mouse up"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: 10),
        .ignore,
        "pointer event policy ignores non-click events"
    )
}

func runEventTapLifecyclePolicyTests() throws {
    try expect(
        EventTapLifecyclePolicy.action(
            isDisabledByTimeout: true,
            isDisabledByUserInput: false
        ),
        .reenableTap(reason: "tap disabled by timeout"),
        "event tap lifecycle policy re-enables tap disabled by timeout"
    )
    try expect(
        EventTapLifecyclePolicy.action(
            isDisabledByTimeout: false,
            isDisabledByUserInput: true
        ),
        .reenableTap(reason: "tap disabled by user input"),
        "event tap lifecycle policy re-enables tap disabled by user input"
    )
    try expect(
        EventTapLifecyclePolicy.action(
            isDisabledByTimeout: true,
            isDisabledByUserInput: true
        ),
        .reenableTap(reason: "tap disabled by timeout"),
        "event tap lifecycle policy gives timeout a stable priority"
    )
    try expect(
        EventTapLifecyclePolicy.action(
            isDisabledByTimeout: false,
            isDisabledByUserInput: false
        ),
        .ignore,
        "event tap lifecycle policy ignores ordinary events"
    )
}

func runAccessibilityNotificationPolicyTests() throws {
    let now = Date(timeIntervalSince1970: 1_000)

    try expect(
        AccessibilityNotificationPolicy.supportedNotifications,
        [
            AccessibilityNotificationPolicy.focusedUIElementChanged,
            AccessibilityNotificationPolicy.focusedWindowChanged,
            AccessibilityNotificationPolicy.mainWindowChanged,
            AccessibilityNotificationPolicy.windowCreated,
            AccessibilityNotificationPolicy.selectedTextChanged,
            AccessibilityNotificationPolicy.valueChanged
        ],
        "accessibility notification policy observes focus, main-window, window creation, selection, and value changes"
    )
    try expect(
        AccessibilityNotificationPolicy.supportedNotifications,
        [
            PuntoSwitcherObservedSurface.AccessibilityNotifications.focusedUIElementChanged,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.focusedWindowChanged,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.mainWindowChanged,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.windowCreated,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.selectedTextChanged,
            PuntoSwitcherObservedSurface.AccessibilityNotifications.valueChanged
        ],
        "accessibility notification policy aligns native notification names to reverse-audit anchors"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedUIElementChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXFocusedUIElementChanged"),
        "accessibility notification policy clears state on focused element changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXSelectedTextChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .ignore(reason: "text mutation notification is diagnostic"),
        "accessibility notification policy keeps typed tracking on noisy selection changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXMainWindowChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXMainWindowChanged"),
        "accessibility notification policy clears state when the main window changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXWindowCreated",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXWindowCreated"),
        "accessibility notification policy clears state when a new window is created"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXValueChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .ignore(reason: "text mutation notification is diagnostic"),
        "accessibility notification policy observes but does not clear on ordinary value changes"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: now.addingTimeInterval(0.1),
            isConversionInProgress: false
        ),
        .ignore(reason: "replacement grace window"),
        "accessibility notification policy suppresses replacement-window notifications"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: now,
            isConversionInProgress: false
        ),
        .clearTrackedText(reason: "accessibility AXFocusedWindowChanged"),
        "accessibility notification policy clears after replacement grace window expires"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            sourceBundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: true
        ),
        .ignore(reason: "conversion in progress"),
        "accessibility notification policy suppresses in-flight conversions"
    )
    try expect(
        AccessibilityNotificationPolicy.action(
            notificationName: "AXFocusedWindowChanged",
            sourceBundleID: " COM.Example.Punto ",
            ownBundleID: "com.example.punto",
            now: now,
            ignoreUntil: nil,
            isConversionInProgress: false
        ),
        .ignore(reason: "own application"),
        "accessibility notification policy ignores Punto's own windows"
    )
    try expect(
        ConversionProtectionPolicy.eventRecaptureIgnoreDeadline(now: now),
        now.addingTimeInterval(ConversionProtectionPolicy.eventRecaptureProtectionDelay),
        "conversion protection policy shares replacement grace interval with accessibility notifications"
    )
}
