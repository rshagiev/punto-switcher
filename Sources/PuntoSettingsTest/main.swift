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
        SearchbarSettingsPolicy.shouldSearchByDoubleClickKey: true
    ], forKey: SearchbarSettingsPolicy.settingsKey)

    var settings = fixture.manager()
    try expect(settings.searchSelectedTextByDoubleClick, "settings manager imports legacy double-click search")

    settings.searchSelectedTextByDoubleClick = false
    settings = fixture.manager()
    try expect(!settings.searchSelectedTextByDoubleClick, "settings manager prefers native double-click search")
    try expect(
        (fixture.defaults.dictionary(forKey: SearchbarSettingsPolicy.settingsKey)?[
            SearchbarSettingsPolicy.shouldSearchByDoubleClickKey
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
        ProductStatisticsPolicy.dayuseManualSwitchesKey: 3
    ], forKey: ProductStatisticsPolicy.dayuseSettingsKey)

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
}

func runUpdateImportTests() throws {
    let fixture = try DefaultsFixture("update")
    fixture.defaults.set(12, forKey: ApplicationUpdateSettingsPolicy.configVersionKey)
    fixture.defaults.set(true, forKey: ApplicationUpdateSettingsPolicy.isJustUpdatedKey)

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
        fixture.defaults.integer(forKey: ApplicationUpdateSettingsPolicy.configVersionKey) == 12,
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

do {
    print("PuntoSettingsTest starting")
    try runSearchbarImportTests()
    try runLaunchAtLoginImportTests()
    try runSoundImportTests()
    try runStatisticsImportTests()
    try runUpdateImportTests()
    try runUserRuleImportTests()
    try runInputSourceNotificationTests()
    print("PuntoSettingsTest passed")
} catch {
    fputs("PuntoSettingsTest failed: \(error)\n", stderr)
    exit(1)
}
