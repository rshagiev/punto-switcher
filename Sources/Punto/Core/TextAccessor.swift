import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// Handles getting and setting selected text using Accessibility API
/// Falls back to clipboard-based approach for apps that don't support Accessibility
final class TextAccessor {

    /// Tracks if the last getSelectedText used clipboard fallback
    /// If true, setSelectedText should also use clipboard (Cmd+V) since AX won't work
    private var lastGetUsedClipboard = false

    // MARK: - Security Detection

    /// Checks if Secure Keyboard Input is enabled (e.g., in Terminal password prompts)
    /// When enabled, CGEvent simulation is blocked for security
    func isSecureInputEnabled() -> Bool {
        return IsSecureEventInputEnabled()
    }

    // MARK: - Get Selected Text

    /// Attempts to get the currently selected text using Accessibility API
    /// Falls back to Cmd+C clipboard method for browsers/apps that don't expose selectedText
    func getSelectedText() -> String? {
        // 1. Try Accessibility API (direct access)
        if let text = getSelectedTextViaAccessibility() {
            lastGetUsedClipboard = false
            return text
        }

        // 2. Fallback: Cmd+C for browsers and other problematic apps
        lastGetUsedClipboard = true
        return getSelectedTextViaClipboard()
    }

    private func getSelectedTextViaAccessibility() -> String? {
        PuntoLog.info("getSelectedTextViaAccessibility: starting")

        guard let focusedElement = getFocusedElement() else {
            PuntoLog.info("getSelectedTextViaAccessibility: no focused element")
            return nil
        }

        // Direct attempt on focused element
        PuntoLog.info("getSelectedTextViaAccessibility: trying direct on focused element")
        if let text = tryGetSelectedText(focusedElement) {
            PuntoLog.info("getSelectedTextViaAccessibility: direct succeeded")
            return text
        }

        // For Safari/Electron: try via app's focusedUIElement
        // (as AXorcist does for Chromium apps)
        PuntoLog.info("getSelectedTextViaAccessibility: trying via app focusedUIElement")
        if let appFocusedElement = getAppFocusedElement() {
            if let text = tryGetSelectedText(appFocusedElement) {
                PuntoLog.info("getSelectedTextViaAccessibility: appFocusedElement succeeded")
                return text
            }
        }

        // Recursive search in children (maxDepth=5)
        PuntoLog.info("getSelectedTextViaAccessibility: trying recursive search in children")
        let result = searchForSelectedText(focusedElement, depth: 0)
        PuntoLog.info("getSelectedTextViaAccessibility: recursive search returned '\(result?.prefix(20) ?? "nil")'")
        return result
    }

    /// Attempts to get selectedText from an element
    private func tryGetSelectedText(_ element: AXUIElement) -> String? {
        var selectedText: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )

        // Log the result for debugging
        if result != .success {
            // Only log non-noValue errors (noValue is normal for containers)
            if result.rawValue != -25212 {
                PuntoLog.info("tryGetSelectedText: AX error=\(result.rawValue)")
            }
            return nil
        }

        guard let text = selectedText as? String, !text.isEmpty else {
            PuntoLog.info("tryGetSelectedText: got empty or nil string")
            return nil
        }

