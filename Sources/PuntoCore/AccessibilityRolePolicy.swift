import Foundation

public struct AccessibilityReplacementCapability: Equatable {
    public let role: String?
    public let axEditable: Bool?
    public let selectedTextSettable: Bool
    public let selectedTextSettableErrorCode: Int

    public init(
        role: String?,
        axEditable: Bool?,
        selectedTextSettable: Bool,
        selectedTextSettableErrorCode: Int
    ) {
        self.role = role
        self.axEditable = axEditable
        self.selectedTextSettable = selectedTextSettable
        self.selectedTextSettableErrorCode = selectedTextSettableErrorCode
    }

    public var supportsDirectSelectedTextReplacement: Bool {
        AccessibilityRolePolicy.shouldUseDirectSelectedTextReplacement(self)
    }

    public var logDescription: String {
        "role=\(role ?? "nil") axEditable=\(axEditable.map(String.init) ?? "nil") selectedTextSettable=\(selectedTextSettable) settableError=\(selectedTextSettableErrorCode)"
    }
}

public enum AccessibilityRolePolicy {
    public enum SearchExceptionContext: Equatable {
        case searchbar
        case click
    }

    public static let observedMailApplicationToken = "Mail"
    public static let observedParallelsBundleID = "com.parallels.desktop"
    public static let observedScrollAreaRole = "AXScrollArea"

    public static let observedSearchbarExceptionRoles: [String: [String]] = [
        "*": ["AXTextField", "AXTextArea", "AXComboBox", "AXWindow", "AXUnknown", "AXStaticText", "AXPopUpButton", "AXApplication"],
        "com.adobe.acc.AdobeCreativeCloud": [],
        "com.apple.ActivityMonitor": [],
        "com.apple.Aperture": [],
        "com.apple.DiskImageMounter": [],
        "com.apple.FinalCut": [],
        "com.apple.Notes": [],
        "com.apple.Photos": [],
        "com.apple.Preview": [],
        "com.apple.RemoteDesktop": [],
        "com.apple.ScreenSharing": [],
        "com.apple.SystemProfiler": [],
        "com.apple.dock": [],
        "com.apple.dt.Xcode": ["AXGroup"],
        "com.apple.finder": ["AXList", "AXOutline", "AXGrid", "AXImage"],
        "com.apple.garageband10": [],
        "com.apple.iCal": [],
        "com.apple.iTunes": [],
        "com.apple.iWork.Keynote": [],
        "com.apple.iWork.Numbers": [],
        "com.apple.iWork.Pages": [],
        "com.apple.logic10": [],
        "com.apple.loginwindow": [],
        "com.apple.mail": ["AXWebArea"],
        "com.apple.reminders": [],
        "com.apple.storeuid": [],
        "com.apple.talagent": [],
        "com.aspyr": [],
        "com.bittorrent.uTorrent": [],
        "com.blizzard": [],
        "com.bohemiancoding.sketch3": [],
        "com.google.chrome": ["AXGroup", "AXList"],
        "com.microsoft": [],
        "com.mojang": [],
        observedParallelsBundleID: [],
        "com.teamviewer.TeamViewer": [],
        "com.wunderkinder.wunderlistdesktop": [],
        "it.bloop.airmail": [],
        "it.bloop.airmail2": [],
        "org.chromium.chromium": ["AXGroup", "AXList"],
        "org.mozilla.firefox": ["AXMenuItem"],
        "org.telegram.desktop": [],
        "ru.keepcoder.Telegram": [],
        "ru.yandex.desktop.yandex-browser": ["AXGroup", "AXList"]
    ]

    public static let observedClickExceptionRoles: [String: [String]] = [
        "*": ["AXTextField", "AXTextArea", "AXComboBox", "AXWindow", "AXUnknown", "AXStaticText", "AXPopUpButton"],
        "com.adobe.acc.AdobeCreativeCloud": [],
        "com.apple.ActivityMonitor": [],
        "com.apple.Aperture": [],
        "com.apple.DiskImageMounter": [],
        "com.apple.DiskUtility": [],
        "com.apple.FinalCut": [],
        "com.apple.Notes": [],
        "com.apple.Photos": [],
        "com.apple.Preview": [],
        "com.apple.RemoteDesktop": [],
        "com.apple.ScreenSharing": [],
        "com.apple.SystemProfiler": [],
        "com.apple.dock": [],
        "com.apple.dt.Xcode": ["AXGroup"],
        "com.apple.finder": ["AXList", "AXOutline", "AXGrid", "AXImage", "AXGroup"],
        "com.apple.garageband10": [],
        "com.apple.iCal": [],
        "com.apple.iTunes": [],
        "com.apple.iWork.Keynote": [],
        "com.apple.iWork.Numbers": [],
        "com.apple.iWork.Pages": [],
        "com.apple.logic10": [],
        "com.apple.loginwindow": [],
        "com.apple.mail": ["AXWebArea"],
        "com.apple.reminders": [],
        "com.apple.storeuid": [],
        "com.apple.talagent": [],
        "com.bittorrent.uTorrent": [],
        "com.bohemiancoding.sketch3": [],
        "com.google.chrome": ["AXGroup", "AXList"],
        "com.microsoft": [],
        observedParallelsBundleID: [],
        "com.teamviewer.TeamViewer": [],
        "com.wunderkinder.wunderlistdesktop": [],
        "it.bloop.airmail": [],
        "it.bloop.airmail2": [],
        "org.chromium.chromium": ["AXGroup", "AXList"],
        "org.mozilla.firefox": ["AXMenuItem"],
        "org.telegram.desktop": [],
        "ru.keepcoder.Telegram": [],
        "ru.yandex.desktop.yandex-browser": ["AXGroup", "AXList"]
    ]

