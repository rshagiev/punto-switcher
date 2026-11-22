import Foundation

public struct SupportInvitation: Codable, Equatable {
    private var cycle: UUID?
    private var shown = false
    private var dismissed = false
    private var remindAfter: Date?

    public init() {}

    public mutating func qualify() {
        guard cycle == nil, !dismissed else { return }
        cycle = UUID()
    }

    public func available(at date: Date) -> UUID? {
        guard !dismissed, (remindAfter ?? .distantPast) <= date else { return nil }
        return cycle
    }

    public mutating func registerShow(at date: Date) -> UUID? {
        guard !shown, let cycle = available(at: date) else { return nil }
        shown = true
        return cycle
    }

    public mutating func snooze(at date: Date) {
        guard available(at: date) != nil else { return }
        remindAfter = date.addingTimeInterval(3 * 24 * 60 * 60)
        cycle = UUID()
        shown = false
    }

    public mutating func dismiss() {
        dismissed = true
        cycle = nil
        remindAfter = nil
    }
}
