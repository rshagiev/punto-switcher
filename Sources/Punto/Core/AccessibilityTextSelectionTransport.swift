import ApplicationServices
import PuntoCore

/// App-side AX selected-text transport.
///
/// This adapter owns live selected-text reads/writes, descendant selection
/// probing, cached editable selection targets, AX write verification, and
/// replacement reselection. Policy modules own traversal decisions and safety
/// checks; `TextAccessor` owns cross-transport capture/replacement routing.
final class AccessibilityTextSelectionTransport {
    enum CaptureResult {
        case text(String, AXUIElement, replacementSupported: Bool)
        case empty
        case noFocus
        case failed

        var observation: TextCapturePolicy.AccessibilityObservation {
            switch self {
            case .text(let text, _, let replacementSupported):
                return .selectedText(text, replacementSupported: replacementSupported)
            case .empty:
                return .emptySelection
            case .noFocus:
                return .noFocusedElement
            case .failed:
                return .failed
            }
        }
    }

    private enum ProbeResult {
        case text(String, AXUIElement)
        case empty
        case noFocus
        case failed

        var searchOutcome: AccessibilitySelectionProbeOutcome {
            switch self {
            case .text:
                return .text
            case .empty:
                return .empty
            case .noFocus:
                return .noFocus
            case .failed:
                return .failed
            }
        }
    }

    private let accessibilityElements: AccessibilityElementClient
    private var lastEditableSelectionElement: AXUIElement?

    init(accessibilityElements: AccessibilityElementClient) {
        self.accessibilityElements = accessibilityElements
    }

    func captureSelection() -> CaptureResult {
        let probeResult = selectedTextViaAccessibility()
        switch probeResult {
        case .text(let text, let element):
            let supportsReplacement = elementSupportsSelectedTextReplacement(element)
            if supportsReplacement {
                lastEditableSelectionElement = element
                PuntoLog.info("captureSelectedText: AX editable selection accepted")
            } else {
                lastEditableSelectionElement = nil
                PuntoLog.info("captureSelectedText: AX selection rejected because focused surface is not settable")
            }
            return .text(text, element, replacementSupported: supportsReplacement)

        case .empty:
            lastEditableSelectionElement = nil
            return .empty

        case .noFocus:
            lastEditableSelectionElement = nil
            return .noFocus

        case .failed:
            lastEditableSelectionElement = nil
            return .failed
        }
    }

    func clearCachedEditableElement() {
        lastEditableSelectionElement = nil
    }

    @discardableResult
    func replaceSelection(with text: String, keepSelection: Bool = false) -> Bool {
        guard let focusedElement = lastEditableSelectionElement ?? accessibilityElements.focusedElement() else {
            PuntoLog.info("setSelectedTextViaAccessibility: no focused element")
            return false
        }

        let originalText = AccessibilityValueBridge.stringAttribute(kAXSelectedTextAttribute as CFString, from: focusedElement)

        var originalSelectionLocation: Int?
        if AccessibilityReplacementPolicy.shouldReadOriginalSelectionRange(keepSelection: keepSelection) {
            let (_, cfRange) = AccessibilityValueBridge.cfRangeAttribute(
                kAXSelectedTextRangeAttribute as CFString,
                from: focusedElement,
                context: "setSelectedTextViaAccessibility: selected text range"
            )
            if let cfRange {
                originalSelectionLocation = AccessibilityReplacementPolicy.originalSelectionLocation(
                    location: cfRange.location,
                    length: cfRange.length
                )
            }
        }

        let result = AXUIElementSetAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        let setSucceeded = result == .success
        if !setSucceeded {
            PuntoLog.info("setSelectedTextViaAccessibility: AXUIElementSetAttributeValue failed with \(result.rawValue)")
            lastEditableSelectionElement = nil
            return false
        }

        Thread.sleep(forTimeInterval: AccessibilityReplacementPolicy.selectedTextVerificationDelay)
        let actualText = AccessibilityValueBridge.stringAttribute(kAXSelectedTextAttribute as CFString, from: focusedElement)

        if !AccessibilityReplacementPolicy.shouldAcceptSelectedTextSet(
            setSucceeded: setSucceeded,
            originalSelectedText: originalText,
            observedSelectedText: actualText,
            replacement: text
        ) {
            PuntoLog.info("setSelectedTextViaAccessibility: AX returned success but text unchanged (Safari bug), original='\(originalText ?? "nil")', expected='\(text)'")
            lastEditableSelectionElement = nil
            return false
        }

        PuntoLog.info("setSelectedTextViaAccessibility: verified text changed to '\(actualText?.prefix(20) ?? "nil")'")

        if let replacementRange = AccessibilityReplacementPolicy.replacementSelectionRange(
            originalSelectionLocation: originalSelectionLocation,
            replacement: text,
            keepSelection: keepSelection
        ) {
            var newRange = CFRange(location: replacementRange.location, length: replacementRange.length)
            if let rangeValue = AXValueCreate(.cfRange, &newRange) {
                let selectResult = AXUIElementSetAttributeValue(
                    focusedElement,
                    kAXSelectedTextRangeAttribute as CFString,
                    rangeValue
                )
                if selectResult == .success {
                    PuntoLog.info("setSelectedTextViaAccessibility: re-selected \(text.count) chars")
                } else {
                    PuntoLog.info("setSelectedTextViaAccessibility: failed to re-select, error=\(selectResult.rawValue)")
                }
            }
        } else if keepSelection {
            PuntoLog.info("setSelectedTextViaAccessibility: skipped re-select because original selection range was unavailable")
        }

        return true
    }

