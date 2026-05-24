import Foundation
import PuntoCore

func runTextTrackingSecurityPolicyTests() throws {
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: false, isPasswordField: false),
        true,
        "text tracking security allows normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: true, isPasswordField: false),
        false,
        "text tracking security blocks secure input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: false, isPasswordField: true),
        false,
        "text tracking security blocks password fields"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldTrackTextInput(isSecureInputEnabled: true, isPasswordField: true),
        false,
        "text tracking security blocks combined secure password context"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: false, isPasswordField: false),
        false,
        "text tracking security keeps state for normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: true, isPasswordField: false),
        true,
        "text tracking security clears state for secure input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: false, isPasswordField: true),
        true,
        "text tracking security clears state for password fields"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldClearTrackedState(isSecureInputEnabled: true, isPasswordField: true),
        true,
        "text tracking security clears state for combined secure password context"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(isSecureInputEnabled: false, isPasswordField: false),
        false,
        "text tracking security skips secure diagnostics for normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(isSecureInputEnabled: true, isPasswordField: false),
        true,
        "text tracking security writes secure diagnostics when secure input blocks tracking"
    )
    try expect(
        TextTrackingSecurityPolicy.shouldWriteSecureInputDiagnostics(isSecureInputEnabled: false, isPasswordField: true),
        true,
        "text tracking security writes secure diagnostics when password fields block tracking"
    )
    try expectNil(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: false, isPasswordField: false),
        "text tracking security omits secure diagnostics context for normal input"
    )
    try expect(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: true, isPasswordField: false),
        "secure input",
        "text tracking security reports secure-input diagnostics context"
    )
    try expect(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: false, isPasswordField: true),
        "password field",
        "text tracking security reports password-field diagnostics context"
    )
    try expect(
        TextTrackingSecurityPolicy.diagnosticContext(isSecureInputEnabled: true, isPasswordField: true),
        "secure input",
        "text tracking security gives secure input diagnostics priority over password field"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: false, isPasswordField: false),
        TextTrackingSecurityClearAction(clearTrackedText: false, clearConversionSession: false),
        "text tracking security keeps state for normal clear action"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: true, isPasswordField: false),
        TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: true,
            diagnosticContext: "secure input",
            logMessage: "Secure/password input - cleared text state"
        ),
        "text tracking security owns secure-input state cleanup action"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: false, isPasswordField: true),
        TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: true,
            diagnosticContext: "password field",
            logMessage: "Secure/password input - cleared text state"
        ),
        "text tracking security owns password-field state cleanup action"
    )
    try expect(
        TextTrackingSecurityPolicy.clearAction(isSecureInputEnabled: true, isPasswordField: true),
        TextTrackingSecurityClearAction(
            clearTrackedText: true,
            clearConversionSession: true,
            clearTrackedTextReason: "secure text input",
            clearConversionSessionReason: "secure text input",
            shouldWriteDiagnostics: true,
            diagnosticContext: "secure input",
            logMessage: "Secure/password input - cleared text state"
        ),
        "text tracking security gives secure input priority in combined cleanup action"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXTextField", subrole: "AXSecureTextField"),
        true,
        "text tracking security detects secure text subrole"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXSecureTextField", subrole: nil),
        true,
        "text tracking security detects secure text role"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: " axsecuretextfield ", subrole: nil),
        true,
        "text tracking security normalizes secure text role"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: " AX Secure Text Field ", subrole: nil),
        true,
        "text tracking security shares AX role normalization with accessibility role policy"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXTextField", subrole: "AXPasswordTextField"),
        true,
        "text tracking security detects password-like subrole"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXTextField", subrole: nil),
        false,
        "text tracking security allows ordinary text role"
    )
    try expect(
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(role: "AXWebArea", subrole: "AXSearchField"),
        false,
        "text tracking security allows ordinary web/search text roles"
    )

    let diagnosticsSnapshot = SecureInputDiagnosticsPolicy.snapshot(
        secureInputState: true,
        context: " secure text input ",
        currentApp: " COM.Apple.Terminal ",
        runningApps: ["com.apple.Terminal", "COM.APPLE.TERMINAL", nil, " "],
        enabledLayouts: ["com.apple.keylayout.ABC", "UNDEFINED", " com.apple.keylayout.Russian "]
    )
    try expect(
        diagnosticsSnapshot,
        SecureInputDiagnosticsSnapshot(
            secureInputState: true,
            context: "secure text input",
            currentApp: "com.apple.terminal",
            runningApps: ["com.apple.terminal"],
            enabledLayouts: ["com.apple.keylayout.ABC", "com.apple.keylayout.Russian"]
        ),
        "secure input diagnostics policy normalizes Punto Switcher-style plist fields"
    )
    let diagnosticsDictionary = SecureInputDiagnosticsPolicy.plistDictionary(from: diagnosticsSnapshot)
    try expect(
        SecureInputDiagnosticsPolicy.secureInputDiagnosticsPlistFilename,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.plistFilename,
        "secure input diagnostics policy aligns plist filename to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.secureInputStateKey] as? Bool,
        true,
        "secure input diagnostics writes SecureInputState key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.secureInputStateKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.secureInputStateKey,
        "secure input diagnostics policy aligns secure input key to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.contextKey] as? String,
        "secure text input",
        "secure input diagnostics writes Context key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.contextKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.contextKey,
        "secure input diagnostics policy aligns context key to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.currentAppKey] as? String,
        "com.apple.terminal",
        "secure input diagnostics writes currentApp key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.currentAppKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.currentAppKey,
        "secure input diagnostics policy aligns current-app key to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.runningAppsKey] as? [String],
        ["com.apple.terminal"],
        "secure input diagnostics writes runningApps key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.runningAppsKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.runningAppsKey,
        "secure input diagnostics policy aligns running-apps key to reverse-audit anchor"
    )
    try expect(
        diagnosticsDictionary[SecureInputDiagnosticsPolicy.enabledLayoutsKey] as? [String],
        ["com.apple.keylayout.ABC", "com.apple.keylayout.Russian"],
        "secure input diagnostics writes enabledLayouts key"
    )
    try expect(
        SecureInputDiagnosticsPolicy.enabledLayoutsKey,
        PuntoSwitcherObservedSurface.SecureInputDiagnostics.enabledLayoutsKey,
        "secure input diagnostics policy aligns enabled-layouts key to reverse-audit anchor"
    )
}

