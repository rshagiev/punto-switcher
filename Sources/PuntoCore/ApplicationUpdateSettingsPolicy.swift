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
    public static let legacyConfigVersionKey = "configVersion"
    public static let legacyIsFirstInstallationKey = "isFirstInstallation"
    public static let legacyIsJustInstalledKey = "isJustInstalled"
    public static let legacyIsJustUpdatedKey = "isJustUpdated"
    public static let legacyIsUpdatingKey = "isUpdating"
    public static let legacyShouldCheckForUpdatesAutomaticallyKey = "shouldCheckForUpdatesAutomatically"
    public static let legacyUpdateRequestRateInDaysKey = "updateRequestRateInDays"
    public static let legacyLastStatisticsRequestDateKey = "lastStatisticsRequestDate"
    public static let legacyLastUpdateRequestDateKey = "lastUpdateRequestDate"
    public static let legacyLastUpdateShownDateKey = "lastUpdateShownDate"

    public static let legacyDefaultConfigVersion = 8
    public static let legacyInitialDate = Date(timeIntervalSince1970: 1_230_757_200)

    public static let defaultSnapshot = ApplicationUpdateSettingsSnapshot(
        configVersion: legacyDefaultConfigVersion,
        isFirstInstallation: true,
        isJustInstalled: false,
        isJustUpdated: false,
        isUpdating: false,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: legacyInitialDate,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: legacyInitialDate
    )

    public static func snapshot(from dictionary: [String: Any]) -> ApplicationUpdateSettingsSnapshot {
        ApplicationUpdateSettingsSnapshot(
            configVersion: LegacyValuePolicy.nonNegativeInt(
                dictionary[legacyConfigVersionKey],
                defaultValue: defaultSnapshot.configVersion
            ),
            isFirstInstallation: LegacyValuePolicy.bool(
                dictionary[legacyIsFirstInstallationKey],
                defaultValue: defaultSnapshot.isFirstInstallation
            ),
            isJustInstalled: LegacyValuePolicy.bool(
                dictionary[legacyIsJustInstalledKey],
                defaultValue: defaultSnapshot.isJustInstalled
            ),
            isJustUpdated: LegacyValuePolicy.bool(
                dictionary[legacyIsJustUpdatedKey],
                defaultValue: defaultSnapshot.isJustUpdated
            ),
            isUpdating: LegacyValuePolicy.bool(
                dictionary[legacyIsUpdatingKey],
                defaultValue: defaultSnapshot.isUpdating
            ),
            shouldCheckForUpdatesAutomatically: LegacyValuePolicy.bool(
                dictionary[legacyShouldCheckForUpdatesAutomaticallyKey],
                defaultValue: defaultSnapshot.shouldCheckForUpdatesAutomatically
            ),
            updateRequestRateInDays: LegacyValuePolicy.nonNegativeInt(
                dictionary[legacyUpdateRequestRateInDaysKey],
                defaultValue: defaultSnapshot.updateRequestRateInDays
            ),
            lastStatisticsRequestDate: LegacyValuePolicy.date(dictionary[legacyLastStatisticsRequestDateKey])
                ?? defaultSnapshot.lastStatisticsRequestDate,
            lastUpdateRequestDate: LegacyValuePolicy.date(dictionary[legacyLastUpdateRequestDateKey])
                ?? defaultSnapshot.lastUpdateRequestDate,
            lastUpdateShownDate: LegacyValuePolicy.date(dictionary[legacyLastUpdateShownDateKey])
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
