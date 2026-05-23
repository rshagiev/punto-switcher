import ApplicationServices
import Foundation
import PuntoCore

enum AccessibilityValueBridge {
    static func stringAttributeResult(_ attribute: CFString, from element: AXUIElement) -> (AXError, String?) {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        return (result, value as? String)
    }

    static func stringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
        let (result, value) = stringAttributeResult(attribute, from: element)
        guard result == .success else {
            return nil
        }
        return value
    }

    static func boolAttribute(_ attribute: CFString, from element: AXUIElement) -> Bool? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value as? Bool
    }

    static func elementAttribute(_ attribute: CFString, from element: AXUIElement, context: String) -> AXUIElement? {
        let (result, value) = elementAttributeResult(attribute, from: element, context: context)
        guard result == .success else {
            return nil
        }
        return value
    }

    static func elementAttributeResult(_ attribute: CFString, from element: AXUIElement, context: String) -> (AXError, AXUIElement?) {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success else {
            return (result, nil)
        }
        return (result, self.element(from: value, context: context))
    }

    static func elementArrayAttribute(_ attribute: CFString, from element: AXUIElement) -> [AXUIElement]? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value as? [AXUIElement]
    }

    static func cfRangeAttribute(_ attribute: CFString, from element: AXUIElement, context: String) -> (AXError, CFRange?) {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success else {
            return (result, nil)
        }
        return (result, cfRange(from: value, context: context))
    }

    static func element(from value: AnyObject?, context: String) -> AXUIElement? {
        guard let value else {
            PuntoLog.info("\(context): missing AXUIElement value")
            return nil
        }

        guard CFGetTypeID(value) == AXUIElementGetTypeID() else {
            PuntoLog.info("\(context): unexpected AX value type")
            return nil
        }

        return (value as! AXUIElement)
    }

    static func cfRange(from value: AnyObject?, context: String) -> CFRange? {
        guard let value else {
            PuntoLog.info("\(context): missing AXValue range")
            return nil
        }

        guard CFGetTypeID(value) == AXValueGetTypeID() else {
            PuntoLog.info("\(context): unexpected AX range value type")
            return nil
        }

        let range = value as! AXValue
        guard AXValueGetType(range) == .cfRange else {
            PuntoLog.info("\(context): AXValue is not a CFRange")
            return nil
        }

        var cfRange = CFRange(location: 0, length: 0)
        guard AXValueGetValue(range, .cfRange, &cfRange) else {
            PuntoLog.info("\(context): failed to read CFRange")
            return nil
        }

        return cfRange
    }
}
