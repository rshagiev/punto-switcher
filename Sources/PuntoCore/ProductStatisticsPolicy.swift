import Foundation

public struct ProductStatisticsSnapshot: Codable, Equatable {
    public let typedWords: Int
    public let typedSymbols: Int
    public let automaticSwitches: Int
    public let manualSwitches: Int
    public let reverts: Int
    public let lastDayuseDate: Date?
    public let lastProductStatDate: Date?

    private enum CodingKeys: String, CodingKey {
        case typedWords
        case typedSymbols
        case automaticSwitches
        case manualSwitches
        case reverts
        case lastDayuseDate
        case lastProductStatDate
    }

    public init(
        typedWords: Int = 0,
        typedSymbols: Int = 0,
        automaticSwitches: Int = 0,
        manualSwitches: Int = 0,
        reverts: Int = 0,
        lastDayuseDate: Date? = nil,
        lastProductStatDate: Date? = nil
    ) {
        self.typedWords = typedWords
        self.typedSymbols = typedSymbols
        self.automaticSwitches = automaticSwitches
        self.manualSwitches = manualSwitches
        self.reverts = reverts
        self.lastDayuseDate = lastDayuseDate
        self.lastProductStatDate = lastProductStatDate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.typedWords = try container.decodeIfPresent(Int.self, forKey: .typedWords) ?? 0
        self.typedSymbols = try container.decodeIfPresent(Int.self, forKey: .typedSymbols) ?? 0
        self.automaticSwitches = try container.decodeIfPresent(Int.self, forKey: .automaticSwitches) ?? 0
        self.manualSwitches = try container.decodeIfPresent(Int.self, forKey: .manualSwitches) ?? 0
        self.reverts = try container.decodeIfPresent(Int.self, forKey: .reverts) ?? 0
        self.lastDayuseDate = try container.decodeIfPresent(Date.self, forKey: .lastDayuseDate)
        self.lastProductStatDate = try container.decodeIfPresent(Date.self, forKey: .lastProductStatDate)
    }
}

public enum ProductStatisticsEvent: Equatable {
    case typedText(String?)
    case completedWord
    case manualSwitch
    case automaticSwitch
    case revert
}

public enum ProductStatisticsPolicy {
    public static let emptySnapshot = ProductStatisticsSnapshot()
    public static let defaultSnapshot = emptySnapshot
    public static let legacyDayuseSettingsKey = "PSDayuseSettings"
    public static let legacyDayuseTypedWordsKey = "TypedWords"
    public static let legacyDayuseTypedSymbolsKey = "TypedSymbols"
    public static let legacyDayuseAutoSwitchesKey = "AutoSwitches"
    public static let legacyDayuseManualSwitchesKey = "ManualSwitches"
    public static let legacyDayuseRevertsKey = "Reverts"
    public static let legacyDayuseLastDayuseDateKey = "LastDayuseDate"
    public static let legacyDayuseLastProductStatDateKey = "LastProductStatDate"
    public static let typedSymbolMetricName = "product.typed.symbol"
    public static let typedWordMetricName = "product.typed.word"
    public static let automaticSwitchMetricName = "product.switch.auto"
    public static let manualSwitchMetricName = "product.switch.manual"
    public static let revertMetricName = "product.switch.reverse"
    public static let legacyTypedWordsKey = "typedWords"
    public static let legacyTypedSymbolsKey = "typedSymbols"
    public static let legacyAutomaticSwitchesKey = "automaticSwitches"
    public static let legacyManualSwitchesKey = "manualSwitches"
    public static let legacyRevertsKey = "reverts"

    public static func normalized(_ snapshot: ProductStatisticsSnapshot) -> ProductStatisticsSnapshot {
        ProductStatisticsSnapshot(
            typedWords: max(0, snapshot.typedWords),
            typedSymbols: max(0, snapshot.typedSymbols),
            automaticSwitches: max(0, snapshot.automaticSwitches),
            manualSwitches: max(0, snapshot.manualSwitches),
            reverts: max(0, snapshot.reverts),
            lastDayuseDate: snapshot.lastDayuseDate,
            lastProductStatDate: snapshot.lastProductStatDate
        )
    }

