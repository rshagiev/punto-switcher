import Foundation
import PuntoCore

/// Resolves native settings with read-only Punto Switcher import fallbacks.
final class SettingsValueResolver {
    private let store: SettingsDefaultsStore

    init(store: SettingsDefaultsStore) {
        self.store = store
    }

    func bool(nativeKey: String, defaultValue: Bool) -> Bool {
        SettingsPersistencePolicy.effectiveBool(
            hasPersistedValue: hasStoredValue(nativeKey),
            persistedValue: storedBool(nativeKey),
            defaultValue: defaultValue
        )
    }

    func bool(nativeKey: String, legacyKey: String, defaultValue: Bool) -> Bool {
        SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: hasStoredValue(nativeKey),
            persistedValue: storedBool(nativeKey),
            hasLegacyValue: hasStoredValue(legacyKey),
            legacyValue: storedBool(legacyKey),
            defaultValue: defaultValue
        )
    }

    func invertedLegacyBool(nativeKey: String, legacyKey: String, defaultValue: Bool) -> Bool {
        SettingsPersistencePolicy.effectiveBoolWithInvertedLegacyAlias(
            hasPersistedValue: hasStoredValue(nativeKey),
            persistedValue: storedBool(nativeKey),
            hasLegacyValue: hasStoredValue(legacyKey),
            invertedLegacyValue: storedBool(legacyKey),
            defaultValue: defaultValue
        )
    }

    func firstStoredBool(keys: [String], defaultValue: Bool) -> Bool {
        for key in keys where hasStoredValue(key) {
            return storedBool(key) ?? defaultValue
        }
        return defaultValue
    }

    func hotkey(nativeKey: String, legacyKey: String, fallback: Hotkey) -> Hotkey {
        if let hotkey = store.decode(Hotkey.self, forKey: nativeKey) {
            return HotkeyValidationPolicy.normalized(hotkey, fallback: fallback)
        }

        if store.object(forKey: legacyKey) != nil {
            return LegacyHotkeyPolicy.normalized(store.dictionary(forKey: legacyKey), fallback: fallback)
        }

        return fallback
    }

    func russianKeyboardLayoutType(nativeKey: String, legacyKey: String) -> KeyboardLayoutType {
        SettingsPersistencePolicy.effectiveRussianKeyboardLayoutType(
            hasPersistedValue: hasStoredValue(nativeKey),
            persistedValue: store.string(forKey: nativeKey),
            hasLegacyValue: hasStoredValue(legacyKey),
            legacyValue: store.string(forKey: legacyKey)
        )
    }

    func inputSourceID(nativeKey: String, legacyKey: String) -> String? {
        SettingsPersistencePolicy.effectiveInputSourceID(
            hasPersistedValue: hasStoredValue(nativeKey),
            persistedValue: store.string(forKey: nativeKey),
            hasLegacyValue: hasStoredValue(legacyKey),
            legacyValue: store.string(forKey: legacyKey)
        )
    }

    func disabledApplicationBundleIDs(nativeKey: String, legacyKey: String) -> Set<String> {
        SettingsPersistencePolicy.effectiveDisabledApplicationBundleIDs(
            hasPersistedValue: hasStoredValue(nativeKey),
            persistedValue: Set(store.stringArray(forKey: nativeKey) ?? []),
            hasLegacyValue: hasStoredValue(legacyKey),
            legacyValue: Set(store.stringArray(forKey: legacyKey) ?? [])
        )
    }

    func resetOnReturnBundleComponents(nativeKey: String, legacyKey: String) -> Set<String> {
        SettingsPersistencePolicy.effectiveResetOnReturnBundleComponents(
            hasPersistedComponents: store.object(forKey: nativeKey) != nil,
            persistedComponents: store.stringArray(forKey: nativeKey).map(Set.init),
            hasLegacyComponents: store.object(forKey: legacyKey) != nil,
            legacyComponents: store.stringArray(forKey: legacyKey).map(Set.init)
        )
    }

    func autoCorrectionCancellingKeyNames(nativeKey: String, legacyKey: String) -> Set<String> {
        SettingsPersistencePolicy.effectiveAutoCorrectionCancellingKeyNames(
            hasPersistedValue: hasStoredValue(nativeKey),
            persistedValue: Set(store.stringArray(forKey: nativeKey) ?? []),
            hasLegacyValue: hasStoredValue(legacyKey),
            legacyBitmask: store.integer(forKey: legacyKey)
        )
    }

    func undoLearningEnabled(nativeKey: String, legacyKey: String, defaultValue: Bool) -> Bool {
        let legacyValue = SettingsPersistencePolicy.legacyUndoCollectionEnabled(
            from: store.dictionary(forKey: legacyKey)
        )
        return SettingsPersistencePolicy.effectiveBoolWithLegacyAlias(
            hasPersistedValue: hasStoredValue(nativeKey),
            persistedValue: storedBool(nativeKey),
            hasLegacyValue: legacyValue != nil,
            legacyValue: legacyValue ?? defaultValue,
            defaultValue: defaultValue
        )
    }

    func searchSelectedTextByDoubleClick(nativeKey: String, legacyKey: String) -> Bool {
        SearchbarSettingsPolicy.effectiveShouldSearchByDoubleClick(
            hasNativeValue: hasStoredValue(nativeKey),
            nativeValue: store.bool(forKey: nativeKey),
            legacySnapshot: SearchbarSettingsPolicy.snapshot(from: store.dictionary(forKey: legacyKey))
        )
    }

    func enabledSoundResourceNames(
        nativeKey: String,
        legacyBitmaskKey: String,
        legacyToggleKeys: [String]
    ) -> Set<String> {
        if store.object(forKey: nativeKey) != nil {
            return SoundFeedbackPolicy.normalizedEnabledResourceNames(
                Set(store.stringArray(forKey: nativeKey) ?? [])
            )
        }
        if store.object(forKey: legacyBitmaskKey) != nil,
           let legacyNames = SoundFeedbackPolicy.enabledResourceNames(
            fromLegacyBitmask: store.integer(forKey: legacyBitmaskKey)
           ) {
            return legacyNames
        }
        if let legacyToggleNames = SoundFeedbackPolicy.enabledResourceNames(
            fromLegacyToggles: soundResourceToggles(keys: legacyToggleKeys)
        ) {
            return legacyToggleNames
        }
        return SoundFeedbackPolicy.defaultEnabledResourceNames
    }

    func productStatistics(
        nativeKey: String,
        typedWordsKey: String,
        typedSymbolsKey: String,
        automaticSwitchesKey: String,
        manualSwitchesKey: String,
        revertsKey: String,
        dayuseSettingsKey: String
    ) -> ProductStatisticsSnapshot {
        let persistedSnapshot = store.decode(ProductStatisticsSnapshot.self, forKey: nativeKey)
        let legacyCountersSnapshot = ProductStatisticsPolicy.snapshotFromLegacySources(
            typedWords: store.integer(forKey: typedWordsKey),
            typedSymbols: store.integer(forKey: typedSymbolsKey),
            automaticSwitches: store.integer(forKey: automaticSwitchesKey),
            manualSwitches: store.integer(forKey: manualSwitchesKey),
            reverts: store.integer(forKey: revertsKey),
            dayuseSettings: store.dictionary(forKey: dayuseSettingsKey)
        )
        return ProductStatisticsPolicy.effectiveSnapshot(
            persistedSnapshot: persistedSnapshot,
            legacyCountersSnapshot: legacyCountersSnapshot
        )
    }

    func applicationUpdateSettings(nativeKey: String) -> ApplicationUpdateSettingsSnapshot {
        if let snapshot = store.decode(ApplicationUpdateSettingsSnapshot.self, forKey: nativeKey) {
            return ApplicationUpdateSettingsPolicy.normalized(snapshot)
        }
        return ApplicationUpdateSettingsPolicy.snapshot(from: store.storedDefaults)
    }

    func autoCorrectionRules(
        nativeKey: String,
        legacyUserRulesKey: String,
        useStarterRules: Bool
    ) -> [AutoCorrectionRule] {
        let hasPersistedRules = store.object(forKey: nativeKey) != nil
        let rules = store.decode([AutoCorrectionRule].self, forKey: nativeKey)
            .map(AutoCorrectionRuleStore.normalizedRules)
        let legacyRules = LegacyUserRulePolicy.rules(from: store.object(forKey: legacyUserRulesKey))
        return AutoCorrectionRuleSourcePolicy.effectiveRules(
            hasPersistedRules: hasPersistedRules,
            persistedRules: rules,
            legacyUserRules: legacyRules,
            useStarterRules: useStarterRules
        )
    }

    func soundResourceToggles(keys: [String]) -> [String: Bool] {
        var toggles: [String: Bool] = [:]
        for key in keys where hasStoredValue(key) {
            if let value = storedBool(key) {
                toggles[key] = value
            }
        }
        return toggles
    }

    func hasStoredValue(_ key: String) -> Bool {
        store.hasStoredValue(forKey: key)
    }

    private func storedBool(_ key: String) -> Bool? {
        store.bool(forKey: key)
    }
}
