import Foundation
import PuntoCore

func runStartupPresentationPolicyTests() throws {
    try expect(
        StartupPresentationPolicy.installArgument,
        "--install",
        "startup presentation policy preserves observed installer argument"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.handleInstallArgumentSelector,
        "handleInstallArgument",
        "startup presentation policy preserves observed install handler selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.installedTooltipKey,
        "tooltip-app-installed",
        "startup presentation policy preserves observed installed tooltip key"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.showUpdateFinishedTooltipSelector,
        "showUpdateFinishedTooltip",
        "startup presentation policy preserves observed update-finished tooltip selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.shouldDisplayWelcomeSelector,
        "shouldDisplayWelcome",
        "startup presentation policy preserves observed welcome selector"
    )
    try expect(
        StartupPresentationPolicy.installArgumentHandlerLogName,
        PuntoSwitcherObservedSurface.StartupPresentation.handleInstallArgumentSelector,
        "startup presentation policy keeps install handler log aligned with reverse-audit anchor"
    )
    try expect(
        StartupPresentationPolicy.updateFinishedTooltipLogName,
        PuntoSwitcherObservedSurface.StartupPresentation.showUpdateFinishedTooltipSelector,
        "startup presentation policy keeps update-finished log aligned with reverse-audit anchor"
    )
    try expect(
        StartupPresentationPolicy.welcomeLogMessage,
        "Displaying welcome screen...",
        "startup presentation policy preserves observed welcome log"
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: true,
            updateSettings: ApplicationUpdateSettingsPolicy.defaultSnapshot
        ),
        true,
        "startup presentation policy shows welcome on native first launch"
    )
    let alreadyInstalled = ApplicationUpdateSettingsSnapshot(
        configVersion: 8,
        isFirstInstallation: false,
        isJustInstalled: false,
        isJustUpdated: false,
        isUpdating: false,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: false,
            updateSettings: alreadyInstalled
        ),
        false,
        "startup presentation policy skips welcome after first-install flags are consumed"
    )
    let justInstalled = ApplicationUpdateSettingsSnapshot(
        configVersion: 8,
        isFirstInstallation: false,
        isJustInstalled: true,
        isJustUpdated: false,
        isUpdating: false,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: false,
            updateSettings: justInstalled
        ),
        true,
        "startup presentation policy shows welcome for observed just-installed flag"
    )
    let consumed = StartupPresentationPolicy.updateSettingsAfterWelcome(justInstalled)
    try expect(consumed.isFirstInstallation, false, "startup presentation policy consumes first-install flag")
    try expect(consumed.isJustInstalled, false, "startup presentation policy consumes just-installed flag")
    try expect(consumed.configVersion, justInstalled.configVersion, "startup presentation policy preserves config version")

    try expect(
        StartupPresentationPolicy.shouldHandleInstallArgument(["/Applications/Punto.app/Contents/MacOS/Punto", "--install"]),
        true,
        "startup presentation policy detects observed installer launch argument"
    )
    try expect(
        StartupPresentationPolicy.shouldHandleInstallArgument(["/Applications/Punto.app/Contents/MacOS/Punto", "--not-install"]),
        false,
        "startup presentation policy rejects non-matching installer argument"
    )

    let afterInstallArgument = StartupPresentationPolicy.updateSettingsAfterInstallArgument(alreadyInstalled)
    try expect(afterInstallArgument.isJustInstalled, true, "startup presentation policy marks just-installed after installer argument")
    try expect(afterInstallArgument.isUpdating, false, "startup presentation policy clears updating after installer argument")
    try expect(afterInstallArgument.configVersion, alreadyInstalled.configVersion, "startup presentation policy preserves config version after installer argument")
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(isFirstLaunch: false, updateSettings: afterInstallArgument),
        true,
        "startup presentation policy shows welcome after installer argument"
    )

    let justUpdated = ApplicationUpdateSettingsSnapshot(
        configVersion: 9,
        isFirstInstallation: false,
        isJustInstalled: false,
        isJustUpdated: true,
        isUpdating: true,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayUpdateFinishedTooltip(updateSettings: justUpdated),
        true,
        "startup presentation policy shows update-finished tooltip for observed just-updated flag"
    )
    let afterUpdateTooltip = StartupPresentationPolicy.updateSettingsAfterUpdateFinishedTooltip(justUpdated)
    try expect(afterUpdateTooltip.isJustUpdated, false, "startup presentation policy consumes just-updated flag")
    try expect(afterUpdateTooltip.isUpdating, false, "startup presentation policy clears updating after update-finished tooltip")
    try expect(afterUpdateTooltip.configVersion, justUpdated.configVersion, "startup presentation policy preserves config version after update-finished tooltip")
}

