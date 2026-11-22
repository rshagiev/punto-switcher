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
                    if setupComplete, let id = support.visibleID {
                        supportCard.onAppear { support.shown(id) }.id(id)
                    }
                    statistics(points: points, totals: totals)
                }
                .padding(.horizontal, 26).padding(.bottom, 20)
            }
        }
    }

    private var supportCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.fill").foregroundStyle(Color(nsColor: .systemYellow))
                .accessibilityHidden(true)
            Text(SupportMenuRow.title).font(.headline)
            Spacer()
            Button("Открыть GitHub") { support.openInvitation() }
            Button("Больше не предлагать") { support.dismiss() }
                .buttonStyle(.borderless).foregroundStyle(.secondary)
        }
        .modifier(TodayCard())
    }

    private let automaticColor = Color(nsColor: .systemBlue)
    private let manualColor = Color(red: 0.46, green: 0.56, blue: 0.71)

    private func statistics(points: [Point], totals: ActivityCounts) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                counter("Автопереключения", color: automaticColor, value: totals.automatic)
                counter("Ручные конвертации", color: manualColor, value: totals.manual)
                Picker("Период", selection: $period) {
                    ForEach(Period.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).labelsHidden().frame(width: 144)
            }

            let peak = points.compactMap { $0.counts.map { $0.automatic + $0.manual } }.max() ?? 0
            Chart(points) { point in
                if let counts = point.counts {
                    BarMark(x: .value("Интервал", point.label),
                            yStart: .value("Конвертации", 0),
                            yEnd: .value("Конвертации", counts.automatic))
                        .foregroundStyle(automaticColor)
                        .cornerRadius(3)
                        .accessibilityLabel("\(point.label), автопереключения")
                        .accessibilityValue(counts.automatic.formatted())

                    BarMark(x: .value("Интервал", point.label),
                            yStart: .value("Конвертации", counts.automatic),
                            yEnd: .value("Конвертации", counts.automatic + counts.manual))
                        .foregroundStyle(manualColor)
                        .cornerRadius(3)
                        .accessibilityLabel("\(point.label), ручные конвертации")
                        .accessibilityValue(counts.manual.formatted())
                } else {
                    PointMark(x: .value("Интервал", point.label), y: .value("Конвертации", 0))
                        .foregroundStyle(.clear)
                        .annotation(position: .top) { Text("—").font(.caption).foregroundStyle(.secondary) }
                        .accessibilityLabel(point.label)
                        .accessibilityValue("Нет истории")
                }
            }
            .chartXScale(domain: points.map(\.label))
            .chartXAxis { AxisMarks { AxisValueLabel() } }
            .chartYAxis { AxisMarks(position: .leading) { AxisGridLine(); AxisValueLabel() } }
            .chartYScale(domain: 0...max(4, peak + 1))
            .frame(height: 205)

            Divider()
            HStack {
                Label("Набрано символов", systemImage: "keyboard").foregroundStyle(.secondary)
                Spacer()
                Text(totals.symbols.formatted()).fontWeight(.semibold).monospacedDigit()
            }
            .font(.callout)
            .accessibilityElement(children: .combine)
        }
        .modifier(TodayCard())
    }

    private func counter(_ title: String, color: Color, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color).frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text(title).font(.callout).foregroundStyle(.secondary)
            }
            Text(value.formatted()).font(.system(size: 34, weight: .semibold)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func points(at now: Date) -> [Point] {
        var calendar = LocalActivity.localCalendar
        calendar.locale = Locale(identifier: "ru_RU")
        let today = ActivityHistory.dayKey(now, calendar: calendar)
        if period == .day {
            let current = activity.snapshot.day(today)
            return (0..<8).map {
                Point(label: String(format: "%02d", $0 * 3), counts: current?[$0])
            }
        }
        return (-6...0).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: now) else { return nil }
            let key = ActivityHistory.dayKey(date, calendar: calendar)
            let label = calendar.shortStandaloneWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            return Point(label: label, counts: activity.snapshot.day(key)?.totals)
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