    private func selectedTextViaAccessibility() -> ProbeResult {
        guard let focusedElement = accessibilityElements.focusedElement() else {
            PuntoLog.info("getSelectedTextViaAccessibility: no focused element")
            return .noFocus
        }
        var sawEmptySelection = false

        let focusedResult = tryGetSelectedText(focusedElement)
        switch focusedResult {
        case .text(let text, let element):
            PuntoLog.info("getSelectedTextViaAccessibility: direct succeeded")
            return .text(text, element)
        case .empty:
            PuntoLog.info("getSelectedTextViaAccessibility: direct returned empty (nothing selected)")
        case .noFocus, .failed:
            break
        }
        sawEmptySelection = AccessibilitySelectionSearchPolicy.sawEmptySelection(
            sawEmptySelection,
            after: focusedResult.searchOutcome
        )
        guard AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: focusedResult.searchOutcome) else {
            return focusedResult
        }

        if let appFocusedElement = accessibilityElements.appFocusedElement() {
            let appFocusedResult = tryGetSelectedText(appFocusedElement)
            switch appFocusedResult {
            case .text(let text, let element):
                PuntoLog.info("getSelectedTextViaAccessibility: appFocusedElement succeeded")
                return .text(text, element)
            case .empty:
                break
            case .noFocus, .failed:
                break
            }
            sawEmptySelection = AccessibilitySelectionSearchPolicy.sawEmptySelection(
                sawEmptySelection,
                after: appFocusedResult.searchOutcome
            )
            guard AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: appFocusedResult.searchOutcome) else {
                return appFocusedResult
            }
        }

        let recursiveResult = searchForSelectedText(focusedElement, depth: 0)
        switch recursiveResult {
        case .text(let text, let element):
            PuntoLog.info("getSelectedTextViaAccessibility: recursive search found text")
            return .text(text, element)
        case .empty:
            break
        case .noFocus, .failed:
            break
        }
        sawEmptySelection = AccessibilitySelectionSearchPolicy.sawEmptySelection(
            sawEmptySelection,
            after: recursiveResult.searchOutcome
        )

        switch AccessibilitySelectionSearchPolicy.finalOutcomeAfterSearch(sawEmptySelection: sawEmptySelection) {
        case .empty:
            PuntoLog.info("getSelectedTextViaAccessibility: no selected text found after empty AX selection")
            return .empty
        case .failed:
            PuntoLog.info("getSelectedTextViaAccessibility: all methods failed")
            return .failed
        }
    }

    private func tryGetSelectedText(_ element: AXUIElement) -> ProbeResult {
        let (result, selectedText) = AccessibilityValueBridge.stringAttributeResult(
            kAXSelectedTextAttribute as CFString,
            from: element
        )

        if result != .success {
            return .failed
        }

        if let text = selectedText, !text.isEmpty {
            PuntoLog.info("tryGetSelectedText: got '\(text.prefix(30))'")
            return .text(text, element)
        }

        return .empty
    }

    private func searchForSelectedText(_ element: AXUIElement, depth: Int) -> ProbeResult {
        guard AccessibilityTraversalPolicy.shouldInspectDescendant(depth: depth) else {
            return .failed
        }

        guard let childArray = AccessibilityValueBridge.elementArrayAttribute(kAXChildrenAttribute as CFString, from: element) else {
            return .failed
        }

        var sawEmptySelection = false
        for child in childArray {
            let childResult = tryGetSelectedText(child)
            switch childResult {
            case .text(let text, let element):
                PuntoLog.info("searchForSelectedText: found text at depth \(depth)")
                return .text(text, element)
            case .empty:
                break
            case .noFocus, .failed:
                break
            }
            sawEmptySelection = AccessibilitySelectionSearchPolicy.sawEmptySelection(
                sawEmptySelection,
                after: childResult.searchOutcome
            )
            guard AccessibilitySelectionSearchPolicy.shouldTryAlternativeSelectionSource(after: childResult.searchOutcome) else {
                return childResult
            }

            let descendantResult = searchForSelectedText(child, depth: depth + 1)
            switch descendantResult {
            case .text:
                return descendantResult
            case .empty:
                break
            case .noFocus, .failed:
                break
            }
            sawEmptySelection = AccessibilitySelectionSearchPolicy.sawEmptySelection(
                sawEmptySelection,
                after: descendantResult.searchOutcome
            )
        }

        switch AccessibilitySelectionSearchPolicy.finalOutcomeAfterSearch(sawEmptySelection: sawEmptySelection) {
        case .empty:
            return .empty
        case .failed:
            return .failed
        }
    }

    private func elementSupportsSelectedTextReplacement(_ element: AXUIElement) -> Bool {
        let capability = accessibilityElements.selectedTextReplacementCapability(of: element)
        if let editable = capability.axEditable {
            PuntoLog.info("elementSupportsSelectedTextReplacement: AXEditable=\(editable)")
        }
        if capability.selectedTextSettable {
            PuntoLog.info("elementSupportsSelectedTextReplacement: AXSelectedText settable")
        }

        if capability.supportsDirectSelectedTextReplacement {
            return true
        }

        PuntoLog.info("elementSupportsSelectedTextReplacement: no editable/settable replacement capability (\(capability.logDescription))")
        return false
    }
}
