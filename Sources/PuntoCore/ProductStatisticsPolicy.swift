import Foundation

public struct ProductStatisticsSnapshot: Codable, Equatable {
    public let typedWords: Int
    public let typedSymbols: Int
    public let automaticSwitches: Int
    public let manualSwitches: Int
    public let reverts: Int

    private enum CodingKeys: String, CodingKey {
        case typedWords
        case typedSymbols
        case automaticSwitches
        case manualSwitches
        case reverts
    }

    public init(
        typedWords: Int = 0,
        typedSymbols: Int = 0,
        automaticSwitches: Int = 0,
        manualSwitches: Int = 0,
        reverts: Int = 0
    ) {
        self.typedWords = typedWords
        self.typedSymbols = typedSymbols
        self.automaticSwitches = automaticSwitches
        self.manualSwitches = manualSwitches
        self.reverts = reverts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.typedWords = try container.decodeIfPresent(Int.self, forKey: .typedWords) ?? 0
        self.typedSymbols = try container.decodeIfPresent(Int.self, forKey: .typedSymbols) ?? 0
        self.automaticSwitches = try container.decodeIfPresent(Int.self, forKey: .automaticSwitches) ?? 0
        self.manualSwitches = try container.decodeIfPresent(Int.self, forKey: .manualSwitches) ?? 0
        self.reverts = try container.decodeIfPresent(Int.self, forKey: .reverts) ?? 0
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
    public static let dayuseSettingsKey = "PSDayuseSettings"
    public static let dayuseTypedWordsKey = "TypedWords"
    public static let dayuseTypedSymbolsKey = "TypedSymbols"
    public static let dayuseAutoSwitchesKey = "AutoSwitches"
    public static let dayuseManualSwitchesKey = "ManualSwitches"
    public static let dayuseRevertsKey = "Reverts"
    public static let dayuseLastDayuseDateKey = "LastDayuseDate"
    public static let dayuseLastProductStatDateKey = "LastProductStatDate"
    public static let observedDayuseStatClassName = "PSDayuseStat"
    public static let observedSetDayuseSelector = "setDayuse:"
    public static let observedTypedWordsAccessor = "typedWords"
    public static let observedTypedSymbolsAccessor = "typedSymbols"
    public static let observedLastDayuseDateAccessor = "lastDayuseDate"
    public static let observedLastProductStatDateAccessor = "lastProductStatDate"
    public static let observedSetTypedWordsSelector = "setTypedWords:"
    public static let observedSetTypedSymbolsSelector = "setTypedSymbols:"
    public static let observedSetAutomaticSwitchesSelector = "setAutomaticSwitches:"
    public static let observedSetManualSwitchesSelector = "setManualSwitches:"
    public static let observedSetRevertsSelector = "setReverts:"
    public static let observedSetLastDayuseDateSelector = "setLastDayuseDate:"
    public static let observedSetLastProductStatDateSelector = "setLastProductStatDate:"
    public static let observedTypedSymbolMetricName = "product.typed.symbol"
    public static let observedTypedWordMetricName = "product.typed.word"
    public static let observedAutomaticSwitchMetricName = "product.switch.auto"
    public static let observedManualSwitchMetricName = "product.switch.manual"
    public static let observedRevertMetricName = "product.switch.reverse"

    public static func normalized(_ snapshot: ProductStatisticsSnapshot) -> ProductStatisticsSnapshot {
        ProductStatisticsSnapshot(
            typedWords: max(0, snapshot.typedWords),
            typedSymbols: max(0, snapshot.typedSymbols),
            automaticSwitches: max(0, snapshot.automaticSwitches),
            manualSwitches: max(0, snapshot.manualSwitches),
            reverts: max(0, snapshot.reverts)
        )
    }

    public static func snapshot(after event: ProductStatisticsEvent, current: ProductStatisticsSnapshot) -> ProductStatisticsSnapshot {
        let current = normalized(current)
        switch event {
        case .typedText(let text):
            return ProductStatisticsSnapshot(
                typedWords: current.typedWords,
                typedSymbols: current.typedSymbols + typedSymbolCount(text),
                automaticSwitches: current.automaticSwitches,
                manualSwitches: current.manualSwitches,
                reverts: current.reverts
            )
        case .completedWord:
            return ProductStatisticsSnapshot(
                typedWords: current.typedWords + 1,
                typedSymbols: current.typedSymbols,
                automaticSwitches: current.automaticSwitches,
                manualSwitches: current.manualSwitches,
                reverts: current.reverts
            )
        case .manualSwitch:
            return ProductStatisticsSnapshot(
                typedWords: current.typedWords,
                typedSymbols: current.typedSymbols,
                automaticSwitches: current.automaticSwitches,
                manualSwitches: current.manualSwitches + 1,
                reverts: current.reverts
            )
        case .automaticSwitch:
            return ProductStatisticsSnapshot(
                typedWords: current.typedWords,
                typedSymbols: current.typedSymbols,
                automaticSwitches: current.automaticSwitches + 1,
                manualSwitches: current.manualSwitches,
                reverts: current.reverts
            )
        case .revert:
            return ProductStatisticsSnapshot(
                typedWords: current.typedWords,
                typedSymbols: current.typedSymbols,
                automaticSwitches: current.automaticSwitches,
                manualSwitches: current.manualSwitches,
                reverts: current.reverts + 1
            )
        }
    }

    public static func eventAfterCompletedTokenConsumption(_ consumedCompletedToken: Bool) -> ProductStatisticsEvent? {
        consumedCompletedToken ? .completedWord : nil
    }

    public static func observedMetricName(for event: ProductStatisticsEvent) -> String? {
        switch event {
        case .typedText(let text):
            typedSymbolCount(text) > 0 ? observedTypedSymbolMetricName : nil
        case .completedWord:
            observedTypedWordMetricName
        case .automaticSwitch:
            observedAutomaticSwitchMetricName
        case .manualSwitch:
            observedManualSwitchMetricName
        case .revert:
            observedRevertMetricName
        }
    }

    public static func snapshotFromLegacyCounters(
        typedWords: Int?,
        typedSymbols: Int?,
        automaticSwitches: Int?,
        manualSwitches: Int?,
        reverts: Int? = nil
    ) -> ProductStatisticsSnapshot? {
        guard typedWords != nil || typedSymbols != nil || automaticSwitches != nil || manualSwitches != nil || reverts != nil else {
            return nil
        }

        return normalized(ProductStatisticsSnapshot(
            typedWords: typedWords ?? 0,
            typedSymbols: typedSymbols ?? 0,
            automaticSwitches: automaticSwitches ?? 0,
            manualSwitches: manualSwitches ?? 0,
            reverts: reverts ?? 0
        ))
    }

    public static func snapshotFromDayuseSettings(_ settings: [String: Any]?) -> ProductStatisticsSnapshot? {
        guard let settings else {
            return nil
        }

        return snapshotFromLegacyCounters(
            typedWords: intValue(settings[dayuseTypedWordsKey]),
            typedSymbols: intValue(settings[dayuseTypedSymbolsKey]),
            automaticSwitches: intValue(settings[dayuseAutoSwitchesKey]),
            manualSwitches: intValue(settings[dayuseManualSwitchesKey]),
            reverts: intValue(settings[dayuseRevertsKey])
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
            reverts: reverts ?? dayuseSnapshot?.reverts ?? 0
        ))
    }

