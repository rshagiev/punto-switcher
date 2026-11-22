import Combine
import Foundation
import PuntoCore

final class UsageAnalytics: NSObject, ObservableObject, URLSessionTaskDelegate {
    @Published private(set) var choice: Bool?
    private let defaults: UserDefaults
    private let token: String?
    private let version: String
    private let build: String
    private let os: String
    private let sessionConfiguration: URLSessionConfiguration
    private var state: State?
    private var task: URLSessionDataTask?
    private var pending: DispatchWorkItem?
    private var sending: Batch?
    private lazy var session: URLSession = {
        let configuration = sessionConfiguration
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    private static let choiceKey = "puntoUsageChoice"
    private static let stateKey = "puntoUsageStateV1"
    private static let existingKey = "puntoUsageExistingAtIntroduction"
    private static let batchSize = 20
    private static let queueLimit = 80

    private struct State: Codable {
        let installation: UUID
        var firstStart = false
        var firstReady = false
        var activeDay: String?
        var invitation: UUID?
        var queue: [UsageEnvelope] = []
        var update: UpdateAttempt?

        init() { installation = UUID() }
    }

    private struct UpdateAttempt: Codable {
        let id: UUID
        let from: String
        let target: String
        let targetBuild: String
        var installing = false
    }

    private struct Batch {
        let id = UUID()
        let created = Date()
        var events: [UsageEnvelope]
        var attempt = 1
    }

    var isConfigured: Bool { token != nil }
    var existingInstall: Bool { defaults.bool(forKey: Self.existingKey) }
    var displayVersion: String { version }

    init(defaults: UserDefaults = .standard, bundle: Bundle = .main,
         sessionConfiguration: URLSessionConfiguration = .ephemeral) {
        self.defaults = defaults
        self.sessionConfiguration = sessionConfiguration
        let configuredToken = bundle.object(forInfoDictionaryKey: "PuntoPostHogProjectToken") as? String
        let validToken = configuredToken.flatMap { UsageCapture.validToken($0) ? $0 : nil }
        token = validToken
        version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        os = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        let storedChoice = defaults.object(forKey: Self.choiceKey) as? Bool
        choice = storedChoice
        if validToken != nil, storedChoice == true {
            state = defaults.data(forKey: Self.stateKey).flatMap { try? JSONDecoder().decode(State.self, from: $0) } ?? State()
        }
        super.init()
    }

    func setChoice(_ enabled: Bool) {
        guard isConfigured else { return }
        defaults.set(enabled, forKey: Self.choiceKey)
        choice = enabled
        if enabled {
            if state == nil { state = State(); save() }
        } else {
            pending?.cancel()
            pending = nil
            task?.cancel()
            task = nil
            sending = nil
            state = nil
            defaults.removeObject(forKey: Self.stateKey)
        }
    }

    func prepareInstall(existing: Bool) {
        guard isConfigured, defaults.object(forKey: Self.existingKey) == nil else { return }
        defaults.set(existing, forKey: Self.existingKey)
    }

    func start(keyboardReady: Bool) {
        guard isConfigured, choice == true, let current = state else { return }
        if !current.firstStart {
            state?.firstStart = true
            enqueue(.firstStart(existingInstall ? .existing : .fresh))
        }
        if keyboardReady { noteKeyboardReady() }
        if let update = state?.update, update.installing, update.targetBuild == build {
            completeUpdate(.installed)
        }
        schedule()
    }

    func noteKeyboardReady() {
        guard choice == true, state?.firstReady == false else { return }
        state?.firstReady = true
        enqueue(.keyboardReady)
    }

    func noteActiveDay() {
        guard choice == true, let current = state else { return }
        let day = UsageCapture.day(at: Date())
        guard current.activeDay.map({ $0 < day }) ?? true else { return }
        state?.activeDay = day
        enqueue(.activeDay(first: current.activeDay == nil), day: day)
    }

    func noteSupportShown(_ id: UUID) {
        guard choice == true, let current = state, current.invitation != id else { return }
        state?.invitation = id
        enqueue(.support(id: id, opened: false))
    }

    func noteSupportOpened(_ id: UUID) {
        guard state?.invitation == id else { return }
        enqueue(.support(id: id, opened: true))
    }

    func beginUpdate(to target: String, build: String) {
        guard choice == true, let current = state, Self.versionLike(target), Self.versionLike(build) else { return }
        if let previous = current.update, previous.targetBuild == build, previous.from == version, !previous.installing { return }
        let attempt = UpdateAttempt(id: UUID(), from: version, target: target, targetBuild: build)
        state?.update = attempt
        enqueue(.update(id: attempt.id, from: attempt.from, to: attempt.target, outcome: .started))
    }

    func installingUpdate(build: String) {
        guard state?.update?.targetBuild == build else { return }
        state?.update?.installing = true
        save()
    }

    func completeUpdate(_ outcome: UsageEvent.Outcome, matching targetBuild: String? = nil) {
        guard let attempt = state?.update, targetBuild == nil || attempt.targetBuild == targetBuild else { return }
        state?.update = nil
        enqueue(.update(id: attempt.id, from: attempt.from, to: attempt.target, outcome: outcome))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }

    private static func versionLike(_ value: String) -> Bool {
        value.range(of: #"^[0-9][0-9A-Za-z.+-]{0,47}$"#, options: .regularExpression) != nil
    }

    private func enqueue(_ event: UsageEvent, day: String? = nil) {
        guard isConfigured, choice == true, let current = state else { return }
        let envelope = UsageEnvelope(day: day ?? UsageCapture.day(at: Date()), version: version, os: os, event: event)
        let protectedIDs = Set(sending?.events.map(\.id) ?? [])
        var queue = current.queue
        if queue.count >= Self.queueLimit, let removable = queue.firstIndex(where: { !protectedIDs.contains($0.id) }) {
            queue.remove(at: removable)
        }
        queue.append(envelope)
        state?.queue = queue
        save()
        schedule()
    }

    private func save() {
        if let state, let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: Self.stateKey) }
    }

