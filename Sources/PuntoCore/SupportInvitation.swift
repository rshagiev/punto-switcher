import Foundation

public struct SupportInvitation: Codable, Equatable {
    public static let conversionThreshold = 6

    private let cycle: UUID
    private var dismissed: Bool
    private var conversions: Int
    public private(set) var wasPresented: Bool

    private enum CodingKeys: String, CodingKey {
        case cycle, dismissed, conversions, wasPresented
    }

    public init() {
        cycle = UUID()
        dismissed = false
        conversions = 0
        wasPresented = false
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        cycle = try values.decodeIfPresent(UUID.self, forKey: .cycle) ?? UUID()
        dismissed = try values.decode(Bool.self, forKey: .dismissed)
        let savedCount = try values.decodeIfPresent(Int.self, forKey: .conversions) ?? 0
        conversions = min(max(savedCount, 0), Self.conversionThreshold)
        // A legacy menu or Today impression did not display the new popover.
        wasPresented = try values.decodeIfPresent(Bool.self, forKey: .wasPresented) ?? false
    }

    public var visibleID: UUID? {
        dismissed || conversions < Self.conversionThreshold ? nil : cycle
    }

    /// Returns true only for the successful conversion that reaches the threshold.
    public mutating func recordConversion() -> Bool {
        guard !dismissed, conversions < Self.conversionThreshold else { return false }
        conversions += 1
        return conversions == Self.conversionThreshold
    }

    public mutating func markPresented() {
        if visibleID != nil { wasPresented = true }
    }

    public mutating func dismiss() {
        if visibleID != nil { dismissed = true }
    }

    public mutating func open(using openRepository: () -> Bool) -> UUID? {
        guard let id = visibleID, openRepository() else { return nil }
        dismiss()
        return id
    }
}
