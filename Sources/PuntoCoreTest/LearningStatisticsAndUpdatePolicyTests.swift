import Foundation
import PuntoCore

func runUndoLearningSettingsPolicyTests() throws {
    try expect(
        UndoLearningSettingsPolicy.defaultSnapshot,
        UndoLearningSettingsSnapshot(
            undoCollectionEnabled: false,
            mustShowUndoWindow: true,
            undoDictionary: [:]
        ),
        "undo learning policy mirrors observed Punto Switcher defaults"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.setUndoCollectionEnabledSelector,
        "setUndoCollectionEnabled:",
        "observed surface preserves undo learning collection setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.setMustShowUndoWindowSelector,
        "setMustShowUndoWindow:",
        "observed surface preserves undo learning undo-window setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.setUndoDictionarySelector,
        "setUndoDictionary:",
        "observed surface preserves undo learning undo dictionary setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWindowControllerClassName,
        "UndoWindowController",
        "observed surface preserves undo window controller name"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWindowDelegateProtocolName,
        "UndoWindowDelegate",
        "observed surface preserves undo window delegate name"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWindowResourceName,
        "UndoWindow",
        "observed surface preserves undo window resource name"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoAlertFormatKey,
        "PMUserRuleUndoAlertFormat",
        "observed surface preserves undo alert format key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.showUndoLearningWindowCheckboxChangedSelector,
        "showUndoLearningWindowCheckboxChanged:",
        "observed surface preserves undo show-window checkbox selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoLearningCheckboxChangedSelector,
        "undoLearningCheckboxChanged:",
        "observed surface preserves undo learning checkbox selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoLearningCheckboxKey,
        "undoLearningCheckbox",
        "observed surface preserves undo learning checkbox key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.showUndoLearningWindowCheckboxKey,
        "showUndoLearningWindowCheckbox",
        "observed surface preserves undo show-window checkbox key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoTriesKey,
        "undoTries",
        "observed surface preserves undo tries key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoPersistsKey,
        "undoPersists",
        "observed surface preserves undo persistence key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoWasDoneKey,
        "undoWasDone",
        "observed surface preserves undo completion key"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.undoConvertionSelector,
        "undoConvertion",
        "observed surface preserves legacy undo selector spelling"
    )
    try expect(
        PuntoSwitcherObservedSurface.UndoLearning.resetUndoBufferSelector,
        "resetUndoBuffer",
        "observed surface preserves undo-buffer reset selector"
    )
    try expectNil(
        UndoLearningSettingsPolicy.snapshot(from: nil),
        "undo learning policy rejects missing dictionary"
    )
    try expect(
        UndoLearningSettingsPolicy.snapshot(from: [
            UndoLearningSettingsPolicy.undoCollectionEnabledKey: NSNumber(value: false),
            UndoLearningSettingsPolicy.mustShowUndoWindowKey: NSNumber(value: true),
            UndoLearningSettingsPolicy.undoDictionaryKey: [:]
        ]),
        UndoLearningSettingsPolicy.defaultSnapshot,
        "undo learning policy reads observed Punto Switcher plist shape"
    )
    try expect(
        UndoLearningSettingsPolicy.snapshot(from: [
            UndoLearningSettingsPolicy.undoCollectionEnabledKey: "yes",
            UndoLearningSettingsPolicy.mustShowUndoWindowKey: "0",
            UndoLearningSettingsPolicy.undoDictionaryKey: [
                " teh ": " the ",
                "": "ignored",
                "adn": " "
            ]
        ]),
        UndoLearningSettingsSnapshot(
            undoCollectionEnabled: true,
            mustShowUndoWindow: false,
            undoDictionary: ["teh": "the"]
        ),
        "undo learning policy parses imported string-backed values and normalizes undo dictionary"
    )
    try expect(
        UndoLearningSettingsPolicy.legacyUndoCollectionEnabled(from: [
            UndoLearningSettingsPolicy.undoCollectionEnabledKey: NSNumber(value: true)
        ]),
        true,
        "undo learning policy exposes imported undoCollectionEnabled for settings fallback"
    )
    try expectNil(
        UndoLearningSettingsPolicy.legacyUndoCollectionEnabled(from: nil),
        "undo learning policy ignores missing undoLearning dictionaries"
    )

    try expect(
        UndoLearningSettingsPolicy.normalizedUndoDictionary([
            " ghbdtn ": " привет ",
            "": "ignored",
            "adn": " "
        ]),
        ["ghbdtn": "привет"],
        "undo learning policy normalizes imported undo dictionary entries"
    )
}

