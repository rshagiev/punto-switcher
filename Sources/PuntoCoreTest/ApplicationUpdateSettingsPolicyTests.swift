import Foundation
import PuntoCore

func runApplicationUpdateSettingsPolicyTests() throws {
    try expect(
        ApplicationUpdateSettingsPolicy.legacyConfigVersionKey,
        PuntoSwitcherObservedSurface.ApplicationUpdateSettings.configVersionKey,
        "update settings policy keeps config-version import key aligned with reverse-audit anchor"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyIsFirstInstallationKey,
        PuntoSwitcherObservedSurface.ApplicationUpdateSettings.isFirstInstallationKey,
        "update settings policy keeps first-install import key aligned with reverse-audit anchor"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyIsJustInstalledKey,
        PuntoSwitcherObservedSurface.ApplicationUpdateSettings.isJustInstalledKey,
        "update settings policy keeps just-installed import key aligned with reverse-audit anchor"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyIsJustUpdatedKey,
        PuntoSwitcherObservedSurface.ApplicationUpdateSettings.isJustUpdatedKey,
        "update settings policy keeps just-updated import key aligned with reverse-audit anchor"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyIsUpdatingKey,
        PuntoSwitcherObservedSurface.ApplicationUpdateSettings.isUpdatingKey,
        "update settings policy keeps updating import key aligned with reverse-audit anchor"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyShouldCheckForUpdatesAutomaticallyKey,
        PuntoSwitcherObservedSurface.ApplicationUpdateSettings.shouldCheckForUpdatesAutomaticallyKey,
        "update settings policy keeps automatic-update-check import key aligned with reverse-audit anchor"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyUpdateRequestRateInDaysKey,
        PuntoSwitcherObservedSurface.ApplicationUpdateSettings.updateRequestRateInDaysKey,
        "update settings policy keeps update-request-rate import key aligned with reverse-audit anchor"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyLastStatisticsRequestDateKey,
        PuntoSwitcherObservedSurface.ApplicationUpdateSettings.lastStatisticsRequestDateKey,
        "update settings policy keeps statistics-request import key aligned with reverse-audit anchor"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyLastUpdateRequestDateKey,
        PuntoSwitcherObservedSurface.ApplicationUpdateSettings.lastUpdateRequestDateKey,
        "update settings policy keeps update-request import key aligned with reverse-audit anchor"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyLastUpdateShownDateKey,
        PuntoSwitcherObservedSurface.ApplicationUpdateSettings.lastUpdateShownDateKey,
        "update settings policy keeps update-shown import key aligned with reverse-audit anchor"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyDefaultConfigVersion,
        PuntoSwitcherObservedSurface.ApplicationUpdateSettings.defaultConfigVersion,
        "update settings policy keeps default config version aligned with reverse-audit anchor"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.legacyInitialDate,
        Date(timeIntervalSince1970: PuntoSwitcherObservedSurface.ApplicationUpdateSettings.initialDateUnixTimestamp),
        "update settings policy keeps initial date marker aligned with reverse-audit anchor"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.configVersion,
        PuntoSwitcherObservedSurface.ApplicationUpdateSettings.defaultConfigVersion,
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