    public static func snapshot(
        after event: ProductStatisticsEvent,
        current: ProductStatisticsSnapshot,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ProductStatisticsSnapshot {
        let current = currentDaySnapshot(current, now: now, calendar: calendar)
        switch event {
        case .typedText(let text):
            let symbolCount = typedSymbolCount(text)
            guard symbolCount > 0 else {
                return current
            }
            return ProductStatisticsSnapshot(
                typedWords: current.typedWords,
                typedSymbols: current.typedSymbols + symbolCount,
                automaticSwitches: current.automaticSwitches,
                manualSwitches: current.manualSwitches,
                reverts: current.reverts,
                lastDayuseDate: now,
                lastProductStatDate: current.lastProductStatDate
            )
        case .completedWord:
            return ProductStatisticsSnapshot(
                typedWords: current.typedWords + 1,
                typedSymbols: current.typedSymbols,
                automaticSwitches: current.automaticSwitches,
                manualSwitches: current.manualSwitches,
                reverts: current.reverts,
                lastDayuseDate: now,
                lastProductStatDate: current.lastProductStatDate
            )
        case .manualSwitch:
            return ProductStatisticsSnapshot(
                typedWords: current.typedWords,
                typedSymbols: current.typedSymbols,
                automaticSwitches: current.automaticSwitches,
                manualSwitches: current.manualSwitches + 1,
                reverts: current.reverts,
                lastDayuseDate: now,
                lastProductStatDate: current.lastProductStatDate
            )
        case .automaticSwitch:
            return ProductStatisticsSnapshot(
                typedWords: current.typedWords,
                typedSymbols: current.typedSymbols,
                automaticSwitches: current.automaticSwitches + 1,
                manualSwitches: current.manualSwitches,
                reverts: current.reverts,
                lastDayuseDate: now,
                lastProductStatDate: current.lastProductStatDate
            )
        case .revert:
            return ProductStatisticsSnapshot(
                typedWords: current.typedWords,
                typedSymbols: current.typedSymbols,
                automaticSwitches: current.automaticSwitches,
                manualSwitches: current.manualSwitches,
                reverts: current.reverts + 1,
                lastDayuseDate: now,
                lastProductStatDate: current.lastProductStatDate
            )
        }
    }

    public static func eventAfterCompletedTokenConsumption(_ consumedCompletedToken: Bool) -> ProductStatisticsEvent? {
        consumedCompletedToken ? .completedWord : nil
    }

    public static func metricName(for event: ProductStatisticsEvent) -> String? {
        switch event {
        case .typedText(let text):
            typedSymbolCount(text) > 0 ? typedSymbolMetricName : nil
        case .completedWord:
            typedWordMetricName
        case .automaticSwitch:
            automaticSwitchMetricName
        case .manualSwitch:
            manualSwitchMetricName
        case .revert:
            revertMetricName
        }
    }

    public static func snapshotFromLegacyCounters(
        typedWords: Int?,
        typedSymbols: Int?,
        automaticSwitches: Int?,
        manualSwitches: Int?,
        reverts: Int? = nil,
        lastDayuseDate: Date? = nil,
        lastProductStatDate: Date? = nil
    ) -> ProductStatisticsSnapshot? {
        guard typedWords != nil ||
                typedSymbols != nil ||
                automaticSwitches != nil ||
                manualSwitches != nil ||
                reverts != nil ||
                lastDayuseDate != nil ||
                lastProductStatDate != nil else {
            return nil
        }

        return normalized(ProductStatisticsSnapshot(
            typedWords: typedWords ?? 0,
            typedSymbols: typedSymbols ?? 0,
            automaticSwitches: automaticSwitches ?? 0,
            manualSwitches: manualSwitches ?? 0,
            reverts: reverts ?? 0,
            lastDayuseDate: lastDayuseDate,
            lastProductStatDate: lastProductStatDate
        ))
    }

    public static func snapshotFromDayuseSettings(_ settings: [String: Any]?) -> ProductStatisticsSnapshot? {
        guard let settings else {
            return nil
        }

        return snapshotFromLegacyCounters(
            typedWords: LegacyValuePolicy.int(settings[legacyDayuseTypedWordsKey]),
            typedSymbols: LegacyValuePolicy.int(settings[legacyDayuseTypedSymbolsKey]),
            automaticSwitches: LegacyValuePolicy.int(settings[legacyDayuseAutoSwitchesKey]),
            manualSwitches: LegacyValuePolicy.int(settings[legacyDayuseManualSwitchesKey]),
            reverts: LegacyValuePolicy.int(settings[legacyDayuseRevertsKey]),
            lastDayuseDate: LegacyValuePolicy.date(settings[legacyDayuseLastDayuseDateKey]),
            lastProductStatDate: LegacyValuePolicy.date(settings[legacyDayuseLastProductStatDateKey])
        )
    }

    public static func snapshotFromLegacySources(
        typedWords: Int?,
        typedSymbols: Int?,
        automaticSwitches: Int?,
        manualSwitches: Int?,
        reverts: Int? = nil,
        dayuseSettings: [String: Any]?
    ) -> ProductStatisticsSnapshot? {
        let dayuseSnapshot = snapshotFromDayuseSettings(dayuseSettings)
        guard typedWords != nil ||
                typedSymbols != nil ||
                automaticSwitches != nil ||
                manualSwitches != nil ||
                reverts != nil ||
                dayuseSnapshot != nil else {
            return nil
        }

        return normalized(ProductStatisticsSnapshot(
            typedWords: typedWords ?? dayuseSnapshot?.typedWords ?? 0,
            typedSymbols: typedSymbols ?? dayuseSnapshot?.typedSymbols ?? 0,
            automaticSwitches: automaticSwitches ?? dayuseSnapshot?.automaticSwitches ?? 0,
            manualSwitches: manualSwitches ?? dayuseSnapshot?.manualSwitches ?? 0,
            reverts: reverts ?? dayuseSnapshot?.reverts ?? 0,
            lastDayuseDate: dayuseSnapshot?.lastDayuseDate,
            lastProductStatDate: dayuseSnapshot?.lastProductStatDate
        ))
    }

    public static func effectiveSnapshot(
        persistedSnapshot: ProductStatisticsSnapshot?,
        legacyCountersSnapshot: ProductStatisticsSnapshot?,
        now: Date? = nil,
        calendar: Calendar = .current
    ) -> ProductStatisticsSnapshot {
        let snapshot: ProductStatisticsSnapshot
        if let persistedSnapshot {
            snapshot = normalized(persistedSnapshot)
        } else if let legacyCountersSnapshot {
            snapshot = normalized(legacyCountersSnapshot)
        } else {
            snapshot = emptySnapshot
        }

        guard let now else {
            return snapshot
        }
        return currentDaySnapshot(snapshot, now: now, calendar: calendar)
    }

    public static func typedSymbolCount(_ text: String?) -> Int {
        guard let text else {
            return 0
        }
        return text.filter { !$0.isNewline && !$0.isWhitespace }.count
    }

    public static func currentDaySnapshot(
        _ snapshot: ProductStatisticsSnapshot,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ProductStatisticsSnapshot {
        snapshotForCurrentDay(normalized(snapshot), now: now, calendar: calendar)
    }

    private static func snapshotForCurrentDay(
        _ snapshot: ProductStatisticsSnapshot,
        now: Date,
        calendar: Calendar
    ) -> ProductStatisticsSnapshot {
        guard let lastDayuseDate = snapshot.lastDayuseDate else {
            return snapshot
        }

        guard !calendar.isDate(lastDayuseDate, inSameDayAs: now) else {
            return snapshot
        }

        return ProductStatisticsSnapshot(
            lastDayuseDate: lastDayuseDate,
            lastProductStatDate: snapshot.lastProductStatDate
        )
    }
}
