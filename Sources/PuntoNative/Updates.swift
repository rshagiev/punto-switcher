import AppKit
import Combine
import Sparkle

final class Updates: ObservableObject {
    @Published private(set) var canCheck = false
    private let controller: SPUStandardUpdaterController?
    private var availability: AnyCancellable?

    var isConfigured: Bool { controller != nil }

    init() {
        let info = Bundle.main.infoDictionary ?? [:]
        guard info["SUFeedURL"] is String, info["SUPublicEDKey"] is String else {
            controller = nil
            return
        }
        controller = SPUStandardUpdaterController(
            startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil
        )
    }

    func start(automaticallyCheck: Bool) {
        guard let controller else { return }
        let updater = controller.updater
        // Keep the existing Punto preference, including opt-outs from older versions.
        setAutomaticChecks(automaticallyCheck)
        availability = updater.publisher(for: \.canCheckForUpdates)
            .sink { [weak self] in self?.canCheck = $0 }
        controller.startUpdater()
    }

    func setAutomaticChecks(_ enabled: Bool) {
        guard let updater = controller?.updater, updater.automaticallyChecksForUpdates != enabled else { return }
        updater.automaticallyChecksForUpdates = enabled
    }

    func check() {
        guard canCheck else { return }
        controller?.checkForUpdates(nil)
    }
}
