import Foundation

public enum UsageEvent: Codable, Equatable {
    public enum Outcome: String, Codable { case started, installed, cancelled, signatureError, downloadError, installationError }
    public enum Install: String, Codable { case fresh, existing }

    case firstStart(Install)
    case keyboardReady
    case activeDay(first: Bool)
    case update(id: UUID, from: String, to: String, outcome: Outcome)
    // Older versions can leave these events in the persisted queue.
    case support(id: UUID, opened: Bool)
}

public struct UsageEnvelope: Codable, Equatable {
    public let id: UUID
    public let day: String
    public let version: String
    public let os: String
    public let event: UsageEvent

    public init(id: UUID = UUID(), day: String, version: String, os: String, event: UsageEvent) {
        self.id = id
        self.day = day
        self.version = version
        self.os = os
        self.event = event
    }
}

public enum UsageCapture {
    public static let endpoint = URL(string: "https://eu.i.posthog.com/i/v1/analytics/events")!

    public static func validToken(_ token: String) -> Bool {
        token.range(of: #"^phc_[A-Za-z0-9_-]+$"#, options: .regularExpression) != nil
    }

    public static func day(at date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    public static func request(
        token: String, installation: UUID, events: [UsageEnvelope], version: String,
        requestID: UUID, attempt: Int, created: Date, now: Date
    ) throws -> URLRequest {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let batch = Batch(created_at: formatter.string(from: created), batch: events.map { envelope in
            var properties = Properties(app_version: envelope.version, macos_version: envelope.os)
            let name: String
            switch envelope.event {
            case .firstStart(let kind):
                name = "punto_first_start"; properties.install_kind = kind.rawValue
            case .keyboardReady:
                name = "punto_keyboard_ready"
            case .activeDay(let first):
                name = "punto_active_day"; properties.first_active_day = first
            case let .update(id, from, to, outcome):
                name = "punto_update"
                properties.update_id = id.uuidString
                properties.from_version = from
                properties.to_version = to
                properties.outcome = outcome.rawValue
            case let .support(id, opened):
                name = opened ? "punto_support_opened" : "punto_support_shown"
                properties.invitation_id = id.uuidString
            }
            return Event(
                event: name, uuid: envelope.id.uuidString.lowercased(),
                distinct_id: installation.uuidString, timestamp: envelope.day + "T00:00:00.000Z",
                properties: properties
            )
        })
        var request = URLRequest(url: endpoint, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("PuntoNative/" + version, forHTTPHeaderField: "User-Agent")
        request.setValue("PuntoNative/" + version, forHTTPHeaderField: "PostHog-Sdk-Info")
        request.setValue(requestID.uuidString, forHTTPHeaderField: "PostHog-Request-Id")
        request.setValue(String(attempt), forHTTPHeaderField: "PostHog-Attempt")
        request.setValue(formatter.string(from: now), forHTTPHeaderField: "PostHog-Request-Timestamp")
        request.httpBody = try JSONEncoder().encode(batch)
        return request
    }

    public static func awaitingRetry(status: Int, body: Data, in events: [UsageEnvelope]) -> [UsageEnvelope] {
        if [404, 408, 429, 500, 502, 503, 504].contains(status) { return events }
        guard status == 200, let reply = try? JSONDecoder().decode(Reply.self, from: body) else { return [] }
        return events.filter { reply.results[$0.id.uuidString.lowercased()]?.result == "retry" }
    }

    private struct Reply: Decodable {
        struct Result: Decodable { let result: String }
        let results: [String: Result]
    }

    private struct Batch: Encodable {
        let created_at: String
        let batch: [Event]
    }

    private struct Event: Encodable {
        struct Options: Encodable {
            let process_person_profile = false
            let disable_skew_correction = true
        }
        let event: String
        let uuid: String
        let distinct_id: String
        let timestamp: String
        let properties: Properties
        let options = Options()
    }

    private struct Properties: Encodable {
        let schema_version = 1
        let app_version: String
        let macos_version: String
        let geoipDisabled = true
        var install_kind: String?
        var first_active_day: Bool?
        var update_id: String?
        var from_version: String?
        var to_version: String?
        var outcome: String?
        var invitation_id: String?

        enum CodingKeys: String, CodingKey {
            case schema_version, app_version, macos_version, install_kind, first_active_day
            case update_id, from_version, to_version, outcome, invitation_id
            case geoipDisabled = "$geoip_disable"
        }
    }
}
