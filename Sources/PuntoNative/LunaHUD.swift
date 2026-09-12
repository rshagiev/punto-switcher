import AppKit

private final class LunaHUDPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// A nonactivating, native material capsule. Its buttons never take keyboard focus.
final class LunaHUD: NSObject {
    private let panel = LunaHUDPanel(contentRect:.zero,styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
    private let label = NSTextField(labelWithString:"")
    private let spinner = NSProgressIndicator()
    private let icon = NSImageView()
    private let button = NSButton(title:"",target:nil,action:nil)
    private var action:(()->Void)?
    private var dismissal:DispatchWorkItem?
    override init() {
        super.init()
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
        panel.hidesOnDeactivate = false; panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces,.fullScreenAuxiliary,.transient,.ignoresCycle]
        let material = NSVisualEffectView()
        material.material = .hudWindow; material.blendingMode = .behindWindow; material.state = .active
        material.wantsLayer = true; material.layer?.cornerRadius = 18; material.layer?.masksToBounds = true
        panel.contentView = material
        label.font = .systemFont(ofSize:13,weight:.medium)
        spinner.style = .spinning; spinner.controlSize = .small; spinner.isDisplayedWhenStopped = false
        button.bezelStyle = .inline; button.font = .systemFont(ofSize:12,weight:.medium)
        button.contentTintColor = .controlAccentColor
        button.target = self; button.action = #selector(performAction)
        for view in [label,spinner,icon,button] { material.addSubview(view) }
    }
    @objc private func performAction() { action?() }
    func hide() { dismissal?.cancel(); panel.orderOut(nil); spinner.stopAnimation(nil); action = nil }
    func show(_ text:String,focus:Focus?,loading:Bool = false,symbol:String = "checkmark",button title:String? = nil,duration:Double = 3,action:(()->Void)? = nil) {
        dismissal?.cancel(); self.action = action; label.stringValue = text
        label.sizeToFit(); button.title = title ?? ""; button.sizeToFit(); button.isHidden = title == nil
        let buttonWidth = title == nil ? 0 : button.frame.width + 12
        let width = max(120,label.frame.width + buttonWidth + 54)
        panel.setContentSize(NSSize(width:width,height:36))
        spinner.frame = NSRect(x:13,y:10,width:16,height:16)
        icon.frame = spinner.frame; icon.image = NSImage(systemSymbolName:symbol,accessibilityDescription:nil)
        icon.contentTintColor = .secondaryLabelColor; icon.isHidden = loading
        if loading { spinner.startAnimation(nil) } else { spinner.stopAnimation(nil) }
        label.frame.origin = NSPoint(x:37,y:10)
        button.frame.origin = NSPoint(x:width-button.frame.width-12,y:9)
        do {
            let caret = focus.flatMap { ConversionFeedback.caret($0) }
            let anchor = caret.map { NSPoint(x:$0.minX,y:$0.minY) } ?? NSEvent.mouseLocation
            if let screen = NSScreen.screens.first(where:{$0.frame.contains(anchor)}) ?? NSScreen.main {
                let frame = screen.visibleFrame.insetBy(dx:8,dy:8)
                let y = anchor.y-44 < frame.minY ? (caret?.maxY ?? anchor.y)+8 : anchor.y-44
                panel.setFrameOrigin(NSPoint(x:min(max(anchor.x,frame.minX),frame.maxX-width),y:min(max(y,frame.minY),frame.maxY-36)))
            }
        }
        panel.orderFrontRegardless()
        if duration > 0 {
            let task = DispatchWorkItem { [weak self] in self?.hide() }; dismissal = task
            DispatchQueue.main.asyncAfter(deadline:.now()+duration,execute:task)
        }
    }
}
