import Foundation
import PuntoCore

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
        ProductStatisticsPolicy.currentDaySnapshot(
            ProductStatisticsSnapshot(
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
            typedWords: 0,
            typedSymbols: 0,
            automaticSwitches: 0,
            manualSwitches: 0,
            reverts: 0,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy exposes current-day rollover without recording new activity"
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
    try expect(
        ProductStatisticsPolicy.effectiveSnapshot(
            persistedSnapshot: ProductStatisticsSnapshot(
                typedWords: 5,
                typedSymbols: 6,
                automaticSwitches: 7,
                manualSwitches: 8,
                reverts: 9,
                lastDayuseDate: today,
                lastProductStatDate: lastProductStatDate
            ),
            legacyCountersSnapshot: ProductStatisticsSnapshot(typedWords: 1),
            now: tomorrow,
            calendar: utcCalendar
        ),
        ProductStatisticsSnapshot(
            typedWords: 0,
            typedSymbols: 0,
            automaticSwitches: 0,
            manualSwitches: 0,
            reverts: 0,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy rolls over native day-use counters when resolving current statistics"
    )
    try expect(
        ProductStatisticsPolicy.effectiveSnapshot(
            persistedSnapshot: nil,
            legacyCountersSnapshot: ProductStatisticsSnapshot(
                typedWords: 5,
                typedSymbols: 6,
                automaticSwitches: 7,
                manualSwitches: 8,
                reverts: 9,
                lastDayuseDate: today,
                lastProductStatDate: lastProductStatDate
            ),
            now: tomorrow,
            calendar: utcCalendar
        ),
        ProductStatisticsSnapshot(
            typedWords: 0,
            typedSymbols: 0,
            automaticSwitches: 0,
            manualSwitches: 0,
            reverts: 0,
            lastDayuseDate: today,
            lastProductStatDate: lastProductStatDate
        ),
        "product statistics policy rolls over imported legacy day-use counters when resolving current statistics"
    )
}
