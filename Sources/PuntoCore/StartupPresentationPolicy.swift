public enum StartupPresentationPolicy {
    public static let observedInstallArgument = "--install"
    public static let nativeInstalledTooltipMessage = "Punto installed. Automatic layout switching is ready."
    public static let nativeUpdatedTooltipMessage = "Punto updated. Automatic layout switching is ready."

    public static let observedWelcomeLogMessage = "Displaying welcome screen..."
    public static let observedAccessibilityEnabledLogMessage = "Accessibility API enabled. Initializing services."
    public static let observedAccessibilityDisabledLogMessage = "Accessibility API disabled. Showing accessibility preference window."

    public static func shouldHandleInstallArgument(_ arguments: [String]) -> Bool {
        arguments.contains(observedInstallArgument)
    }

    public static func updateSettingsAfterInstallArgument(_ snapshot: ApplicationUpdateSettingsSnapshot) -> ApplicationUpdateSettingsSnapshot {
        ApplicationUpdateSettingsSnapshot(
            configVersion: snapshot.configVersion,
            isFirstInstallation: snapshot.isFirstInstallation,
            isJustInstalled: true,
            isJustUpdated: snapshot.isJustUpdated,
            isUpdating: false,
            shouldCheckForUpdatesAutomatically: snapshot.shouldCheckForUpdatesAutomatically,
            updateRequestRateInDays: snapshot.updateRequestRateInDays,
            lastStatisticsRequestDate: snapshot.lastStatisticsRequestDate,
            lastUpdateRequestDate: snapshot.lastUpdateRequestDate,
            lastUpdateShownDate: snapshot.lastUpdateShownDate
        )
    }

    public static func shouldDisplayWelcome(
        isFirstLaunch: Bool,
        updateSettings: ApplicationUpdateSettingsSnapshot
    ) -> Bool {
        isFirstLaunch || updateSettings.isFirstInstallation || updateSettings.isJustInstalled
    }

    public static func updateSettingsAfterWelcome(_ snapshot: ApplicationUpdateSettingsSnapshot) -> ApplicationUpdateSettingsSnapshot {
        ApplicationUpdateSettingsSnapshot(
            configVersion: snapshot.configVersion,
            isFirstInstallation: false,
            isJustInstalled: false,
            isJustUpdated: snapshot.isJustUpdated,
            isUpdating: snapshot.isUpdating,
            shouldCheckForUpdatesAutomatically: snapshot.shouldCheckForUpdatesAutomatically,
            updateRequestRateInDays: snapshot.updateRequestRateInDays,
            lastStatisticsRequestDate: snapshot.lastStatisticsRequestDate,
            lastUpdateRequestDate: snapshot.lastUpdateRequestDate,
            lastUpdateShownDate: snapshot.lastUpdateShownDate
        )
    }

    public static func shouldDisplayUpdateFinishedTooltip(
        updateSettings: ApplicationUpdateSettingsSnapshot
    ) -> Bool {
        updateSettings.isJustUpdated
    }

    public static func updateSettingsAfterUpdateFinishedTooltip(
        _ snapshot: ApplicationUpdateSettingsSnapshot
    ) -> ApplicationUpdateSettingsSnapshot {
        ApplicationUpdateSettingsSnapshot(
            configVersion: snapshot.configVersion,
            isFirstInstallation: snapshot.isFirstInstallation,
            isJustInstalled: snapshot.isJustInstalled,
            isJustUpdated: false,
            isUpdating: false,
            shouldCheckForUpdatesAutomatically: snapshot.shouldCheckForUpdatesAutomatically,
            updateRequestRateInDays: snapshot.updateRequestRateInDays,
            lastStatisticsRequestDate: snapshot.lastStatisticsRequestDate,
            lastUpdateRequestDate: snapshot.lastUpdateRequestDate,
            lastUpdateShownDate: snapshot.lastUpdateShownDate
        )
    }
}
