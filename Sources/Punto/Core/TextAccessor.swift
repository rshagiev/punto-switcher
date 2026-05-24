import AppKit
import ApplicationServices
import Carbon.HIToolbox
import PuntoCore

/// Handles getting and setting selected text using Accessibility API
/// Falls back to clipboard-based approach for apps that don't support Accessibility
final class TextAccessor {

    typealias ReplacementMethod = TextReplacementMethod
    typealias CapturedText = PuntoCore.CapturedText

    private let shouldRestorePasteboard: () -> Bool
    private let keyboardEvents: KeyboardEventTransport
    private var lastEditableSelectionElement: AXUIElement?

    init(
        shouldRestorePasteboard: @escaping () -> Bool = { true },
        keyboardEvents: KeyboardEventTransport = KeyboardEventTransport()
    ) {
        self.shouldRestorePasteboard = shouldRestorePasteboard
        self.keyboardEvents = keyboardEvents
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
        if let focusedElement = getFocusedElement(),
           elementOrDescendantIsPasswordField(focusedElement, depth: 0) {
            PuntoLog.info("isPasswordField: secure field detected from focused element tree")
            return true
        }

        if let appFocusedElement = getAppFocusedElement(),
           elementOrDescendantIsPasswordField(appFocusedElement, depth: 0) {
            PuntoLog.info("isPasswordField: secure field detected from app focusedUIElement tree")
            return true
        }

        return false
    }

    func canDoSearchClick(bundleID: String?) -> Bool {
        guard let focusedElement = getFocusedElement() else {
            PuntoLog.info("canDoSearchClick: no focused element")
            return false
        }

        let role = accessibilityRole(of: focusedElement)
        let canSearch = SearchClickPolicy.canDoSearchClick(role: role, bundleID: bundleID)
        PuntoLog.info("canDoSearchClick: role='\(role ?? "?")' bundle='\(bundleID ?? "?")' result=\(canSearch)")
        return canSearch
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

        for child in childArray {
            if elementOrDescendantIsPasswordField(child, depth: depth + 1) {
                return true
            }
        }

        return false
    }

