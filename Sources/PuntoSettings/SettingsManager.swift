import Foundation
import PuntoCore

public extension Notification.Name {
    static let puntoRussianKeyboardLayoutTypeChanged = Notification.Name("puntoRussianKeyboardLayoutTypeChanged")
    static let puntoInputSourcePreferencesChanged = Notification.Name("puntoInputSourcePreferencesChanged")
}

/// Composes application settings from native storage, import fallbacks, and policy-provided base values.
public final class SettingsManager {

    // MARK: - Properties

    private let store: SettingsDefaultsStore
    private lazy var resolver = SettingsValueResolver(store: store)

    /// Whether the app functionality is enabled
    public var isEnabled: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.isEnabled, defaultValue: SettingsPersistencePolicy.defaultIsEnabled) }
        set { store.set(newValue, forKey: SettingsStorageKeys.isEnabled) }
    }

    /// Whether this is the first launch
    public var isFirstLaunch: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.isFirstLaunch, legacyKey: SettingsImportKeys.isFirstInstallation, defaultValue: StartupPresentationPolicy.defaultIsFirstLaunch) }
        set { store.set(newValue, forKey: SettingsStorageKeys.isFirstLaunch) }
    }

    /// Consumes native and imported Punto Switcher first-run flags after onboarding.
    public func consumeFirstLaunchPresentationFlags() {
        store.set(false, forKey: SettingsStorageKeys.isFirstLaunch)
        store.set(false, forKey: SettingsImportKeys.isFirstInstallation)
        store.set(false, forKey: SettingsImportKeys.isJustInstalled)
    }

    /// Consumes imported Punto Switcher update flags after native update presentation.
    public func consumeUpdatePresentationImportFlags() {
        store.set(false, forKey: SettingsImportKeys.isJustUpdated)
        store.set(false, forKey: SettingsImportKeys.isUpdating)
    }

    /// Whether to show the icon in the menu bar
    public var showInMenuBar: Bool {
        get { bool(for: .showInMenuBar) }
        set { setBool(newValue, for: .showInMenuBar) }
    }

    /// Whether advanced settings are visible in the preferences window
    public var showAdvancedSettings: Bool {
        get { bool(for: .showAdvancedSettings) }
        set { setBool(newValue, for: .showAdvancedSettings) }
    }

    /// Whether to launch at login
    public var launchAtLogin: Bool {
        get { bool(for: .launchAtLogin) }
        set { setBool(newValue, for: .launchAtLogin) }
    }

    /// Hotkey for converting layout
    public var convertLayoutHotkey: Hotkey {
        get { hotkey(for: .convertLayout) }
        set { setHotkey(newValue, for: .convertLayout) }
    }

    /// Hotkey for toggling case
    public var toggleCaseHotkey: Hotkey {
        get { hotkey(for: .toggleCase) }
        set { setHotkey(newValue, for: .toggleCase) }
    }

    /// Hotkey for toggling auto-correction
    public var toggleAutoCorrectionHotkey: Hotkey {
        get { hotkey(for: .toggleAutoCorrection) }
        set { setHotkey(newValue, for: .toggleAutoCorrection) }
    }

    /// Hotkey for cancelling the last layout change.
    public var cancelLayoutChangeHotkey: Hotkey {
        get { hotkey(for: .cancelLayoutChange) }
        set { setHotkey(newValue, for: .cancelLayoutChange) }
    }

    /// Hotkey for opening selected text in Yandex search.
    public var findInYandexHotkey: Hotkey {
        get { hotkey(for: .findInYandex) }
        set { setHotkey(newValue, for: .findInYandex) }
    }

    /// Hotkey for opening selected text in Yandex Translate/Slovari flow.
    public var findInSlovariHotkey: Hotkey {
        get { hotkey(for: .findInSlovari) }
        set { setHotkey(newValue, for: .findInSlovari) }
    }

    public var hotkeyAssignments: [HotkeyAssignment] {
        HotkeyCommandPolicy.displayOrder.map {
            HotkeyAssignment(slot: $0.slot, hotkey: hotkey(for: $0.slot))
        }
    }

    public func hotkey(for slot: HotkeySlot) -> Hotkey {
        resolver.hotkeySlot(SettingsHotkeySlotRegistry.descriptor(for: slot))
    }

    public func setHotkey(_ hotkey: Hotkey, for slot: HotkeySlot) {
        let descriptor = SettingsHotkeySlotRegistry.descriptor(for: slot)
        let normalized = HotkeyValidationPolicy.normalized(hotkey, fallback: descriptor.fallback)
        store.encodeAndSet(normalized, forKey: descriptor.nativeKey)
    }

    public func resetHotkey(for slot: HotkeySlot) {
        setHotkey(HotkeyCommandPolicy.defaultHotkey(for: slot), for: slot)
    }

    public func bool(for slot: SettingsToggleSlot) -> Bool {
        resolver.boolSlot(SettingsBoolSlotRegistry.descriptor(for: slot))
    }

    public func setBool(_ isEnabled: Bool, for slot: SettingsToggleSlot) {
        store.set(isEnabled, forKey: SettingsBoolSlotRegistry.descriptor(for: slot).nativeKey)
    }

    public var searchSelectedTextByDoubleClick: Bool {
        get { bool(for: .searchSelectedTextByDoubleClick) }
        set { setBool(newValue, for: .searchSelectedTextByDoubleClick) }
    }

    /// Переключать раскладку после конвертации
    public var switchLayoutAfterConversion: Bool {
        get { bool(for: .switchLayoutAfterConversion) }
        set { setBool(newValue, for: .switchLayoutAfterConversion) }
    }

    public var switchLayoutAfterSelectedTextConversion: Bool {
        get { bool(for: .switchLayoutAfterSelectedTextConversion) }
        set { setBool(newValue, for: .switchLayoutAfterSelectedTextConversion) }
    }

    public var manualConversionDisabled: Bool {
        get { bool(for: .manualConversionDisabled) }
        set { setBool(newValue, for: .manualConversionDisabled) }
    }

    public var russianKeyboardLayoutType: KeyboardLayoutType {
        get { resolver.russianKeyboardLayoutType(nativeKey: SettingsStorageKeys.russianKeyboardLayoutType, legacyKey: SettingsImportKeys.kbdLayoutType) }
        set {
            store.set(newValue.rawValue, forKey: SettingsStorageKeys.russianKeyboardLayoutType)
            NotificationCenter.default.post(name: .puntoRussianKeyboardLayoutTypeChanged, object: self)
            NotificationCenter.default.post(name: .puntoInputSourcePreferencesChanged, object: self)
        }
    }

    public var preferredEnglishInputSourceID: String? {
        get { resolver.inputSourceID(nativeKey: SettingsStorageKeys.preferredEnglishInputSourceID, legacyKey: SettingsImportKeys.englishLayoutID) }
        set {
            setPreferredInputSourceID(newValue, nativeKey: SettingsStorageKeys.preferredEnglishInputSourceID)
        }
    }

    public var preferredRussianInputSourceID: String? {
        get { resolver.inputSourceID(nativeKey: SettingsStorageKeys.preferredRussianInputSourceID, legacyKey: SettingsImportKeys.russianLayoutID) }
        set {
            setPreferredInputSourceID(newValue, nativeKey: SettingsStorageKeys.preferredRussianInputSourceID)
        }
    }

    /// Punto Switcher-style per-application layout memory.
    public var rememberInputSourceForEachApp: Bool {
        get { bool(for: .rememberInputSourceForEachApp) }
        set { setBool(newValue, for: .rememberInputSourceForEachApp) }
    }

    public var rememberedApplicationLayouts: [String: String] {
        get {
            ApplicationLayoutMemory.normalizedSnapshot(
                store.dictionary(forKey: SettingsStorageKeys.rememberedApplicationLayouts) as? [String: String] ?? [:]
            )
        }
        set {
            store.set(
                ApplicationLayoutMemory.normalizedSnapshot(newValue),
                forKey: SettingsStorageKeys.rememberedApplicationLayouts
            )
        }
    }

    public var disabledApplicationBundleIDs: Set<String> {
        get { resolver.disabledApplicationBundleIDs(nativeKey: SettingsStorageKeys.disabledApplicationBundleIDs, legacyKey: SettingsImportKeys.disabledApps) }
        set {
            let normalized = Array(ApplicationDisablePolicy.normalizedSet(newValue)).sorted()
            store.set(normalized, forKey: SettingsStorageKeys.disabledApplicationBundleIDs)
        }
    }

    public func isApplicationDisabled(bundleID: String?) -> Bool {
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: bundleID,
            disabledBundleIDs: disabledApplicationBundleIDs
        )
    }

    public var completelyDisableInExceptionApplications: Bool {
        get { bool(for: .completelyDisableInExceptionApplications) }
        set { setBool(newValue, for: .completelyDisableInExceptionApplications) }
    }

    public func isApplicationCompletelyDisabled(bundleID: String?) -> Bool {
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: bundleID,
            disabledBundleIDs: disabledApplicationBundleIDs,
            completelyDisableInExceptionApplications: completelyDisableInExceptionApplications
        )
    }

    public func setApplicationDisabled(bundleID: String?, disabled: Bool) {
        disabledApplicationBundleIDs = ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: bundleID,
            disabled: disabled,
            disabledBundleIDs: disabledApplicationBundleIDs
        )
    }

    public var resetOnReturnBundleComponents: Set<String> {
        get { resolver.resetOnReturnBundleComponents(nativeKey: SettingsStorageKeys.resetOnReturnBundleComponents, legacyKey: SettingsImportKeys.switcherResetOnReturn) }
        set {
            let normalized = Array(ApplicationReturnKeyPolicy.normalizedResetBundleComponents(newValue)).sorted()
            store.set(
                normalized,
                forKey: SettingsStorageKeys.resetOnReturnBundleComponents
            )
        }
    }

    public var autoCorrectionEnabled: Bool {
        get { bool(for: .autoCorrectionEnabled) }
        set { setBool(newValue, for: .autoCorrectionEnabled) }
    }

    public var autoCorrectionStarterRulesEnabled: Bool {
        get {
            resolver.firstStoredBool(
                keys: [
                    SettingsStorageKeys.autoCorrectionStarterRulesEnabled,
                    SettingsImportKeys.switcherUseOldRulesDefaultConf,
                    SettingsImportKeys.switcherUseOldRulesAccessor
                ],
                defaultValue: AutoCorrectionRuleSourcePolicy.defaultStarterRulesEnabled
            )
        }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.autoCorrectionStarterRulesEnabled)
        }
    }

    public var autoCorrectOnEnterAndTab: Bool {
        get { bool(for: .autoCorrectOnEnterAndTab) }
        set { setBool(newValue, for: .autoCorrectOnEnterAndTab) }
    }

    public var autoCorrectionUndoLearningEnabled: Bool {
        get { bool(for: .autoCorrectionUndoLearningEnabled) }
        set { setBool(newValue, for: .autoCorrectionUndoLearningEnabled) }
    }

    public var suppressAutoCorrectionAfterManualConversion: Bool {
        get { bool(for: .suppressAutoCorrectionAfterManualConversion) }
        set { setBool(newValue, for: .suppressAutoCorrectionAfterManualConversion) }
    }

    public var autoCorrectionCancellingKeyNames: Set<String> {
        get { resolver.autoCorrectionCancellingKeyNames(nativeKey: SettingsStorageKeys.autoCorrectionCancellingKeyNames, legacyKey: SettingsImportKeys.cancellingKeys) }
        set {
            store.set(
                Array(AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames(newValue)).sorted(),
                forKey: SettingsStorageKeys.autoCorrectionCancellingKeyNames
            )
        }
    }

    public func isAutoCorrectionCancellingKeyEnabled(_ keyName: String) -> Bool {
        autoCorrectionCancellingKeyNames.contains(
            AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames([keyName]).first ?? ""
        )
    }

    public func setAutoCorrectionCancellingKey(_ keyName: String, enabled: Bool) {
        guard let normalized = AutoCorrectionCancellingKeyPolicy.normalizedEnabledKeyNames([keyName]).first else {
            return
        }
        var enabledKeyNames = autoCorrectionCancellingKeyNames
        if enabled {
            enabledKeyNames.insert(normalized)
        } else {
            enabledKeyNames.remove(normalized)
        }
        autoCorrectionCancellingKeyNames = enabledKeyNames
    }

    public var soundEffectsEnabled: Bool {
        get { bool(for: .soundEffectsEnabled) }
        set { setBool(newValue, for: .soundEffectsEnabled) }
    }

    public var enabledSoundResourceNames: Set<String> {
        get {
            resolver.enabledSoundResourceNames(
                nativeKey: SettingsStorageKeys.enabledSoundResourceNames,
                legacyBitmaskKey: SettingsImportKeys.enabledSounds,
                legacyToggleKeys: SoundFeedbackPolicy.legacyPerResourceToggleKeys
            )
        }
        set {
            let normalized = SoundFeedbackPolicy.normalizedEnabledResourceNames(newValue)
            store.set(Array(normalized).sorted(), forKey: SettingsStorageKeys.enabledSoundResourceNames)
        }
    }

    public func isSoundResourceEnabled(_ resourceName: String) -> Bool {
        enabledSoundResourceNames.contains(resourceName)
    }

    public func setSoundResource(_ resourceName: String, enabled: Bool) {
        var enabledNames = enabledSoundResourceNames
        if enabled {
            enabledNames.insert(resourceName)
        } else {
            enabledNames.remove(resourceName)
        }
        enabledSoundResourceNames = enabledNames
    }

    public var restorePasteboardAfterConversion: Bool {
        get { resolver.bool(nativeKey: SettingsStorageKeys.restorePasteboardAfterConversion, legacyKey: SettingsImportKeys.shouldRestorePasteboard, defaultValue: ClipboardReplacementPolicy.defaultRestorePasteboardAfterConversion) }
        set {
            store.set(newValue, forKey: SettingsStorageKeys.restorePasteboardAfterConversion)
        }
    }

    public var productStatistics: ProductStatisticsSnapshot {
        get {
            resolver.productStatistics(
                nativeKey: SettingsStorageKeys.productStatistics,
                typedWordsKey: SettingsImportKeys.typedWords,
                typedSymbolsKey: SettingsImportKeys.typedSymbols,
                automaticSwitchesKey: SettingsImportKeys.automaticSwitches,
                manualSwitchesKey: SettingsImportKeys.manualSwitches,
                revertsKey: SettingsImportKeys.reverts,
                dayuseSettingsKey: SettingsImportKeys.dayuseSettings
            )
        }
        set {
            let normalized = ProductStatisticsPolicy.normalized(newValue)
            store.encodeAndSet(normalized, forKey: SettingsStorageKeys.productStatistics)
        }
    }

    public func recordProductStatisticsEvent(_ event: ProductStatisticsEvent) {
        productStatistics = ProductStatisticsPolicy.snapshot(after: event, current: productStatistics)
    }

    public var applicationUpdateSettings: ApplicationUpdateSettingsSnapshot {
        get { resolver.applicationUpdateSettings(nativeKey: SettingsStorageKeys.applicationUpdateSettings) }
        set {
            let normalized = ApplicationUpdateSettingsPolicy.normalized(newValue)
            store.encodeAndSet(normalized, forKey: SettingsStorageKeys.applicationUpdateSettings)
        }
    }

    public var autoCorrectionRules: [AutoCorrectionRule] {
        get {
            resolver.autoCorrectionRules(
                nativeKey: SettingsStorageKeys.autoCorrectionRules,
                legacyUserRulesKey: SettingsImportKeys.userRulesDictionary,
                useStarterRules: autoCorrectionStarterRulesEnabled
            )
        }
        set {
            guard let data = try? AutoCorrectionRuleStore.encodeRules(newValue) else { return }
            store.set(data, forKey: SettingsStorageKeys.autoCorrectionRules)
        }
    }

    @discardableResult
    public func importAutoCorrectionRules(from data: Data, merge: Bool = true) throws -> AutoCorrectionRuleImportResult {
        let result = try AutoCorrectionRuleStore.decodeRules(from: data)
        autoCorrectionRules = merge
            ? AutoCorrectionRuleStore.mergedRules(existing: autoCorrectionRules, imported: result.rules)
            : result.rules
        return result
    }

    public func exportAutoCorrectionRules() throws -> Data {
        try AutoCorrectionRuleStore.encodeRules(autoCorrectionRules)
    }

    // MARK: - Initialization

    public init(
        defaults: UserDefaults = .standard,
        domainName: String? = Bundle.main.bundleIdentifier
    ) {
        self.store = SettingsDefaultsStore(defaults: defaults, domainName: domainName)
        // Register defaults
        store.register(defaults: [
            SettingsStorageKeys.isEnabled: SettingsPersistencePolicy.defaultIsEnabled,
            SettingsStorageKeys.isFirstLaunch: StartupPresentationPolicy.defaultIsFirstLaunch,
            SettingsStorageKeys.russianKeyboardLayoutType: KeyboardLayoutTypePolicy.defaultRussianLayoutTypeRawValue,
            SettingsStorageKeys.rememberedApplicationLayouts: ApplicationLayoutMemory.defaultSnapshot,
            SettingsStorageKeys.disabledApplicationBundleIDs: ApplicationDisablePolicy.defaultDisabledBundleIDs,
            SettingsStorageKeys.autoCorrectionCancellingKeyNames: AutoCorrectionCancellingKeyPolicy.defaultEnabledKeyNameList
        ].merging(SettingsBoolSlotRegistry.nativeDefaultValues) { nativeValue, _ in nativeValue })
    }

    // MARK: - Reset to Defaults

    public func resetConvertLayoutHotkey() {
        resetHotkey(for: .convertLayout)
    }

    public func resetToggleCaseHotkey() {
        resetHotkey(for: .toggleCase)
    }

    public func resetToggleAutoCorrectionHotkey() {
        resetHotkey(for: .toggleAutoCorrection)
    }

    public func resetCancelLayoutChangeHotkey() {
        resetHotkey(for: .cancelLayoutChange)
    }

    public func resetFindInYandexHotkey() {
        resetHotkey(for: .findInYandex)
    }

    public func resetFindInSlovariHotkey() {
        resetHotkey(for: .findInSlovari)
    }

    private func setPreferredInputSourceID(_ sourceID: String?, nativeKey: String) {
        if let normalized = InputSourceSelectionPolicy.normalizedSourceID(sourceID) {
            store.set(normalized, forKey: nativeKey)
        } else {
            store.removeObject(forKey: nativeKey)
        }
        NotificationCenter.default.post(name: .puntoInputSourcePreferencesChanged, object: self)
    }

}
