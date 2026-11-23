import AppKit
import ApplicationServices
import SwiftUI

private extension KeyboardPermission {
    var title: String {
        self == .inputMonitoring ? "Мониторинг ввода" : "Универсальный доступ"
    }

    var settingsURL: URL {
        let pane = self == .inputMonitoring ? "Privacy_ListenEvent" : "Privacy_Accessibility"
        return URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")!
    }
}

final class PermissionSetup {
    private static let settingsID = "com.apple.systempreferences"
    private static let trackingInterval: TimeInterval = 0.08
    private static let checkInterval: TimeInterval = 0.5

    private var panel: NSPanel?
    private var timer: Timer?
    private var windowID: CGWindowID?
    private var nextPermissionCheck: TimeInterval = 0
    private var windowSearchDeadline: TimeInterval = 0
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    @discardableResult
    func show(_ permission: KeyboardPermission, onGrant: @escaping () -> Void) -> Bool {
        close()
        if permission.isGranted {
            onGrant()
            return true
        }
        if permission == .postEvents {
            // Quartz asks for this separately on some Macs. The app can already
            // be listed under Accessibility, so there is no second drag step.
            if CGRequestPostEventAccess() {
                onGrant()
            } else {
                nextPermissionCheck = 0
                windowSearchDeadline = ProcessInfo.processInfo.systemUptime + 60
                setInterval(Self.checkInterval, permission: permission, onGrant: onGrant)
            }
            return true
        }

        let bundle = Bundle.main
        guard bundle.bundleURL.pathExtension == "app", NSWorkspace.shared.open(permission.settingsURL) else { return false }
        panel = makePanel(bundle: bundle, permission: permission)
        nextPermissionCheck = 0
        windowSearchDeadline = ProcessInfo.processInfo.systemUptime + 10
        update(permission, onGrant: onGrant)
        return true
    }

    func close() {
        timer?.invalidate()
        timer = nil
        panel?.orderOut(nil)
        panel = nil
        windowID = nil
    }

    func dismiss() {
        close()
        onDismiss()
    }

    private func setInterval(_ interval: TimeInterval, permission: KeyboardPermission, onGrant: @escaping () -> Void) {
        guard timer?.timeInterval != interval else { return }
        timer?.invalidate()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.update(permission, onGrant: onGrant)
        }
        timer.tolerance = interval / 4
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func update(_ permission: KeyboardPermission, onGrant: @escaping () -> Void) {
        let now = ProcessInfo.processInfo.systemUptime
        if now >= nextPermissionCheck {
            nextPermissionCheck = now + Self.checkInterval
            if let windowID {
                // Including the window by ID also finds it when it is minimized or on another Space.
                guard let windows = CGWindowListCopyWindowInfo(.optionIncludingWindow, windowID),
                      CFArrayGetCount(windows) > 0 else {
                    dismiss()
                    return
                }
            }
            if permission.isGranted {
                close()
                onGrant()
                return
            }
            if windowID == nil, now >= windowSearchDeadline {
                dismiss()
                return
            }
        }

        guard let panel else { return }
        guard let front = NSWorkspace.shared.frontmostApplication, front.bundleIdentifier == Self.settingsID,
              let (id, bounds) = settingsWindow(pid: front.processIdentifier) else {
            if panel.isVisible { panel.orderOut(nil) }
            setInterval(Self.checkInterval, permission: permission, onGrant: onGrant)
            return
        }

        windowID = id
        let sidebarWidth: CGFloat = 216
        let paneWidth = bounds.width - sidebarWidth
        let width = min(560, paneWidth - 32)
        let frame = NSRect(x: bounds.minX + sidebarWidth + (paneWidth - width) / 2 + 8,
                           y: CGDisplayBounds(CGMainDisplayID()).maxY - bounds.maxY + 18,
                           width: width, height: 136).integral
        if panel.frame != frame { panel.setFrame(frame, display: true) }
        if !panel.isVisible { panel.orderFrontRegardless() }
        setInterval(Self.trackingInterval, permission: permission, onGrant: onGrant)
    }

