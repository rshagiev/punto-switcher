import AppKit

final class AppMenuTile: NSView {
    init(application: NSRunningApplication, title: String, subtitle: String) {
        super.init(frame: NSRect(x: 0, y: 0, width: 285, height: 56))
        autoresizingMask = [.width]

        let tile = NSView(frame: bounds.insetBy(dx: 10, dy: 4))
        tile.autoresizingMask = [.width]
        tile.wantsLayer = true
        tile.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.07).cgColor
        tile.layer?.cornerRadius = 9
        addSubview(tile)

        let icon = NSImageView(frame: NSRect(x: 10, y: 11, width: 26, height: 26))
        icon.image = application.icon ?? NSImage(systemSymbolName: "app", accessibilityDescription: nil)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.setAccessibilityHidden(true)
        tile.addSubview(icon)
        tile.addSubview(menuLabel(title, size: 13, weight: .semibold, y: 24, width: 215, x: 45))
        tile.addSubview(menuLabel(subtitle, size: 11, weight: .regular, y: 8, width: 215, x: 45, secondary: true))
    }

    required init?(coder: NSCoder) { nil }
}

private func menuLabel(_ text: String, size: CGFloat, weight: NSFont.Weight, y: CGFloat,
                       width: CGFloat, x: CGFloat, secondary: Bool = false) -> NSTextField {
    let label = NSTextField(labelWithString: text)
    label.font = .systemFont(ofSize: size, weight: weight)
    label.lineBreakMode = .byTruncatingTail
    label.textColor = secondary ? .secondaryLabelColor : .labelColor
    label.frame = NSRect(x: x, y: y, width: width, height: 17)
    label.autoresizingMask = [.width]
    return label
}
