import Foundation

public struct ApplicationUpdateSettingsSnapshot: Codable, Equatable {
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
            configVersion: LegacyValuePolicy.nonNegativeInt(
                dictionary[configVersionKey],
                defaultValue: defaultSnapshot.configVersion
            ),
            isFirstInstallation: LegacyValuePolicy.bool(
                dictionary[isFirstInstallationKey],
                defaultValue: defaultSnapshot.isFirstInstallation
            ),
            isJustInstalled: LegacyValuePolicy.bool(
                dictionary[isJustInstalledKey],
                defaultValue: defaultSnapshot.isJustInstalled
            ),
            isJustUpdated: LegacyValuePolicy.bool(
                dictionary[isJustUpdatedKey],
                defaultValue: defaultSnapshot.isJustUpdated
            ),
            isUpdating: LegacyValuePolicy.bool(
                dictionary[isUpdatingKey],
                defaultValue: defaultSnapshot.isUpdating
            ),
            shouldCheckForUpdatesAutomatically: LegacyValuePolicy.bool(
                dictionary[shouldCheckForUpdatesAutomaticallyKey],
                defaultValue: defaultSnapshot.shouldCheckForUpdatesAutomatically
            ),
            updateRequestRateInDays: LegacyValuePolicy.nonNegativeInt(
                dictionary[updateRequestRateInDaysKey],
                defaultValue: defaultSnapshot.updateRequestRateInDays
            ),
            lastStatisticsRequestDate: LegacyValuePolicy.date(dictionary[lastStatisticsRequestDateKey])
                ?? defaultSnapshot.lastStatisticsRequestDate,
            lastUpdateRequestDate: LegacyValuePolicy.date(dictionary[lastUpdateRequestDateKey])
                ?? defaultSnapshot.lastUpdateRequestDate,
            lastUpdateShownDate: LegacyValuePolicy.date(dictionary[lastUpdateShownDateKey])
                ?? defaultSnapshot.lastUpdateShownDate
        )
    }

    public static func normalized(_ snapshot: ApplicationUpdateSettingsSnapshot) -> ApplicationUpdateSettingsSnapshot {
        ApplicationUpdateSettingsSnapshot(
            configVersion: max(0, snapshot.configVersion),
            isFirstInstallation: snapshot.isFirstInstallation,
            isJustInstalled: snapshot.isJustInstalled,
            isJustUpdated: snapshot.isJustUpdated,
            isUpdating: snapshot.isUpdating,
            shouldCheckForUpdatesAutomatically: snapshot.shouldCheckForUpdatesAutomatically,
            updateRequestRateInDays: max(0, snapshot.updateRequestRateInDays),
            lastStatisticsRequestDate: snapshot.lastStatisticsRequestDate,
            lastUpdateRequestDate: snapshot.lastUpdateRequestDate,
            lastUpdateShownDate: snapshot.lastUpdateShownDate
        )
    }

}
