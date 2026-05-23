import Foundation

public struct ApplicationUpdateSettingsSnapshot: Equatable {
    public let configVersion: Int
    public let isFirstInstallation: Bool
    public let isJustInstalled: Bool
    public let isJustUpdated: Bool
    public let isUpdating: Bool
    public let shouldCheckForUpdatesAutomatically: Bool
    public let updateRequestRateInDays: Int
    public let lastStatisticsRequestDate: Date?
    public let lastUpdateRequestDate: Date?
    public let lastUpdateShownDate: Date?

    public init(
        configVersion: Int,
        isFirstInstallation: Bool,
        isJustInstalled: Bool,
        isJustUpdated: Bool,
        isUpdating: Bool,
        shouldCheckForUpdatesAutomatically: Bool,
        updateRequestRateInDays: Int,
        lastStatisticsRequestDate: Date?,
        lastUpdateRequestDate: Date?,
        lastUpdateShownDate: Date?
    ) {
        self.configVersion = configVersion
        self.isFirstInstallation = isFirstInstallation
        self.isJustInstalled = isJustInstalled
        self.isJustUpdated = isJustUpdated
        self.isUpdating = isUpdating
        self.shouldCheckForUpdatesAutomatically = shouldCheckForUpdatesAutomatically
        self.updateRequestRateInDays = updateRequestRateInDays
        self.lastStatisticsRequestDate = lastStatisticsRequestDate
        self.lastUpdateRequestDate = lastUpdateRequestDate
        self.lastUpdateShownDate = lastUpdateShownDate
    }
}

public enum ApplicationUpdateSettingsPolicy {
    public static let configVersionKey = "configVersion"
    public static let isFirstInstallationKey = "isFirstInstallation"
    public static let isJustInstalledKey = "isJustInstalled"
    public static let isJustUpdatedKey = "isJustUpdated"
    public static let isUpdatingKey = "isUpdating"
    public static let shouldCheckForUpdatesAutomaticallyKey = "shouldCheckForUpdatesAutomatically"
    public static let updateRequestRateInDaysKey = "updateRequestRateInDays"
    public static let lastStatisticsRequestDateKey = "lastStatisticsRequestDate"
    public static let lastUpdateRequestDateKey = "lastUpdateRequestDate"
    public static let lastUpdateShownDateKey = "lastUpdateShownDate"

    public static let observedLegacyConfigVersion = 8
    public static let observedLegacyInitialDate = Date(timeIntervalSince1970: 1_230_757_200)

    public static let defaultSnapshot = ApplicationUpdateSettingsSnapshot(
        configVersion: observedLegacyConfigVersion,
        isFirstInstallation: true,
        isJustInstalled: false,
        isJustUpdated: false,
        isUpdating: false,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: observedLegacyInitialDate,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: observedLegacyInitialDate
    )

    public static func snapshot(from dictionary: [String: Any]) -> ApplicationUpdateSettingsSnapshot {
        ApplicationUpdateSettingsSnapshot(
            configVersion: max(0, intValue(dictionary[configVersionKey]) ?? defaultSnapshot.configVersion),
            isFirstInstallation: boolValue(dictionary[isFirstInstallationKey]) ?? defaultSnapshot.isFirstInstallation,
            isJustInstalled: boolValue(dictionary[isJustInstalledKey]) ?? defaultSnapshot.isJustInstalled,
            isJustUpdated: boolValue(dictionary[isJustUpdatedKey]) ?? defaultSnapshot.isJustUpdated,
            isUpdating: boolValue(dictionary[isUpdatingKey]) ?? defaultSnapshot.isUpdating,
            shouldCheckForUpdatesAutomatically: boolValue(dictionary[shouldCheckForUpdatesAutomaticallyKey]) ?? defaultSnapshot.shouldCheckForUpdatesAutomatically,
            updateRequestRateInDays: max(0, intValue(dictionary[updateRequestRateInDaysKey]) ?? defaultSnapshot.updateRequestRateInDays),
            lastStatisticsRequestDate: dateValue(dictionary[lastStatisticsRequestDateKey]) ?? defaultSnapshot.lastStatisticsRequestDate,
            lastUpdateRequestDate: dateValue(dictionary[lastUpdateRequestDateKey]) ?? defaultSnapshot.lastUpdateRequestDate,
            lastUpdateShownDate: dateValue(dictionary[lastUpdateShownDateKey]) ?? defaultSnapshot.lastUpdateShownDate
        )
    }

    public static func dictionary(from snapshot: ApplicationUpdateSettingsSnapshot) -> [String: Any] {
        var dictionary: [String: Any] = [
            configVersionKey: max(0, snapshot.configVersion),
            isFirstInstallationKey: snapshot.isFirstInstallation,
            isJustInstalledKey: snapshot.isJustInstalled,
            isJustUpdatedKey: snapshot.isJustUpdated,
            isUpdatingKey: snapshot.isUpdating,
            shouldCheckForUpdatesAutomaticallyKey: snapshot.shouldCheckForUpdatesAutomatically,
            updateRequestRateInDaysKey: max(0, snapshot.updateRequestRateInDays)
        ]
        dictionary[lastStatisticsRequestDateKey] = snapshot.lastStatisticsRequestDate
        dictionary[lastUpdateRequestDateKey] = snapshot.lastUpdateRequestDate
        dictionary[lastUpdateShownDateKey] = snapshot.lastUpdateShownDate
        return dictionary
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        switch value {
        case let value as Bool:
            return value
        case let value as NSNumber:
            return value.boolValue
        case let value as String:
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "1", "true", "yes":
                return true
            case "0", "false", "no":
                return false
            default:
                return nil
            }
        default:
            return nil
        }
    }

    private static func intValue(_ value: Any?) -> Int? {
        switch value {
        case let value as Int:
            return value
        case let value as NSNumber:
            return value.intValue
        case let value as String:
            return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
        default:
            return nil
        }
    }

    private static func dateValue(_ value: Any?) -> Date? {
        switch value {
        case let value as Date:
            return value
        case let value as NSNumber:
            return Date(timeIntervalSince1970: value.doubleValue)
        case let value as String:
            return legacyDateFormatter.date(from: value.trimmingCharacters(in: .whitespacesAndNewlines))
        default:
            return nil
        }
    }

    private static let legacyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter
    }()
}
