import AppKit

class AppMenuCardRow: NSView {
    let card: NSView

    init(height: CGFloat, top: CGFloat, bottom: CGFloat, corners: CACornerMask) {
        let width: CGFloat = 305
        card = NSView(frame: NSRect(x: 8, y: bottom, width: width - 16, height: height - top - bottom))
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))
        autoresizingMask = [.width]
        card.autoresizingMask = [.width]
        card.wantsLayer = true
        card.layer?.cornerRadius = 9
        card.layer?.maskedCorners = corners
        addSubview(card)
        setHighlighted(false)
    }

    func setHighlighted(_ highlighted: Bool) {
        card.layer?.backgroundColor = highlighted
            ? NSColor.selectedContentBackgroundColor.withAlphaComponent(0.24).cgColor
            : NSColor.labelColor.withAlphaComponent(0.07).cgColor
    }

    func addHitTarget(_ target: NSButton, action: Selector, in content: NSView) {
        target.target = self
        target.action = action
        target.frame = content.bounds
        target.autoresizingMask = [.width]
        target.isBordered = false
        target.isTransparent = true
        content.addSubview(target)
    }

    required init?(coder: NSCoder) { nil }
}

final class AppMenuTile: AppMenuCardRow {
    private let name: String
    private let toggleDisclosure: () -> Void
    private let subtitle = NSTextField(labelWithString: "")
    private let chevron = NSImageView()
    private let disclosure = NSButton()
    private let header = NSView()
    private let topCorners: CACornerMask = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    private let bottomCorners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

    init(application: NSRunningApplication, title: String, toggleDisclosure: @escaping () -> Void) {
        name = title
        self.toggleDisclosure = toggleDisclosure
        super.init(height: 54, top: 3, bottom: 3, corners: [.layerMinXMaxYCorner, .layerMaxXMaxYCorner,
                                                            .layerMinXMinYCorner, .layerMaxXMinYCorner])
        header.frame = card.bounds
        header.autoresizingMask = [.width, .minYMargin]
        card.addSubview(header)

        let icon = NSImageView(frame: NSRect(x: 11, y: 10, width: 28, height: 28))
        icon.image = application.icon ?? NSImage(systemSymbolName: "app", accessibilityDescription: nil)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.setAccessibilityHidden(true)
        header.addSubview(icon)
        header.addSubview(menuLabel(title, size: 13, weight: .semibold, y: 25, width: card.bounds.width - 76, x: 47))
        styleMenuLabel(subtitle, size: 11, weight: .regular, y: 8, width: card.bounds.width - 76, x: 47, secondary: true)
        header.addSubview(subtitle)

        chevron.frame = NSRect(x: card.bounds.width - 27, y: 17, width: 13, height: 13)
        chevron.contentTintColor = .secondaryLabelColor
        chevron.autoresizingMask = [.minXMargin]
        chevron.setAccessibilityHidden(true)
        header.addSubview(chevron)
        addHitTarget(disclosure, action: #selector(disclose), in: header)
        disclosure.setAccessibilityHelp("⌥0")
    }

    func update(subtitle text: String, expanded: Bool) {
        let bottom: CGFloat = expanded ? 0 : 3
        card.frame.origin.y = bottom
        card.frame.size.height = bounds.height - 3 - bottom
        card.layer?.maskedCorners = expanded ? topCorners : topCorners.union(bottomCorners)
        subtitle.stringValue = text
        chevron.image = NSImage(systemSymbolName: expanded ? "chevron.up" : "chevron.down", accessibilityDescription: nil)
        disclosure.setAccessibilityLabel(expanded ? "Свернуть настройки для \(name)" : "Раскрыть настройки для \(name)")
        disclosure.setAccessibilityValue(text)
        disclosure.setAccessibilityExpanded(expanded)
    }

    @objc private func disclose() { toggleDisclosure() }

    required init?(coder: NSCoder) { nil }
}

final class AppMenuAutomaticRow: AppMenuCardRow {
    private let setAutomatic: (Bool) -> Void
    private let automaticSwitch = AppMenuSwitch()
    private let label = NSTextField(labelWithString: "Автопереключение")

