import AppKit

final class AppMenuTile: NSView {
    private let toggleDisclosure: () -> Void
    private let toggleAutomatic: () -> Void
    private let togglePause: () -> Void
    override var isFlipped: Bool { true }

    init(application: NSRunningApplication, title: String, subtitle: String, expanded: Bool,
         automatic: Bool, automaticAvailable: Bool, paused: Bool,
         toggleDisclosure: @escaping () -> Void, toggleAutomatic: @escaping () -> Void,
         togglePause: @escaping () -> Void) {
        self.toggleDisclosure = toggleDisclosure
        self.toggleAutomatic = toggleAutomatic
        self.togglePause = togglePause
        super.init(frame: NSRect(x: 0, y: 0, width: 305, height: expanded ? 125 : 54))
        autoresizingMask = [.width]

        let card = NSView(frame: bounds.insetBy(dx: 8, dy: 3))
        card.autoresizingMask = [.width]
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.07).cgColor
        card.layer?.cornerRadius = 9
        addSubview(card)

        let header = NSView(frame: NSRect(x: 0, y: card.bounds.height - 48, width: card.bounds.width, height: 48))
        header.autoresizingMask = [.width]
        card.addSubview(header)
        let icon = NSImageView(frame: NSRect(x: 11, y: 10, width: 28, height: 28))
        icon.image = application.icon ?? NSImage(systemSymbolName: "app", accessibilityDescription: nil)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.setAccessibilityHidden(true)
        header.addSubview(icon)
        header.addSubview(menuLabel(title, size: 13, weight: .semibold, y: 25, width: card.bounds.width - 76, x: 47))
        header.addSubview(menuLabel(subtitle, size: 11, weight: .regular, y: 8, width: card.bounds.width - 76, x: 47, secondary: true))
        let chevron = NSImageView(frame: NSRect(x: card.bounds.width - 27, y: 17, width: 13, height: 13))
        chevron.image = NSImage(systemSymbolName: expanded ? "chevron.up" : "chevron.down", accessibilityDescription: nil)
        chevron.contentTintColor = .secondaryLabelColor
        chevron.autoresizingMask = [.minXMargin]
        chevron.setAccessibilityHidden(true)
        header.addSubview(chevron)

        let disclosure = NSButton(title: "", target: self, action: #selector(disclose))
        disclosure.frame = header.bounds
        disclosure.autoresizingMask = [.width]
        disclosure.isBordered = false
        disclosure.isTransparent = true
        disclosure.setAccessibilityLabel(expanded ? "Свернуть настройки для \(title)" : "Раскрыть настройки для \(title)")
        disclosure.setAccessibilityValue(subtitle)
        disclosure.setAccessibilityExpanded(expanded)
        header.addSubview(disclosure)

        guard expanded else { return }
        let divider = NSBox(frame: NSRect(x: 10, y: 69, width: card.bounds.width - 20, height: 1))
        divider.boxType = .separator
        divider.autoresizingMask = [.width]
        card.addSubview(divider)

        let bolt = NSImageView(frame: NSRect(x: 12, y: 44, width: 15, height: 15))
        bolt.image = NSImage(systemSymbolName: "bolt", accessibilityDescription: nil)
        bolt.contentTintColor = .secondaryLabelColor
        bolt.setAccessibilityHidden(true)
        card.addSubview(bolt)
        let autoLabel = menuLabel("Автопереключение", size: 13, weight: .regular, y: 43,
                                  width: card.bounds.width - 94, x: 34, secondary: !automaticAvailable)
        card.addSubview(autoLabel)
        let automaticSwitch = NSSwitch()
        automaticSwitch.sizeToFit()
        automaticSwitch.frame.origin = NSPoint(x: card.bounds.width - automaticSwitch.frame.width - 11, y: 42)
        automaticSwitch.autoresizingMask = [.minXMargin]
        automaticSwitch.state = automatic ? .on : .off
        automaticSwitch.isEnabled = automaticAvailable
        automaticSwitch.target = self
        automaticSwitch.action = #selector(changeAutomatic)
        automaticSwitch.setAccessibilityLabel("Автопереключение для \(title)")
        card.addSubview(automaticSwitch)

        let pauseIcon = NSImageView(frame: NSRect(x: 12, y: 14, width: 15, height: 15))
        pauseIcon.image = NSImage(systemSymbolName: paused ? "play.circle" : "pause.circle", accessibilityDescription: nil)
        pauseIcon.contentTintColor = .secondaryLabelColor
        pauseIcon.setAccessibilityHidden(true)
        card.addSubview(pauseIcon)
        let pauseTitle = paused ? "Возобновить Punto" : "Приостановить Punto"
        card.addSubview(menuLabel(pauseTitle, size: 13, weight: .regular, y: 13,
                                 width: card.bounds.width - 49, x: 34))
        let pause = NSButton(title: "", target: self, action: #selector(changePaused))
        pause.frame = NSRect(x: 8, y: 5, width: card.bounds.width - 16, height: 30)
        pause.autoresizingMask = [.width]
        pause.isBordered = false
        pause.isTransparent = true
        pause.setAccessibilityLabel(pauseTitle)
        card.addSubview(pause)
    }

    @objc private func disclose() { toggleDisclosure() }
    @objc private func changeAutomatic() { toggleAutomatic() }
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
