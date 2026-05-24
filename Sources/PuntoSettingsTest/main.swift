import Foundation
import PuntoCore
import PuntoSettings

enum TestFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        throw TestFailure.failed(message)
    }
    print("PASS \(message)")
}

final class DefaultsFixture {
    let suiteName: String
    let defaults: UserDefaults

    init(_ name: String) throws {
        suiteName = "com.rshagiev.Punto.settings-test.\(name).\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestFailure.failed("created defaults suite")
        }
        self.defaults = defaults
        defaults.removePersistentDomain(forName: suiteName)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func manager() -> SettingsManager {
        SettingsManager(defaults: defaults, domainName: suiteName)
    }
}

func runSearchbarImportTests() throws {
    let fixture = try DefaultsFixture("searchbar")
    fixture.defaults.set([
        SearchbarSettingsPolicy.legacyShouldSearchByDoubleClickKey: true
    ], forKey: SearchbarSettingsPolicy.legacySettingsKey)

    var settings = fixture.manager()
    try expect(settings.searchSelectedTextByDoubleClick, "settings manager imports legacy double-click search")

    settings.searchSelectedTextByDoubleClick = false
    settings = fixture.manager()
    try expect(!settings.searchSelectedTextByDoubleClick, "settings manager prefers native double-click search")
    try expect(
        (fixture.defaults.dictionary(forKey: SearchbarSettingsPolicy.legacySettingsKey)?[
            SearchbarSettingsPolicy.legacyShouldSearchByDoubleClickKey
        ] as? Bool) == true,
        "settings manager keeps legacy searchbar dictionary read-only"
    )
}

func runLaunchAtLoginImportTests() throws {
    let fixture = try DefaultsFixture("launch-at-login")
    fixture.defaults.set(true, forKey: LoginItemPolicy.legacyLaunchesOnStartupKey)

    var settings = fixture.manager()
    try expect(settings.launchAtLogin, "settings manager imports legacy launch-at-login")

    settings.launchAtLogin = false
    settings = fixture.manager()
    try expect(!settings.launchAtLogin, "settings manager prefers native launch-at-login")
    try expect(
        fixture.defaults.bool(forKey: LoginItemPolicy.legacyLaunchesOnStartupKey),
        "settings manager keeps legacy launch-at-login read-only"
    )
}

func runSoundImportTests() throws {
    let fixture = try DefaultsFixture("sound")
    fixture.defaults.set(1, forKey: SoundFeedbackPolicy.legacyEnabledSoundsKey)

    var settings = fixture.manager()
    try expect(settings.enabledSoundResourceNames == ["replace"], "settings manager imports legacy sound bitmask")

    settings.enabledSoundResourceNames = ["reverse"]
    settings = fixture.manager()
    try expect(settings.enabledSoundResourceNames == ["reverse"], "settings manager prefers native sound resources")
    try expect(
        fixture.defaults.integer(forKey: SoundFeedbackPolicy.legacyEnabledSoundsKey) == 1,
        "settings manager keeps legacy sound bitmask read-only"
    )
}

