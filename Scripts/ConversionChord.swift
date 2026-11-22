import CoreGraphics

enum ConversionChord {
    static func events(source: CGEventSource?) -> [CGEvent]? {
        let sequence: [(CGKeyCode, Bool, CGEventFlags)] = [
            (55, true, .maskCommand),
            (58, true, [.maskCommand, .maskAlternate]),
            (56, true, [.maskCommand, .maskAlternate, .maskShift]),
            (56, false, [.maskCommand, .maskAlternate]),
            (58, false, .maskCommand),
            (55, false, [])
        ]
        var events: [CGEvent] = []
        for (key, down, flags) in sequence {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: down) else {
                return nil
            }
            event.type = .flagsChanged
            event.flags = flags.union(.maskNonCoalesced)
            events.append(event)
        }
        return events
    }
}

#if POST_CONVERSION_CHORD
import AppKit
import ApplicationServices
import Carbon

@main
enum PressConversionChord {
    static func main() {
        var args = Array(CommandLine.arguments.dropFirst())
        let waitForFocus = args.first == "--wait"
        if waitForFocus { args.removeFirst() }
        guard args.count == 2, !args[1].isEmpty else {
            fail("Usage: press-conversion-chord.sh [--wait] <frontmost-bundle-id> <exact-test-field-text>")
        }
        guard CGPreflightPostEventAccess(), !IsSecureEventInputEnabled() else {
            fail("Event posting is unavailable or Secure Input is active.")
        }
        let modifiers: CGEventFlags = [.maskCommand, .maskAlternate, .maskShift, .maskControl]
        guard CGEventSource.flagsState(.combinedSessionState).intersection(modifiers).isEmpty else {
            fail("Release held modifiers before running the check.")
        }
        let workspace = NSWorkspace.shared
        if waitForFocus {
            let deadline = ProcessInfo.processInfo.systemUptime + 12
            while workspace.frontmostApplication?.bundleIdentifier != args[0],
                  ProcessInfo.processInfo.systemUptime < deadline {
                Thread.sleep(forTimeInterval: 0.015)
            }
        }
        guard let app = workspace.frontmostApplication, app.bundleIdentifier == args[0] else {
            fail("The target app is not frontmost.")
        }
        let application = AXUIElementCreateApplication(app.processIdentifier)
        guard let field = focusedField(in: application) else {
            fail("The focused field is unavailable.")
        }
        guard matchesFixture(field, expectedText: args[1]) else {
            fail("The focused field does not match the test fixture.")
        }
        guard let source = CGEventSource(stateID: .hidSystemState),
              let events = ConversionChord.events(source: source) else {
            fail("Could not prepare the chord.")
        }
        guard let currentField = focusedField(in: application),
              CFEqual(currentField, field),
              matchesFixture(currentField, expectedText: args[1]),
              workspace.frontmostApplication?.processIdentifier == app.processIdentifier,
              !IsSecureEventInputEnabled(),
              CGEventSource.flagsState(.combinedSessionState).intersection(modifiers).isEmpty else {
            fail("The target field or keyboard state changed before posting the chord.")
        }
        for event in events {
            event.post(tap: .cghidEventTap)
            Thread.sleep(forTimeInterval: 0.015)
        }
        print("Posted Command-Option-Shift. Verify the resulting text in the fixture.")
    }

    private static func focusedField(in application: AXUIElement) -> AXUIElement? {
        guard let field = attribute(application, kAXFocusedUIElementAttribute),
              CFGetTypeID(field) == AXUIElementGetTypeID() else { return nil }
        return (field as! AXUIElement)
    }

    private static func matchesFixture(_ field: AXUIElement, expectedText: String) -> Bool {
        (attribute(field, kAXSubroleAttribute) as? String) != kAXSecureTextFieldSubrole &&
            (attribute(field, kAXValueAttribute) as? String) == expectedText
    }

    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data((message + "\n").utf8))
        exit(EXIT_FAILURE)
    }
}
#endif