    // Window geometry is available before Accessibility or Screen Recording is granted.
    private func settingsWindow(pid: pid_t) -> (CGWindowID, CGRect)? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
        for window in windows {
            guard window[kCGWindowOwnerPID as String] as? Int == Int(pid),
                  window[kCGWindowLayer as String] as? Int == 0,
                  let id = window[kCGWindowNumber as String] as? CGWindowID,
                  windowID == nil || windowID == id,
                  let values = window[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: values as CFDictionary),
                  bounds.width >= 500, bounds.height >= 350 else { continue }
            return (id, bounds)
        }
        return nil
    }

    private func makePanel(bundle: Bundle, permission: KeyboardPermission) -> NSPanel {
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? FileManager.default.displayName(atPath: bundle.bundleURL.path)
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 560, height: 136),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.title = "\(name) · \(permission.title)"
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        // Order it only over the foreground System Settings window.
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .ignoresCycle]
        panel.animationBehavior = .none

        let content = NSHostingView(rootView: PermissionCard(bundle: bundle.bundleURL, name: name) { [weak self] in
            self?.dismiss()
        })
        content.sizingOptions = []
        panel.contentView = content
        return panel
    }
}

// Permission panel layout adapted from T3 Code's MacPermissionHelper (MIT).
private struct PermissionCard: View {
    let bundle: URL
    let name: String
    let close: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    private var icon: NSImage { NSWorkspace.shared.icon(forFile: bundle.path) }

    var body: some View {
        let dark = colorScheme == .dark
        let shape = RoundedRectangle(cornerRadius: 24)
        VStack(alignment: .leading, spacing: 16) {
            Label("Перетащите карточку, если приложения нет в списке", systemImage: "arrow.up")
                .font(.system(size: 15, weight: .semibold))
                .padding(.trailing, 20)
            HStack(spacing: 12) {
                Image(nsImage: icon).resizable().scaledToFit().frame(width: 26, height: 26)
                Text(name).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Color(white: dark ? 0.22 : 0.91), in: RoundedRectangle(cornerRadius: 10))
            .accessibilityHidden(true)
            .overlay {
                PermissionDragTile(bundle: bundle, name: name, icon: icon)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(white: dark ? 0.14 : 1), in: shape)
        .overlay(shape.strokeBorder(Color(white: dark ? 0.28 : 0.89)))
        .overlay(alignment: .topTrailing) {
            Button(action: close) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Закрыть подсказку")
            .padding(8)
        }
    }
}

private struct PermissionDragTile: NSViewRepresentable {
    let bundle: URL
    let name: String
    let icon: NSImage

    func makeNSView(context: Context) -> PermissionDragButton { PermissionDragButton(bundle: bundle, name: name, icon: icon) }
    func updateNSView(_ view: PermissionDragButton, context: Context) {}
}

private final class PermissionDragButton: NSButton, NSDraggingSource {
    private let bundle: URL
    private let dragIcon: NSImage
    private var dragStart: NSPoint?

    init(bundle: URL, name: String, icon: NSImage) {
        self.bundle = bundle
        dragIcon = icon
        super.init(frame: .zero)
        setAccessibilityLabel(name)
        toolTip = "Перетащить в список или показать в Finder"
        setAccessibilityHelp(toolTip)
        target = self
        action = #selector(revealInFinder)
    }

    required init?(coder: NSCoder) { nil }

    override func draw(_ dirtyRect: NSRect) {} // SwiftUI draws the tile below this drag surface.

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }

    override func mouseDown(with event: NSEvent) {
        dragStart = event.locationInWindow
        highlight(true)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart else { return }
        let point = event.locationInWindow
        guard hypot(point.x - start.x, point.y - start.y) >= 4 else { return }

        dragStart = nil
        highlight(false)
        let item = NSDraggingItem(pasteboardWriter: bundle as NSURL)
        let location = convert(point, from: nil)
        item.setDraggingFrame(NSRect(x: location.x - 16, y: location.y - 16, width: 32, height: 32),
                              contents: dragIcon)
        beginDraggingSession(with: [item], event: event, source: self)
    }

    override func mouseUp(with event: NSEvent) {
        guard dragStart != nil else { return }
        dragStart = nil
        highlight(false)
        if bounds.contains(convert(event.locationInWindow, from: nil)) { performClick(nil) }
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .copy
    }

    @objc private func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([bundle])
    }
}
