import AppKit
import Carbon

private final class FeedbackPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Conversion-only feedback: ordinary input-source changes keep macOS's own UI.
final class ConversionFeedback {
    private let panel: FeedbackPanel
    private let label = NSTextField(labelWithString:"")
    private var dismissal: DispatchWorkItem?
    private(set) var count = 0
    private(set) var anchorKind = "none"
    var diagnostics: [String:Any] { ["visible":panel.isVisible,"count":count,"anchor":anchorKind,"label":label.stringValue,"x":panel.frame.minX,"y":panel.frame.minY,"canBecomeKey":panel.canBecomeKey,"ignoresMouseEvents":panel.ignoresMouseEvents] }
    init() {
        panel = FeedbackPanel(contentRect:NSRect(x:0,y:0,width:34,height:26),styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.ignoresMouseEvents = true; panel.hidesOnDeactivate = false; panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces,.fullScreenAuxiliary,.ignoresCycle,.transient]
        let view = NSView(frame:panel.contentView!.bounds)
        view.wantsLayer = true; view.layer?.backgroundColor = NSColor.systemBlue.cgColor
        view.layer?.cornerRadius = 13; view.layer?.borderWidth = 0.5
        view.layer?.borderColor = NSColor.white.withAlphaComponent(0.35).cgColor
        label.font = .systemFont(ofSize:13,weight:.medium); label.textColor = .white; label.alignment = .center
        label.frame = NSRect(x:2,y:5,width:30,height:17)
        view.addSubview(label); view.setAccessibilityHidden(true); panel.contentView = view
    }
    func hide() { dismissal?.cancel(); dismissal = nil; panel.orderOut(nil) }
    func show(_ text:String, pid:pid_t) {
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid, !IsSecureEventInputEnabled(), let focus = Focus.current(), !focus.secure else { hide(); return }
        hide(); label.stringValue = text
        let rect = Self.caret(focus)
        anchorKind = rect == nil ? "mouse" : "caret"
        let anchor = rect.map { NSPoint(x:$0.minX,y:$0.minY) } ?? NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where:{$0.frame.contains(anchor)}) ?? NSScreen.main else { return }
        let bounds = screen.visibleFrame.insetBy(dx:6,dy:6)
        var y = anchor.y - 34
        if y < bounds.minY { y = (rect?.maxY ?? anchor.y) + 8 }
        panel.setFrameOrigin(NSPoint(x:min(max(anchor.x + (rect == nil ? 12 : 0),bounds.minX),bounds.maxX-34),y:min(max(y,bounds.minY),bounds.maxY-26)))
        count += 1; panel.orderFrontRegardless()
        let task = DispatchWorkItem { [weak self] in self?.panel.orderOut(nil) }; dismissal = task
        DispatchQueue.main.asyncAfter(deadline:.now()+0.5,execute:task)
    }
    static func caret(_ focus:Focus) -> NSRect? {
        guard let element = focus.element else { return nil }
        func rect(_ raw:CFTypeRef?) -> NSRect? {
            guard let raw, CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
            var rect = CGRect.zero
            guard AXValueGetValue(raw as! AXValue,.cgRect,&rect), rect.minX.isFinite, rect.minY.isFinite, rect.height > 0, rect.height < 160, rect.width >= 0, rect.width < 160, let primary = NSScreen.screens.first else { return nil }
            return NSRect(x:rect.minX,y:primary.frame.maxY-rect.maxY,width:max(1,rect.width),height:rect.height)
        }
        if var range = focus.range {
            range = CFRange(location:range.location+range.length,length:0)
            if let parameter = AXValueCreate(.cfRange,&range) {
                var raw:CFTypeRef?
                if AXUIElementCopyParameterizedAttributeValue(element,kAXBoundsForRangeParameterizedAttribute as CFString,parameter,&raw) == .success, let bounds = rect(raw) { return bounds }
            }
        }
        // WebKit may expose an empty AXBoundsForRange but valid text-marker bounds.
        var marker:CFTypeRef?
        if AXUIElementCopyAttributeValue(element,"AXSelectedTextMarkerRange" as CFString,&marker) == .success, let marker {
            var raw:CFTypeRef?
            if AXUIElementCopyParameterizedAttributeValue(element,"AXBoundsForTextMarkerRange" as CFString,marker,&raw) == .success { return rect(raw) }
        }
        return nil
    }
}
