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
    public static let observedLegacyInitialDate = Date(timeIntervalSince1970: 1_230_757_200)

    public static let defaultSnapshot = SearchbarSettingsSnapshot(
        activationShortcut: defaultActivationShortcut,
        shouldOfferSearchbarAutoactivation: true,
        autoactivationExceptions: [],
        alertShownIn: observedLegacyInitialDate,
        shouldSearchByDoubleClick: false,
        sitesearchPromptCounter: 3
    )

    public static func snapshot(from dictionary: [String: Any]?) -> SearchbarSettingsSnapshot? {
        guard let dictionary else {
            return nil
        }

        return SearchbarSettingsSnapshot(
            activationShortcut: LegacyHotkeyPolicy.normalized(
                dictionary[activationShortcutKey] as? [String: Any],
                fallback: defaultSnapshot.activationShortcut
            ),
            shouldOfferSearchbarAutoactivation: boolValue(
                dictionary[autoactivationKey],
                defaultValue: defaultSnapshot.shouldOfferSearchbarAutoactivation
            ),
            autoactivationExceptions: stringArrayValue(
                dictionary[autoactivationExceptionsKey]
            ),
            alertShownIn: dateValue(
                dictionary[alertShownInKey],
                defaultValue: defaultSnapshot.alertShownIn
            ),
            shouldSearchByDoubleClick: boolValue(
                dictionary[shouldSearchByDoubleClickKey],
                defaultValue: defaultSnapshot.shouldSearchByDoubleClick
            ),
            sitesearchPromptCounter: intValue(
                dictionary[sitesearchPromptCounterKey],
                defaultValue: defaultSnapshot.sitesearchPromptCounter
            )
        )
    }

    public static func dictionary(from snapshot: SearchbarSettingsSnapshot) -> [String: Any] {
        [
            activationShortcutKey: LegacyHotkeyPolicy.dictionary(from: snapshot.activationShortcut),
            autoactivationKey: snapshot.shouldOfferSearchbarAutoactivation,
            autoactivationExceptionsKey: snapshot.autoactivationExceptions,
            alertShownInKey: snapshot.alertShownIn,
            shouldSearchByDoubleClickKey: snapshot.shouldSearchByDoubleClick,
            sitesearchPromptCounterKey: max(0, snapshot.sitesearchPromptCounter)
        ]
    }

    public static func snapshot(
        _ snapshot: SearchbarSettingsSnapshot,
        settingDoubleClickSearch enabled: Bool
    ) -> SearchbarSettingsSnapshot {
        SearchbarSettingsSnapshot(
            activationShortcut: snapshot.activationShortcut,
            shouldOfferSearchbarAutoactivation: snapshot.shouldOfferSearchbarAutoactivation,
            autoactivationExceptions: snapshot.autoactivationExceptions,
            alertShownIn: snapshot.alertShownIn,
            shouldSearchByDoubleClick: enabled,
            sitesearchPromptCounter: snapshot.sitesearchPromptCounter
        )
    }

    private static func boolValue(_ rawValue: Any?, defaultValue: Bool) -> Bool {
        if let value = rawValue as? Bool {
            return value
        }

        if let value = rawValue as? NSNumber {
            return value.boolValue
        }

        if let value = rawValue as? String {
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "yes", "1":
                return true
            case "false", "no", "0":
                return false
            default:
                return defaultValue
            }
        }

        return defaultValue
    }

    private static func intValue(_ rawValue: Any?, defaultValue: Int) -> Int {
        if let value = rawValue as? Int {
            return max(0, value)
        }

        if let value = rawValue as? NSNumber {
            return max(0, value.intValue)
        }

        if let value = rawValue as? String,
           let parsed = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return max(0, parsed)
        }

        return max(0, defaultValue)
    }

    private static func stringArrayValue(_ rawValue: Any?) -> [String] {
        guard let values = rawValue as? [String] else {
            return []
        }

        return Array(ApplicationBundleIDPolicy.normalizedSet(Set(values))).sorted()
    }

    private static func dateValue(_ rawValue: Any?, defaultValue: Date) -> Date {
        if let value = rawValue as? Date {
            return value
        }

        if let value = rawValue as? NSNumber {
            return Date(timeIntervalSince1970: value.doubleValue)
        }

        if let value = rawValue as? String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if let seconds = TimeInterval(trimmed) {
                return Date(timeIntervalSince1970: seconds)
            }

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let parsed = formatter.date(from: trimmed) {
                return parsed
            }
        }

        return defaultValue
    }
}
