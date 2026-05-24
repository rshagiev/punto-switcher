import Foundation

public enum KeyboardLayoutType: String, Codable, Equatable, CaseIterable {
    case mac
    case windows
}

public enum KeyboardLayoutTypePolicy {
    public static let defaultRussianLayoutType: KeyboardLayoutType = .mac
    public static let legacyRussianKeyboardLayoutTypeKey = "kbdLayoutType"

    public static func normalized(_ rawValue: String?) -> KeyboardLayoutType {
        guard let rawValue else {
            return defaultRussianLayoutType
        }

        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "windows", "win", "pc", "russianwin":
            return .windows
        case "mac", "default", "russian", "appl", "apple":
            return .mac
        default:
            return defaultRussianLayoutType
        }
    }

    public static func effectiveRussianKeyboardLayoutType(
        hasPersistedValue: Bool,
        persistedValue: String?,
        hasLegacyValue: Bool,
        legacyValue: String?
    ) -> KeyboardLayoutType {
        if hasPersistedValue {
            return normalized(persistedValue)
        }

        if hasLegacyValue {
            return normalized(legacyValue)
        }

        return defaultRussianLayoutType
    }

    public static func isPreferredRussianSource(
        sourceID: String,
        layoutType: KeyboardLayoutType
    ) -> Bool {
        switch layoutType {
        case .mac:
            return KeyboardLayoutVariantPolicy.isAppleRussianSource(sourceID)
        case .windows:
            return KeyboardLayoutVariantPolicy.isWindowsRussianSource(sourceID)
        }
    }
}