func runStatisticsImportTests() throws {
    let fixture = try DefaultsFixture("statistics")
    fixture.defaults.set(7, forKey: ProductStatisticsPolicy.legacyTypedWordsKey)
    fixture.defaults.set(11, forKey: ProductStatisticsPolicy.legacyTypedSymbolsKey)
    fixture.defaults.set([
        ProductStatisticsPolicy.legacyDayuseManualSwitchesKey: 3
    ], forKey: ProductStatisticsPolicy.legacyDayuseSettingsKey)

    var settings = fixture.manager()
    try expect(settings.productStatistics.typedWords == 7, "settings manager imports legacy typed word counter")
    try expect(settings.productStatistics.typedSymbols == 11, "settings manager imports legacy typed symbol counter")
    try expect(settings.productStatistics.manualSwitches == 3, "settings manager imports legacy dayuse counters")

    settings.productStatistics = ProductStatisticsSnapshot(typedWords: 2, typedSymbols: 4)
    settings = fixture.manager()
    try expect(settings.productStatistics.typedWords == 2, "settings manager prefers native statistics snapshot")
    try expect(
        fixture.defaults.integer(forKey: ProductStatisticsPolicy.legacyTypedWordsKey) == 7,
        "settings manager keeps legacy statistics read-only"
    )

    let staleDayuseFixture = try DefaultsFixture("statistics-stale-dayuse")
    let previousDay = Date(timeIntervalSince1970: 1_704_067_200)
    staleDayuseFixture.defaults.set([
        ProductStatisticsPolicy.legacyDayuseTypedWordsKey: 5,
        ProductStatisticsPolicy.legacyDayuseTypedSymbolsKey: 6,
        ProductStatisticsPolicy.legacyDayuseAutoSwitchesKey: 7,
        ProductStatisticsPolicy.legacyDayuseManualSwitchesKey: 8,
        ProductStatisticsPolicy.legacyDayuseRevertsKey: 9,
        ProductStatisticsPolicy.legacyDayuseLastDayuseDateKey: previousDay
    ], forKey: ProductStatisticsPolicy.legacyDayuseSettingsKey)

    let staleDayuseSettings = staleDayuseFixture.manager()
    try expect(staleDayuseSettings.productStatistics.typedWords == 0, "settings manager rolls over stale legacy dayuse typed words")
    try expect(staleDayuseSettings.productStatistics.typedSymbols == 0, "settings manager rolls over stale legacy dayuse typed symbols")
    try expect(staleDayuseSettings.productStatistics.automaticSwitches == 0, "settings manager rolls over stale legacy dayuse automatic switches")
    try expect(staleDayuseSettings.productStatistics.manualSwitches == 0, "settings manager rolls over stale legacy dayuse manual switches")
    try expect(staleDayuseSettings.productStatistics.reverts == 0, "settings manager rolls over stale legacy dayuse reverts")

    let staleNativeFixture = try DefaultsFixture("statistics-stale-native")
    var staleNativeSettings = staleNativeFixture.manager()
    staleNativeSettings.productStatistics = ProductStatisticsSnapshot(
        typedWords: 5,
        typedSymbols: 6,
        automaticSwitches: 7,
        manualSwitches: 8,
        reverts: 9,
        lastDayuseDate: previousDay
    )
    staleNativeSettings = staleNativeFixture.manager()
    try expect(staleNativeSettings.productStatistics.typedWords == 0, "settings manager rolls over stale native dayuse typed words")
    try expect(staleNativeSettings.productStatistics.typedSymbols == 0, "settings manager rolls over stale native dayuse typed symbols")
    try expect(staleNativeSettings.productStatistics.automaticSwitches == 0, "settings manager rolls over stale native dayuse automatic switches")
    try expect(staleNativeSettings.productStatistics.manualSwitches == 0, "settings manager rolls over stale native dayuse manual switches")
    try expect(staleNativeSettings.productStatistics.reverts == 0, "settings manager rolls over stale native dayuse reverts")
}

func runUpdateImportTests() throws {
    let fixture = try DefaultsFixture("update")
    fixture.defaults.set(12, forKey: ApplicationUpdateSettingsPolicy.legacyConfigVersionKey)
    fixture.defaults.set(true, forKey: ApplicationUpdateSettingsPolicy.legacyIsJustUpdatedKey)

    var settings = fixture.manager()
    try expect(settings.applicationUpdateSettings.configVersion == 12, "settings manager imports legacy update config")
    try expect(settings.applicationUpdateSettings.isJustUpdated, "settings manager imports legacy update flag")

    settings.applicationUpdateSettings = ApplicationUpdateSettingsSnapshot(
        configVersion: 21,
        isFirstInstallation: false,
        isJustInstalled: false,
        isJustUpdated: false,
        isUpdating: false,
        shouldCheckForUpdatesAutomatically: false,
        updateRequestRateInDays: 9,
        lastStatisticsRequestDate: nil,
        lastUpdateRequestDate: nil,
        lastUpdateShownDate: nil
    )
    settings = fixture.manager()
    try expect(settings.applicationUpdateSettings.configVersion == 21, "settings manager prefers native update snapshot")
    try expect(
        fixture.defaults.integer(forKey: ApplicationUpdateSettingsPolicy.legacyConfigVersionKey) == 12,
        "settings manager keeps legacy update config read-only"
    )
}

func runUserRuleImportTests() throws {
    let fixture = try DefaultsFixture("rules")
    fixture.defaults.set([
        [
            LegacyUserRulePolicy.ruleStringKey: "custom",
            LegacyUserRulePolicy.ruleKey: "замена",
            LegacyUserRulePolicy.isActiveKey: true,
            LegacyUserRulePolicy.doReplaceKey: true,
            LegacyUserRulePolicy.isRegExpKey: false
        ]
    ], forKey: LegacyUserRulePolicy.userRulesDictionaryKey)

    var settings = fixture.manager()
    try expect(
        settings.autoCorrectionRules.contains(AutoCorrectionRule(trigger: "custom", replacement: "замена")),
        "settings manager imports legacy user rules"
    )

    settings.autoCorrectionRules = [AutoCorrectionRule(trigger: "native", replacement: "правило")]
    settings = fixture.manager()
    try expect(settings.autoCorrectionRules == [AutoCorrectionRule(trigger: "native", replacement: "правило")],
        "settings manager prefers native user rules")
    try expect(
        fixture.defaults.object(forKey: LegacyUserRulePolicy.userRulesDictionaryKey) != nil,
        "settings manager keeps legacy user rules read-only"
    )
}

