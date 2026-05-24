import Foundation

public struct SearchbarSettingsSnapshot: Codable, Equatable {
    public let activationShortcut: Hotkey
    public let shouldOfferSearchbarAutoactivation: Bool
    public let autoactivationExceptions: [String]
    public let alertShownIn: Date
    public let shouldSearchByDoubleClick: Bool
    public let sitesearchPromptCounter: Int

    public init(
        activationShortcut: Hotkey = Hotkey.disabled,
        shouldOfferSearchbarAutoactivation: Bool,
        autoactivationExceptions: [String] = [],
        alertShownIn: Date = Date(timeIntervalSince1970: 1_230_757_200),
        shouldSearchByDoubleClick: Bool,
        sitesearchPromptCounter: Int
    ) {
        self.activationShortcut = HotkeyValidationPolicy.normalized(
            activationShortcut,
            fallback: Hotkey.disabled
        )
        self.shouldOfferSearchbarAutoactivation = shouldOfferSearchbarAutoactivation
        self.autoactivationExceptions = Array(
            ApplicationBundleIDPolicy.normalizedSet(Set(autoactivationExceptions))
        ).sorted()
        self.alertShownIn = alertShownIn
        self.shouldSearchByDoubleClick = shouldSearchByDoubleClick
        self.sitesearchPromptCounter = max(0, sitesearchPromptCounter)
    }
}

public enum SearchbarSettingsPolicy {
    public static let settingsKey = "PSSearchbarSettings"
    public static let activationShortcutKey = "ActivationShortcut"
    public static let autoactivationKey = "Autoactivation"
    public static let autoactivationExceptionsKey = "AutoactivationExceptions"
    public static let alertShownInKey = "AlertShownIn"
    public static let shouldSearchByDoubleClickKey = "ShouldSearchByDoubleClick"
    public static let sitesearchPromptCounterKey = "SitesearchPromptCounter"

    public static let defaultActivationShortcut = Hotkey.disabled
    public static let legacyInitialDate = Date(timeIntervalSince1970: 1_230_757_200)

    public static let defaultSnapshot = SearchbarSettingsSnapshot(
        activationShortcut: defaultActivationShortcut,
        shouldOfferSearchbarAutoactivation: true,
        autoactivationExceptions: [],
        alertShownIn: legacyInitialDate,
        shouldSearchByDoubleClick: false,
        sitesearchPromptCounter: 3
    )

    public static func effectiveShouldSearchByDoubleClick(
        hasNativeValue: Bool,
        nativeValue: Bool?,
        legacySnapshot: SearchbarSettingsSnapshot?
    ) -> Bool {
        if hasNativeValue {
            return nativeValue ?? defaultSnapshot.shouldSearchByDoubleClick
        }

        if let legacySnapshot {
            return legacySnapshot.shouldSearchByDoubleClick
        }

        return defaultSnapshot.shouldSearchByDoubleClick
    }

    public static func snapshot(from dictionary: [String: Any]?) -> SearchbarSettingsSnapshot? {
        guard let dictionary else {
            return nil
        }

        return SearchbarSettingsSnapshot(
            activationShortcut: LegacyHotkeyPolicy.normalized(
                dictionary[activationShortcutKey] as? [String: Any],
                fallback: defaultSnapshot.activationShortcut
            ),
            shouldOfferSearchbarAutoactivation: LegacyValuePolicy.bool(
                dictionary[autoactivationKey],
                defaultValue: defaultSnapshot.shouldOfferSearchbarAutoactivation
            ),
            autoactivationExceptions: LegacyValuePolicy.normalizedStringArray(
                dictionary[autoactivationExceptionsKey]
            ),
            alertShownIn: LegacyValuePolicy.date(
                dictionary[alertShownInKey],
                defaultValue: defaultSnapshot.alertShownIn,
                allowNumericString: true
            ),
            shouldSearchByDoubleClick: LegacyValuePolicy.bool(
                dictionary[shouldSearchByDoubleClickKey],
                defaultValue: defaultSnapshot.shouldSearchByDoubleClick
            ),
            sitesearchPromptCounter: LegacyValuePolicy.nonNegativeInt(
                dictionary[sitesearchPromptCounterKey],
                defaultValue: defaultSnapshot.sitesearchPromptCounter
            )
        )
    }
}
