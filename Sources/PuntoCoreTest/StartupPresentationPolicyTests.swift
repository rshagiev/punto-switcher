import Foundation
import PuntoCore

func runStartupPresentationPolicyTests() throws {
    try expect(
        StartupPresentationPolicy.installArgument,
        PuntoSwitcherObservedSurface.StartupPresentation.installArgument,
        "startup presentation policy keeps installer argument aligned with reverse-audit anchor"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.handleInstallArgumentSelector,
        "handleInstallArgument",
        "startup presentation policy preserves observed install handler selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.installedTooltipKey,
        "tooltip-app-installed",
        "startup presentation policy preserves observed installed tooltip key"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.showUpdateFinishedTooltipSelector,
        "showUpdateFinishedTooltip",
        "startup presentation policy preserves observed update-finished tooltip selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.StartupPresentation.shouldDisplayWelcomeSelector,
        "shouldDisplayWelcome",
        "startup presentation policy preserves observed welcome selector"
    )
    try expect(
        StartupPresentationPolicy.installArgumentHandlerLogName,
        PuntoSwitcherObservedSurface.StartupPresentation.handleInstallArgumentSelector,
        "startup presentation policy keeps install handler log aligned with reverse-audit anchor"
    )
    try expect(
        StartupPresentationPolicy.updateFinishedTooltipLogName,
        PuntoSwitcherObservedSurface.StartupPresentation.showUpdateFinishedTooltipSelector,
        "startup presentation policy keeps update-finished log aligned with reverse-audit anchor"
    )
    try expect(
        StartupPresentationPolicy.welcomeLogMessage,
        PuntoSwitcherObservedSurface.StartupPresentation.welcomeLogMessage,
        "startup presentation policy keeps welcome log aligned with reverse-audit anchor"
    )
    try expect(
        StartupPresentationPolicy.accessibilityEnabledLogMessage,
        PuntoSwitcherObservedSurface.StartupPresentation.accessibilityEnabledLogMessage,
        "startup presentation policy keeps accessibility-enabled log aligned with reverse-audit anchor"
    )
    try expect(
        StartupPresentationPolicy.accessibilityDisabledLogMessage,
        PuntoSwitcherObservedSurface.StartupPresentation.accessibilityDisabledLogMessage,
        "startup presentation policy keeps accessibility-disabled log aligned with reverse-audit anchor"
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: true,
            updateSettings: ApplicationUpdateSettingsPolicy.defaultSnapshot
        ),
        true,
        "startup presentation policy shows welcome on native first launch"
    )
    let alreadyInstalled = ApplicationUpdateSettingsSnapshot(
        configVersion: 8,
        isFirstInstallation: false,
        isJustInstalled: false,
        isJustUpdated: false,
        isUpdating: false,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: false,
            updateSettings: alreadyInstalled
        ),
        false,
        "startup presentation policy skips welcome after first-install flags are consumed"
    )
    let justInstalled = ApplicationUpdateSettingsSnapshot(
        configVersion: 8,
        isFirstInstallation: false,
        isJustInstalled: true,
        isJustUpdated: false,
        isUpdating: false,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(
            isFirstLaunch: false,
            updateSettings: justInstalled
        ),
        true,
        "startup presentation policy shows welcome for observed just-installed flag"
    )
    let consumed = StartupPresentationPolicy.updateSettingsAfterWelcome(justInstalled)
    try expect(consumed.isFirstInstallation, false, "startup presentation policy consumes first-install flag")
    try expect(consumed.isJustInstalled, false, "startup presentation policy consumes just-installed flag")
    try expect(consumed.configVersion, justInstalled.configVersion, "startup presentation policy preserves config version")

    try expect(
        StartupPresentationPolicy.shouldHandleInstallArgument(["/Applications/Punto.app/Contents/MacOS/Punto", "--install"]),
        true,
        "startup presentation policy detects observed installer launch argument"
    )
    try expect(
        StartupPresentationPolicy.shouldHandleInstallArgument(["/Applications/Punto.app/Contents/MacOS/Punto", "--not-install"]),
        false,
        "startup presentation policy rejects non-matching installer argument"
    )

    let afterInstallArgument = StartupPresentationPolicy.updateSettingsAfterInstallArgument(alreadyInstalled)
    try expect(afterInstallArgument.isJustInstalled, true, "startup presentation policy marks just-installed after installer argument")
    try expect(afterInstallArgument.isUpdating, false, "startup presentation policy clears updating after installer argument")
    try expect(afterInstallArgument.configVersion, alreadyInstalled.configVersion, "startup presentation policy preserves config version after installer argument")
    try expect(
        StartupPresentationPolicy.shouldDisplayWelcome(isFirstLaunch: false, updateSettings: afterInstallArgument),
        true,
        "startup presentation policy shows welcome after installer argument"
    )

    let justUpdated = ApplicationUpdateSettingsSnapshot(
        configVersion: 9,
        isFirstInstallation: false,
        isJustInstalled: false,
        isJustUpdated: true,
        isUpdating: true,
        shouldCheckForUpdatesAutomatically: true,
        updateRequestRateInDays: 0,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    try expect(
        StartupPresentationPolicy.shouldDisplayUpdateFinishedTooltip(updateSettings: justUpdated),
        true,
        "startup presentation policy shows update-finished tooltip for observed just-updated flag"
    )
    let afterUpdateTooltip = StartupPresentationPolicy.updateSettingsAfterUpdateFinishedTooltip(justUpdated)
    try expect(afterUpdateTooltip.isJustUpdated, false, "startup presentation policy consumes just-updated flag")
    try expect(afterUpdateTooltip.isUpdating, false, "startup presentation policy clears updating after update-finished tooltip")
    try expect(afterUpdateTooltip.configVersion, justUpdated.configVersion, "startup presentation policy preserves config version after update-finished tooltip")
}
