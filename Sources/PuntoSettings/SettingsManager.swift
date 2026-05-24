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
    private lazy var slots = SettingsSlotStore(store: store, resolver: resolver)
    private lazy var applications = SettingsApplicationStore(
        store: store,
        resolver: resolver,
        notificationObject: self
    )

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
        slots.hotkeyAssignments
    }

    public func hotkey(for slot: HotkeySlot) -> Hotkey {
        slots.hotkey(for: slot)
    }

    public func setHotkey(_ hotkey: Hotkey, for slot: HotkeySlot) {
        slots.setHotkey(hotkey, for: slot)
    }

    public func resetHotkey(for slot: HotkeySlot) {
        slots.resetHotkey(for: slot)
    }

    public func bool(for slot: SettingsToggleSlot) -> Bool {
        slots.bool(for: slot)
    }

    public func setBool(_ isEnabled: Bool, for slot: SettingsToggleSlot) {
        slots.setBool(isEnabled, for: slot)
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
        get { applications.russianKeyboardLayoutType }
        set { applications.russianKeyboardLayoutType = newValue }
    }

    public var preferredEnglishInputSourceID: String? {
        get { applications.preferredEnglishInputSourceID }
        set { applications.preferredEnglishInputSourceID = newValue }
    }

    public var preferredRussianInputSourceID: String? {
        get { applications.preferredRussianInputSourceID }
        set { applications.preferredRussianInputSourceID = newValue }
    }

    /// Punto Switcher-style per-application layout memory.
    public var rememberInputSourceForEachApp: Bool {
        get { bool(for: .rememberInputSourceForEachApp) }
        set { setBool(newValue, for: .rememberInputSourceForEachApp) }
    }

    public var rememberedApplicationLayouts: [String: String] {
        get { applications.rememberedApplicationLayouts }
        set { applications.rememberedApplicationLayouts = newValue }
    }

    public var disabledApplicationBundleIDs: Set<String> {
        get { applications.disabledApplicationBundleIDs }
        set { applications.disabledApplicationBundleIDs = newValue }
    }

    public func isApplicationDisabled(bundleID: String?) -> Bool {
        applications.isApplicationDisabled(bundleID: bundleID)
    }

    public var completelyDisableInExceptionApplications: Bool {
        get { bool(for: .completelyDisableInExceptionApplications) }
        set { setBool(newValue, for: .completelyDisableInExceptionApplications) }
    }

    public func isApplicationCompletelyDisabled(bundleID: String?) -> Bool {
        applications.isApplicationCompletelyDisabled(
            bundleID: bundleID,
            completelyDisableInExceptionApplications: completelyDisableInExceptionApplications
        )
    }

    public func setApplicationDisabled(bundleID: String?, disabled: Bool) {
        applications.setApplicationDisabled(bundleID: bundleID, disabled: disabled)
    }

    public var resetOnReturnBundleComponents: Set<String> {
        get { applications.resetOnReturnBundleComponents }
        set { applications.resetOnReturnBundleComponents = newValue }
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
                legacyDayuseSettingsKey: SettingsImportKeys.dayuseSettings
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
        store.register(defaults: SettingsDefaultRegistry.registeredDefaults)
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

}
