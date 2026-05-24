import Foundation
import PuntoCore

func runLayoutAndManualSettingsPolicyTests() throws {
    try expect(
        LayoutSwitchPolicy.defaultSwitchLayoutAfterConversion,
        false,
        "settings defaults do not switch input source after conversion"
    )
    try expect(
        LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion,
        true,
        "settings defaults allow selected-text layout switching when global switching is enabled"
    )
    try expect(
        LayoutSwitchPolicy.legacySwitchLayoutOnSelectedTextSwitchKey,
        "switchLayoutOnSelectedTextSwitch",
        "settings persistence preserves observed selected-text switch key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setSwitchLanguageWhenChangingSelectionLayoutSelector,
        "setSwitchLanguageWhenChangingSelectionLayout:",
        "settings persistence preserves observed selected-text switch setter"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion
        ),
        true,
        "settings persistence reads Punto Switcher switchLayoutOnSelectedTextSwitch alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: LayoutSwitchPolicy.defaultSwitchLayoutAfterSelectedTextConversion
        ),
        false,
        "settings persistence prefers native selected-text layout switch over Punto Switcher alias"
    )
    try expect(
        KeyboardLayoutTypePolicy.defaultRussianLayoutTypeRawValue,
        "mac",
        "settings defaults use Mac Russian keyboard layout"
    )
    try expect(
        TextActionPreflightPolicy.defaultManualConversionDisabled,
        false,
        "settings defaults keep manual conversion enabled"
    )
    try expect(
        TextActionPreflightPolicy.legacyIsManualConversionDisabledKey,
        "isManualConversionDisabled",
        "settings persistence preserves observed manual-conversion-disable key"
    )
    try expect(
        PuntoSwitcherObservedSurface.Settings.setIsManualConversionDisabledSelector,
        "setIsManualConversionDisabled:",
        "settings persistence preserves observed manual-conversion-disable setter"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: false,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: TextActionPreflightPolicy.defaultManualConversionDisabled
        ),
        true,
        "settings persistence reads Punto Switcher isManualConversionDisabled alias"
    )
    try expect(
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: true,
            persistedValue: false,
            hasLegacyValue: true,
            legacyValue: true,
            defaultValue: TextActionPreflightPolicy.defaultManualConversionDisabled
        ),
        false,
        "settings persistence prefers native manual conversion setting over Punto Switcher alias"
    )
}