func runInputSourceNotificationTests() throws {
    let fixture = try DefaultsFixture("input-source")
    let settings = fixture.manager()
    var notificationNames: [Notification.Name] = []
    let observer = NotificationCenter.default.addObserver(
        forName: nil,
        object: settings,
        queue: nil
    ) { notification in
        notificationNames.append(notification.name)
    }
    defer {
        NotificationCenter.default.removeObserver(observer)
    }

    settings.russianKeyboardLayoutType = .windows
    settings.preferredEnglishInputSourceID = " com.apple.keylayout.ABC "

    try expect(
        notificationNames.contains(.puntoRussianKeyboardLayoutTypeChanged),
        "settings manager posts layout-type change notification"
    )
    try expect(
        notificationNames.filter { $0 == .puntoInputSourcePreferencesChanged }.count >= 2,
        "settings manager posts input-source preference notifications"
    )
    try expect(
        settings.preferredEnglishInputSourceID == "com.apple.keylayout.ABC",
        "settings manager normalizes preferred input source ids"
    )
}

func runHotkeySlotAccessTests() throws {
    let fixture = try DefaultsFixture("hotkey-slots")
    let settings = fixture.manager()
    let customToggleCase = Hotkey(keyCode: 31, command: true, option: true, shift: false, control: false)

    for (index, slot) in HotkeySlot.allCases.enumerated() {
        let custom = Hotkey(
            keyCode: UInt16(18 + index),
            command: true,
            option: index % 2 == 0,
            shift: index % 3 == 0,
            control: false
        )
        settings.setHotkey(custom, for: slot)
        try expect(
            settings.hotkey(for: slot) == custom,
            "settings manager round-trips hotkey slot \(slot.rawValue)"
        )
        settings.resetHotkey(for: slot)
    }

    settings.setHotkey(customToggleCase, for: .toggleCase)

    try expect(
        settings.hotkey(for: .toggleCase) == customToggleCase,
        "settings manager writes hotkeys through slot-based access"
    )
    try expect(
        settings.hotkeyAssignments == HotkeyCommandPolicy.displayOrder.map {
            HotkeyAssignment(slot: $0.slot, hotkey: settings.hotkey(for: $0.slot))
        },
        "settings manager exposes hotkey assignments in command policy order"
    )

    settings.resetHotkey(for: .toggleCase)
    try expect(
        settings.hotkey(for: .toggleCase) == Hotkey.defaultToggleCase,
        "settings manager resets hotkeys through slot-based access"
    )
}

func runBooleanToggleSlotAccessTests() throws {
    let fixture = try DefaultsFixture("toggle-slots")
    let settings = fixture.manager()

    for slot in SettingsToggleSlot.allCases {
        let previous = settings.bool(for: slot)
        settings.setBool(!previous, for: slot)
        try expect(
            settings.bool(for: slot) == !previous,
            "settings manager round-trips boolean slot \(slot.rawValue)"
        )
        settings.setBool(previous, for: slot)
    }

    settings.setBool(true, for: .soundEffectsEnabled)
    settings.setBool(true, for: .showAdvancedSettings)
    settings.setBool(false, for: .switchLayoutAfterConversion)

    try expect(
        settings.bool(for: .soundEffectsEnabled),
        "settings manager writes sound effects through boolean slot access"
    )
    try expect(
        settings.bool(for: .showAdvancedSettings),
        "settings manager writes advanced settings through boolean slot access"
    )
    try expect(
        !settings.bool(for: .switchLayoutAfterConversion),
        "settings manager writes layout switching through boolean slot access"
    )
}

do {
    print("PuntoSettingsTest starting")
    try runSearchbarImportTests()
    try runLaunchAtLoginImportTests()
    try runSoundImportTests()
    try runStatisticsImportTests()
    try runUpdateImportTests()
    try runUserRuleImportTests()
    try runInputSourceNotificationTests()
    try runHotkeySlotAccessTests()
    try runBooleanToggleSlotAccessTests()
    print("PuntoSettingsTest passed")
} catch {
    fputs("PuntoSettingsTest failed: \(error)\n", stderr)
    exit(1)
}
