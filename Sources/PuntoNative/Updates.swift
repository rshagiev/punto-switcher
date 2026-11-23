import AppKit
import Combine
import PuntoCore
import Sparkle

final class Updates: NSObject, ObservableObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    struct Offer {
        let version: String
        let date: Date?
        let notes: AttributedString?

        init(_ item: SUAppcastItem) {
            version = item.displayVersionString
            date = item.date
            guard let description = item.itemDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !description.isEmpty else {
                notes = nil
                return
            }

            switch item.itemDescriptionFormat {
            case "markdown":
                let list = description.split(separator: "\n", omittingEmptySubsequences: false).map { line in
                    line.hasPrefix("- ") ? "• " + line.dropFirst(2) : String(line)
                }.joined(separator: "\n")
                notes = (try? AttributedString(markdown: list, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                    ?? AttributedString(list)
            case "plain-text":
                notes = AttributedString(description)
            default:
                notes = nil
            }
        }
    }

    @Published private(set) var canCheck = false
    @Published private(set) var offer: Offer?
    private var controller: SPUStandardUpdaterController?
    private var availability: AnyCancellable?
    private let analytics: UsageAnalytics
    private let settingsWindowIsActive: () -> Bool
    private var observedBuild: String?

    var isConfigured: Bool { controller != nil }

    init(analytics: UsageAnalytics, settingsWindowIsActive: @escaping () -> Bool) {
        self.analytics = analytics
        self.settingsWindowIsActive = settingsWindowIsActive
        super.init()
        let info = Bundle.main.infoDictionary ?? [:]
        guard info["SUFeedURL"] is String, info["SUPublicEDKey"] is String else { return }
        controller = SPUStandardUpdaterController(
            startingUpdater: false, updaterDelegate: self, userDriverDelegate: self
        )
    }

    func start(automaticallyCheck: Bool) {
        guard let controller else { return }
        let updater = controller.updater
        // Keep the existing Punto preference, including opt-outs from older versions.
        setAutomaticChecks(automaticallyCheck)
        availability = updater.publisher(for: \.canCheckForUpdates)
            .sink { [weak self] in self?.canCheck = $0 }
        let lastCheckAtLaunch = updater.lastUpdateCheckDate
        controller.startUpdater()
        guard automaticallyCheck else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak updater] in
            guard let updater, updater.automaticallyChecksForUpdates, !updater.sessionInProgress,
                  updater.lastUpdateCheckDate == lastCheckAtLaunch else { return }
            updater.checkForUpdatesInBackground()
        }
    }

    func setAutomaticChecks(_ enabled: Bool) {
        guard let updater = controller?.updater, updater.automaticallyChecksForUpdates != enabled else { return }
        updater.automaticallyChecksForUpdates = enabled
    }

    func check() {
        guard canCheck else { return }
        controller?.checkForUpdates(nil)
    }

    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        update.isCriticalUpdate || !settingsWindowIsActive()
    }

    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        offer = Offer(update)
    }

    func standardUserDriverWillFinishUpdateSession() {
        offer = nil
    }

    func updater(_ updater: SPUUpdater, willDownloadUpdate item: SUAppcastItem, with request: NSMutableURLRequest) {
        observedBuild = item.versionString
        analytics.beginUpdate(to: item.displayVersionString, build: item.versionString)
    }

    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        observedBuild = item.versionString
        analytics.installingUpdate(build: item.versionString)
    }

    func userDidCancelDownload(_ updater: SPUUpdater) {
        finish(.cancelled)
    }

    func updater(_ updater: SPUUpdater, userDidMake choice: SPUUserUpdateChoice, forUpdate item: SUAppcastItem, state: SPUUserUpdateState) {
        if choice == .skip {
            analytics.completeUpdate(.cancelled, matching: item.versionString)
            observedBuild = nil
        }
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        let failure = error as NSError
        if failure.domain == SUSparkleErrorDomain, failure.code == Int(SUError.noUpdateError.rawValue) { return }
        var cause: NSError? = failure
        for _ in 0..<8 {
            guard let current = cause else { break }
            if current.domain == SUSparkleErrorDomain {
                switch SUError(rawValue: Int32(clamping: current.code)) {
                case .installationCanceledError: finish(.cancelled); return
                case .downloadError: finish(.downloadError); return
                case .signatureError, .validationError, .insufficientSigningError: finish(.signatureError); return
                default: break
                }
            }
            cause = current.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        finish(.installationError)
    }

    private func finish(_ outcome: UsageEvent.Outcome) {
        guard let observedBuild else { return }
        self.observedBuild = nil
        analytics.completeUpdate(outcome, matching: observedBuild)
    }
}