    private static let editableTextRoles: Set<String> = [
        "axtextfield",
        "axtextarea",
        "axcombobox",
        "axsearchfield"
    ]

    private static let nonEditableContentRoles: Set<String> = [
        "axstatictext",
        "aximage",
        "axbutton",
        "axlink",
        "axlist",
        "axoutline",
        "axtable",
        "axrow",
        "axcell",
        "axgroup",
        "axwindow",
        normalizedRole(observedScrollAreaRole) ?? "axscrollarea"
    ]

    private static let globalSearchbarExceptionRoles = normalizedGlobalRoles(from: observedSearchbarExceptionRoles)
    private static let globalClickExceptionRoles = normalizedGlobalRoles(from: observedClickExceptionRoles)
    private static let appSpecificSearchbarExceptionRoles = normalizedAppSpecificRoles(from: observedSearchbarExceptionRoles)
    private static let appSpecificClickExceptionRoles = normalizedAppSpecificRoles(from: observedClickExceptionRoles)

    public static func normalizedRole(_ role: String?) -> String? {
        guard let role else {
            return nil
        }

        let normalized = role
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()

        return normalized.isEmpty ? nil : normalized
    }

    private static func normalizedGlobalRoles(from matrix: [String: [String]]) -> Set<String> {
        Set((matrix["*"] ?? []).compactMap(normalizedRole))
    }

    private static func normalizedAppSpecificRoles(from matrix: [String: [String]]) -> [String: Set<String>] {
        var result: [String: Set<String>] = [:]

        for (bundleID, roles) in matrix where bundleID != "*" {
            guard let normalizedBundleID = ApplicationBundleIDPolicy.normalized(bundleID) else {
                continue
            }

            let normalizedRoles = Set(roles.compactMap(normalizedRole))
            if !normalizedRoles.isEmpty {
                result[normalizedBundleID] = normalizedRoles
            }
        }

        return result
    }

    public static func isWebAreaRole(_ role: String?) -> Bool {
        normalizedRole(role) == "axwebarea"
    }

    public static func containsWebAreaRole(_ roles: [String]) -> Bool {
        roles.contains { isWebAreaRole($0) }
    }

    public static func isObservedClipboardReplaceableContentRole(_ role: String?) -> Bool {
        switch normalizedRole(role) {
        case "axwebarea", "axscrollarea":
            return true
        default:
            return false
        }
    }

    public static func containsObservedClipboardReplaceableContentRole(_ roles: [String]) -> Bool {
        roles.contains { isObservedClipboardReplaceableContentRole($0) }
    }

    public static func isEditableTextRole(_ role: String?) -> Bool {
        guard let normalized = normalizedRole(role) else {
            return false
        }

        return editableTextRoles.contains(normalized)
    }

    public static func isNonEditableContentRole(_ role: String?) -> Bool {
        guard let normalized = normalizedRole(role) else {
            return false
        }

        return nonEditableContentRoles.contains(normalized)
    }

    public static func isObservedSearchExceptionRole(
        role: String?,
        bundleID: String?,
        context: SearchExceptionContext
    ) -> Bool {
        guard let role = normalizedRole(role) else {
            return false
        }

        let globalRoles: Set<String>
        let appSpecificRoles: [String: Set<String>]
        switch context {
        case .searchbar:
            globalRoles = globalSearchbarExceptionRoles
            appSpecificRoles = appSpecificSearchbarExceptionRoles
        case .click:
            globalRoles = globalClickExceptionRoles
            appSpecificRoles = appSpecificClickExceptionRoles
        }

        if globalRoles.contains(role) {
            return true
        }

        guard let bundleID = ApplicationBundleIDPolicy.normalized(bundleID) else {
            return false
        }

        return appSpecificRoles[bundleID]?.contains(role) == true
    }

    public static func shouldUseDirectSelectedTextReplacement(
        role: String?,
        axEditable: Bool?,
        selectedTextSettable: Bool
    ) -> Bool {
        if isNonEditableContentRole(role) {
            return false
        }

        if axEditable == true {
            return true
        }

        return selectedTextSettable
    }

    public static func shouldUseDirectSelectedTextReplacement(_ capability: AccessibilityReplacementCapability) -> Bool {
        shouldUseDirectSelectedTextReplacement(
            role: capability.role,
            axEditable: capability.axEditable,
            selectedTextSettable: capability.selectedTextSettable
        )
    }
}
