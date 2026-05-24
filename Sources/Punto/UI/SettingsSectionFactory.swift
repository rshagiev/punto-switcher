import AppKit

enum SettingsSectionFactory {
    static func createSection(title: String, iconName: String) -> (container: NSView, contentStack: NSStackView) {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        let headerIcon = NSImageView()
        headerIcon.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        headerIcon.contentTintColor = .secondaryLabelColor

        let headerLabel = NSTextField(labelWithString: title)
        headerLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        headerLabel.textColor = .secondaryLabelColor

        let headerRow = NSStackView(views: [headerIcon, headerLabel])
        headerRow.orientation = .horizontal
        headerRow.alignment = .centerY
        headerRow.spacing = 6
        container.addArrangedSubview(headerRow)

        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .withinWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 14
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.borderWidth = 1
        visualEffect.layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
        visualEffect.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.08).cgColor
        visualEffect.translatesAutoresizingMaskIntoConstraints = false

        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)

        visualEffect.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            visualEffect.widthAnchor.constraint(equalToConstant: 400)
        ])

        container.addArrangedSubview(visualEffect)

        return (container, contentStack)
    }

    static func createIconLabel(_ title: String, systemName: String) -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor

        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .labelColor

        let stack = NSStackView(views: [icon, label])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 6
        return stack
    }
}
