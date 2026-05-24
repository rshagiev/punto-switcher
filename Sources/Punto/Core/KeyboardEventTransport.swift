import AppKit
import PuntoCore

/// Concrete CGEvent transport for text replacement mechanics.
///
/// Policy modules decide whether an action is allowed and which key codes/timings
/// to use; this adapter only creates and posts the actual keyboard events.
final class KeyboardEventTransport {

    @discardableResult
    func postCommandCopyAnnotated() -> Bool {
        postKeyPair(
            keyCode: ClipboardCapturePolicy.copyKeyCode,
            flags: .maskCommand,
            sourceID: .combinedSessionState,
            tap: .cgAnnotatedSessionEventTap,
            keyUpDelay: ClipboardCapturePolicy.keyUpDelay
        )
    }

    @discardableResult
    func postCommandCopyHID() -> Bool {
        postKeyPair(
            keyCode: ClipboardCapturePolicy.copyKeyCode,
            flags: .maskCommand,
            sourceID: .hidSystemState,
            tap: .cghidEventTap,
            keyUpDelay: ClipboardCapturePolicy.keyUpDelay
        )
    }

    @discardableResult
    func postCommandPasteHID() -> Bool {
        postKeyPair(
            keyCode: KeyboardEventKeyCodePolicy.pasteKeyCode,
            flags: .maskCommand,
            sourceID: .hidSystemState,
            tap: .cghidEventTap,
            keyUpDelay: KeyboardEventTimingPolicy.commandKeyUpDelay
        )
    }

    func selectBackwards(characterCount: Int) {
        guard characterCount > 0 else {
            return
        }

        for _ in 0..<characterCount {
            _ = postKeyPair(
                keyCode: KeyboardEventKeyCodePolicy.leftArrowKeyCode,
                flags: .maskShift,
                sourceID: .hidSystemState,
                tap: .cghidEventTap,
                keyUpDelay: 0
            )
        }
        Thread.sleep(forTimeInterval: KeyboardEventTimingPolicy.selectionSettleDelay)
    }

    func postBackspaces(count: Int) -> Int {
        guard count > 0 else {
            return 0
        }

        var sent = 0
        for index in 0..<count {
            let posted = postKeyPair(
                keyCode: KeyboardEventKeyCodePolicy.backspaceKeyCode,
                flags: [],
                sourceID: .hidSystemState,
                tap: .cghidEventTap,
                keyUpDelay: 0
            )
            if posted {
                sent += 1
            } else {
                PuntoLog.error("replaceLastWord: FAILED to create backspace event #\(index + 1)")
            }
            Thread.sleep(forTimeInterval: KeyboardReplacementPolicy.backspaceInterval)
        }
        return sent
    }

    @discardableResult
    func postKeyUps(_ keyCodes: [UInt16]) -> Int {
        let source = CGEventSource(stateID: .hidSystemState)
        var sent = 0

        for keyCode in keyCodes {
            guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
                continue
            }
            keyUp.flags = []
            keyUp.post(tap: .cghidEventTap)
            sent += 1
        }

        return sent
    }

    private func postKeyPair(
        keyCode: UInt16,
        flags: CGEventFlags,
        sourceID: CGEventSourceStateID,
        tap: CGEventTapLocation,
        keyUpDelay: TimeInterval
    ) -> Bool {
        let source = CGEventSource(stateID: sourceID)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return false
        }

        keyDown.flags = flags
        keyDown.post(tap: tap)
        if keyUpDelay > 0 {
            Thread.sleep(forTimeInterval: keyUpDelay)
        }
        keyUp.flags = flags
        keyUp.post(tap: tap)
        return true
    }
}
