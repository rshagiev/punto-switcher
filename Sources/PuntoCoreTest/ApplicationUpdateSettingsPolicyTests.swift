import Foundation
import PuntoCore

func runApplicationUpdateSettingsPolicyTests() throws {
    try expect(
        ApplicationUpdateSettingsPolicy.legacyConfigVersionKey,
        "configVersion",
        "update settings policy preserves observed config-version key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyIsFirstInstallationKey,
        "isFirstInstallation",
        "update settings policy preserves observed first-install key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyIsJustInstalledKey,
        "isJustInstalled",
        "update settings policy preserves observed just-installed key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyIsJustUpdatedKey,
        "isJustUpdated",
        "update settings policy preserves observed just-updated key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyIsUpdatingKey,
        "isUpdating",
        "update settings policy preserves observed updating key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyShouldCheckForUpdatesAutomaticallyKey,
        "shouldCheckForUpdatesAutomatically",
        "update settings policy preserves observed automatic-update-check key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyUpdateRequestRateInDaysKey,
        "updateRequestRateInDays",
        "update settings policy preserves observed update-request-rate key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyLastStatisticsRequestDateKey,
        "lastStatisticsRequestDate",
        "update settings policy preserves observed statistics-request date key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyLastUpdateRequestDateKey,
        "lastUpdateRequestDate",
        "update settings policy preserves observed update-request date key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyLastUpdateShownDateKey,
        "lastUpdateShownDate",
        "update settings policy preserves observed update-shown date key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.configVersion,
        8,
        "update settings policy defaults to observed Punto Switcher config version"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.isUpdating,
        false,
        "update settings policy defaults to non-updating state"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.shouldCheckForUpdatesAutomatically,
        true,
        "update settings policy mirrors observed automatic update check preference"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.updateRequestRateInDays,
        0,
        "update settings policy mirrors observed update request rate"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.lastStatisticsRequestDate,
        ApplicationUpdateSettingsPolicy.legacyInitialDate,
        "update settings policy mirrors observed initial statistics date"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.snapshot(from: [
            ApplicationUpdateSettingsPolicy.legacyConfigVersionKey: NSNumber(value: 8),
            ApplicationUpdateSettingsPolicy.legacyIsFirstInstallationKey: NSNumber(value: true),
            ApplicationUpdateSettingsPolicy.legacyIsJustInstalledKey: NSNumber(value: false),
            ApplicationUpdateSettingsPolicy.legacyIsJustUpdatedKey: NSNumber(value: false),
            ApplicationUpdateSettingsPolicy.legacyIsUpdatingKey: NSNumber(value: false),
            ApplicationUpdateSettingsPolicy.legacyShouldCheckForUpdatesAutomaticallyKey: NSNumber(value: true),
            ApplicationUpdateSettingsPolicy.legacyUpdateRequestRateInDaysKey: NSNumber(value: 0),
            ApplicationUpdateSettingsPolicy.legacyLastStatisticsRequestDateKey: "2008-12-31 21:00:00 +0000",
            ApplicationUpdateSettingsPolicy.legacyLastUpdateShownDateKey: "2008-12-31 21:00:00 +0000"
        ]),
        ApplicationUpdateSettingsPolicy.defaultSnapshot,
        "update settings policy reads observed Punto Switcher updater/install state"
    )

    let updateRequestDate = Date(timeIntervalSince1970: 1_768_132_509)
    let snapshot = ApplicationUpdateSettingsPolicy.snapshot(from: [
        ApplicationUpdateSettingsPolicy.legacyConfigVersionKey: "9",
        ApplicationUpdateSettingsPolicy.legacyIsFirstInstallationKey: "0",
        ApplicationUpdateSettingsPolicy.legacyIsJustInstalledKey: "yes",
        ApplicationUpdateSettingsPolicy.legacyIsJustUpdatedKey: NSNumber(value: true),
        ApplicationUpdateSettingsPolicy.legacyIsUpdatingKey: "false",
        ApplicationUpdateSettingsPolicy.legacyShouldCheckForUpdatesAutomaticallyKey: "no",
        ApplicationUpdateSettingsPolicy.legacyUpdateRequestRateInDaysKey: " 14 ",
        ApplicationUpdateSettingsPolicy.legacyLastStatisticsRequestDateKey: ApplicationUpdateSettingsPolicy.legacyInitialDate,
        ApplicationUpdateSettingsPolicy.legacyLastUpdateRequestDateKey: updateRequestDate.timeIntervalSince1970,
        ApplicationUpdateSettingsPolicy.legacyLastUpdateShownDateKey: "2008-12-31 21:00:00 +0000"
    ])
    try expect(snapshot.configVersion, 9, "update settings policy parses string config version")
    try expect(snapshot.isFirstInstallation, false, "update settings policy parses string first-install flag")
    try expect(snapshot.isJustInstalled, true, "update settings policy parses yes boolean")
    try expect(snapshot.isJustUpdated, true, "update settings policy parses NSNumber boolean")
    try expect(snapshot.isUpdating, false, "update settings policy parses false boolean")
    try expect(snapshot.shouldCheckForUpdatesAutomatically, false, "update settings policy parses no boolean")
    try expect(snapshot.updateRequestRateInDays, 14, "update settings policy parses string update request rate")
    try expect(snapshot.lastUpdateRequestDate, updateRequestDate, "update settings policy parses numeric date")

    let clamped = ApplicationUpdateSettingsPolicy.snapshot(from: [
        ApplicationUpdateSettingsPolicy.legacyConfigVersionKey: -1,
        ApplicationUpdateSettingsPolicy.legacyUpdateRequestRateInDaysKey: -7
    ])
    try expect(clamped.configVersion, 0, "update settings policy clamps negative config version")
    try expect(clamped.updateRequestRateInDays, 0, "update settings policy clamps negative update request rate")

    let encoded = try JSONEncoder().encode(snapshot)
    let decoded = try JSONDecoder().decode(ApplicationUpdateSettingsSnapshot.self, from: encoded)
    try expect(decoded, snapshot, "update settings snapshot supports native Codable persistence")

    let normalized = ApplicationUpdateSettingsPolicy.normalized(
        ApplicationUpdateSettingsSnapshot(
            configVersion: -2,
            isFirstInstallation: false,
            isJustInstalled: true,
            isJustUpdated: true,
            isUpdating: false,
            shouldCheckForUpdatesAutomatically: false,
            updateRequestRateInDays: -5,
            lastStatisticsRequestDate: nil,
            lastUpdateRequestDate: updateRequestDate,
            lastUpdateShownDate: nil
        )
    )
    try expect(normalized.configVersion, 0, "update settings native snapshot clamps config version")
    try expect(normalized.updateRequestRateInDays, 0, "update settings native snapshot clamps update rate")
    try expect(normalized.isJustInstalled, true, "update settings native snapshot preserves install flag")
    try expect(normalized.lastUpdateRequestDate, updateRequestDate, "update settings native snapshot preserves update date")
}