    public static func dayuseSettings(from snapshot: ProductStatisticsSnapshot, date: Date = Date()) -> [String: Any] {
        let normalized = normalized(snapshot)
        return [
            dayuseTypedWordsKey: normalized.typedWords,
            dayuseTypedSymbolsKey: normalized.typedSymbols,
            dayuseAutoSwitchesKey: normalized.automaticSwitches,
            dayuseManualSwitchesKey: normalized.manualSwitches,
            dayuseRevertsKey: normalized.reverts,
            dayuseLastDayuseDateKey: date,
            dayuseLastProductStatDateKey: date
        ]
    }

    public static func effectiveSnapshot(
        persistedSnapshot: ProductStatisticsSnapshot?,
        legacyCountersSnapshot: ProductStatisticsSnapshot?
    ) -> ProductStatisticsSnapshot {
        if let persistedSnapshot {
            return normalized(persistedSnapshot)
        }

        if let legacyCountersSnapshot {
            return normalized(legacyCountersSnapshot)
        }

        return emptySnapshot
    }

    public static func typedSymbolCount(_ text: String?) -> Int {
        guard let text else {
            return 0
        }
        return text.filter { !$0.isNewline && !$0.isWhitespace }.count
    }

    private static func intValue(_ value: Any?) -> Int? {
        switch value {
        case let value as Int:
            return value
        case let value as NSNumber:
            return value.intValue
        case let value as String:
            return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
        default:
            return nil
        }
    }
}
