import AppKit
import ApplicationServices
import Carbon.HIToolbox
import PuntoCore

/// Handles getting and setting selected text using Accessibility API
/// Falls back to clipboard-based approach for apps that don't support Accessibility
final class TextAccessor {

    typealias ReplacementMethod = TextReplacementMethod
    typealias CapturedText = PuntoCore.CapturedText

    private let keyboardEvents: KeyboardEventTransport
    private let accessibilityElements: AccessibilityElementClient
    private let clipboard: ClipboardTransport
    private var lastEditableSelectionElement: AXUIElement?

    init(
        shouldRestorePasteboard: @escaping () -> Bool = { true },
        keyboardEvents: KeyboardEventTransport = KeyboardEventTransport(),
        accessibilityElements: AccessibilityElementClient = AccessibilityElementClient(),
        clipboard: ClipboardTransport? = nil
    ) {
        self.keyboardEvents = keyboardEvents
        self.accessibilityElements = accessibilityElements
        self.clipboard = clipboard ?? ClipboardTransport(
            shouldRestorePasteboard: shouldRestorePasteboard,
            keyboardEvents: keyboardEvents
        )
    }

    // MARK: - Security Detection

    /// Checks if Secure Keyboard Input is enabled (e.g., in Terminal password prompts)
    /// When enabled, CGEvent simulation is blocked for security
    func isSecureInputEnabled() -> Bool {
        return IsSecureEventInputEnabled()
    }

    /// Checks if focused element is a secure/password text field
    /// Used to skip conversion in browser password fields
    func isPasswordField() -> Bool {
        accessibilityElements.isPasswordField()
    }

    func canDoSearchClick(bundleID: String?) -> Bool {
        accessibilityElements.canDoSearchClick(bundleID: bundleID)
    }

    // MARK: - Get Selected Text

    /// Result of trying to get selected text via Accessibility API
    private enum AXGetResult {
        case text(String, AXUIElement)  // Got non-empty selected text and source element
        case empty              // AX worked, but nothing is selected
        case noFocus            // Couldn't get focused element (skip clipboard, use WordTracker)
        case failed             // AX API failed on element (should try clipboard fallback)

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

    /// Captures a usable text selection and the safest way to replace it.
    ///
    /// The decision is capability based:
    /// - AX selections are used only when the focused element appears editable and
    ///   can set selected text.
    /// - Non-editable text surfaces are treated as terminal-like. We only accept
    ///   passive clipboard selection when it ends with the tracked input tail.
    /// - Apps without useful AX selection still get the active Cmd+C fallback.
    func captureSelectedText(lastTrackedWord: String?, lastTrackedTail: String?) -> CapturedText? {
        let axResult = getSelectedTextViaAccessibility()
        let observation: TextCapturePolicy.AccessibilityObservation
        var activeClipboardText: String?
        var passiveClipboardText: String?
        var overrideCapturedText: CapturedText?

        switch axResult {
        case .text(let text, let element):
            let supportsReplacement = elementSupportsSelectedTextReplacement(element)
            observation = .selectedText(text, replacementSupported: supportsReplacement)
            if supportsReplacement {
                lastEditableSelectionElement = element
                PuntoLog.info("captureSelectedText: AX editable selection accepted")
            } else {
                lastEditableSelectionElement = nil
                PuntoLog.info("captureSelectedText: AX selection rejected because focused surface is not settable")
                if TextCapturePolicy.shouldAttemptActiveClipboardFallbackForNonSettableSelection(
                    selectedText: text,
                    lastTrackedTail: lastTrackedTail
                ) {
                    PuntoLog.info("captureSelectedText: trying active clipboard copy for non-settable AX selection")
                    activeClipboardText = getSelectedTextViaClipboard()
                    passiveClipboardText = currentClipboardText()
                    overrideCapturedText = TextCapturePolicy.activeClipboardFallbackForNonSettableContentSelection(
                        selectedText: text,
                        activeClipboardText: activeClipboardText,
                        accessibilityRoles: accessibilityElements.rolesFromElementToAncestors(
                            element,
                            maxDepth: AccessibilityTraversalPolicy.maxAncestorRoleDepth
                        )
                    )
                }
            }

        case .empty:
            lastEditableSelectionElement = nil
            observation = .emptySelection

        case .noFocus:
            lastEditableSelectionElement = nil
            observation = .noFocusedElement
            PuntoLog.info("captureSelectedText: noFocus, trying active clipboard fallback")
            activeClipboardText = getSelectedTextViaClipboard()

        case .failed:
            lastEditableSelectionElement = nil
            observation = .failed
            passiveClipboardText = currentClipboardText()
            activeClipboardText = getSelectedTextViaClipboard()
        }

        let captured = overrideCapturedText ?? TextCapturePolicy.captureDecision(
            observation: observation,
            activeClipboardText: activeClipboardText,
            passiveClipboardText: passiveClipboardText,
            lastTrackedWord: lastTrackedWord,
            lastTrackedTail: lastTrackedTail
        )

        if captured?.replacementMethod == .blocked {
            lastEditableSelectionElement = nil
            PuntoLog.info("captureSelectedText: blocking fallback because non-settable selection is not current command tail")
        }
        if captured?.replacementMethod != .accessibilitySelection {
            lastEditableSelectionElement = nil
        }

        return captured
    }

