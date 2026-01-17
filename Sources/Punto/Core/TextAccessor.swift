import AppKit
import ApplicationServices

/// Handles getting and setting selected text using Accessibility API
/// Falls back to clipboard-based approach for apps that don't support Accessibility
final class TextAccessor {

    // MARK: - Get Selected Text

    /// Attempts to get the currently selected text
    /// Uses Accessibility API first, falls back to clipboard if needed
    func getSelectedText() -> String? {
        // Try Accessibility API first
        if let text = getSelectedTextViaAccessibility() {
            return text
        }

        // Fall back to clipboard method
        return getSelectedTextViaClipboard()
    }

    private func getSelectedTextViaAccessibility() -> String? {
        guard let focusedElement = getFocusedElement() else {
            return nil
        }

        var selectedText: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )

        guard result == .success, let text = selectedText as? String else {
            return nil
        }

        return text
    }

    private func getSelectedTextViaClipboard() -> String? {
        // Save current clipboard contents
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)

        // Clear and copy
        pasteboard.clearContents()

        // Simulate Cmd+C
        simulateKeyPress(keyCode: 8, flags: .maskCommand) // C key

        // Small delay to let the copy complete
        Thread.sleep(forTimeInterval: 0.05)

        // Get the copied text
        let copiedText = pasteboard.string(forType: .string)

        // Restore old clipboard if we got nothing or same content
        if copiedText == nil || copiedText == oldContents {
            pasteboard.clearContents()
            if let old = oldContents {
                pasteboard.setString(old, forType: .string)
            }
            return nil
        }

        return copiedText
    }

    // MARK: - Set Selected Text

    /// Replaces the currently selected text with new text
    func setSelectedText(_ text: String) {
        // Try Accessibility API first
        if setSelectedTextViaAccessibility(text) {
            return
        }

        // Fall back to clipboard method
        setSelectedTextViaClipboard(text)
    }

    private func setSelectedTextViaAccessibility(_ text: String) -> Bool {
        guard let focusedElement = getFocusedElement() else {
            return false
        }

        let result = AXUIElementSetAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        return result == .success
    }

    private func setSelectedTextViaClipboard(_ text: String) {
        // Save current clipboard
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)

        // Set new text to clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V
        simulateKeyPress(keyCode: 9, flags: .maskCommand) // V key

        // Small delay
        Thread.sleep(forTimeInterval: 0.05)

        // Restore old clipboard after a longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let old = oldContents {
                pasteboard.clearContents()
                pasteboard.setString(old, forType: .string)
            }
        }
    }

    // MARK: - Replace Last Word

    /// Deletes the last word and types the replacement
    func replaceLastWord(wordLength: Int, with replacement: String) {
        // Delete the last word using backspace
        for _ in 0..<wordLength {
            simulateKeyPress(keyCode: 51, flags: []) // Delete/Backspace key
            Thread.sleep(forTimeInterval: 0.01)
        }

        // Type the replacement
        typeText(replacement)
    }

    private func typeText(_ text: String) {
        for char in text {
            let source = CGEventSource(stateID: .hidSystemState)

            // Create key down event
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                var chars = Array(String(char).utf16)
                keyDown.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: &chars)
                keyDown.post(tap: .cghidEventTap)
            }

            // Create key up event
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                var chars = Array(String(char).utf16)
                keyUp.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: &chars)
                keyUp.post(tap: .cghidEventTap)
            }

            Thread.sleep(forTimeInterval: 0.005)
        }
    }

    // MARK: - Helpers

    private func getFocusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedApp: AnyObject?
        guard AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        ) == .success else {
            return nil
        }

        let appElement = focusedApp as! AXUIElement

        var focusedElement: AnyObject?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        ) == .success else {
            return nil
        }

        return (focusedElement as! AXUIElement)
    }

    private func simulateKeyPress(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = flags
            keyDown.post(tap: .cghidEventTap)
        }

        // Key up
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = flags
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
