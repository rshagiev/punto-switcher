import Foundation

public enum SettingsPersistencePolicy {
    public static let defaultIsEnabled = true
    public static let nativeIsEnabledKey = "isEnabled"
    public static let defaultShowInMenuBar = true
    public static let defaultShowAdvancedSettings = false
    public static let nativeShowAdvancedSettingsKey = "showAdvancedSettings"
    public static let defaultRememberInputSourceForEachApp = false
    public static let defaultRememberedApplicationLayouts: [String: String] = [:]
    public static let defaultDisabledApplicationBundleIDs: [String] = []
    public static let defaultCompletelyDisableInExceptionApplications = false
    public static let defaultAutoCorrectionStarterRulesEnabled = true
    public static let defaultAutoCorrectionUndoLearningEnabled = false
    public static let defaultAutoCorrectionCancellingKeyNames = Array(AutoCorrectionCancellingKeyPolicy.defaultEnabledKeyNames).sorted()
    public static let defaultSoundEffectsEnabled = false
    public static let defaultRestorePasteboardAfterConversion = true
    public static let defaultIsFirstLaunch = true
    public static let defaultRussianKeyboardLayoutType = KeyboardLayoutTypePolicy.defaultRussianLayoutType.rawValue
    public static let defaultProductStatistics = ProductStatisticsPolicy.emptySnapshot

    public static func normalizedProductStatistics(_ snapshot: ProductStatisticsSnapshot) -> ProductStatisticsSnapshot {
        ProductStatisticsPolicy.normalized(snapshot)
    }

    public static func boolValue(_ value: Any?) -> Bool? {
        LegacyValuePolicy.bool(value)
    }

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

    public static func legacyUndoCollectionEnabled(from undoLearning: [String: Any]?) -> Bool? {
        UndoLearningSettingsPolicy.snapshot(from: undoLearning)?.undoCollectionEnabled
    }

}