func runLayoutSwitchPolicyTests() throws {
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .lastWord,
            switchLayoutAfterConversion: false,
            switchLayoutAfterSelectedTextConversion: true
        ),
        false,
        "layout switch policy respects global switch-off for last-word conversion"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .selectedText,
            switchLayoutAfterConversion: false,
            switchLayoutAfterSelectedTextConversion: true
        ),
        false,
        "layout switch policy respects global switch-off for selected-text conversion"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false
        ),
        true,
        "layout switch policy keeps last-word switching when selected-text switching is disabled"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .undo,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false
        ),
        true,
        "layout switch policy keeps undo layout switching when selected-text switching is disabled"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .selectedText,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false
        ),
        false,
        "layout switch policy can suppress selected-text layout switching only"
    )
    try expect(
        LayoutSwitchPolicy.shouldSwitchLayoutAfterConversion(
            surface: .selectedText,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: true
        ),
        true,
        "layout switch policy allows selected-text layout switching when both switches are enabled"
    )

    let now = Date(timeIntervalSince1970: 500)
    let expectedDeadline = now.addingTimeInterval(ConversionProtectionPolicy.inputSourceSwitchGraceInterval)
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .russian,
            surface: .lastWord,
            switchLayoutAfterConversion: false,
            switchLayoutAfterSelectedTextConversion: true,
            now: now
        ),
        .skip,
        "layout switch runtime skips when global switch is disabled"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .russian,
            surface: .selectedText,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false,
            now: now
        ),
        .skip,
        "layout switch runtime skips selected text when selected-text switch is disabled"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .russian,
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false,
            now: now
        ),
        .switchTo(LayoutSwitchRuntimeRequest(
            language: .russian,
            targetLayout: .russian,
            ignoreInputSourceChangesUntil: expectedDeadline
        )),
        "layout switch runtime requests Russian switch with programmatic grace deadline"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .english,
            surface: .undo,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: false,
            now: now
        ),
        .switchTo(LayoutSwitchRuntimeRequest(
            language: .english,
            targetLayout: .english,
            ignoreInputSourceChangesUntil: expectedDeadline
        )),
        "layout switch runtime requests English switch for undo"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .mixed,
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: true,
            now: now
        ),
        .unsupportedTarget(clearInputSourceIgnoreDeadline: true),
        "layout switch runtime clears programmatic guard for mixed target"
    )
    try expect(
        LayoutSwitchRuntimePolicy.plan(
            targetLayout: .unknown,
            surface: .lastWord,
            switchLayoutAfterConversion: true,
            switchLayoutAfterSelectedTextConversion: true,
            now: now
        ),
        .unsupportedTarget(clearInputSourceIgnoreDeadline: true),
        "layout switch runtime clears programmatic guard for unknown target"
    )
}