func runAccessibilityRolePolicyTests() throws {
    try expect(
        AccessibilityRolePolicy.normalizedRole(" ax web area "),
        "axwebarea",
        "accessibility role policy normalizes whitespace and case"
    )
    try expectNil(
        AccessibilityRolePolicy.normalizedRole("   "),
        "accessibility role policy rejects blank role"
    )
    try expect(
        AccessibilityRolePolicy.isWebAreaRole("AXWebArea"),
        true,
        "accessibility role policy detects AXWebArea"
    )
    try expect(
        AccessibilityRolePolicy.containsWebAreaRole(["AXStaticText", "AXGroup", "AXWebArea"]),
        true,
        "accessibility role policy detects AXWebArea ancestry"
    )
    try expect(
        AccessibilityRolePolicy.containsWebAreaRole(["AXStaticText", "AXGroup", "AXWindow"]),
        false,
        "accessibility role policy rejects static ancestry without AXWebArea"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityMailReplacement.fullWordReplacementSelector,
        "applyMailBehaviourForFullWords:withEvent:withCharsToSelect:withForceWordEndingCharPresent:",
        "accessibility role policy pins observed Punto Switcher Mail full-word helper selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityMailReplacement.partialWordReplacementSelector,
        "applyMailBehaviourForPartialWords:",
        "accessibility role policy pins observed Punto Switcher Mail partial-word helper selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.AccessibilityMailReplacement.deletionCounterKey,
        "numberOfDeletionsInMail",
        "accessibility role policy pins observed Punto Switcher Mail deletion counter"
    )
    try expect(
        AccessibilityRolePolicy.mailApplicationToken,
        PuntoSwitcherObservedSurface.AccessibilityRoles.mailApplicationToken,
        "accessibility role policy aligns native Mail app token to reverse-audit anchor"
    )
    try expect(
        AccessibilityRolePolicy.parallelsBundleID,
        PuntoSwitcherObservedSurface.AccessibilityRoles.parallelsBundleID,
        "accessibility role policy aligns native Parallels bundle id to reverse-audit anchor"
    )
    try expect(
        AccessibilityRolePolicy.scrollAreaRole,
        PuntoSwitcherObservedSurface.AccessibilityRoles.scrollAreaRole,
        "accessibility role policy aligns native scroll-area role to reverse-audit anchor"
    )
    try expect(
        AccessibilityRolePolicy.isClipboardReplaceableContentRole("AXScrollArea"),
        true,
        "accessibility role policy mirrors observed Punto Switcher AXScrollArea content surface"
    )
    try expect(
        AccessibilityRolePolicy.containsClipboardReplaceableContentRole(["AXStaticText", "AXScrollArea"]),
        true,
        "accessibility role policy detects observed clipboard-replaceable content ancestry"
    )
    try expect(
        AccessibilityRolePolicy.containsClipboardReplaceableContentRole(["AXStaticText", "AXGroup"]),
        false,
        "accessibility role policy rejects generic content ancestry for active clipboard replacement"
    )
    for role in ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"] {
        try expect(
            AccessibilityRolePolicy.isEditableTextRole(role),
            true,
            "accessibility role policy treats \(role) as editable text"
        )
    }
    for role in ["AXStaticText", "AXList", "AXTable", "AXButton", "AXWindow", "AXScrollArea"] {
        try expect(
            AccessibilityRolePolicy.isNonEditableContentRole(role),
            true,
            "accessibility role policy treats \(role) as non-editable content"
        )
    }
    try expect(
        AccessibilityRolePolicy.isEditableTextRole("AXStaticText"),
        false,
        "accessibility role policy does not treat static text as editable"
    )
    try expect(
        AccessibilityRolePolicy.isNonEditableContentRole("AXTextArea"),
        false,
        "accessibility role policy does not treat text area as non-editable content"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXTextArea",
            axEditable: true,
            selectedTextSettable: false
        ),
        true,
        "accessibility role policy accepts editable text area replacement"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXComboBox",
            axEditable: false,
            selectedTextSettable: true
        ),
        true,
        "accessibility role policy accepts settable editable-role replacement"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: nil,
            axEditable: nil,
            selectedTextSettable: true
        ),
        true,
        "accessibility role policy preserves settable replacement for unknown roles"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXStaticText",
            axEditable: true,
            selectedTextSettable: true
        ),
        false,
        "accessibility role policy blocks direct replacement for static content role"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXList",
            axEditable: false,
            selectedTextSettable: true
        ),
        false,
        "accessibility role policy blocks direct replacement for navigation/list role"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(
            role: "AXScrollArea",
            axEditable: true,
            selectedTextSettable: true
        ),
        false,
        "accessibility role policy blocks direct replacement for observed AXScrollArea content"
    )
    let editableTextAreaCapability = AccessibilityReplacementCapability(
        role: "AXTextArea",
        axEditable: true,
        selectedTextSettable: false,
        selectedTextSettableErrorCode: -25205
    )
    try expect(
        editableTextAreaCapability.supportsDirectSelectedTextReplacement,
        true,
        "accessibility replacement capability accepts editable text area evidence"
    )
    try expect(
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(editableTextAreaCapability),
        true,
        "accessibility role policy accepts typed replacement capability evidence"
    )
    try expect(
        editableTextAreaCapability.logDescription,
        "role=AXTextArea axEditable=true selectedTextSettable=false settableError=-25205",
        "accessibility replacement capability preserves AX evidence for diagnostics"
    )
    let staticContentCapability = AccessibilityReplacementCapability(
        role: "AXStaticText",
        axEditable: true,
        selectedTextSettable: true,
        selectedTextSettableErrorCode: 0
    )
    try expect(
        staticContentCapability.supportsDirectSelectedTextReplacement,
        false,
        "accessibility replacement capability blocks static content despite optimistic AX flags"
    )
    let unknownSettableCapability = AccessibilityReplacementCapability(
        role: nil,
        axEditable: nil,
        selectedTextSettable: true,
        selectedTextSettableErrorCode: 0
    )
    try expect(
        unknownSettableCapability.supportsDirectSelectedTextReplacement,
        true,
        "accessibility replacement capability preserves settable unknown-role support"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXTextField",
            bundleID: nil,
            context: .searchbar
        ),
        true,
        "accessibility role policy mirrors global searchbar editable-role exception"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXApplication",
            bundleID: nil,
            context: .searchbar
        ),
        true,
        "accessibility role policy mirrors AXApplication searchbar-only exception"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXApplication",
            bundleID: nil,
            context: .click
        ),
        false,
        "accessibility role policy keeps AXApplication out of click exceptions"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXGroup",
            bundleID: "com.apple.finder",
            context: .click
        ),
        true,
        "accessibility role policy mirrors Finder click group exception"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXGroup",
            bundleID: "com.apple.finder",
            context: .searchbar
        ),
        false,
        "accessibility role policy keeps Finder group click-only exception scoped"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXMenuItem",
            bundleID: "ORG.MOZILLA.FIREFOX",
            context: .click
        ),
        true,
        "accessibility role policy normalizes app-specific search exception bundle ids"
    )
    try expect(
        AccessibilityRolePolicy.isSearchExceptionRole(
            role: "AXGroup",
            bundleID: "com.example.Editor",
            context: .click
        ),
        false,
        "accessibility role policy rejects app-specific roles outside observed apps"
    )
    try expect(
        Set(AccessibilityRolePolicy.searchbarExceptionRoles.keys),
        [
            "*",
            "com.adobe.acc.AdobeCreativeCloud",
            "com.apple.ActivityMonitor",
            "com.apple.Aperture",
            "com.apple.DiskImageMounter",
            "com.apple.FinalCut",
            "com.apple.Notes",
            "com.apple.Photos",
            "com.apple.Preview",
            "com.apple.RemoteDesktop",
            "com.apple.ScreenSharing",
            "com.apple.SystemProfiler",
            "com.apple.dock",
            "com.apple.dt.Xcode",
            "com.apple.finder",
            "com.apple.garageband10",
            "com.apple.iCal",
            "com.apple.iTunes",
            "com.apple.iWork.Keynote",
            "com.apple.iWork.Numbers",
            "com.apple.iWork.Pages",
            "com.apple.logic10",
            "com.apple.loginwindow",
            "com.apple.mail",
            "com.apple.reminders",
            "com.apple.storeuid",
            "com.apple.talagent",
            "com.aspyr",
            "com.bittorrent.uTorrent",
            "com.blizzard",
            "com.bohemiancoding.sketch3",
            "com.google.chrome",
            "com.microsoft",
            "com.mojang",
            "com.parallels.desktop",
            "com.teamviewer.TeamViewer",
            "com.wunderkinder.wunderlistdesktop",
            "it.bloop.airmail",
            "it.bloop.airmail2",
            "org.chromium.chromium",
            "org.mozilla.firefox",
            "org.telegram.desktop",
            "ru.keepcoder.Telegram",
            "ru.yandex.desktop.yandex-browser"
        ],
        "accessibility role policy preserves full observed searchbar exception key set"
    )
    try expect(
        Set(AccessibilityRolePolicy.clickExceptionRoles.keys),
        [
            "*",
            "com.adobe.acc.AdobeCreativeCloud",
            "com.apple.ActivityMonitor",
            "com.apple.Aperture",
            "com.apple.DiskImageMounter",
            "com.apple.DiskUtility",
            "com.apple.FinalCut",
            "com.apple.Notes",
            "com.apple.Photos",
            "com.apple.Preview",
            "com.apple.RemoteDesktop",
            "com.apple.ScreenSharing",
            "com.apple.SystemProfiler",
            "com.apple.dock",
            "com.apple.dt.Xcode",
            "com.apple.finder",
            "com.apple.garageband10",
            "com.apple.iCal",
            "com.apple.iTunes",
            "com.apple.iWork.Keynote",
            "com.apple.iWork.Numbers",
            "com.apple.iWork.Pages",
            "com.apple.logic10",
            "com.apple.loginwindow",
            "com.apple.mail",
            "com.apple.reminders",
            "com.apple.storeuid",
            "com.apple.talagent",
            "com.bittorrent.uTorrent",
            "com.bohemiancoding.sketch3",
            "com.google.chrome",
            "com.microsoft",
            "com.parallels.desktop",
            "com.teamviewer.TeamViewer",
            "com.wunderkinder.wunderlistdesktop",
            "it.bloop.airmail",
            "it.bloop.airmail2",
            "org.chromium.chromium",
            "org.mozilla.firefox",
            "org.telegram.desktop",
            "ru.keepcoder.Telegram",
            "ru.yandex.desktop.yandex-browser"
        ],
        "accessibility role policy preserves full observed click exception key set"
    )
    try expect(
        AccessibilityRolePolicy.searchbarExceptionRoles["*"],
        ["AXTextField", "AXTextArea", "AXComboBox", "AXWindow", "AXUnknown", "AXStaticText", "AXPopUpButton", "AXApplication"],
        "accessibility role policy preserves observed global searchbar roles"
    )
    try expect(
        AccessibilityRolePolicy.clickExceptionRoles["*"],
        ["AXTextField", "AXTextArea", "AXComboBox", "AXWindow", "AXUnknown", "AXStaticText", "AXPopUpButton"],
        "accessibility role policy preserves observed global click roles"
    )
    try expect(
        AccessibilityRolePolicy.searchbarExceptionRoles["com.apple.finder"],
        ["AXList", "AXOutline", "AXGrid", "AXImage"],
        "accessibility role policy preserves Finder searchbar exception roles"
    )
    try expect(
        AccessibilityRolePolicy.clickExceptionRoles["com.apple.finder"],
        ["AXList", "AXOutline", "AXGrid", "AXImage", "AXGroup"],
        "accessibility role policy preserves Finder click exception roles"
    )
    try expect(
        AccessibilityRolePolicy.searchbarExceptionRoles["com.apple.Preview"],
        [],
        "accessibility role policy preserves explicit empty observed app searchbar exception"
    )
    try expect(
        AccessibilityRolePolicy.clickExceptionRoles["com.apple.DiskUtility"],
        [],
        "accessibility role policy preserves explicit empty observed app click exception"
    )
}