func runProductStatisticsPolicyTests() throws {
    var utcCalendar = Calendar(identifier: .gregorian)
    utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let today = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01 00:00:00 +0000
    let laterToday = Date(timeIntervalSince1970: 1_704_110_400) // 2024-01-01 12:00:00 +0000
    let tomorrow = Date(timeIntervalSince1970: 1_704_153_600) // 2024-01-02 00:00:00 +0000
    let lastProductStatDate = Date(timeIntervalSince1970: 1_704_024_000)

    let legacyNativeData = Data("""
    {"typedWords":2,"typedSymbols":3,"automaticSwitches":4,"manualSwitches":5}
    """.utf8)
    let legacyNativeSnapshot = try JSONDecoder().decode(ProductStatisticsSnapshot.self, from: legacyNativeData)
    try expect(
        legacyNativeSnapshot,
        ProductStatisticsSnapshot(typedWords: 2, typedSymbols: 3, automaticSwitches: 4, manualSwitches: 5, reverts: 0),
        "product statistics snapshot decodes older native payloads without reverts"
    )

    try expect(
        ProductStatisticsPolicy.normalized(ProductStatisticsSnapshot(
            typedWords: -1,
            typedSymbols: -2,
            automaticSwitches: -3,
            manualSwitches: -4,
            reverts: -5
        )),
        ProductStatisticsSnapshot(),
        "product statistics policy clamps negative persisted counters"
    )

    var snapshot = ProductStatisticsSnapshot()
    snapshot = ProductStatisticsPolicy.snapshot(after: .typedText("ab в\n "), current: snapshot, now: today, calendar: utcCalendar)
    try expect(
        snapshot,
        ProductStatisticsSnapshot(
            typedWords: 0,
            typedSymbols: 3,
            automaticSwitches: 0,
            manualSwitches: 0,
            lastDayuseDate: today
        ),
        "product statistics policy counts typed non-whitespace symbols"
    )
    snapshot = ProductStatisticsPolicy.snapshot(after: .completedWord, current: snapshot, now: today, calendar: utcCalendar)
    snapshot = ProductStatisticsPolicy.snapshot(after: .manualSwitch, current: snapshot, now: today, calendar: utcCalendar)
    snapshot = ProductStatisticsPolicy.snapshot(after: .automaticSwitch, current: snapshot, now: today, calendar: utcCalendar)
    snapshot = ProductStatisticsPolicy.snapshot(after: .revert, current: snapshot, now: today, calendar: utcCalendar)
    try expect(
        snapshot,
        ProductStatisticsSnapshot(
            typedWords: 1,
            typedSymbols: 3,
            automaticSwitches: 1,
            manualSwitches: 1,
            reverts: 1,
            lastDayuseDate: today
        ),
        "product statistics policy increments Punto Switcher-style counters"
    )
    try expect(
        ProductStatisticsPolicy.typedSymbolCount(nil),
        0,
        "product statistics policy ignores missing typed text"
    )
    try expect(
        ProductStatisticsPolicy.snapshot(after: .typedText("\n\t "), current: snapshot, now: laterToday, calendar: utcCalendar),
        snapshot,
        "product statistics policy ignores whitespace-only typed text"
    )
    try expect(
        ProductStatisticsPolicy.eventAfterCompletedTokenConsumption(true),
        .completedWord,
        "product statistics policy records completed words when a token is consumed outside autocorrect"
    )
    try expect(
        ProductStatisticsPolicy.eventAfterCompletedTokenConsumption(false),
        nil,
        "product statistics policy skips completed-word event without a consumed token"
    )
    try expect(
        ProductStatisticsPolicy.snapshot(
            after: .completedWord,
            current: ProductStatisticsSnapshot(
                typedWords: 2,
                typedSymbols: 9,
                automaticSwitches: 3,
                manualSwitches: 4,
                reverts: 5,
                lastDayuseDate: today,
                lastProductStatDate: lastProductStatDate
            ),
            now: tomorrow,
            calendar: utcCalendar
        ),
        ProductStatisticsSnapshot(
            typedWords: 1,
            typedSymbols: 0,
            automaticSwitches: 0,
            manualSwitches: 0,
            reverts: 0,
            lastDayuseDate: tomorrow,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy resets day-use counters when the day changes"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromLegacyCounters(
            typedWords: 2,
            typedSymbols: -1,
            automaticSwitches: nil,
            manualSwitches: 3,
            reverts: 4,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        ProductStatisticsSnapshot(
            typedWords: 2,
            typedSymbols: 0,
            automaticSwitches: 0,
            manualSwitches: 3,
            reverts: 4,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy reads Punto Switcher-style individual counters"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromLegacyCounters(
            typedWords: nil,
            typedSymbols: nil,
            automaticSwitches: nil,
            manualSwitches: nil,
            reverts: nil,
            lastDayuseDate: nil,
            lastProductStatDate: nil
        ),
        nil,
        "product statistics policy ignores missing legacy counters"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromDayuseSettings([
            "TypedWords": 109879,
            "TypedSymbols": NSNumber(value: 375547),
            "AutoSwitches": -1,
            "ManualSwitches": 901,
            "Reverts": 12,
            "LastDayuseDate": today,
            "LastProductStatDate": lastProductStatDate
        ]),
        ProductStatisticsSnapshot(
            typedWords: 109879,
            typedSymbols: 375547,
            automaticSwitches: 0,
            manualSwitches: 901,
            reverts: 12,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy reads Punto Switcher PSDayuseSettings counters and dates"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromDayuseSettings([
            "TypedWords": " 109879 ",
            "TypedSymbols": "375547",
            "AutoSwitches": "-1",
            "ManualSwitches": "901",
            "Reverts": "12",
            "LastDayuseDate": "2024-01-01 00:00:00 +0000",
            "LastProductStatDate": "2023-12-31 12:00:00 +0000"
        ]),
        ProductStatisticsSnapshot(
            typedWords: 109879,
            typedSymbols: 375547,
            automaticSwitches: 0,
            manualSwitches: 901,
            reverts: 12,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy reads string-backed Punto Switcher PSDayuseSettings counters and dates"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromLegacySources(
            typedWords: 10,
            typedSymbols: nil,
            automaticSwitches: nil,
            manualSwitches: 40,
            reverts: nil,
            dayuseSettings: [
                "TypedWords": 1,
                "TypedSymbols": 20,
                "AutoSwitches": 30,
                "ManualSwitches": 4,
                "Reverts": 50,
                "LastDayuseDate": today,
                "LastProductStatDate": lastProductStatDate
            ]
        ),
        ProductStatisticsSnapshot(
            typedWords: 10,
            typedSymbols: 20,
            automaticSwitches: 30,
            manualSwitches: 40,
            reverts: 50,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy merges partial legacy counters with Punto Switcher PSDayuseSettings"
    )
    try expect(
        ProductStatisticsPolicy.snapshotFromLegacySources(
            typedWords: nil,
            typedSymbols: -2,
            automaticSwitches: nil,
            manualSwitches: nil,
            reverts: nil,
            dayuseSettings: [
                "TypedWords": 1,
                "TypedSymbols": 20,
                "AutoSwitches": 30,
                "ManualSwitches": 40,
                "Reverts": 50
            ]
        ),
        ProductStatisticsSnapshot(
            typedWords: 1,
            typedSymbols: 0,
            automaticSwitches: 30,
            manualSwitches: 40,
            reverts: 50
        ),
        "product statistics policy lets present stale individual counters override matching dayuse fields only"
    )
    try expect(
        ProductStatisticsPolicy.dayuseSettingsKey,
        "PSDayuseSettings",
        "product statistics policy preserves observed dayuse settings key"
    )
    try expect(
        ProductStatisticsPolicy.legacyTypedWordsKey,
        "typedWords",
        "product statistics policy owns legacy typed-words counter key"
    )
    try expect(
        ProductStatisticsPolicy.legacyTypedSymbolsKey,
        "typedSymbols",
        "product statistics policy owns legacy typed-symbols counter key"
    )
    try expect(
        ProductStatisticsPolicy.legacyAutomaticSwitchesKey,
        "automaticSwitches",
        "product statistics policy owns legacy automatic-switch counter key"
    )
    try expect(
        ProductStatisticsPolicy.legacyManualSwitchesKey,
        "manualSwitches",
        "product statistics policy owns legacy manual-switch counter key"
    )
    try expect(
        ProductStatisticsPolicy.legacyRevertsKey,
        "reverts",
        "product statistics policy owns legacy revert counter key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.dayuseStatClassName,
        "PSDayuseStat",
        "product statistics policy preserves observed dayuse stat class boundary"
    )
    try expect(
        ProductStatisticsPolicy.dayuseLastDayuseDateKey,
        "LastDayuseDate",
        "product statistics policy preserves observed dayuse date key"
    )
    try expect(
        ProductStatisticsPolicy.dayuseLastProductStatDateKey,
        "LastProductStatDate",
        "product statistics policy preserves observed product stat date key"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setDayuseSelector,
        "setDayuse:",
        "product statistics policy preserves observed setDayuse selector"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setTypedWordsSelector,
        "setTypedWords:",
        "product statistics policy preserves observed typed words setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setTypedSymbolsSelector,
        "setTypedSymbols:",
        "product statistics policy preserves observed typed symbols setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setAutomaticSwitchesSelector,
        "setAutomaticSwitches:",
        "product statistics policy preserves observed automatic switches setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setManualSwitchesSelector,
        "setManualSwitches:",
        "product statistics policy preserves observed manual switches setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.setRevertsSelector,
        "setReverts:",
        "product statistics policy preserves observed reverts setter"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.typedSymbolMetricName,
        "product.typed.symbol",
        "product statistics policy preserves observed typed-symbol metric name"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.typedWordMetricName,
        "product.typed.word",
        "product statistics policy preserves observed typed-word metric name"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.automaticSwitchMetricName,
        "product.switch.auto",
        "product statistics policy preserves observed automatic-switch metric name"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.manualSwitchMetricName,
        "product.switch.manual",
        "product statistics policy preserves observed manual-switch metric name"
    )
    try expect(
        PuntoSwitcherObservedSurface.ProductStatistics.revertMetricName,
        "product.switch.reverse",
        "product statistics policy preserves observed revert metric name"
    )
    try expect(
        ProductStatisticsPolicy.typedSymbolMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.typedSymbolMetricName,
        "product statistics policy keeps typed-symbol metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.typedWordMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.typedWordMetricName,
        "product statistics policy keeps typed-word metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.automaticSwitchMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.automaticSwitchMetricName,
        "product statistics policy keeps automatic-switch metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.manualSwitchMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.manualSwitchMetricName,
        "product statistics policy keeps manual-switch metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.revertMetricName,
        PuntoSwitcherObservedSurface.ProductStatistics.revertMetricName,
        "product statistics policy keeps revert metric aligned with reverse-audit anchor"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .typedText("a ")),
        "product.typed.symbol",
        "product statistics policy maps typed-symbol events to observed metric name"
    )
    try expectNil(
        ProductStatisticsPolicy.metricName(for: .typedText("\n\t ")),
        "product statistics policy skips observed typed-symbol metric for whitespace-only text"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .completedWord),
        "product.typed.word",
        "product statistics policy maps completed words to observed metric name"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .automaticSwitch),
        "product.switch.auto",
        "product statistics policy maps automatic switches to observed metric name"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .manualSwitch),
        "product.switch.manual",
        "product statistics policy maps manual switches to observed metric name"
    )
    try expect(
        ProductStatisticsPolicy.metricName(for: .revert),
        "product.switch.reverse",
        "product statistics policy maps reverts to observed metric name"
    )
    try expect(
        ProductStatisticsPolicy.effectiveSnapshot(
            persistedSnapshot: ProductStatisticsSnapshot(typedWords: 5),
            legacyCountersSnapshot: ProductStatisticsSnapshot(typedWords: 1)
        ),
        ProductStatisticsSnapshot(typedWords: 5),
        "product statistics policy prefers native snapshot over legacy counters"
    )
    try expect(
        ProductStatisticsPolicy.effectiveSnapshot(
            persistedSnapshot: nil,
            legacyCountersSnapshot: ProductStatisticsSnapshot(typedSymbols: 7)
        ),
        ProductStatisticsSnapshot(typedSymbols: 7),
        "product statistics policy falls back to legacy counters"
    )
}

