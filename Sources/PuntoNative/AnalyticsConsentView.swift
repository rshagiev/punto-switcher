import AppKit
import SwiftUI

struct AnalyticsConsentView: View {
    let existing: Bool
    let version: String
    let onDone: (Bool) -> Void
    @State private var share = true
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable().interpolation(.high).frame(width: 70, height: 70)
                    .accessibilityHidden(true)
                Text(existing ? "Punto обновлён до \(version)" : "Punto готов к работе")
                    .font(.system(size: 24, weight: .semibold))
                Text(existing ? "Новая настройка конфиденциальности" : "Доступ к клавиатуре настроен.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .background(alignment: .top) { keyboardPattern }

            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $share) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Делиться данными об использовании").font(.headline)
                        Text("Версии Punto и macOS, дни активности и результаты обновлений.")
                            .font(.callout).foregroundStyle(.secondary)
                    }.fixedSize(horizontal: false, vertical: true)
                }.toggleStyle(.checkbox)
                Divider()
                Label("Текст и буфер обмена остаются на Mac.", systemImage: "lock")
                    .font(.callout).foregroundStyle(.secondary)
                if expanded {
                    Divider()
                    AnalyticsDetails()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.10)))

            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { expanded.toggle() }
                } label: {
                    Label(expanded ? "Скрыть подробности" : "Подробнее",
                          systemImage: expanded ? "chevron.up" : "chevron.down")
                }.buttonStyle(.borderless)
                Spacer()
                Button("Готово") { onDone(share) }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 450)
        .background {
            RadialGradient(colors: [.accentColor.opacity(0.17), .clear],
                           center: .top, startRadius: 8, endRadius: 245)
                .allowsHitTesting(false)
        }
    }

    private var keyboardPattern: some View {
        VStack(spacing: 4) {
            ForEach(["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"], id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(Array(row), id: \.self) { key in
                        Text(String(key)).font(.system(size: 8, weight: .medium))
                            .frame(width: 26, height: 17)
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(lineWidth: 0.6))
                    }
                }
            }
        }
        .rotationEffect(.degrees(-5))
        .foregroundStyle(.primary.opacity(0.10))
        .padding(.top, 8)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

struct AnalyticsDetails: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Случайный ID установки, версии, дни активности, готовность клавиатуры, исходы обновлений, показы приглашения и переходы на GitHub.")
            Text("События хранятся в PostHog Cloud EU один год. Изменить выбор можно в «Основные» → «Конфиденциальность».")
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
}