    private func getSelectedTextViaAccessibility() -> AXGetResult {
        guard let focusedElement = accessibilityElements.focusedElement() else {
            PuntoLog.info("getSelectedTextViaAccessibility: no focused element")
            return .noFocus
        }
        var sawEmptySelection = false

        // Direct attempt on focused element
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

        // For Safari/Electron: try via app's focusedUIElement
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

        // Recursive search in children with the shared AX traversal bound.
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
            // All methods failed - might be a browser that needs clipboard fallback.
            PuntoLog.info("getSelectedTextViaAccessibility: all methods failed")
            return .failed
        }
    }

    /// Attempts to get selectedText from an element
    private func tryGetSelectedText(_ element: AXUIElement) -> AXGetResult {
        let (result, selectedText) = AccessibilityValueBridge.stringAttributeResult(
            kAXSelectedTextAttribute as CFString,
            from: element
        )

        // AX API failed - element doesn't support selectedText
        if result != .success {
            return .failed
        }

        // AX API succeeded - check if there's actual text
        if let text = selectedText, !text.isEmpty {
            PuntoLog.info("tryGetSelectedText: got '\(text.prefix(30))'")
            return .text(text, element)
        }

        // AX succeeded but returned empty string = nothing selected
        return .empty
    }

    /// Recursive search for selectedText in child elements
    private func searchForSelectedText(_ element: AXUIElement, depth: Int) -> AXGetResult {
        guard AccessibilityTraversalPolicy.shouldInspectDescendant(depth: depth) else {
            return .failed
        }

        guard let childArray = AccessibilityValueBridge.elementArrayAttribute(kAXChildrenAttribute as CFString, from: element) else {
            return .failed
        }

        var sawEmptySelection = false
        for child in childArray {
            // First check the element itself
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

            // Then recursively search in its children
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
        let capability = selectedTextReplacementCapability(of: element)
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

    private func selectedTextReplacementCapability(of element: AXUIElement) -> AccessibilityReplacementCapability {
        accessibilityElements.selectedTextReplacementCapability(of: element)
    }

    // MARK: - Clipboard Fallback

    private func getSelectedTextViaClipboard() -> String? {
        clipboard.captureSelectedText()
    }

    private func currentClipboardText() -> String? {
        clipboard.currentText()
    }

    // MARK: - Set Selected Text

    /// Replaces the currently selected text with new text
    /// - Parameters:
    ///   - text: The text to insert
    ///   - keepSelection: If true, the inserted text will be selected after insertion (for undo support)
    @discardableResult
    func setSelectedText(_ text: String, keepSelection: Bool = false) -> Bool {
        PuntoLog.info("setSelectedText called with \(text.count) chars, keepSelection=\(keepSelection)")

        // Try Accessibility API first
        if setSelectedTextViaAccessibility(text, keepSelection: keepSelection) {
            PuntoLog.info("setSelectedText: Accessibility API succeeded")
            return true
        }

        PuntoLog.info("setSelectedText: Accessibility API failed, using clipboard")
        // Fall back to clipboard method
        return setSelectedTextViaClipboard(text, selectAfterPaste: keepSelection)
    }

    @discardableResult
    func replaceCapturedText(_ capturedText: CapturedText, with replacement: String, keepSelection: Bool = false) -> Bool {
        PuntoLog.info("replaceCapturedText: method=\(capturedText.replacementMethod), source=\(capturedText.source)")
        switch TextReplacementPolicy.plan(
            for: capturedText,
            replacement: replacement,
            keepSelection: keepSelection
        ) {
        case .accessibilitySelection(let text, let keepSelection):
            return setSelectedText(text, keepSelection: keepSelection)
        case .clipboardSelection(let text, let selectAfterPaste):
            return setSelectedTextViaClipboard(text, selectAfterPaste: selectAfterPaste)
        case .keyboardBackspacePaste(let deleteLength, let text):
            return replaceLastWord(wordLength: deleteLength, with: text)
        case .blocked:
            PuntoLog.info("replaceCapturedText: blocked capture or unrewritable tail, no replacement")
            return false
        }
    }

    private func setSelectedTextViaAccessibility(_ text: String, keepSelection: Bool = false) -> Bool {
        guard let focusedElement = lastEditableSelectionElement ?? accessibilityElements.focusedElement() else {
            PuntoLog.info("setSelectedTextViaAccessibility: no focused element")
            return false
        }

        // Get current selected text to verify change later
        let originalText = AccessibilityValueBridge.stringAttribute(kAXSelectedTextAttribute as CFString, from: focusedElement)

        // Get current selection range before replacing
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

        // Verify the text actually changed (Safari returns success but doesn't change text)
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

        // If keepSelection is true, select the inserted text
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

    private func setSelectedTextViaClipboard(_ text: String, selectAfterPaste: Bool = false) -> Bool {
        lastEditableSelectionElement = nil
        return clipboard.pasteSelectedText(text, selectAfterPaste: selectAfterPaste)
    }

    // MARK: - Replace Last Word

    /// Deletes the last word and pastes the replacement via clipboard
    @discardableResult
    func replaceLastWord(wordLength: Int, with replacement: String) -> Bool {
        let startTime = Date()

        guard KeyboardReplacementPolicy.shouldAttemptKeyboardReplacement(deleteLength: wordLength) else {
            PuntoLog.info("replaceLastWord: aborting keyboard replacement because delete length is \(wordLength)")
            return false
        }

        // Log active app state before sending events
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let isActive = frontApp.isActive
            let isHidden = frontApp.isHidden
            PuntoLog.info("replaceLastWord: target app='\(frontApp.localizedName ?? "?")' isActive=\(isActive) isHidden=\(isHidden) pid=\(frontApp.processIdentifier)")
        }

        // Check keyboard focus via AX before sending events
        let axFocusEvidence = checkKeyboardFocusEvidence()
        PuntoLog.info("replaceLastWord: AX focus check: \(axFocusEvidence.logDescription)")
        if !KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(focusEvidence: axFocusEvidence) {
            PuntoLog.info("replaceLastWord: aborting keyboard replacement because focused editable target is not verifiable")
            return false
        }

        PuntoLog.info("replaceLastWord: deleting \(wordLength) chars, replacing with '\(replacement)'")

        // Check current modifier state BEFORE delay
        let modifiersBefore = CGEventSource.flagsState(.hidSystemState)
        let modDescBefore = describeModifiers(modifiersBefore)
        PuntoLog.info("replaceLastWord: modifiers BEFORE delay: \(modDescBefore)")
        releaseLatchedKeyboardModifiers(modifiersBefore)

        // Wait until the hotkey modifiers are fully released before sending destructive keys.
        let modifiersAfter = waitForModifierRelease()
        let modDescAfter = describeModifiers(modifiersAfter)
        PuntoLog.info("replaceLastWord: modifiers AFTER release wait: \(modDescAfter)")
        if !KeyboardReplacementPolicy.shouldStartKeyboardEventsAfterModifierWait(
            modifiersArePressed: hasKeyboardModifiers(modifiersAfter)
        ) {
            PuntoLog.info("replaceLastWord: aborting keyboard replacement because modifiers are still pressed after release wait")
            return false
        }

        // Delete characters one by one using Backspace (keyCode 51)
        // Using .cghidEventTap which works for most apps
        // Do not use line-kill shortcuts here: this path must delete exactly the captured tail.
        PuntoLog.info("replaceLastWord: sending \(wordLength) backspaces via cghidEventTap (after \(Int(KeyboardReplacementPolicy.modifierReleaseSettleDelay * 1000))ms delay)")
        let backspacesSent = keyboardEvents.postBackspaces(count: wordLength)
        let backspaceTime = Date().timeIntervalSince(startTime) * 1000
        PuntoLog.info("replaceLastWord: \(backspacesSent)/\(wordLength) backspaces sent in \(String(format: "%.1f", backspaceTime))ms, waiting \(Int(KeyboardReplacementPolicy.prePasteDelay * 1000))ms")
        guard KeyboardReplacementPolicy.shouldPasteReplacementAfterBackspaces(expectedCount: wordLength, sentCount: backspacesSent) else {
            PuntoLog.info("replaceLastWord: aborting paste because not all backspaces were sent")
            return false
        }
        Thread.sleep(forTimeInterval: KeyboardReplacementPolicy.prePasteDelay)

        guard clipboard.pasteKeyboardReplacement(replacement) else {
            return false
        }

        // Note: Active verification via select+copy is destructive - removed
        // Instead rely on AX focus check and clipboard state for diagnostics

        let totalTime = Date().timeIntervalSince(startTime) * 1000
        PuntoLog.info("replaceLastWord: completed in \(String(format: "%.1f", totalTime))ms (sent \(backspacesSent) backspaces + Cmd+V with '\(replacement)')")
        return true
    }

    @discardableResult
    func replaceRecentText(length: Int, with replacement: String) -> Bool {
        replaceLastWord(wordLength: length, with: replacement)
    }

    // MARK: - Helpers

    // MARK: - Debugging Helpers

    /// Describes current modifier key state
    private func describeModifiers(_ flags: CGEventFlags) -> String {
        var parts: [String] = []
        if flags.contains(.maskCommand) { parts.append("⌘") }
        if flags.contains(.maskAlternate) { parts.append("⌥") }
        if flags.contains(.maskShift) { parts.append("⇧") }
        if flags.contains(.maskControl) { parts.append("⌃") }
        return parts.isEmpty ? "none" : parts.joined()
    }

    private func waitForModifierRelease() -> CGEventFlags {
        Thread.sleep(forTimeInterval: KeyboardReplacementPolicy.modifierReleaseSettleDelay)

        let deadline = Date().addingTimeInterval(KeyboardReplacementPolicy.modifierReleaseMaxWait)
        var flags = CGEventSource.flagsState(.hidSystemState)
        while hasKeyboardModifiers(flags), Date() < deadline {
            Thread.sleep(forTimeInterval: KeyboardReplacementPolicy.modifierReleasePollInterval)
            flags = CGEventSource.flagsState(.hidSystemState)
        }

        return flags
    }

    private func releaseLatchedKeyboardModifiers(_ flags: CGEventFlags) {
        let snapshot = ModifierFlagsSnapshot(
            command: flags.contains(.maskCommand),
            option: flags.contains(.maskAlternate),
            shift: flags.contains(.maskShift),
            control: flags.contains(.maskControl)
        )
        guard KeyboardModifierCleanupPolicy.shouldPostCleanup(for: snapshot) else {
            return
        }

        _ = keyboardEvents.postKeyUps(KeyboardModifierCleanupPolicy.keyUpCodes(for: snapshot))
        PuntoLog.info("replaceLastWord: sent modifier key-up cleanup for \(describeModifiers(flags))")
    }

    private func hasKeyboardModifiers(_ flags: CGEventFlags) -> Bool {
        flags.contains(.maskCommand)
            || flags.contains(.maskAlternate)
            || flags.contains(.maskShift)
            || flags.contains(.maskControl)
    }

    /// Checks keyboard focus state via AX API.
    private func checkKeyboardFocusEvidence() -> KeyboardFocusEvidence {
        accessibilityElements.keyboardFocusEvidence()
    }

}