        PuntoLog.info("tryGetSelectedText: SUCCESS got '\(text.prefix(30))'")
        return text
    }

    /// Gets focusedUIElement directly from application (bypass for Electron/Safari)
    private func getAppFocusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedApp: AnyObject?
        let appResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )
        guard appResult == .success else {
            PuntoLog.info("getAppFocusedElement: failed to get app, error=\(appResult.rawValue)")
            return nil
        }

        let appElement = focusedApp as! AXUIElement

        var focusedElement: AnyObject?
        let elemResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard elemResult == .success else {
            PuntoLog.info("getAppFocusedElement: failed to get focusedUIElement, error=\(elemResult.rawValue)")
            return nil
        }

        PuntoLog.info("getAppFocusedElement: got focusedUIElement")
        return (focusedElement as! AXUIElement)
    }

    /// Recursive search for selectedText in child elements
    private func searchForSelectedText(_ element: AXUIElement, depth: Int) -> String? {
        guard depth < 5 else {
            return nil
        }

        var children: AnyObject?
        let childResult = AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &children
        )
        guard childResult == .success, let childArray = children as? [AXUIElement] else {
            if depth == 0 {
                PuntoLog.info("searchForSelectedText: no children at depth 0, error=\(childResult.rawValue)")
            }
            return nil
        }

        if depth == 0 {
            PuntoLog.info("searchForSelectedText: found \(childArray.count) children at depth 0")
        }

        for child in childArray {
            // First check the element itself
            if let text = tryGetSelectedText(child) {
                PuntoLog.info("searchForSelectedText: found text at depth \(depth)")
                return text
            }
            // Then recursively search in its children
            if let text = searchForSelectedText(child, depth: depth + 1) {
                return text
            }
        }
        return nil
    }

    // MARK: - Clipboard Fallback

    private func getSelectedTextViaClipboard() -> String? {
        PuntoLog.info("getSelectedTextViaClipboard: using Cmd+C fallback")

        let pasteboard = NSPasteboard.general
        let previousContent = pasteboard.string(forType: .string)
        let initialChangeCount = pasteboard.changeCount

        pasteboard.clearContents()

        // Send Cmd+C via CGEvent (fastest method)
        let source = CGEventSource(stateID: .combinedSessionState)
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cgAnnotatedSessionEventTap)
        }
        Thread.sleep(forTimeInterval: 0.01)
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cgAnnotatedSessionEventTap)
        }

        // Poll clipboard with short intervals instead of one long wait
        // This makes fast apps respond quickly while still supporting slow ones
        for i in 1...10 {
            Thread.sleep(forTimeInterval: 0.02)  // 20ms per iteration, max 200ms total
            if pasteboard.changeCount != initialChangeCount {
                break
            }
            // After 60ms, try HID fallback
            if i == 3 {
                let sourceHID = CGEventSource(stateID: .hidSystemState)
                if let keyDown = CGEvent(keyboardEventSource: sourceHID, virtualKey: 8, keyDown: true) {
                    keyDown.flags = .maskCommand
                    keyDown.post(tap: .cghidEventTap)
                }
                Thread.sleep(forTimeInterval: 0.01)
                if let keyUp = CGEvent(keyboardEventSource: sourceHID, virtualKey: 8, keyDown: false) {
                    keyUp.flags = .maskCommand
                    keyUp.post(tap: .cghidEventTap)
                }
            }
        }

        let selected = pasteboard.string(forType: .string)

        guard let text = selected, !text.isEmpty else {
            PuntoLog.info("getSelectedTextViaClipboard: no text in clipboard")
            return nil
        }

        // If clipboard content is same as before, nothing was selected
        if text == previousContent {
            PuntoLog.info("getSelectedTextViaClipboard: clipboard unchanged (nothing selected)")
            return nil
        }

        PuntoLog.info("getSelectedTextViaClipboard: got '\(text.prefix(30))'")
        return text
    }

    // MARK: - Set Selected Text

    /// Replaces the currently selected text with new text
    /// - Parameters:
    ///   - text: The text to insert
    ///   - keepSelection: If true, the inserted text will be selected after insertion (for undo support)
    func setSelectedText(_ text: String, keepSelection: Bool = false) {
        PuntoLog.info("setSelectedText called with \(text.count) chars, keepSelection=\(keepSelection), lastGetUsedClipboard=\(lastGetUsedClipboard)")

        // If getSelectedText used clipboard, we must use clipboard for set too
        // because AX API returns "success" but doesn't actually work for web content
        if lastGetUsedClipboard {
            PuntoLog.info("setSelectedText: using clipboard (matched get method)")
            setSelectedTextViaClipboard(text, selectAfterPaste: keepSelection)
            return
        }

        // Try Accessibility API first
        if setSelectedTextViaAccessibility(text, keepSelection: keepSelection) {
            PuntoLog.info("setSelectedText: Accessibility API succeeded")
            return
        }

        PuntoLog.info("setSelectedText: Accessibility API failed, using clipboard")
        // Fall back to clipboard method
        setSelectedTextViaClipboard(text, selectAfterPaste: keepSelection)
    }

    private func setSelectedTextViaAccessibility(_ text: String, keepSelection: Bool = false) -> Bool {
        guard let focusedElement = getFocusedElement() else {
            PuntoLog.info("setSelectedTextViaAccessibility: no focused element")
            return false
        }

        // Get current selected text to verify change later
        var currentSelectedText: AnyObject?
        AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute as CFString, &currentSelectedText)
        let originalText = currentSelectedText as? String

        // Get current selection range before replacing
        var selectionRange: AnyObject?
        var startIndex: Int = 0
        if keepSelection {
            if AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, &selectionRange) == .success,
               let range = selectionRange {
                var cfRange = CFRange(location: 0, length: 0)
                // selectionRange is an AXValue containing CFRange
                AXValueGetValue(range as! AXValue, .cfRange, &cfRange)
                startIndex = cfRange.location
            }
        }

        let result = AXUIElementSetAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        if result != .success {
            PuntoLog.info("setSelectedTextViaAccessibility: AXUIElementSetAttributeValue failed with \(result.rawValue)")
            return false
        }

        // Verify the text actually changed (Safari returns success but doesn't change text)
        Thread.sleep(forTimeInterval: 0.05)
        var newSelectedText: AnyObject?
        AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute as CFString, &newSelectedText)
        let actualText = newSelectedText as? String

        // If text didn't change or still equals original, AX set failed silently
        if actualText == originalText && originalText != text {
            PuntoLog.info("setSelectedTextViaAccessibility: AX returned success but text unchanged (Safari bug), original='\(originalText ?? "nil")', expected='\(text)'")
            return false
        }

        PuntoLog.info("setSelectedTextViaAccessibility: verified text changed to '\(actualText?.prefix(20) ?? "nil")'")

        // If keepSelection is true, select the inserted text
        if keepSelection {
            var newRange = CFRange(location: startIndex, length: text.utf16.count)
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
        }

        return true
    }

    private func setSelectedTextViaClipboard(_ text: String, selectAfterPaste: Bool = false) {
        let pasteboard = NSPasteboard.general

        // Save current clipboard to restore later
        let savedClipboard = pasteboard.string(forType: .string)

        // Set new text to clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        PuntoLog.info("setSelectedTextViaClipboard: pasting \(text.count) chars")

        // Simulate Cmd+V
        simulatePaste()
        Thread.sleep(forTimeInterval: 0.03)

        PuntoLog.info("setSelectedTextViaClipboard: paste completed")

        // Select the pasted text using Shift+Cmd+Left (select to beginning of line/word)
        // Much faster than character-by-character selection
        if selectAfterPaste {
            Thread.sleep(forTimeInterval: 0.02)
            selectBackwardsFast(characterCount: text.count)
            PuntoLog.info("setSelectedTextViaClipboard: selected backwards")
        }

        // Restore original clipboard asynchronously
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let old = savedClipboard {
                pasteboard.clearContents()
                pasteboard.setString(old, forType: .string)
            }
        }
    }

    /// Fast backward selection using Shift+Arrow with batching
    private func selectBackwardsFast(characterCount: Int) {
        let source = CGEventSource(stateID: .hidSystemState)

        // For short text, use character-by-character (more precise)
        // For longer text, use word-based selection or batch
        if characterCount <= 10 {
            // Character by character but without delays between
            for _ in 0..<characterCount {
                if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 123, keyDown: true) {
                    keyDown.flags = .maskShift
                    keyDown.post(tap: .cghidEventTap)
                }
                if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 123, keyDown: false) {
                    keyUp.flags = .maskShift
                    keyUp.post(tap: .cghidEventTap)
                }
            }
            Thread.sleep(forTimeInterval: 0.02)
        } else {
            // Use Cmd+Shift+Left repeatedly to select by words (much faster)
            // Each press selects ~1 word, estimate ~5 chars per word
            let wordCount = (characterCount + 4) / 5
            for _ in 0..<wordCount {
                if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 123, keyDown: true) {
                    keyDown.flags = [.maskShift, .maskAlternate]  // Opt+Shift+Left = select word
                    keyDown.post(tap: .cghidEventTap)
                }
                if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 123, keyDown: false) {
                    keyUp.flags = [.maskShift, .maskAlternate]
                    keyUp.post(tap: .cghidEventTap)
                }
            }
            Thread.sleep(forTimeInterval: 0.02)
        }
    }

    /// Simulates Cmd+V keystroke for paste operation
    private func simulatePaste() {
        // Use .cghidEventTap for better Safari compatibility
        let source = CGEventSource(stateID: .hidSystemState)

        // Create key down event for V with Command modifier
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }

        Thread.sleep(forTimeInterval: 0.02)

        // Create key up event for V with Command modifier
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }

        PuntoLog.info("simulatePaste: sent Cmd+V via CGEvent (HID)")
    }

    // MARK: - Replace Last Word

    /// Deletes the last word and pastes the replacement via clipboard
    /// Much faster than character-by-character typing
    func replaceLastWord(wordLength: Int, with replacement: String) {
        PuntoLog.info("replaceLastWord: deleting \(wordLength) chars, replacing with '\(replacement)'")

        // Use Opt+Backspace to delete word at once (faster than multiple backspaces)
        // This works in most apps and deletes the entire word
        simulateKeyPress(keyCode: 51, flags: .maskAlternate) // Opt+Delete
        Thread.sleep(forTimeInterval: 0.02)

        // If Opt+Backspace didn't work (some apps don't support it), fall back to multiple backspaces
        // We'll use clipboard paste anyway, so we rely on Opt+Backspace working

        // Paste replacement via clipboard (much faster than typing)
        let pasteboard = NSPasteboard.general
        let savedClipboard = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(replacement, forType: .string)

        // Simulate Cmd+V
        simulatePaste()
        Thread.sleep(forTimeInterval: 0.03)

        // Restore clipboard asynchronously
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let old = savedClipboard {
                pasteboard.clearContents()
                pasteboard.setString(old, forType: .string)
            }
        }

        PuntoLog.info("replaceLastWord: completed")
    }

    // MARK: - Helpers

    private func getFocusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()

        // Try to get focused application with retry
        // Sometimes AX API returns -25212 temporarily
        var focusedApp: AnyObject?
        var appResult: AXError = .failure

        for attempt in 1...3 {
            appResult = AXUIElementCopyAttributeValue(
                systemWide,
                kAXFocusedApplicationAttribute as CFString,
                &focusedApp
            )
            if appResult == .success {
                break
            }
            if attempt < 3 {
                Thread.sleep(forTimeInterval: 0.05)
            }
        }

        guard appResult == .success, let app = focusedApp else {
            PuntoLog.info("getFocusedElement: failed to get focused app, error=\(appResult.rawValue)")
            return nil
        }

        let appElement = app as! AXUIElement

        // Log which app is focused
        var appTitle: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXTitleAttribute as CFString, &appTitle) == .success {
            PuntoLog.info("getFocusedElement: focused app is '\(appTitle as? String ?? "unknown")'")
        }

        var focusedElement: AnyObject?
        let elemResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard elemResult == .success else {
            PuntoLog.info("getFocusedElement: failed to get focused element, error=\(elemResult.rawValue)")
            return nil
        }

        // Log element role
        var role: AnyObject?
        if AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXRoleAttribute as CFString, &role) == .success {
            PuntoLog.info("getFocusedElement: focused element role='\(role as? String ?? "unknown")'")
        }

        return (focusedElement as! AXUIElement)
    }

    private func simulateKeyPress(keyCode: CGKeyCode, flags: CGEventFlags) {
        // Use privateState for better isolation
        let source = CGEventSource(stateID: .privateState)

        // Key down
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = flags
            keyDown.post(tap: .cghidEventTap)
        }

        // Small delay between key down and key up
        Thread.sleep(forTimeInterval: 0.01)

        // Key up
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = flags
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
