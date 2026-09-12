import AppKit
import ApplicationServices

/// AX is additional evidence, not a prerequisite for observing physical typing.
/// Some web editors expose their focused field only after accessibility is enabled.
struct Focus {
    let pid: pid_t
    let element: AXUIElement?
    let window: AXUIElement?
    let appID: String
    private static var enabledApps: Set<pid_t> = []
    static func current() -> Focus? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let root = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(root, 0.005)
        if enabledApps.insert(app.processIdentifier).inserted {
            // Electron exposes its renderer's native accessibility tree on request.
            _ = AXUIElementSetAttributeValue(root, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        }
        func elementAttribute(_ name: String) -> AXUIElement? {
            var raw: CFTypeRef?
            guard AXUIElementCopyAttributeValue(root, name as CFString, &raw) == .success,
                  let raw, CFGetTypeID(raw) == AXUIElementGetTypeID() else { return nil }
            let value = raw as! AXUIElement
            AXUIElementSetMessagingTimeout(value, 0.005)
            return value
        }
        return Focus(pid: app.processIdentifier, element: elementAttribute(kAXFocusedUIElementAttribute),
                     window: elementAttribute(kAXFocusedWindowAttribute), appID: app.bundleIdentifier ?? "")
    }
    func attribute(_ name: String) -> CFTypeRef? {
        guard let element else { return nil }
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &result) == .success else { return nil }
        return result
    }
    var secure: Bool { (attribute(kAXSubroleAttribute) as? String) == kAXSecureTextFieldSubrole }
    var selected: String? { attribute(kAXSelectedTextAttribute) as? String }
    var value: String? { attribute(kAXValueAttribute) as? String }
    var range: CFRange? {
        guard let raw = attribute(kAXSelectedTextRangeAttribute), CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        var range = CFRange()
        guard AXValueGetValue(raw as! AXValue, .cfRange, &range), range.location >= 0, range.length >= 0 else { return nil }
        return range
    }
    var editable: Bool {
        let role = attribute(kAXRoleAttribute) as? String
        return role == kAXTextFieldRole || role == kAXTextAreaRole || role == kAXComboBoxRole
    }
    func stillFocused() -> Bool {
        guard let f = Self.current(), pid == f.pid, !f.secure else { return false }
        if let window, let other = f.window, !CFEqual(window, other) { return false }
        // A renderer may replace its AX object during an edit. For exposed text fields,
        // keep the stronger identity check; opaque editors rely on the physical session,
        // which is invalidated by clicks, navigation and app activation.
        if let element, let other = f.element, editable, f.editable, !CFEqual(element, other) { return false }
        return true
    }
    var terminal: Bool { ["com.apple.Terminal", "com.googlecode.iterm2", "com.mitchellh.ghostty", "dev.warp.Warp-Stable", "net.kovidgoyal.kitty", "org.alacritty"].contains(appID) }
}

