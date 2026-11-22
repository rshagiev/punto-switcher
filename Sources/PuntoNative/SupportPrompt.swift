import AppKit
import Carbon
import Combine
import PuntoCore

final class SupportPrompt: ObservableObject {
    @Published private var invitation: SupportInvitation
    private let defaults: UserDefaults
    private let analytics: UsageAnalytics
    private static let key = "puntoSupportInvitationV1"
    private static let repository = URL(string: "https://github.com/rshagiev/punto-switcher")!

    init(analytics: UsageAnalytics, defaults: UserDefaults = .standard) {
        self.analytics = analytics
        self.defaults = defaults
        invitation = defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(SupportInvitation.self, from: $0) } ?? SupportInvitation()
    }

    func qualify() { update { $0.qualify() } }

    func available(setupComplete: Bool, at date: Date = Date()) -> UUID? {
        guard setupComplete, !IsSecureEventInputEnabled() else { return nil }
        return invitation.available(at: date)
    }

    func shown(_ id: UUID) {
        update {
            guard $0.available(at: Date()) == id else { return }
            _ = $0.registerShow(at: Date())
        }
        guard invitation.available(at: Date()) == id else { return }
        analytics.noteSupportShown(id)
    }

    func snooze() { update { $0.snooze(at: Date()) } }

    func dismiss() { update { $0.dismiss() } }

    func openInvitation() {
        guard let id = invitation.available(at: Date()), Self.openRepository() else { return }
        analytics.noteSupportOpened(id)
        dismiss()
    }

    @discardableResult static func openRepository() -> Bool {
        NSWorkspace.shared.open(repository)
    }

    private func update(_ mutate: (inout SupportInvitation) -> Void) {
        var changed = invitation
        mutate(&changed)
        guard changed != invitation else { return }
        if let data = try? JSONEncoder().encode(changed) { defaults.set(data, forKey: Self.key) }
        invitation = changed
    }
}
