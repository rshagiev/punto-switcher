import AppKit
import SwiftUI

private final class SupportPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class SupportPopover {
    private static let size = NSSize(width: 318, height: 141)
    private let panel: SupportPanel
    private let open: () -> Void
    private let dismiss: () -> Void
    private let onClose: () -> Void
    private var mouseMonitors: [Any] = []
    private var workspaceObservers: [NSObjectProtocol] = []

    init(open: @escaping () -> Void, dismiss: @escaping () -> Void, close: @escaping () -> Void) {
        self.open = open
        self.dismiss = dismiss
        onClose = close
        panel = SupportPanel(contentRect: NSRect(origin: .zero, size: Self.size),
                             styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hidesOnDeactivate = false
        panel.level = .popUpMenu
        panel.collectionBehavior = [.moveToActiveSpace, .ignoresCycle, .transient]
    }

    func show(under anchor: NSView) -> Bool {
        guard !anchor.isHiddenOrHasHiddenAncestor, let window = anchor.window,
              window.isVisible, let screen = window.screen else { return false }
        let anchorFrame = window.convertToScreen(anchor.convert(anchor.bounds, to: nil))
        let bounds = screen.visibleFrame.insetBy(dx: 6, dy: 0)
        let size = Self.size
        let y = min(anchorFrame.minY - size.height - 3, bounds.maxY - size.height)
        guard screen.frame.intersects(anchorFrame), anchorFrame.midY >= bounds.maxY,
              y >= bounds.minY, bounds.width >= size.width else { return false }
        let x = min(max(anchorFrame.midX - size.width + 30, bounds.minX), bounds.maxX - size.width)
        let arrow = min(max(anchorFrame.midX - x, 22), size.width - 22)

        panel.contentView = NSHostingView(rootView: SupportPopoverView(arrow: arrow, open: open, dismiss: dismiss)
            .frame(width: size.width, height: size.height))
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.orderFrontRegardless()
        guard panel.isVisible else { return false }
        observeOutsideInteraction()
        return true
    }

    func close() {
        mouseMonitors.forEach(NSEvent.removeMonitor)
        mouseMonitors.removeAll()
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach(center.removeObserver)
        workspaceObservers.removeAll()
        panel.orderOut(nil)
    }

    private func observeOutsideInteraction() {
        let mouseDown: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        if let global = NSEvent.addGlobalMonitorForEvents(matching: mouseDown, handler: { [weak self] _ in
            self?.onClose()
        }) { mouseMonitors.append(global) }
        if let local = NSEvent.addLocalMonitorForEvents(matching: mouseDown, handler: { [weak self] event in
            if let self, event.window !== self.panel { self.onClose() }
            return event
        }) { mouseMonitors.append(local) }

        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didActivateApplicationNotification, NSWorkspace.activeSpaceDidChangeNotification] {
            workspaceObservers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.onClose()
            })
        }
    }
}

private struct SupportPopoverView: View {
    let arrow: CGFloat
    let open: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label {
                Text("Поддержать Punto Native").font(.headline)
            } icon: {
                Image(systemName: "star.fill").foregroundStyle(Color(nsColor: .systemYellow))
            }
            Text("Звезда на GitHub поможет другим найти приложение.")
                .font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 22)
            HStack(spacing: 12) {
                Button(action: open) {
                    HStack(spacing: 6) {
                        Text("Открыть GitHub")
                        Image(systemName: "arrow.up.right").accessibilityHidden(true)
                    }
                }.buttonStyle(.bordered)
                Button("Больше не предлагать", action: dismiss)
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
            }.padding(.leading, 22)
        }
        .padding(.horizontal, 14)
        .padding(.top, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            SupportPopoverShape(arrow: arrow)
                .fill(.regularMaterial)
                .overlay { SupportPopoverShape(arrow: arrow).stroke(.primary.opacity(0.17), lineWidth: 1) }
        }
    }
}

private struct SupportPopoverShape: Shape {
    let arrow: CGFloat

    func path(in rect: CGRect) -> Path {
        let top: CGFloat = 8
        let radius: CGFloat = 12
        let width = rect.width
        let height = rect.height
        return Path { path in
            path.move(to: CGPoint(x: radius, y: top))
            path.addLine(to: CGPoint(x: arrow - 8, y: top))
            path.addLine(to: CGPoint(x: arrow, y: 1))
            path.addLine(to: CGPoint(x: arrow + 8, y: top))
            path.addLine(to: CGPoint(x: width - radius, y: top))
            path.addQuadCurve(to: CGPoint(x: width - 1, y: top + radius), control: CGPoint(x: width - 1, y: top))
            path.addLine(to: CGPoint(x: width - 1, y: height - radius))
            path.addQuadCurve(to: CGPoint(x: width - radius, y: height - 1), control: CGPoint(x: width - 1, y: height - 1))
            path.addLine(to: CGPoint(x: radius, y: height - 1))
            path.addQuadCurve(to: CGPoint(x: 1, y: height - radius), control: CGPoint(x: 1, y: height - 1))
            path.addLine(to: CGPoint(x: 1, y: top + radius))
            path.addQuadCurve(to: CGPoint(x: radius, y: top), control: CGPoint(x: 1, y: top))
            path.closeSubpath()
        }
    }

}
