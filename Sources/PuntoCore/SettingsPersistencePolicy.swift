import Foundation

public enum SettingsPersistencePolicy {
    public static let defaultIsEnabled = true
    public static let nativeIsEnabledKey = "isEnabled"
    public static let defaultShowInMenuBar = true
    public static let defaultShowAdvancedSettings = false
    public static let nativeShowAdvancedSettingsKey = "showAdvancedSettings"

    public static func effectiveBool(
        hasPersistedValue: Bool,
        persistedValue: Bool?,
        defaultValue: Bool
    ) -> Bool {
        guard hasPersistedValue else {
            return defaultValue
        }
        return persistedValue ?? defaultValue
    }

    public static func effectiveBoolWithLegacyAlias(
        hasPersistedValue: Bool,
        persistedValue: Bool?,
        hasLegacyValue: Bool,
        legacyValue: Bool?,
        defaultValue: Bool
    ) -> Bool {
        if hasPersistedValue {
            return persistedValue ?? defaultValue
        }

        if hasLegacyValue {
            return legacyValue ?? defaultValue
        }

        return defaultValue
    }

    public static func effectiveBoolWithInvertedLegacyAlias(
        hasPersistedValue: Bool,
        persistedValue: Bool?,
        hasLegacyValue: Bool,
        invertedLegacyValue: Bool?,
        defaultValue: Bool
    ) -> Bool {
        let legacyValue = invertedLegacyValue.map { !$0 }
        return effectiveBoolWithLegacyAlias(
            hasPersistedValue: hasPersistedValue,
            persistedValue: persistedValue,
            hasLegacyValue: hasLegacyValue,
            legacyValue: legacyValue,
            defaultValue: defaultValue
        )
    }

}
