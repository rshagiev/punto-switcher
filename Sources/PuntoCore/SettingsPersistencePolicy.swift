import Foundation

public enum SettingsPersistencePolicy {
    public static let defaultIsEnabled = true
    public static let defaultShowInMenuBar = true
    public static let defaultShowAdvancedSettings = false
    public static let defaultLaunchAtLogin = false
    public static let defaultSwitchLayoutAfterConversion = false
    public static let defaultSwitchLayoutAfterSelectedTextConversion = true
    public static let observedSwitchLayoutOnSelectedTextSwitchKey = "switchLayoutOnSelectedTextSwitch"
    public static let observedSetSwitchLanguageWhenChangingSelectionLayoutSelector = "setSwitchLanguageWhenChangingSelectionLayout:"
    public static let defaultManualConversionDisabled = false
    public static let observedIsManualConversionDisabledKey = "isManualConversionDisabled"
    public static let observedSetIsManualConversionDisabledSelector = "setIsManualConversionDisabled:"
    public static let defaultRememberInputSourceForEachApp = false
    public static let observedShouldRememberInputSourceForEachAppKey = "shouldRememberInputSourceForEachApp"
    public static let defaultRememberedApplicationLayouts: [String: String] = [:]
    public static let defaultDisabledApplicationBundleIDs: [String] = []
    public static let observedDisabledAppsKey = "disabledApps"
    public static let observedSetDisabledApplicationsSelector = "setDisabledApplications:"
    public static let observedDisabledAppsPreferencesControllerKey = "disabledAppsPreferencesController"
    public static let observedSetDisabledAppsPreferencesControllerSelector = "setDisabledAppsPreferencesController:"
    public static let defaultCompletelyDisableInExceptionApplications = false
    public static let observedCompletelyDisableInExceptionApplicationsKey = "CompletelyDisableInExceptionApps"
    public static let defaultAutoCorrectionEnabled = false
    public static let defaultAutoCorrectionStarterRulesEnabled = true
    public static let defaultAutoCorrectOnEnterAndTab = true
    public static let defaultAutoCorrectionUndoLearningEnabled = false
    public static let defaultSuppressAutoCorrectionAfterManualConversion = true
    public static let observedShouldNotAutoconvertAfterConvertionKey = "shouldNotAutoconvertAfterConvertion"
    public static let observedDontAutoconvertWordAfterConvertionSelector = "dontAutoconvertWordAfterConvertion:"
    public static let defaultAutoCorrectionCancellingKeyNames = Array(AutoCorrectionCancellingKeyPolicy.defaultEnabledKeyNames).sorted()
    public static let defaultSoundEffectsEnabled = false
    public static let defaultRestorePasteboardAfterConversion = true
    public static let defaultIsFirstLaunch = true
    public static let defaultRussianKeyboardLayoutType = KeyboardLayoutTypePolicy.defaultRussianLayoutType.rawValue
    public static let defaultProductStatistics = ProductStatisticsPolicy.emptySnapshot

    public static func normalizedDisabledApplicationBundleIDs(_ bundleIDs: Set<String>) -> Set<String> {
        ApplicationDisablePolicy.normalizedSet(bundleIDs)
    }

    public static func effectiveDisabledApplicationBundleIDs(
        hasPersistedValue: Bool,
        persistedValue: Set<String>,
        hasLegacyValue: Bool,
        legacyValue: Set<String>
    ) -> Set<String> {
        if hasPersistedValue {
            return normalizedDisabledApplicationBundleIDs(persistedValue)
        }

        if hasLegacyValue {
            return normalizedDisabledApplicationBundleIDs(legacyValue)
        }

        return normalizedDisabledApplicationBundleIDs(Set(defaultDisabledApplicationBundleIDs))
    }

    public static func normalizedResetOnReturnBundleComponents(_ components: Set<String>) -> Set<String> {
        ApplicationBundleIDPolicy.normalizedSet(components)
    }

    public static func normalizedAutoCorrectionCancellingKeyNames(_ keyNames: Set<String>) -> Set<String> {
        AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames(keyNames)
    }

