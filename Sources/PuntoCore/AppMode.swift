public enum AppMode: String, Codable, CaseIterable {
    case global, automatic, manual, disabled

    public func automaticEnabled(global: Bool) -> Bool {
        switch self {
        case .global: return global
        case .automatic: return true
        case .manual, .disabled: return false
        }
    }
    public var manualEnabled: Bool { self != .disabled }
}
