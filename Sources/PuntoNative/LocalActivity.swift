import AppKit
import Combine
import PuntoCore

final class LocalActivity: ObservableObject {
    @Published private(set) var snapshot: ActivityHistory
    private var history: ActivityHistory
    private let file: URL
    private var tick: DispatchWorkItem?
    private var dirty = false
    private var hour: DateInterval?
    private var dayKey = 0
    private var interval = 0
    private var calendar = LocalActivity.localCalendar
    private var timeZoneObserver: NSObjectProtocol?

    init(folder: URL) {
        file = folder.appendingPathComponent("activity-206.json")
        let existing = (try? Data(contentsOf: file)).flatMap { try? JSONDecoder().decode(ActivityHistory.self, from: $0) }
        var initial = existing ?? ActivityHistory()
        initial.begin(on: ActivityHistory.dayKey(Date(), calendar: calendar))
        snapshot = initial
        history = initial
        timeZoneObserver = NotificationCenter.default.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.hour = nil
        }
        if existing == nil {
            dirty = true
            scheduleWrite()
        }
    }

    deinit {
        if let timeZoneObserver { NotificationCenter.default.removeObserver(timeZoneObserver) }
    }

    static var localCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }

    func typed(_ number: Int) {
        var counts = ActivityCounts()
        counts.symbols = number
        record(counts)
    }

    func converted(automatic: Bool) {
        var counts = ActivityCounts()
        if automatic { counts.automatic = 1 } else { counts.manual = 1 }
        record(counts)
    }

    func flush() {
        guard dirty else { return }
        tick?.cancel()
        tick = nil
        let now = Date()
        if let oldest = calendar.date(byAdding: .day, value: -14, to: now) {
            history.prune(before: ActivityHistory.dayKey(oldest, calendar: calendar))
        }
        snapshot = history
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(history).write(to: file, options: .atomic)
            dirty = false
        } catch {
            // Keep the counts in memory and try again after the next input or at shutdown.
        }
    }

    private func record(_ counts: ActivityCounts) {
        let now = Date()
        if hour.map({ now >= $0.end || now < $0.start }) ?? true {
            calendar = Self.localCalendar
            hour = calendar.dateInterval(of: .hour, for: now)
            dayKey = ActivityHistory.dayKey(now, calendar: calendar)
            interval = calendar.component(.hour, from: now) / 3
        }
        history.record(counts, day: dayKey, interval: interval)
        dirty = true
        scheduleWrite()
    }

    private func scheduleWrite() {
        guard tick == nil else { return }
        let task = DispatchWorkItem { [weak self] in self?.flush() }
        tick = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: task)
    }
}
