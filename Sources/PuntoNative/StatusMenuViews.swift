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
            ? NSColor.selectedContentBackgroundColor.withAlphaComponent(0.32).cgColor
            : NSColor.labelColor.withAlphaComponent(0.07).cgColor
    }

    func addHitTarget(label: String, action: Selector, value: String? = nil, expanded: Bool? = nil, help: String? = nil) {
        let button = NSButton(title: "", target: self, action: action)
        button.frame = card.bounds
        button.autoresizingMask = [.width]
        button.isBordered = false
        button.isTransparent = true
        button.setAccessibilityLabel(label)
        if let value { button.setAccessibilityValue(value) }
        if let expanded { button.setAccessibilityExpanded(expanded) }
        if let help { button.setAccessibilityHelp(help) }
        card.addSubview(button)
    }

    required init?(coder: NSCoder) { nil }
}

final class AppMenuTile: AppMenuCardRow {
    private let toggleDisclosure: () -> Void

    init(application: NSRunningApplication, title: String, subtitle: String, expanded: Bool,
         toggleDisclosure: @escaping () -> Void) {
        self.toggleDisclosure = toggleDisclosure
        let topCorners: CACornerMask = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        let bottomCorners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        super.init(height: expanded ? 51 : 54, top: 3, bottom: expanded ? 0 : 3,
                   corners: expanded ? topCorners : topCorners.union(bottomCorners))

        let icon = NSImageView(frame: NSRect(x: 11, y: 10, width: 28, height: 28))
        icon.image = application.icon ?? NSImage(systemSymbolName: "app", accessibilityDescription: nil)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.setAccessibilityHidden(true)
        card.addSubview(icon)
        card.addSubview(menuLabel(title, size: 13, weight: .semibold, y: 25, width: card.bounds.width - 102, x: 47))
        card.addSubview(menuLabel(subtitle, size: 11, weight: .regular, y: 8, width: card.bounds.width - 102, x: 47, secondary: true))
        let chevron = NSImageView(frame: NSRect(x: card.bounds.width - 27, y: 17, width: 13, height: 13))
        chevron.image = NSImage(systemSymbolName: expanded ? "chevron.up" : "chevron.down", accessibilityDescription: nil)
        chevron.contentTintColor = .secondaryLabelColor
        chevron.autoresizingMask = [.minXMargin]
        chevron.setAccessibilityHidden(true)
        card.addSubview(chevron)
        let shortcut = menuLabel("⌥0", size: 11, weight: .regular, y: 15, width: 21,
                                 x: chevron.frame.minX - 26, secondary: true)
        shortcut.autoresizingMask = [.minXMargin]
        shortcut.setAccessibilityHidden(true)
        card.addSubview(shortcut)
        addHitTarget(label: expanded ? "Свернуть настройки для \(title)" : "Раскрыть настройки для \(title)",
                     action: #selector(disclose), value: subtitle, expanded: expanded, help: "⌥0")
    }

    @objc private func disclose() { toggleDisclosure() }

    required init?(coder: NSCoder) { nil }
}

final class AppMenuAutomaticRow: AppMenuCardRow {
    private let setAutomatic: (Bool) -> Void

    init(appName: String, automatic: Bool, available: Bool, setAutomatic: @escaping (Bool) -> Void) {
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
        card.addSubview(menuLabel("Автопереключение", size: 13, weight: .regular, y: 10,
                                 width: card.bounds.width - 121, x: 34, secondary: !available))

        let automaticSwitch = NSSwitch()
        automaticSwitch.sizeToFit()
        automaticSwitch.frame.origin = NSPoint(x: card.bounds.width - automaticSwitch.frame.width - 11,
                                               y: (card.bounds.height - automaticSwitch.frame.height) / 2)
        automaticSwitch.autoresizingMask = [.minXMargin]
        automaticSwitch.state = automatic ? .on : .off
        automaticSwitch.isEnabled = available
        automaticSwitch.target = self
        automaticSwitch.action = #selector(changeAutomatic(_:))
        automaticSwitch.setAccessibilityLabel("Автопереключение для \(appName)")
        automaticSwitch.setAccessibilityHelp("⌥1")
        card.addSubview(automaticSwitch)
        let shortcut = menuLabel("⌥1", size: 11, weight: .regular, y: 9, width: 21,
                                 x: automaticSwitch.frame.minX - 28, secondary: true)
        shortcut.autoresizingMask = [.minXMargin]
        shortcut.setAccessibilityHidden(true)
        card.addSubview(shortcut)
    }

    @objc private func changeAutomatic(_ sender: NSSwitch) { setAutomatic(sender.state == .on) }

    required init?(coder: NSCoder) { nil }
}

final class AppMenuPauseRow: AppMenuCardRow {
    private let togglePause: () -> Void

    init(title: String, paused: Bool, togglePause: @escaping () -> Void) {
        self.togglePause = togglePause
        super.init(height: 37, top: 0, bottom: 3, corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])

        let pauseIcon = NSImageView(frame: NSRect(x: 12, y: 10, width: 15, height: 15))
        pauseIcon.image = NSImage(systemSymbolName: paused ? "play.circle" : "pause.circle", accessibilityDescription: nil)
        pauseIcon.contentTintColor = .secondaryLabelColor
        pauseIcon.setAccessibilityHidden(true)
        card.addSubview(pauseIcon)
        card.addSubview(menuLabel(title, size: 13, weight: .regular, y: 9,
                                 width: card.bounds.width - 74, x: 34))
        let shortcut = menuLabel("⌥2", size: 11, weight: .regular, y: 8, width: 21,
                                 x: card.bounds.width - 28, secondary: true)
        shortcut.autoresizingMask = [.minXMargin]
        shortcut.setAccessibilityHidden(true)
        card.addSubview(shortcut)
        addHitTarget(label: title, action: #selector(changePaused), help: "⌥2")
    }

    @objc private func changePaused() { togglePause() }

    required init?(coder: NSCoder) { nil }
}

final class SupportMenuRow: NSView {
    static let title = "Поставить звезду на GitHub"
    static let subtitle = "Поддержать Punto Native"

    init(target: AnyObject, open: Selector) {
        super.init(frame: NSRect(x: 0, y: 0, width: 285, height: 48))
        autoresizingMask = [.width]

        let star = NSImageView(frame: NSRect(x: 20, y: 17, width: 15, height: 15))
        star.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
        star.contentTintColor = .systemOrange
        star.setAccessibilityHidden(true)
        addSubview(star)
        addSubview(menuLabel(Self.title, size: 13, weight: .semibold, y: 24, width: 226, x: 44))
        addSubview(menuLabel(Self.subtitle, size: 11, weight: .regular, y: 8, width: 226, x: 44, secondary: true))

        let link = NSButton(title: "", target: target, action: open)
        link.frame = NSRect(x: 10, y: 2, width: bounds.width - 20, height: 44)
        link.autoresizingMask = [.width]
        link.isBordered = false
        link.isTransparent = true
        link.setAccessibilityLabel(Self.title)
        addSubview(link)
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