    private func schedule(after delay: TimeInterval = 2) {
        guard isConfigured, choice == true, task == nil, pending == nil, state?.queue.isEmpty == false else { return }
        let work = DispatchWorkItem { [weak self] in
            self?.pending = nil
            self?.send()
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func send() {
        guard choice == true, task == nil, let token, let state else { return }
        let now = Date()
        let cutoff = UsageCapture.day(at: now.addingTimeInterval(-7 * 86_400))
        if sending == nil {
            let queue = state.queue.filter { $0.day >= cutoff }
            if queue.count != state.queue.count { self.state?.queue = queue; save() }
            guard !queue.isEmpty else { return }
            sending = Batch(events: Array(queue.prefix(Self.batchSize)))
        }
        guard let batch = sending,
              let request = try? UsageCapture.request(token: token, installation: state.installation, events: batch.events,
                                                       version: version, requestID: batch.id, attempt: batch.attempt,
                                                       created: batch.created, now: now) else { return }
        let next = session.dataTask(with: request) { [weak self] body, response, error in
            let response = response as? HTTPURLResponse
            let retry = error == nil
                ? UsageCapture.awaitingRetry(status: response?.statusCode ?? 0, body: body ?? Data(), in: batch.events)
                : batch.events
            let retryAfter = Self.retryDelay(response?.value(forHTTPHeaderField: "Retry-After"))
            DispatchQueue.main.async {
                self?.finish(batch, retry: retry, retryAfter: retryAfter)
            }
        }
        task = next
        next.resume()
    }

    private func finish(_ batch: Batch, retry: [UsageEnvelope], retryAfter: TimeInterval) {
        guard choice == true, sending?.id == batch.id else { return }
        task = nil
        let pendingEvents = batch.attempt < 5 ? retry : []
        let pendingIDs = Set(pendingEvents.map(\.id))
        let completed = Set(batch.events.map(\.id)).subtracting(pendingIDs)
        state?.queue.removeAll { completed.contains($0.id) }
        save()
        if pendingEvents.isEmpty {
            sending = nil
            schedule()
        } else {
            sending?.events = pendingEvents
            sending?.attempt += 1
            let delay = pow(2, Double(batch.attempt)) * Double.random(in: 1...2)
            schedule(after: max(delay, retryAfter))
        }
    }

    private static func retryDelay(_ header: String?) -> TimeInterval {
        guard let header else { return 0 }
        if let seconds = TimeInterval(header), seconds.isFinite { return min(max(0, seconds), 7 * 86_400) }
        let format = DateFormatter()
        format.locale = Locale(identifier: "en_US_POSIX")
        format.timeZone = TimeZone(secondsFromGMT: 0)
        format.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return max(0, min(format.date(from: header)?.timeIntervalSinceNow ?? 0, 7 * 86_400))
    }
}