    init(appName: String, setAutomatic: @escaping (Bool) -> Void) {
        self.setAutomatic = setAutomatic
        super.init(height: 37, top: 0, bottom: 0, corners: [])

        let divider = NSBox(frame: NSRect(x: 10, y: 36, width: card.bounds.width - 20, height: 1))
        divider.boxType = .separator
        divider.autoresizingMask = [.width]
        card.addSubview(divider)

        let bolt = NSImageView(frame: NSRect(x: 12, y: 11, width: 15, height: 15))
        bolt.image = NSImage(systemSymbolName: "bolt", accessibilityDescription: nil)
        bolt.contentTintColor = .secondaryLabelColor
        bolt.setAccessibilityHidden(true)
        card.addSubview(bolt)
        styleMenuLabel(label, size: 13, weight: .regular, y: 10, width: card.bounds.width - 88, x: 34)
        card.addSubview(label)

        automaticSwitch.frame = NSRect(x: card.bounds.width - 48, y: 8, width: 37, height: 21)
        automaticSwitch.autoresizingMask = [.minXMargin]
        automaticSwitch.setButtonType(.switch)
        automaticSwitch.isBordered = false
        automaticSwitch.target = self
        automaticSwitch.action = #selector(changeAutomatic(_:))
        automaticSwitch.setAccessibilityLabel("Автопереключение для \(appName)")
        automaticSwitch.setAccessibilityHelp("⌥1")
        card.addSubview(automaticSwitch)
    }

    func update(automatic: Bool, available: Bool) {
        label.textColor = available ? .labelColor : .secondaryLabelColor
        automaticSwitch.state = automatic ? .on : .off
        automaticSwitch.isEnabled = available
        automaticSwitch.needsDisplay = true
    }

    @objc private func changeAutomatic(_ sender: NSButton) { setAutomatic(sender.state == .on) }

    required init?(coder: NSCoder) { nil }
}

private final class AppMenuSwitch: NSButton {
    override func draw(_ dirtyRect: NSRect) {
        let isOn = state == .on
        let radius = bounds.height / 2
        let color = isOn && isEnabled ? NSColor.systemBlue : NSColor.secondaryLabelColor.withAlphaComponent(0.31)
        color.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius).fill()
        let inset: CGFloat = 2
        let size = bounds.height - inset * 2
        NSColor.white.withAlphaComponent(isEnabled ? 1 : 0.52).setFill()
        NSBezierPath(ovalIn: NSRect(x: isOn ? bounds.maxX - inset - size : inset,
                                   y: inset, width: size, height: size)).fill()
    }
}

final class AppMenuPauseRow: AppMenuCardRow {
    private let togglePause: () -> Void
    private let pauseIcon = NSImageView()
    private let label = NSTextField(labelWithString: "")
    private let button = NSButton()

    init(togglePause: @escaping () -> Void) {
        self.togglePause = togglePause
        super.init(height: 37, top: 0, bottom: 3, corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])

        pauseIcon.frame = NSRect(x: 12, y: 10, width: 15, height: 15)
        pauseIcon.contentTintColor = .secondaryLabelColor
        pauseIcon.setAccessibilityHidden(true)
        card.addSubview(pauseIcon)
        styleMenuLabel(label, size: 13, weight: .regular, y: 9, width: card.bounds.width - 49, x: 34)
        card.addSubview(label)
        addHitTarget(button, action: #selector(changePaused), in: card)
        button.setAccessibilityHelp("⌥2")
    }

    func update(title: String, paused: Bool) {
        label.stringValue = title
        pauseIcon.image = NSImage(systemSymbolName: paused ? "play.circle" : "pause.circle", accessibilityDescription: nil)
        button.setAccessibilityLabel(title)
    }

    @objc private func changePaused() { togglePause() }

    required init?(coder: NSCoder) { nil }
}

enum SupportMenuRow {
    static let title = "Поставить звезду на GitHub"
}

private func menuLabel(_ text: String, size: CGFloat, weight: NSFont.Weight, y: CGFloat,
                       width: CGFloat, x: CGFloat, secondary: Bool = false) -> NSTextField {
    let label = NSTextField(labelWithString: text)
    styleMenuLabel(label, size: size, weight: weight, y: y, width: width, x: x, secondary: secondary)
    return label
}

private func styleMenuLabel(_ label: NSTextField, size: CGFloat, weight: NSFont.Weight, y: CGFloat,
                            width: CGFloat, x: CGFloat, secondary: Bool = false) {
    label.font = .systemFont(ofSize: size, weight: weight)
    label.lineBreakMode = .byTruncatingTail
    label.textColor = secondary ? .secondaryLabelColor : .labelColor
    label.frame = NSRect(x: x, y: y, width: width, height: 17)
    label.autoresizingMask = [.width]
}