func runAccessibilityTraversalPolicyTests() throws {
    try expect(
        AccessibilityTraversalPolicy.maxDescendantSearchDepth,
        5,
        "accessibility traversal policy keeps recursive descendant search bounded"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: 0),
        true,
        "accessibility traversal policy inspects root depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: 4),
        true,
        "accessibility traversal policy inspects final descendant depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: 5),
        false,
        "accessibility traversal policy stops after max descendant depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldInspectDescendant(depth: -1),
        false,
        "accessibility traversal policy rejects negative descendant depth"
    )
    try expect(
        AccessibilityTraversalPolicy.maxAncestorRoleDepth,
        5,
        "accessibility traversal policy keeps ancestor role collection bounded"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldCollectAncestorRole(atDepth: 5),
        true,
        "accessibility traversal policy includes final ancestor role depth"
    )
    try expect(
        AccessibilityTraversalPolicy.shouldCollectAncestorRole(atDepth: 6),
        false,
        "accessibility traversal policy stops ancestor role collection after max depth"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .empty),
        true,
        "accessibility selection search continues after empty wrapper selection"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .failed),
        true,
        "accessibility selection search continues after failed wrapper selection"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .text),
        false,
        "accessibility selection search stops after text is found"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: .noFocus),
        false,
        "accessibility selection search stops when no focused element exists"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.sawEmptySelection(false, after: .empty),
        true,
        "accessibility selection search records empty selection probes"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.sawEmptySelection(true, after: .failed),
        true,
        "accessibility selection search preserves previous empty probes through failures"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.sawEmptySelection(false, after: .failed),
        false,
        "accessibility selection search does not invent empty state from unsupported AX probes"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.finalOutcomeAfterSearch(sawEmptySelection: true),
        .empty,
        "accessibility selection search preserves empty selection after alternatives are exhausted"
    )
    try expect(
        AccessibilitySelectionSearchPolicy.finalOutcomeAfterSearch(sawEmptySelection: false),
        .failed,
        "accessibility selection search falls back to failed when no AX source answered"
    )
}
