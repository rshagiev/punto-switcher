import Foundation

public enum LegacyValuePolicy {
    public static func bool(_ value: Any?) -> Bool? {
        switch value {
        case let value as Bool:
            return value
        case let value as NSNumber:
            return value.boolValue
        case let value as String:
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "1", "true", "yes", "on":
                return true
            case "0", "false", "no", "off":
                return false
            default:
                return nil
            }
        default:
            return nil
        }
    }

    public static func bool(_ value: Any?, defaultValue: Bool) -> Bool {
        bool(value) ?? defaultValue
    }

    public static func int(_ value: Any?) -> Int? {
        switch value {
        case let value as Int:
            return value
        case let value as NSNumber:
            return value.intValue
        case let value as String:
            return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
        default:
            return nil
        }
    }

    public static func nonNegativeInt(_ value: Any?, defaultValue: Int) -> Int {
        max(0, int(value) ?? defaultValue)
    }

    public static func date(
        _ value: Any?,
        allowNumericString: Bool = false
    ) -> Date? {
        switch value {
        case let value as Date:
            return value
        case let value as NSNumber:
            return Date(timeIntervalSince1970: value.doubleValue)
        case let value as String:
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if allowNumericString, let seconds = TimeInterval(trimmed) {
                return Date(timeIntervalSince1970: seconds)
            }
            return legacyDateFormatter.date(from: trimmed)
        default:
            return nil
        }
    }

    public static func date(
        _ value: Any?,
        defaultValue: Date,
        allowNumericString: Bool = false
    ) -> Date {
        date(value, allowNumericString: allowNumericString) ?? defaultValue
    }

    public static func normalizedStringArray(_ value: Any?) -> [String] {
        guard let values = value as? [String] else {
            return []
        }

        return Array(ApplicationBundleIDPolicy.normalizedSet(Set(values))).sorted()
    }

    private static let legacyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter
    }()
}
