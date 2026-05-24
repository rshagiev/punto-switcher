import Foundation

public struct KeyboardFocusEvidence: Equatable {
    public let appName: String?
    public let role: String?
    public let isEnabled: Bool?
    public let isFocused: Bool?
    public let hasFocusedApplication: Bool
    public let hasFocusedElement: Bool
    public let errorCode: Int32?

    public init(
        appName: String? = nil,
        role: String? = nil,
        isEnabled: Bool? = nil,
        isFocused: Bool? = nil,
        hasFocusedApplication: Bool,
        hasFocusedElement: Bool,
        errorCode: Int32? = nil
    ) {
        self.appName = appName
        self.role = role
        self.isEnabled = isEnabled
        self.isFocused = isFocused
        self.hasFocusedApplication = hasFocusedApplication
        self.hasFocusedElement = hasFocusedElement
        self.errorCode = errorCode
    }

    public static func noFocusedApplication(errorCode: Int32) -> Self {
        Self(hasFocusedApplication: false, hasFocusedElement: false, errorCode: errorCode)
    }

    public static func noFocusedElement(appName: String?, errorCode: Int32) -> Self {
        Self(appName: appName, hasFocusedApplication: true, hasFocusedElement: false, errorCode: errorCode)
    }

    public static func focusedElement(
        appName: String?,
        role: String?,
        isEnabled: Bool?,
        isFocused: Bool?
    ) -> Self {
        Self(
            appName: appName,
            role: role,
            isEnabled: isEnabled,
            isFocused: isFocused,
            hasFocusedApplication: true,
            hasFocusedElement: true
        )
    }

    public var logDescription: String {
        if !hasFocusedApplication {
            return "NO_FOCUSED_APP (error=\(errorCode.map(String.init) ?? "?"))"
        }

        let app = appName ?? "?"
        if !hasFocusedElement {
            return "app='\(app)' NO_FOCUSED_ELEMENT (error=\(errorCode.map(String.init) ?? "?"))"
        }

        return "app='\(app)' role='\(role ?? "?")' enabled=\(isEnabled.map(String.init) ?? "?") focused=\(isFocused.map(String.init) ?? "?")"
    }
}

public enum KeyboardFocusPolicy {
    public static func shouldAttemptKeyboardReplacement(focusEvidence: KeyboardFocusEvidence) -> Bool {
        guard focusEvidence.hasFocusedApplication,
              focusEvidence.hasFocusedElement else {
            return false
        }

        if focusEvidence.isEnabled == false {
            return false
        }

        if AccessibilityRolePolicy.isNonEditableContentRole(focusEvidence.role) {
            return false
        }

        return true
    }

    public static func shouldAttemptKeyboardReplacement(focusDescription: String) -> Bool {
        let normalized = focusDescription.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return false
        }

        if normalized.contains("no_focused_app") || normalized.contains("no_focused_element") {
            return false
        }

        if boolValue(for: "enabled", in: focusDescription) == false {
            return false
        }

        if let role = roleValue(in: focusDescription),
           AccessibilityRolePolicy.isNonEditableContentRole(role) {
            return false
        }

        return true
    }

    private static func roleValue(in focusDescription: String) -> String? {
        fieldValue(for: "role", in: focusDescription)
    }

    private static func boolValue(for key: String, in focusDescription: String) -> Bool? {
        fieldValue(for: key, in: focusDescription).flatMap { value in
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true":
                return true
            case "false":
                return false
            default:
                return nil
            }
        }
    }

    private static func fieldValue(for key: String, in focusDescription: String) -> String? {
        let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: key) + #"\s*=\s*'?([^'\s]+)'?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(focusDescription.startIndex..<focusDescription.endIndex, in: focusDescription)
        guard let match = regex.firstMatch(in: focusDescription, range: range),
              match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: focusDescription) else {
            return nil
        }

        return String(focusDescription[valueRange])
    }
}
