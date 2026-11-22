import Foundation

public struct ActivityCounts: Codable, Equatable {
    public var symbols = 0
    public var automatic = 0
    public var manual = 0

    public init() {}

    public static func + (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result.symbols += rhs.symbols
        result.automatic += rhs.automatic
        result.manual += rhs.manual
        return result
    }
}

public struct ActivityDay: Codable, Equatable {
    public private(set) var intervals: [Int: ActivityCounts] = [:]
    public var totals: ActivityCounts { intervals.values.reduce(ActivityCounts(), +) }

    mutating func record(_ counts: ActivityCounts, interval: Int) {
        intervals[interval, default: ActivityCounts()] = self[interval] + counts
    }

    public subscript(interval: Int) -> ActivityCounts { intervals[interval] ?? ActivityCounts() }
}

public struct ActivityHistory: Codable, Equatable {
    public private(set) var started: Int?
    public private(set) var days: [Int: ActivityDay] = [:]

    public init() {}

    public static func dayKey(_ date: Date, calendar: Calendar) -> Int {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return (parts.year ?? 0) * 10_000 + (parts.month ?? 0) * 100 + (parts.day ?? 0)
    }

    public mutating func begin(on day: Int) {
        started = min(started ?? day, day)
    }

    public mutating func record(_ counts: ActivityCounts, day: Int, interval: Int) {
        guard (0..<8).contains(interval) else { return }
        begin(on: day)
        days[day, default: ActivityDay()].record(counts, interval: interval)
    }

    public mutating func prune(before day: Int) {
        days = days.filter { $0.key >= day }
    }

    public func day(_ key: Int) -> ActivityDay? {
        guard let started, key >= started else { return nil }
        return days[key] ?? ActivityDay()
    }
}