    public static func legacyAutoCorrectionCancellingKeyNames(from bitmask: Int?) -> Set<String>? {
        guard let bitmask else {
            return nil
        }

        guard bitmask == 0 else {
            return nil
        }

        return []
    }

    public static func effectiveAutoCorrectionCancellingKeyNames(
        hasPersistedValue: Bool,
        persistedValue: Set<String>,
        hasLegacyValue: Bool,
        legacyBitmask: Int?
    ) -> Set<String> {
        if hasPersistedValue {
            return normalizedAutoCorrectionCancellingKeyNames(persistedValue)
        }

        if hasLegacyValue, let legacyKeyNames = legacyAutoCorrectionCancellingKeyNames(from: legacyBitmask) {
            return legacyKeyNames
        }

        return normalizedAutoCorrectionCancellingKeyNames(Set(defaultAutoCorrectionCancellingKeyNames))
    }

    public static func normalizedRussianKeyboardLayoutType(_ rawValue: String?) -> KeyboardLayoutType {
        KeyboardLayoutTypePolicy.normalized(rawValue)
    }

    public static func effectiveRussianKeyboardLayoutType(
        hasPersistedValue: Bool,
        persistedValue: String?,
        hasLegacyValue: Bool,
        legacyValue: String?
    ) -> KeyboardLayoutType {
        if hasPersistedValue {
            return normalizedRussianKeyboardLayoutType(persistedValue)
        }

        if hasLegacyValue {
            return normalizedRussianKeyboardLayoutType(legacyValue)
        }

        return KeyboardLayoutTypePolicy.defaultRussianLayoutType
    }

    public static func normalizedInputSourceID(_ sourceID: String?) -> String? {
        InputSourceSelectionPolicy.normalizedSourceID(sourceID)
    }

    public static func effectiveInputSourceID(
        hasPersistedValue: Bool,
        persistedValue: String?,
        hasLegacyValue: Bool,
        legacyValue: String?
    ) -> String? {
        if hasPersistedValue {
            return normalizedInputSourceID(persistedValue)
        }

        if hasLegacyValue {
            return normalizedInputSourceID(legacyValue)
        }

        return nil
    }

    public static func effectiveResetOnReturnBundleComponents(
        hasPersistedComponents: Bool,
        persistedComponents: Set<String>?,
        hasLegacyComponents: Bool = false,
        legacyComponents: Set<String>? = nil,
        defaultComponents: Set<String> = ApplicationReturnKeyPolicy.defaultResetBundleComponents
    ) -> Set<String> {
        if hasPersistedComponents {
            guard let persistedComponents else {
                return normalizedResetOnReturnBundleComponents(defaultComponents)
            }

            return normalizedResetOnReturnBundleComponents(persistedComponents)
        }

        if hasLegacyComponents {
            guard let legacyComponents else {
                return normalizedResetOnReturnBundleComponents(defaultComponents)
            }

            return normalizedResetOnReturnBundleComponents(legacyComponents)
        }

        return normalizedResetOnReturnBundleComponents(defaultComponents)
    }

    public static func normalizedRememberedApplicationLayouts(_ layoutsByBundleID: [String: String]) -> [String: String] {
        ApplicationLayoutMemory(layoutsByBundleID: layoutsByBundleID).snapshot()
    }

    public static func normalizedProductStatistics(_ snapshot: ProductStatisticsSnapshot) -> ProductStatisticsSnapshot {
        ProductStatisticsPolicy.normalized(snapshot)
    }

    public static func boolValue(_ value: Any?) -> Bool? {
        switch value {
        case let value as Bool:
            return value
        case let value as NSNumber:
            return value.boolValue
        case let value as String:
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "yes", "1", "on":
                return true
            case "false", "no", "0", "off":
                return false
            default:
                return nil
            }
        default:
            return nil
        }
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

    public static func undoLearningDictionary(
        from existing: [String: Any]?,
        undoCollectionEnabled: Bool
    ) -> [String: Any] {
        UndoLearningSettingsPolicy.dictionary(
            from: existing,
            undoCollectionEnabled: undoCollectionEnabled
        )
    }
}