    private func elementIsPasswordField(_ element: AXUIElement) -> Bool {
        return TextTrackingSecurityPolicy.isPasswordLikeAccessibilityElement(
            role: AccessibilityValueBridge.stringAttribute(kAXRoleAttribute as CFString, from: element),
            subrole: AccessibilityValueBridge.stringAttribute(kAXSubroleAttribute as CFString, from: element)
        )
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
                        accessibilityRoles: accessibilityRoles(
                            from: element,
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
        guard let focusedElement = getFocusedElement() else {
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
        if let appFocusedElement = getAppFocusedElement() {
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

    /// Gets focusedUIElement directly from application (bypass for Electron/Safari)
    private func getAppFocusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()

        let (appResult, appElement) = AccessibilityValueBridge.elementAttributeResult(
            kAXFocusedApplicationAttribute as CFString,
            from: systemWide,
            context: "getAppFocusedElement: focused app"
        )
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
        let role = accessibilityRole(of: element)
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

    private func accessibilityRole(of element: AXUIElement) -> String? {
        AccessibilityValueBridge.stringAttribute(kAXRoleAttribute as CFString, from: element)
    }

    private func accessibilityRoles(from element: AXUIElement, maxDepth: Int) -> [String] {
        var roles: [String] = []
        var current = element

        for depth in 0...maxDepth {
            guard AccessibilityTraversalPolicy.shouldCollectAncestorRole(atDepth: depth) else {
                break
            }

            if let role = accessibilityRole(of: current) {
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

    // MARK: - Clipboard Fallback

    private func getSelectedTextViaClipboard() -> String? {
        PuntoLog.info("getSelectedTextViaClipboard: using Cmd+C fallback")

        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot(pasteboard)
        let previousClipboardText = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        let copyBaselineChangeCount = pasteboard.changeCount

        _ = keyboardEvents.postCommandCopyAnnotated()

        // Poll clipboard with short intervals instead of one long wait
        // This makes fast apps respond quickly while still supporting slow ones
        for i in 1...ClipboardCapturePolicy.maxPollAttempts {
            Thread.sleep(forTimeInterval: ClipboardCapturePolicy.pollInterval)
            let pasteboardChanged = pasteboard.changeCount != copyBaselineChangeCount
            if ClipboardCapturePolicy.shouldStopPolling(pasteboardChanged: pasteboardChanged) {
                break
            }
            // After 60ms, try HID fallback
            if ClipboardCapturePolicy.shouldAttemptHIDFallback(pollAttempt: i, pasteboardChanged: pasteboardChanged) {
                _ = keyboardEvents.postCommandCopyHID()
            }
        }

        let copyChangedPasteboard = pasteboard.changeCount != copyBaselineChangeCount
        guard let text = ClipboardCapturePolicy.capturedTextAfterCopy(
            pasteboardText: pasteboard.string(forType: .string),
            pasteboardChanged: copyChangedPasteboard,
            previousClipboardText: previousClipboardText
        ) else {
            PuntoLog.info("getSelectedTextViaClipboard: no text in clipboard")
            restorePasteboardIfEnabled(snapshot, to: pasteboard, reason: "clipboard capture failed")
            return nil
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        PuntoLog.info("getSelectedTextViaClipboard: got '\(trimmed.prefix(30))' (raw \(text.count) chars, trimmed \(trimmed.count) chars)")
        restorePasteboardIfEnabled(snapshot, to: pasteboard, reason: "clipboard capture completed")
        return text
    }

    private func currentClipboardText() -> String? {
        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            PuntoLog.info("currentClipboardText: clipboard empty")
            return nil
        }

        return text
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
        guard let focusedElement = lastEditableSelectionElement ?? getFocusedElement() else {
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
        let pasteboard = NSPasteboard.general

        let snapshot = PasteboardSnapshot(pasteboard)

        // Set new text to clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let replacementChangeCount = pasteboard.changeCount

        PuntoLog.info("setSelectedTextViaClipboard: pasting \(text.count) chars")

        guard keyboardEvents.postCommandPasteHID() else {
            PuntoLog.info("setSelectedTextViaClipboard: failed to send Cmd+V")
            restorePasteboardIfEnabled(snapshot, to: pasteboard, reason: "selected-text clipboard paste failed")
            return false
        }
        Thread.sleep(forTimeInterval: SelectedTextClipboardReplacementPolicy.postPasteDelay)

        PuntoLog.info("setSelectedTextViaClipboard: paste completed")

        // Select the pasted text using Shift+Cmd+Left (select to beginning of line/word)
        // Much faster than character-by-character selection
        if SelectedTextClipboardReplacementPolicy.shouldSelectAfterPaste(selectAfterPaste, replacementText: text) {
            Thread.sleep(forTimeInterval: SelectedTextClipboardReplacementPolicy.selectAfterPasteDelay)
            keyboardEvents.selectBackwards(characterCount: text.count)
            PuntoLog.info("setSelectedTextViaClipboard: selected backwards")
        }

        // Restore original clipboard asynchronously
        DispatchQueue.main.asyncAfter(deadline: .now() + SelectedTextClipboardReplacementPolicy.clipboardRestoreDelay) {
            if SelectedTextClipboardReplacementPolicy.shouldRestoreClipboardAfterPaste(
                currentChangeCount: pasteboard.changeCount,
                replacementChangeCount: replacementChangeCount
            ) {
                self.restorePasteboardIfEnabled(snapshot, to: pasteboard, reason: "selected-text clipboard replacement")
            }
        }
        return true
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

        // Paste replacement via clipboard (much faster than typing)
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot(pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(replacement, forType: .string)
        let replacementChangeCount = pasteboard.changeCount

        let pasteStartTime = Date()
        guard keyboardEvents.postCommandPasteHID() else {
            PuntoLog.info("replaceLastWord: aborting because Cmd+V events could not be created")
            restorePasteboardIfEnabled(snapshot, to: pasteboard, reason: "keyboard replacement paste failed")
            return false
        }
        Thread.sleep(forTimeInterval: KeyboardReplacementPolicy.postPasteDelay)
        let pasteTime = Date().timeIntervalSince(pasteStartTime) * 1000
        PuntoLog.info("replaceLastWord: paste took \(String(format: "%.1f", pasteTime))ms")

        // Verify paste worked by checking clipboard wasn't cleared by app
        let clipboardAfterPaste = pasteboard.string(forType: .string)
        if clipboardAfterPaste == replacement {
            PuntoLog.info("replaceLastWord: clipboard still contains replacement (paste likely succeeded)")
        } else {
            PuntoLog.info("replaceLastWord: clipboard changed to '\(clipboardAfterPaste?.prefix(20) ?? "nil")' (app may have modified it)")
        }

        // Note: Active verification via select+copy is destructive - removed
        // Instead rely on AX focus check and clipboard state for diagnostics

        // Restore clipboard asynchronously
        DispatchQueue.main.asyncAfter(deadline: .now() + KeyboardReplacementPolicy.clipboardRestoreDelay) {
            if KeyboardReplacementPolicy.shouldRestoreClipboardAfterPaste(
                currentChangeCount: pasteboard.changeCount,
                replacementChangeCount: replacementChangeCount
            ) {
                self.restorePasteboardIfEnabled(snapshot, to: pasteboard, reason: "keyboard replacement")
                PuntoLog.debug("replaceLastWord: clipboard restored to original")
            }
        }

        let totalTime = Date().timeIntervalSince(startTime) * 1000
        PuntoLog.info("replaceLastWord: completed in \(String(format: "%.1f", totalTime))ms (sent \(backspacesSent) backspaces + Cmd+V with '\(replacement)')")
        return true
    }

    @discardableResult
    func replaceRecentText(length: Int, with replacement: String) -> Bool {
        replaceLastWord(wordLength: length, with: replacement)
    }

    // MARK: - Helpers

    private func getFocusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()

        // Try to get focused application with retry
        // Sometimes AX API returns -25212 temporarily
        var focusedAppElement: AXUIElement?
        var appResult: AXError = .failure

        for attempt in 1...AccessibilityReplacementPolicy.focusedApplicationRetryAttempts {
            (appResult, focusedAppElement) = AccessibilityValueBridge.elementAttributeResult(
                kAXFocusedApplicationAttribute as CFString,
                from: systemWide,
                context: "getFocusedElement: focused app"
            )
            if appResult == .success {
                break
            }
            if AccessibilityReplacementPolicy.shouldRetryFocusedApplicationLookup(attempt: attempt) {
                Thread.sleep(forTimeInterval: AccessibilityReplacementPolicy.focusedApplicationRetryDelay)
            }
        }

        guard appResult == .success, focusedAppElement != nil else {
            // Log which app is frontmost via NSWorkspace (works even when AX fails)
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

        // Log which app is focused
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

        // Log element role
        if let role = accessibilityRole(of: element) {
            PuntoLog.info("getFocusedElement: focused element role='\(role)'")
        }

        return element
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

    // MARK: - Debugging Helpers

    private func restorePasteboardIfEnabled(_ snapshot: PasteboardSnapshot, to pasteboard: NSPasteboard, reason: String) {
        guard shouldRestorePasteboard() else {
            PuntoLog.info("Pasteboard restore skipped by setting (reason: \(reason))")
            return
        }

        snapshot.restore(to: pasteboard)
    }

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
        let systemWide = AXUIElementCreateSystemWide()

        // Get focused app
        let (appResult, appElement) = AccessibilityValueBridge.elementAttributeResult(
            kAXFocusedApplicationAttribute as CFString,
            from: systemWide,
            context: "checkKeyboardFocusEvidence: focused app"
        )

        guard appResult == .success, let appElement else {
            return .noFocusedApplication(errorCode: appResult.rawValue)
        }

        // Get app title
        let appName = AccessibilityValueBridge.stringAttribute(kAXTitleAttribute as CFString, from: appElement) ?? "?"

        // Get focused UI element
        let (elemResult, axElement) = AccessibilityValueBridge.elementAttributeResult(
            kAXFocusedUIElementAttribute as CFString,
            from: appElement,
            context: "checkKeyboardFocusEvidence: focusedUIElement"
        )

        guard elemResult == .success, let axElement else {
            return .noFocusedElement(appName: appName, errorCode: elemResult.rawValue)
        }

        // Get element role
        let roleName = accessibilityRole(of: axElement) ?? "?"

        // Check if element is enabled
        let isEnabled = AccessibilityValueBridge.boolAttribute(kAXEnabledAttribute as CFString, from: axElement) ?? true

        // Check if element has keyboard focus
        let hasFocus = AccessibilityValueBridge.boolAttribute(kAXFocusedAttribute as CFString, from: axElement) ?? false

        return .focusedElement(
            appName: appName,
            role: roleName,
            isEnabled: isEnabled,
            isFocused: hasFocus
        )
    }

}
