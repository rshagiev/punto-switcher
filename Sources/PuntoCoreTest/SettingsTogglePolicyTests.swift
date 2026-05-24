import Foundation
import PuntoCore

func runSettingsTogglePolicyTests() throws {
    try expect(
        SettingsTogglePolicy.basicDisplayOrder.map(\.slot),
        [
            .launchAtLogin,
            .showInMenuBar,
            .switchLayoutAfterConversion,
            .autoCorrectionEnabled,
            .soundEffectsEnabled,
            .showAdvancedSettings
        ],
        "settings toggle policy keeps basic display order"
    )
    try expect(
        SettingsTogglePolicy.advancedDisplayOrder.map(\.slot),
        [
            .switchLayoutAfterSelectedTextConversion,
            .searchSelectedTextByDoubleClick,
            .manualConversionDisabled,
            .rememberInputSourceForEachApp,
            .autoCorrectOnEnterAndTab,
            .autoCorrectionUndoLearningEnabled,
            .suppressAutoCorrectionAfterManualConversion,
            .completelyDisableInExceptionApplications
        ],
        "settings toggle policy keeps advanced display order"
    )
    try expect(
        SettingsTogglePolicy.displayOrder.map(\.slot),
        SettingsToggleSlot.allCases,
        "settings toggle policy covers every toggle slot exactly once"
    )
    try expect(
        Set(SettingsTogglePolicy.displayOrder.map(\.slot)).count,
        SettingsToggleSlot.allCases.count,
        "settings toggle policy has no duplicate toggle slots"
    )
    try expect(
        SettingsTogglePolicy.changeAction(
            slot: .launchAtLogin,
            wasEnabled: false,
            isEnabled: true
        ),
        SettingsToggleChangeAction(
            slot: .launchAtLogin,
            wasEnabled: false,
            isEnabled: true,
            effects: [.setLoginItemEnabled(true)]
        ),
        "settings toggle policy applies login-item effect"
    )
    try expect(
        SettingsTogglePolicy.changeAction(
            slot: .showAdvancedSettings,
            wasEnabled: true,
            isEnabled: false
        ),
        SettingsToggleChangeAction(
            slot: .showAdvancedSettings,
            wasEnabled: true,
            isEnabled: false,
            effects: [.updateAdvancedSettingsVisibility(false)]
        ),
        "settings toggle policy applies advanced-settings visibility effect"
    )
    try expect(
        SettingsTogglePolicy.changeAction(
            slot: .showInMenuBar,
            wasEnabled: false,
            isEnabled: true
        )?.effects,
        [.updateStatusBarVisibility],
        "settings toggle policy applies status visibility effect"
    )
    try expect(
        SettingsTogglePolicy.changeAction(
            slot: .autoCorrectionEnabled,
            wasEnabled: false,
            isEnabled: true
        )?.effects,
        [.applyAutoCorrectionRuntimeChange],
        "settings toggle policy applies auto-correction runtime effect"
    )
    try expect(
        SettingsTogglePolicy.changeAction(
            slot: .completelyDisableInExceptionApplications,
            wasEnabled: false,
            isEnabled: true
        )?.effects,
        [.refreshCurrentApplicationState],
        "settings toggle policy applies exception-app refresh effect"
    )
    try expect(
        SettingsTogglePolicy.changeAction(
            slot: .soundEffectsEnabled,
            wasEnabled: false,
            isEnabled: true
        )?.effects,
        [],
        "settings toggle policy allows persistence-only toggles"
    )
    try expectNil(
        SettingsTogglePolicy.changeAction(
            slot: .soundEffectsEnabled,
            wasEnabled: true,
            isEnabled: true
        ),
        "settings toggle policy ignores unchanged toggles"
    )
}
