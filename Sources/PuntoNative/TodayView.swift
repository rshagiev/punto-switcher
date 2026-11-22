import Charts
import SwiftUI
import PuntoCore

struct TodayView: View {
    enum Period: String, CaseIterable, Identifiable {
        case day = "День", week = "Неделя"
        var id: Self { self }
    }

    private struct Point: Identifiable {
        let label: String
        let counts: ActivityCounts?
        let highlighted: Bool
        var id: String { label }
    }

    @ObservedObject var activity: LocalActivity
    @ObservedObject var support: SupportPrompt
    @Binding var period: Period
    let setupComplete: Bool

    var body: some View {
        TimelineView(.everyMinute) { time in
            let points = points(at: time.date)
            let totals = points.compactMap(\.counts).reduce(ActivityCounts(), +)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let id = support.available(setupComplete: setupComplete) {
                        supportCard.onAppear { support.shown(id) }.id(id)
                    }
                    statistics(points: points, totals: totals)
                }
                .padding(.horizontal, 26).padding(.bottom, 20)
            }
        }
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Нравится Punto Native?", systemImage: "star.fill")
                .font(.headline)
                .foregroundStyle(Color(nsColor: .systemOrange))
            Text("Звёздочка на GitHub помогает другим найти Punto.")
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button("Открыть GitHub") { support.openInvitation() }.buttonStyle(.borderedProminent)
                Button("Через 3 дня") { support.snooze() }
                Button("Больше не показывать") { support.dismiss() }.buttonStyle(.borderless)
            }
        }
        .modifier(TodayCard())
    }

    private func statistics(points: [Point], totals: ActivityCounts) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Набрано символов").font(.callout).foregroundStyle(.secondary)
                    Text(totals.symbols.formatted()).font(.system(size: 36, weight: .semibold)).monospacedDigit()
                }
                Spacer()
                Picker("Период", selection: $period) {
                    ForEach(Period.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).labelsHidden().frame(width: 170)
            }
            Chart(points) { point in
                if let counts = point.counts {
                    BarMark(x: .value("Интервал", point.label), y: .value("Символы", counts.symbols))
                        .foregroundStyle(Color.accentColor.opacity(point.highlighted ? 1 : 0.65))
                        .cornerRadius(3)
                        .accessibilityLabel(point.label)
                        .accessibilityValue(counts.symbols.formatted())
                } else {
                    PointMark(x: .value("Интервал", point.label), y: .value("Символы", 0))
                        .foregroundStyle(.clear)
                        .annotation(position: .top) { Text("—").font(.caption).foregroundStyle(.secondary) }
                        .accessibilityLabel(point.label)
                        .accessibilityValue("Нет истории")
                }
            }
            .chartXScale(domain: points.map(\.label))
            .chartYAxis { AxisMarks(position: .leading) { AxisGridLine(); AxisValueLabel() } }
            .chartYScale(domain: 0...max(4, points.compactMap { $0.counts?.symbols }.max() ?? 0))
            .frame(height: 195)
            Divider()
            HStack {
                counter("Автопереключения", icon: "bolt", value: totals.automatic)
                Spacer()
                counter("Ручные конвертации", icon: "command", value: totals.manual)
                Spacer()
            }
        }
        .modifier(TodayCard())
    }

    private func counter(_ title: String, icon: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: icon).font(.callout).foregroundStyle(.secondary)
            Text(value.formatted()).font(.title2.weight(.semibold)).monospacedDigit()
        }
    }

    private func points(at now: Date) -> [Point] {
        var calendar = LocalActivity.localCalendar
        calendar.locale = Locale(identifier: "ru_RU")
        let today = ActivityHistory.dayKey(now, calendar: calendar)
        if period == .day {
            let current = activity.snapshot.day(today)
            return (0..<8).map {
                Point(label: String(format: "%02d", $0 * 3), counts: current?[$0], highlighted: true)
            }
        }
        return (-6...0).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: now) else { return nil }
            let key = ActivityHistory.dayKey(date, calendar: calendar)
            let label = calendar.shortStandaloneWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            return Point(label: label, counts: activity.snapshot.day(key)?.totals, highlighted: offset == 0)
        }
    }
}

private struct TodayCard: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.11)))
    }
}
