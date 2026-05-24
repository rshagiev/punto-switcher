import AppKit
import ApplicationServices
import Carbon.HIToolbox
import PuntoCore

/// App-side Accessibility element lookup and role inspection.
///
/// Pure policy modules own decisions; this adapter owns live AX tree reads,
/// focused-element discovery, and browser/Electron EUI setup.
final class AccessibilityElementClient {

    func focusedElement() -> AXUIElement? {
        let (appResult, focusedAppElement) = focusedApplicationElement(context: "getFocusedElement: focused app")

        guard appResult == .success, focusedAppElement != nil else {
            if let frontApp = NSWorkspace.shared.frontmostApplication {
                PuntoLog.info("getFocusedElement: AX failed (error=\(appResult.rawValue)) for app '\(frontApp.localizedName ?? "?")' bundle=\(frontApp.bundleIdentifier ?? "?")")
            } else {
                PuntoLog.info("getFocusedElement: AX failed (error=\(appResult.rawValue)), no frontmost app")
            }
            return nil
        }

        guard let appElement = focusedAppElement else {
            return nil
        }
        enableEnhancedUserInterfaceIfNeeded(on: appElement)

        if let appTitle = AccessibilityValueBridge.stringAttribute(kAXTitleAttribute as CFString, from: appElement) {
            PuntoLog.info("getFocusedElement: focused app is '\(appTitle)'")
        }

        let (elemResult, element) = AccessibilityValueBridge.elementAttributeResult(
            kAXFocusedUIElementAttribute as CFString,
            from: appElement,
            context: "getFocusedElement: focusedUIElement"
        )
        guard elemResult == .success else {
            PuntoLog.info("getFocusedElement: failed to get focused element, error=\(elemResult.rawValue)")
            return nil
        }

        guard let element else {
            return nil
        }

        if let role = role(of: element) {
            PuntoLog.info("getFocusedElement: focused element role='\(role)'")
        }

        return element
    }

    func appFocusedElement() -> AXUIElement? {
        let (appResult, appElement) = focusedApplicationElement(context: "getAppFocusedElement: focused app")
        guard appResult == .success else {
            PuntoLog.info("getAppFocusedElement: failed to get app, error=\(appResult.rawValue)")
            return nil
        }

        guard let appElement else {
            return nil
        }
        enableEnhancedUserInterfaceIfNeeded(on: appElement)

        let (elemResult, element) = AccessibilityValueBridge.elementAttributeResult(
            kAXFocusedUIElementAttribute as CFString,
            from: appElement,
            context: "getAppFocusedElement: focusedUIElement"
        )
        guard elemResult == .success else {
            PuntoLog.info("getAppFocusedElement: failed to get focusedUIElement, error=\(elemResult.rawValue)")
            return nil
        }

        guard let element else {
            return nil
        }

        PuntoLog.info("getAppFocusedElement: got focusedUIElement")
        return element
    }

    func isPasswordField() -> Bool {
        if let element = focusedElement(),
           elementOrDescendantIsPasswordField(element, depth: 0) {
            PuntoLog.info("isPasswordField: secure field detected from focused element tree")
            return true
        }

        if let element = appFocusedElement(),
           elementOrDescendantIsPasswordField(element, depth: 0) {
            PuntoLog.info("isPasswordField: secure field detected from app focusedUIElement tree")
            return true
        }

        return false
    }

    func canDoSearchClick(bundleID: String?) -> Bool {
        guard let focusedElement = focusedElement() else {
            PuntoLog.info("canDoSearchClick: no focused element")
            return false
        }

        let role = role(of: focusedElement)
        let canSearch = SearchClickPolicy.canDoSearchClick(role: role, bundleID: bundleID)
        PuntoLog.info("canDoSearchClick: role='\(role ?? "?")' bundle='\(bundleID ?? "?")' result=\(canSearch)")
        return canSearch
    }

    func selectedTextReplacementCapability(of element: AXUIElement) -> AccessibilityReplacementCapability {
        let role = role(of: element)
        let editable = AccessibilityValueBridge.boolAttribute("AXEditable" as CFString, from: element)

        var isSettable: DarwinBoolean = false
        let settableResult = AXUIElementIsAttributeSettable(
            element,
            kAXSelectedTextAttribute as CFString,
            &isSettable
        )
        let selectedTextSettable = settableResult == .success && isSettable.boolValue
        return AccessibilityReplacementCapability(
            role: role,
            axEditable: editable,
            selectedTextSettable: selectedTextSettable,
            selectedTextSettableErrorCode: Int(settableResult.rawValue)
        )
    }