func runApplicationDisablePolicyTests() throws {
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "com.microsoft.Word",
            disabledBundleIDs: ["com.microsoft"]
        ),
        true,
        "application disable policy matches bundle prefix"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "com.microsoft",
            disabledBundleIDs: ["com.microsoft"]
        ),
        true,
        "application disable policy matches exact bundle id"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "com.microsoftWord",
            disabledBundleIDs: ["com.microsoft"]
        ),
        false,
        "application disable policy rejects glued prefix"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: "  COM.MICROSOFT.Excel  ",
            disabledBundleIDs: [" com.microsoft "]
        ),
        true,
        "application disable policy normalizes case and whitespace"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: nil,
            disabledBundleIDs: ["com.microsoft"]
        ),
        false,
        "application disable policy ignores missing bundle id"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: "com.microsoft.Word",
            disabledBundleIDs: ["com.microsoft"],
            completelyDisableInExceptionApplications: false
        ),
        false,
        "application disable policy keeps exception apps partially disabled by default"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: "com.microsoft.Word",
            disabledBundleIDs: ["com.microsoft"],
            completelyDisableInExceptionApplications: true
        ),
        true,
        "application disable policy fully disables exception apps when configured"
    )
    try expect(
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: "com.example.editor",
            disabledBundleIDs: ["com.microsoft"],
            completelyDisableInExceptionApplications: true
        ),
        false,
        "application disable policy does not fully disable unrelated apps"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: " com.example.App ",
            disabled: true,
            disabledBundleIDs: ["com.other.App"]
        ),
        ["com.example.app", "com.other.app"],
        "application disable policy stores normalized ids"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "COM.MICROSOFT.Word",
            disabled: true,
            disabledBundleIDs: [" com.microsoft ", "com.other.App"]
        ),
        ["com.microsoft.word", "com.other.app"],
        "application disable policy replaces matching prefix with specific disabled app"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoft",
            disabled: true,
            disabledBundleIDs: ["com.microsoft.Word", "com.other.App"]
        ),
        ["com.microsoft", "com.other.app"],
        "application disable policy replaces covered child ids with broader prefix"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoft.Word",
            disabled: false,
            disabledBundleIDs: ["com.microsoft", "com.other.App"]
        ),
        ["com.other.app"],
        "application disable policy removes matching disabled prefix"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "COM.MICROSOFT.Word",
            disabled: false,
            disabledBundleIDs: [" com.microsoft ", "com.other.App"]
        ),
        ["com.other.app"],
        "application disable policy removes matching prefix case-insensitively"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoft",
            disabled: false,
            disabledBundleIDs: ["com.microsoft.Word", "com.microsoft.Excel", "com.other.App"]
        ),
        ["com.other.app"],
        "application disable policy removes child ids when enabling broader app family"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: "com.microsoftWord",
            disabled: false,
            disabledBundleIDs: ["com.microsoft", "com.other.App"]
        ),
        ["com.microsoft", "com.other.app"],
        "application disable policy keeps glued prefix when enabling app"
    )
    try expect(
        ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: nil,
            disabled: false,
            disabledBundleIDs: [" com.microsoft ", "", "COM.OTHER.App"]
        ),
        ["com.microsoft", "com.other.app"],
        "application disable policy normalizes persisted ids when bundle id is missing"
    )
    try expect(
        ApplicationDisablePolicy.normalizedSet([" com.microsoft ", "", "COM.OTHER.App"]),
        ["com.microsoft", "com.other.app"],
        "application disable policy normalizes disabled-app set"
    )
    try expect(
        ApplicationDisablePolicy.toggleAction(
            bundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableToggleAction(
            bundleID: "com.example.editor",
            disabled: true,
            shouldClearState: true,
            clearTrackedTextReason: "disabled current app",
            clearConversionSessionReason: "disabled current app"
        ),
        "application disable policy disables current external app and clears state"
    )
    try expect(
        ApplicationDisablePolicy.toggleAction(
            bundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: true
        ),
        ApplicationDisableToggleAction(
            bundleID: "com.example.editor",
            disabled: false,
            shouldClearState: false
        ),
        "application disable policy re-enables current external app without clearing state"
    )
    try expect(
        ApplicationDisablePolicy.toggleLogMessage(
            action: ApplicationDisableToggleAction(
                bundleID: "com.example.editor",
                disabled: true,
                shouldClearState: true,
                clearTrackedTextReason: "disabled current app",
                clearConversionSessionReason: "disabled current app"
            ),
            applicationName: " TextEdit "
        ),
        "Disabled Punto in app 'TextEdit' (com.example.editor)",
        "application disable policy trims display name in toggle log"
    )
    try expect(
        ApplicationDisablePolicy.toggleLogMessage(
            action: ApplicationDisableToggleAction(
                bundleID: "com.example.editor",
                disabled: false,
                shouldClearState: false
            ),
            applicationName: "   "
        ),
        "Enabled Punto in app 'com.example.editor' (com.example.editor)",
        "application disable policy falls back to bundle id in toggle log"
    )
    try expectNil(
        ApplicationDisablePolicy.toggleAction(
            bundleID: " COM.Example.Punto ",
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: false
        ),
        "application disable policy refuses to disable Punto itself"
    )
    try expectNil(
        ApplicationDisablePolicy.toggleAction(
            bundleID: nil,
            ownBundleID: "com.example.punto",
            isCurrentlyDisabled: false
        ),
        "application disable policy ignores missing current app id"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: " COM.Example.Editor ",
            ownBundleID: "com.example.punto",
            displayName: " TextEdit ",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "Disable in TextEdit",
            isEnabled: true,
            isChecked: false
        ),
        "application disable policy shows enabled disable action for current external app"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            displayName: "TextEdit",
            isCurrentlyDisabled: true
        ),
        ApplicationDisableMenuState(
            title: "Enable in TextEdit",
            isEnabled: true,
            isChecked: true
        ),
        "application disable policy shows checked enable action for disabled current app"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: "com.example.editor",
            ownBundleID: "com.example.punto",
            displayName: "   ",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "Disable in Current App",
            isEnabled: true,
            isChecked: false
        ),
        "application disable policy falls back to generic current app title"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: "com.example.punto",
            ownBundleID: " COM.Example.Punto ",
            displayName: "Punto",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "No Current App",
            isEnabled: false,
            isChecked: false
        ),
        "application disable policy disables menu action for Punto itself"
    )
    try expect(
        ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: nil,
            ownBundleID: "com.example.punto",
            displayName: "Unknown",
            isCurrentlyDisabled: false
        ),
        ApplicationDisableMenuState(
            title: "No Current App",
            isEnabled: false,
            isChecked: false
        ),
        "application disable policy disables menu action without current bundle id"
    )
}

func runAutoCorrectionTogglePolicyTests() throws {
    try expect(
        AutoCorrectionTogglePolicy.action(wasEnabled: true),
        AutoCorrectionToggleAction(
            newEnabledValue: false,
            clearTrackedTextReason: "auto-correction toggled",
            clearConversionSessionReason: "auto-correction toggled",
            logMessage: "Auto-correction disabled by hotkey",
            shouldFlashIcon: true
        ),
        "auto-correction toggle policy disables enabled setting and clears runtime state"
    )
    try expect(
        AutoCorrectionTogglePolicy.action(wasEnabled: false),
        AutoCorrectionToggleAction(
            newEnabledValue: true,
            clearTrackedTextReason: "auto-correction toggled",
            clearConversionSessionReason: "auto-correction toggled",
            logMessage: "Auto-correction enabled by hotkey",
            shouldFlashIcon: true
        ),
        "auto-correction toggle policy enables disabled setting and clears runtime state"
    )
}

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