final class TextAccess {
    static let marker: Int64 = 0x50554e544f4e
    static let replayMarker: Int64 = 0x50554e544f52
    static let fenceBase: Int64 = 0x505600000000
    private let source = CGEventSource(stateID: .privateState)
    private var restoring: (() -> Void)?
    func fence(_ tag: Int64) {
        for down in [true,false] {
            let event = CGEvent(keyboardEventSource:source,virtualKey:0,keyDown:down)
            event?.flags = []
            event?.setIntegerValueField(.eventSourceUserData,value:tag)
            event?.post(tap:.cgSessionEventTap)
        }
    }
    func forward(_ original: CGEvent, throughEngine: Bool) {
        // A copied tap event retains WindowServer routing history and may bypass this
        // tap when posted again. Recreate it so replay follows the same ordered path.
        let event: CGEvent?
        let type = original.type
        if type == .keyDown || type == .keyUp || type == .flagsChanged {
            event = CGEvent(keyboardEventSource:source,virtualKey:UInt16(original.getIntegerValueField(.keyboardEventKeycode)),keyDown:type != .keyUp)
            event?.type = type
            event?.setIntegerValueField(.keyboardEventAutorepeat,value:original.getIntegerValueField(.keyboardEventAutorepeat))
        } else if type == .scrollWheel {
            event = CGEvent(scrollWheelEvent2Source:source,units:.pixel,wheelCount:3,
                            wheel1:Int32(clamping:original.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)),
                            wheel2:Int32(clamping:original.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)),
                            wheel3:Int32(clamping:original.getIntegerValueField(.scrollWheelEventPointDeltaAxis3)))
            for field: CGEventField in [.scrollWheelEventDeltaAxis1,.scrollWheelEventDeltaAxis2,.scrollWheelEventDeltaAxis3,.scrollWheelEventFixedPtDeltaAxis1,.scrollWheelEventFixedPtDeltaAxis2,.scrollWheelEventFixedPtDeltaAxis3,.scrollWheelEventIsContinuous,.scrollWheelEventScrollPhase,.scrollWheelEventMomentumPhase] {
                event?.setIntegerValueField(field,value:original.getIntegerValueField(field))
            }
        } else {
            event = CGEvent(mouseEventSource:source,mouseType:type,mouseCursorPosition:original.location,mouseButton:CGMouseButton(rawValue:UInt32(original.getIntegerValueField(.mouseEventButtonNumber))) ?? .left)
            for field: CGEventField in [.mouseEventClickState,.mouseEventDeltaX,.mouseEventDeltaY] {
                event?.setIntegerValueField(field,value:original.getIntegerValueField(field))
            }
        }
        guard let event else { return }
        event.flags = original.flags
        event.location = original.location
        if type == .keyDown || type == .keyUp {
            let flags = event.flags
            if !flags.contains(.maskCommand) && !flags.contains(.maskControl) {
                let key = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                let units = Array(Layouts.text(key,flags:flags).utf16)
                event.keyboardSetUnicodeString(stringLength:units.count,unicodeString:units)
            }
        }
        event.setIntegerValueField(.eventSourceUserData,value:throughEngine ? Self.replayMarker : Self.marker)
        event.post(tap:.cgSessionEventTap)
    }
    func key(_ code: UInt16, flags: CGEventFlags = []) {
        for down in [true,false] {
            let e = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: down)
            e?.flags = flags; e?.setIntegerValueField(.eventSourceUserData, value: Self.marker); e?.post(tap: .cgSessionEventTap)
        }
    }
    /// Replay individual physical keys in the selected layout. Chromium, WebKit and
    /// terminal applications do not consistently accept multi-character key events.
    func replay(_ text: String, layout: String) {
        for stroke in Layouts.strokes(text, sourceID: layout) {
            for down in [true, false] {
                let event = CGEvent(keyboardEventSource: source, virtualKey: stroke.key, keyDown: down)
                event?.flags = stroke.flags
                let units = Array(stroke.text.utf16)
                event?.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
                event?.setIntegerValueField(.eventSourceUserData, value: Self.marker)
                event?.post(tap: .cgSessionEventTap)
            }
        }
    }
    func erase(_ count: Int) { for _ in 0..<count { key(51) } }
    func paste(_ text: String, into focus: Focus, completion: @escaping (Bool) -> Void) {
        guard focus.stillFocused(), !focus.secure else { completion(false); return }
        let board = NSPasteboard.general
        restoring?()
        let backup = board.pasteboardItems?.map { item in item.types.compactMap { t -> (NSPasteboard.PasteboardType,Data)? in item.data(forType: t).map { (t,$0) } } } ?? []
        board.clearContents(); board.setString(text, forType: .string)
        let owned = board.changeCount
        let restore: () -> Void = {
            guard board.changeCount == owned else { return }
            board.clearContents()
            let items = backup.map { values -> NSPasteboardItem in let i = NSPasteboardItem(); for (t,d) in values { i.setData(d,forType:t) }; return i }
            if !items.isEmpty { board.writeObjects(items) }
        }
        restoring = restore
        key(9,flags: .maskCommand)
        DispatchQueue.main.asyncAfter(deadline: .now()+0.3) { [weak self] in restore(); self?.restoring = nil; completion(true) }
    }
    /// The original uses Command-C, including in editors without AXSelectedText.
    /// Never interpret the old pasteboard as proof that a selection was copied.
    func copySelection(from focus: Focus, completion: @escaping (String?) -> Void) {
        guard focus.stillFocused(), !focus.secure else { completion(nil); return }
        restoring?()
        let board = NSPasteboard.general
        let backup = board.pasteboardItems?.map { item in item.types.compactMap { t -> (NSPasteboard.PasteboardType,Data)? in item.data(forType:t).map { (t,$0) } } } ?? []
        board.clearContents()
        let emptyCount = board.changeCount
        var ownedCount = emptyCount
        let restore: () -> Void = {
            guard board.changeCount == ownedCount else { return }
            board.clearContents()
            let items = backup.map { values -> NSPasteboardItem in
                let item = NSPasteboardItem(); for (type,data) in values { item.setData(data,forType:type) }; return item
            }
            if !items.isEmpty { board.writeObjects(items) }
        }
        restoring = restore
        key(8, flags: .maskCommand)
        let deadline = Date().addingTimeInterval(0.3)
        func poll() {
            guard focus.stillFocused() else { restore(); self.restoring = nil; completion(nil); return }
            if board.changeCount != emptyCount {
                ownedCount = board.changeCount
                let copied = board.string(forType:.string)
                restore(); self.restoring = nil
                completion(copied?.isEmpty == false ? copied : nil)
            } else if Date() < deadline {
                DispatchQueue.main.asyncAfter(deadline:.now()+0.015, execute:poll)
            } else { restore(); self.restoring = nil; completion(nil) }
        }
        DispatchQueue.main.asyncAfter(deadline:.now()+0.005, execute:poll)
    }
    func finish() { restoring?(); restoring = nil }
}