    func role(of element: AXUIElement) -> String? {
        AccessibilityValueBridge.stringAttribute(kAXRoleAttribute as CFString, from: element)
    }

    func rolesFromElementToAncestors(_ element: AXUIElement, maxDepth: Int) -> [String] {
        var roles: [String] = []
        var current = element

        for depth in 0...maxDepth {
            guard AccessibilityTraversalPolicy.shouldCollectAncestorRole(atDepth: depth) else {
                break
            }

            if let role = role(of: current) {
                roles.append(role)
            }

            guard let parentElement = AccessibilityValueBridge.elementAttribute(
                kAXParentAttribute as CFString,
                from: current,
                context: "accessibilityRoles: parent"
            ) else {
                break
            }
            current = parentElement
        }

        return roles
    }

    func keyboardFocusEvidence() -> KeyboardFocusEvidence {
        let (appResult, appElement) = focusedApplicationElement(context: "checkKeyboardFocusEvidence: focused app")

        guard appResult == .success, let appElement else {
            return .noFocusedApplication(errorCode: appResult.rawValue)
        }

        let appName = AccessibilityValueBridge.stringAttribute(kAXTitleAttribute as CFString, from: appElement) ?? "?"

        let (elemResult, axElement) = AccessibilityValueBridge.elementAttributeResult(
            kAXFocusedUIElementAttribute as CFString,
            from: appElement,
            context: "checkKeyboardFocusEvidence: focusedUIElement"
        )

        guard elemResult == .success, let axElement else {
            return .noFocusedElement(appName: appName, errorCode: elemResult.rawValue)
        }

        let roleName = role(of: axElement) ?? "?"
        let isEnabled = AccessibilityValueBridge.boolAttribute(kAXEnabledAttribute as CFString, from: axElement) ?? true
        let hasFocus = AccessibilityValueBridge.boolAttribute(kAXFocusedAttribute as CFString, from: axElement) ?? false

        return .focusedElement(
            appName: appName,
            role: roleName,
            isEnabled: isEnabled,
            isFocused: hasFocus
        )
    }

    private func focusedApplicationElement(context: String) -> (AXError, AXUIElement?) {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedAppElement: AXUIElement?
        var appResult: AXError = .failure

        for attempt in AccessibilityReplacementPolicy.focusedApplicationLookupAttempts {
            (appResult, focusedAppElement) = AccessibilityValueBridge.elementAttributeResult(
                kAXFocusedApplicationAttribute as CFString,
                from: systemWide,
                context: context
            )
            if appResult == .success {
                break
            }
            if AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: attempt) {
                Thread.sleep(forTimeInterval: AccessibilityReplacementPolicy.focusedApplicationRetryDelay)
            }
        }

        return (appResult, focusedAppElement)
    }

    private func elementOrDescendantIsPasswordField(_ element: AXUIElement, depth: Int) -> Bool {
        guard AccessibilityTraversalPolicy.shouldInspectDescendant(depth: depth) else {
            return false
        }

        if elementIsPasswordField(element) {
            return true
        }

        guard let childArray = AccessibilityValueBridge.elementArrayAttribute(kAXChildrenAttribute as CFString, from: element) else {
            return false
        }

        for child in childArray where elementOrDescendantIsPasswordField(child, depth: depth + 1) {
            return true
        }

        return false
    }

    private func elementIsPasswordField(_ element: AXUIElement) -> Bool {
        TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(
            role: AccessibilityValueBridge.stringAttribute(kAXRoleAttribute as CFString, from: element),
            subrole: AccessibilityValueBridge.stringAttribute(kAXSubroleAttribute as CFString, from: element)
        )
    }

    private func enableEnhancedUserInterfaceIfNeeded(on appElement: AXUIElement) {
        let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard AccessibilityApplicationPolicy.shouldEnableEnhancedUserInterface(bundleID: bundleID) else {
            return
        }

        let result = AXUIElementSetAttributeValue(
            appElement,
            AccessibilityApplicationPolicy.enhancedUserInterfaceAttribute as CFString,
            kCFBooleanTrue
        )

        if result == .success {
            PuntoLog.debug("AXEnhancedUserInterface enabled for bundle=\(bundleID ?? "?")")
        } else {
            PuntoLog.info("AXEnhancedUserInterface failed for bundle=\(bundleID ?? "?"), error=\(result.rawValue)")
        }
    }
}
