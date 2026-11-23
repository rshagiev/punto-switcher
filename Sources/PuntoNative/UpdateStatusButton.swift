import SwiftUI

struct UpdateStatusButton: View {
    @ObservedObject var updates: Updates
    @State private var hoveringButton = false
    @State private var hoveringPreview = false
    @State private var showingPreview = false
    @State private var hoverTask: Task<Void, Never>?

    var body: some View {
        let offer = updates.offer
        Button(action: check) {
            Image(systemName: "arrow.up.circle")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(offer == nil ? Color.secondary : Color.accentColor)
                .frame(width: 30, height: 30)
                .background(offer == nil ? Color.clear : Color.accentColor.opacity(0.14), in: Circle())
                .overlay(alignment: .topTrailing) {
                    if offer != nil {
                        Circle().fill(Color.accentColor).frame(width: 5, height: 5).padding(3)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(offer.map { "Доступно обновление до \($0.version)" } ?? "Проверить обновления")
        .help(offer == nil ? "Проверить обновления" : "")
        .disabled(!updates.canCheck)
        .onHover { hoveringButton = $0; updateHover() }
        .popover(isPresented: $showingPreview, arrowEdge: .bottom) {
            if let offer = updates.offer {
                preview(offer)
                    .onHover { hoveringPreview = $0; updateHover() }
                    .onDisappear { hoveringPreview = false }
            }
        }
        .onChange(of: offer?.version) { _, _ in dismissPreview() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            dismissPreview()
        }
        .onDisappear(perform: dismissPreview)
    }

    private func preview(_ offer: Updates.Offer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Доступно обновление").font(.headline)
                HStack(spacing: 6) {
                    Text("Версия \(offer.version)").monospacedDigit()
                    if let date = offer.date {
                        Text("·")
                        Text(date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "ru_RU"))))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            if let notes = offer.notes {
                ViewThatFits(in: .vertical) {
                    notesText(notes)
                    ScrollView { notesText(notes) }
                }
                .frame(maxHeight: 216)
            }
            Button("Обновить…", action: check)
                .controlSize(.small)
                .disabled(!updates.canCheck)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(14)
        .frame(width: 320, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func notesText(_ notes: AttributedString) -> some View {
        Text(notes)
            .font(.callout)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func updateHover() {
        hoverTask?.cancel()
        guard updates.offer != nil, NSApp.isActive else { return }
        let hovering = hoveringButton || hoveringPreview
        guard hovering != showingPreview else { return }
        hoverTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(hovering ? 350 : 250))
            guard !Task.isCancelled else { return }
            showingPreview = hovering
        }
    }

    private func dismissPreview() {
        hoverTask?.cancel()
        hoverTask = nil
        hoveringButton = false
        hoveringPreview = false
        showingPreview = false
    }

    private func check() {
        dismissPreview()
        updates.check()
    }
}
