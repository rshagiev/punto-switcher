import AppKit

/// Controller for the settings window - liquid glass macOS style
final class SettingsWindowController: NSWindowController {

    private let settingsManager: SettingsManager
    private var convertLayoutRecorder: HotkeyRecorderView?
    private var toggleCaseRecorder: HotkeyRecorderView?

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 360),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Punto"
        window.center()
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear

        super.init(window: window)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let backgroundView = NSVisualEffectView()
        backgroundView.material = .underWindowBackground
        backgroundView.blendingMode = .behindWindow
        backgroundView.state = .active
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(backgroundView)

        // Main stack
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .centerX
        mainStack.spacing = 18
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        // Sections
        mainStack.addArrangedSubview(createHotkeysSection())
        mainStack.addArrangedSubview(createGeneralSection())
        mainStack.addArrangedSubview(createFooter())
    }

    // MARK: - Hotkeys Section

    private func createHotkeysSection() -> NSView {
        let section = createSection(title: "Keyboard Shortcuts", iconName: "keyboard")

        let grid = NSGridView(numberOfColumns: 3, rows: 0)
        grid.rowSpacing = 10
        grid.columnSpacing = 12
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.column(at: 0).xPlacement = .leading
        grid.column(at: 1).xPlacement = .fill
        grid.column(at: 2).xPlacement = .trailing

        // Convert Layout
        let convertRecorder = HotkeyRecorderView(
            hotkey: settingsManager.convertLayoutHotkey,
            onRecord: { [weak self] hotkey in
                self?.settingsManager.convertLayoutHotkey = hotkey
            }
        )
        self.convertLayoutRecorder = convertRecorder
        grid.addRow(with: [
            createIconLabel("Convert Layout", systemName: "textformat.abc"),
            convertRecorder,
            createResetButton(tag: 0)
        ])

        // Toggle Case
        let toggleRecorder = HotkeyRecorderView(
            hotkey: settingsManager.toggleCaseHotkey,
            onRecord: { [weak self] hotkey in
                self?.settingsManager.toggleCaseHotkey = hotkey
            }
        )
        self.toggleCaseRecorder = toggleRecorder
        grid.addRow(with: [
            createIconLabel("Toggle Case", systemName: "textformat"),
            toggleRecorder,
            createResetButton(tag: 1)
        ])

        section.contentStack.addArrangedSubview(grid)

        return section.container
    }

    // MARK: - General Section

    private func createGeneralSection() -> NSView {
        let section = createSection(title: "General", iconName: "slider.horizontal.3")

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10

        stack.addArrangedSubview(createToggleRow(
            "Launch at login",
            isOn: settingsManager.launchAtLogin,
            action: #selector(toggleLaunchAtLogin(_:)),
            systemName: "power"
        ))

        stack.addArrangedSubview(createToggleRow(
            "Show in menu bar",
            isOn: settingsManager.showInMenuBar,
            action: #selector(toggleShowInMenuBar(_:)),
            systemName: "menubar.rectangle"
        ))

        stack.addArrangedSubview(createToggleRow(
            "Switch keyboard after conversion",
            isOn: settingsManager.switchLayoutAfterConversion,
            action: #selector(toggleSwitchLayout(_:)),
            systemName: "arrow.triangle.2.circlepath"
        ))

        section.contentStack.addArrangedSubview(stack)

        return section.container
    }

    // MARK: - Components

    private func createSection(title: String, iconName: String) -> (container: NSView, contentStack: NSStackView) {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        // Header
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

        // Glass box using NSVisualEffectView
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

        // Content stack inside glass box
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

    private func createLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.alignment = .left
        label.textColor = .labelColor
        return label
    }

    private func createIconLabel(_ title: String, systemName: String) -> NSView {
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

    private func createToggleRow(_ title: String, isOn: Bool, action: Selector, systemName: String) -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor

        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor

        let toggle = NSSwitch()
        toggle.state = isOn ? .on : .off
        toggle.target = self
        toggle.action = action

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [icon, label, spacer, toggle])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        toggle.setContentHuggingPriority(.required, for: .horizontal)

        return row
    }

    private func createResetButton(tag: Int) -> NSButton {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: "arrow.counterclockwise", accessibilityDescription: "Reset")
        button.imagePosition = .imageOnly
        button.bezelStyle = .accessoryBarAction
        button.isBordered = false
        button.tag = tag
        button.target = self
        button.action = #selector(resetHotkey(_:))
        button.contentTintColor = .tertiaryLabelColor
        return button
    }

    private func createFooter() -> NSView {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let label = NSTextField(labelWithString: "Punto v\(version)")
        label.font = .systemFont(ofSize: 11)
        label.textColor = .tertiaryLabelColor
        label.alignment = .center
        return label
    }

    // MARK: - Actions

    @objc private func resetHotkey(_ sender: NSButton) {
        if sender.tag == 0 {
            settingsManager.resetConvertLayoutHotkey()
            convertLayoutRecorder?.updateHotkey(settingsManager.convertLayoutHotkey)
        } else {
            settingsManager.resetToggleCaseHotkey()
            toggleCaseRecorder?.updateHotkey(settingsManager.toggleCaseHotkey)
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSSwitch) {
        settingsManager.launchAtLogin = sender.state == .on
    }

    @objc private func toggleShowInMenuBar(_ sender: NSSwitch) {
        settingsManager.showInMenuBar = sender.state == .on
    }

    @objc private func toggleSwitchLayout(_ sender: NSSwitch) {
        settingsManager.switchLayoutAfterConversion = sender.state == .on
    }
}
