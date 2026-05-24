import Foundation
import PuntoCore

func runAccessibilityRolePolicyTests() throws {
    try expect(
        AccessibilityRolePolicy.normalizedRole(" ax web area "),
        "axwebarea",
        "accessibility role policy normalizes whitespace and case"
    )
    try expect(
        AccessibilityRolePolicy.normalizedRole("AX\tWeb\nArea"),
        "axwebarea",
        "accessibility role policy normalizes non-space whitespace inside roles"
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
