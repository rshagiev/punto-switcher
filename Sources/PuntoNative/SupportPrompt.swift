import AppKit
import Carbon
import Combine
import PuntoCore

final class SupportPrompt: ObservableObject {
    @Published private var invitation: SupportInvitation
    private var popover: SupportPopover?
    private let defaults: UserDefaults
    private let analytics: UsageAnalytics
    private static let key = "puntoGitHubSupportV1"
    private static let legacyKey = "puntoSupportInvitationV1"
    static let repository = URL(string: "https://github.com/rshagiev/punto-switcher")!

    init(analytics: UsageAnalytics, defaults: UserDefaults = .standard) {
        self.analytics = analytics
        self.defaults = defaults
        let decoder = JSONDecoder()
        if let current = defaults.data(forKey: Self.key),
           let state = try? decoder.decode(SupportInvitation.self, from: current) {
            invitation = state
        } else {
            let legacy = defaults.data(forKey: Self.legacyKey)
            invitation = legacy.flatMap { try? decoder.decode(SupportInvitation.self, from: $0) } ?? SupportInvitation()
            save()
        }
    }

    var visibleID: UUID? {
        IsSecureEventInputEnabled() ? nil : invitation.visibleID
    }

    func recordConversion() -> Bool {
        var next = invitation
        let reachedThreshold = next.recordConversion()
        store(next)
        return reachedThreshold
    }

    func showPopover(under anchor: NSView) {
        guard !invitation.wasPresented, let id = visibleID else { return }
        let candidate = SupportPopover(open: { [weak self] in self?.openInvitation() },
                                       dismiss: { [weak self] in self?.dismiss() },
                                       close: { [weak self] in self?.closePopover() })
        guard candidate.show(under: anchor) else { return }
        popover = candidate
        shown(id)
    }

    func shown(_ id: UUID) {
        guard id == visibleID else { return }
        var next = invitation
        next.markPresented()
        store(next)
        analytics.noteSupportShown(id)
    }

    func closePopover() {
        popover?.close()
        popover = nil
    }

    func dismiss() {
        guard visibleID != nil else { return }
        var next = invitation
        next.dismiss()
        store(next)
        closePopover()
    }

    func openInvitation() {
        guard visibleID != nil else { return }
        var next = invitation
        next.markPresented()
        guard let id = next.open(using: { NSWorkspace.shared.open(Self.repository) }) else { return }
        store(next)
        closePopover()
        analytics.noteSupportShown(id)
        analytics.noteSupportOpened(id)
    }

    private func store(_ state: SupportInvitation) {
        guard state != invitation else { return }
        invitation = state
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(invitation) { defaults.set(data, forKey: Self.key) }
    }
}