func runApplicationUpdateSettingsPolicyTests() throws {
    try expect(
        ApplicationUpdateSettingsPolicy.configVersionKey,
        "configVersion",
        "update settings policy preserves observed config-version key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.isFirstInstallationKey,
        "isFirstInstallation",
        "update settings policy preserves observed first-install key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.isJustInstalledKey,
        "isJustInstalled",
        "update settings policy preserves observed just-installed key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.isJustUpdatedKey,
        "isJustUpdated",
        "update settings policy preserves observed just-updated key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.isUpdatingKey,
        "isUpdating",
        "update settings policy preserves observed updating key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.shouldCheckForUpdatesAutomaticallyKey,
        "shouldCheckForUpdatesAutomatically",
        "update settings policy preserves observed automatic-update-check key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey,
        "updateRequestRateInDays",
        "update settings policy preserves observed update-request-rate key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.lastStatisticsRequestDateKey,
        "lastStatisticsRequestDate",
        "update settings policy preserves observed statistics-request date key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.lastUpdateRequestDateKey,
        "lastUpdateRequestDate",
        "update settings policy preserves observed update-request date key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.lastUpdateShownDateKey,
        "lastUpdateShownDate",
        "update settings policy preserves observed update-shown date key"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.configVersion,
        8,
        "update settings policy defaults to observed Punto Switcher config version"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.isUpdating,
        false,
        "update settings policy defaults to non-updating state"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.shouldCheckForUpdatesAutomatically,
        true,
        "update settings policy mirrors observed automatic update check preference"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.updateRequestRateInDays,
        0,
        "update settings policy mirrors observed update request rate"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.defaultSnapshot.lastStatisticsRequestDate,
        ApplicationUpdateSettingsPolicy.legacyInitialDate,
        "update settings policy mirrors observed initial statistics date"
    )
    try expect(
        ApplicationUpdateSettingsPolicy.snapshot(from: [
            ApplicationUpdateSettingsPolicy.configVersionKey: NSNumber(value: 8),
            ApplicationUpdateSettingsPolicy.isFirstInstallationKey: NSNumber(value: true),
            ApplicationUpdateSettingsPolicy.isJustInstalledKey: NSNumber(value: false),
            ApplicationUpdateSettingsPolicy.isJustUpdatedKey: NSNumber(value: false),
            ApplicationUpdateSettingsPolicy.isUpdatingKey: NSNumber(value: false),
            ApplicationUpdateSettingsPolicy.shouldCheckForUpdatesAutomaticallyKey: NSNumber(value: true),
            ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey: NSNumber(value: 0),
            ApplicationUpdateSettingsPolicy.lastStatisticsRequestDateKey: "2008-12-31 21:00:00 +0000",
            ApplicationUpdateSettingsPolicy.lastUpdateShownDateKey: "2008-12-31 21:00:00 +0000"
        ]),
        ApplicationUpdateSettingsPolicy.defaultSnapshot,
        "update settings policy reads observed Punto Switcher updater/install state"
    )

    let updateRequestDate = Date(timeIntervalSince1970: 1_768_132_509)
    let snapshot = ApplicationUpdateSettingsPolicy.snapshot(from: [
        ApplicationUpdateSettingsPolicy.configVersionKey: "9",
        ApplicationUpdateSettingsPolicy.isFirstInstallationKey: "0",
        ApplicationUpdateSettingsPolicy.isJustInstalledKey: "yes",
        ApplicationUpdateSettingsPolicy.isJustUpdatedKey: NSNumber(value: true),
        ApplicationUpdateSettingsPolicy.isUpdatingKey: "false",
        ApplicationUpdateSettingsPolicy.shouldCheckForUpdatesAutomaticallyKey: "no",
        ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey: " 14 ",
        ApplicationUpdateSettingsPolicy.lastStatisticsRequestDateKey: ApplicationUpdateSettingsPolicy.legacyInitialDate,
        ApplicationUpdateSettingsPolicy.lastUpdateRequestDateKey: updateRequestDate.timeIntervalSince1970,
        ApplicationUpdateSettingsPolicy.lastUpdateShownDateKey: "2008-12-31 21:00:00 +0000"
    ])
    try expect(snapshot.configVersion, 9, "update settings policy parses string config version")
    try expect(snapshot.isFirstInstallation, false, "update settings policy parses string first-install flag")
    try expect(snapshot.isJustInstalled, true, "update settings policy parses yes boolean")
    try expect(snapshot.isJustUpdated, true, "update settings policy parses NSNumber boolean")
    try expect(snapshot.isUpdating, false, "update settings policy parses false boolean")
    try expect(snapshot.shouldCheckForUpdatesAutomatically, false, "update settings policy parses no boolean")
    try expect(snapshot.updateRequestRateInDays, 14, "update settings policy parses string update request rate")
    try expect(snapshot.lastUpdateRequestDate, updateRequestDate, "update settings policy parses numeric date")

    let clamped = ApplicationUpdateSettingsPolicy.snapshot(from: [
        ApplicationUpdateSettingsPolicy.configVersionKey: -1,
        ApplicationUpdateSettingsPolicy.updateRequestRateInDaysKey: -7
    ])
    try expect(clamped.configVersion, 0, "update settings policy clamps negative config version")
    try expect(clamped.updateRequestRateInDays, 0, "update settings policy clamps negative update request rate")

    let encoded = try JSONEncoder().encode(snapshot)
    let decoded = try JSONDecoder().decode(ApplicationUpdateSettingsSnapshot.self, from: encoded)
    try expect(decoded, snapshot, "update settings snapshot supports native Codable persistence")

    let normalized = ApplicationUpdateSettingsPolicy.normalized(
        ApplicationUpdateSettingsSnapshot(
            configVersion: -2,
            isFirstInstallation: false,
            isJustInstalled: true,
            isJustUpdated: true,
            isUpdating: false,
            shouldCheckForUpdatesAutomatically: false,
            updateRequestRateInDays: -5,
            lastStatisticsRequestDate: nil,
            lastUpdateRequestDate: updateRequestDate,
            lastUpdateShownDate: nil
        )
    )
    try expect(normalized.configVersion, 0, "update settings native snapshot clamps config version")
    try expect(normalized.updateRequestRateInDays, 0, "update settings native snapshot clamps update rate")
    try expect(normalized.isJustInstalled, true, "update settings native snapshot preserves install flag")
    try expect(normalized.lastUpdateRequestDate, updateRequestDate, "update settings native snapshot preserves update date")
}
