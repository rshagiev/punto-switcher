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
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 340),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Punto"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // Main stack
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .centerX
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])

        // Sections
        mainStack.addArrangedSubview(createHotkeysSection())
        mainStack.addArrangedSubview(createGeneralSection())
        mainStack.addArrangedSubview(createFooter())
    }

    // MARK: - Hotkeys Section

    private func createHotkeysSection() -> NSView {
        let section = createSection(title: "Keyboard Shortcuts")

        let grid = NSGridView(numberOfColumns: 3, rows: 0)
        grid.rowSpacing = 8
        grid.columnSpacing = 12
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).xPlacement = .fill
        grid.column(at: 2).xPlacement = .leading

        // Convert Layout
        let convertRecorder = HotkeyRecorderView(
            hotkey: settingsManager.convertLayoutHotkey,
            onRecord: { [weak self] hotkey in
                self?.settingsManager.convertLayoutHotkey = hotkey
            }
        )
        self.convertLayoutRecorder = convertRecorder
        grid.addRow(with: [
            createLabel("Convert Layout"),
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
            createLabel("Toggle Case"),
            toggleRecorder,
            createResetButton(tag: 1)
        ])

        section.contentStack.addArrangedSubview(grid)

        return section.container
    }

    // MARK: - General Section

    private func createGeneralSection() -> NSView {
        let section = createSection(title: "General")

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6

        stack.addArrangedSubview(createCheckbox(
            "Launch at login",
            isOn: settingsManager.launchAtLogin,
            action: #selector(toggleLaunchAtLogin(_:))
        ))

        stack.addArrangedSubview(createCheckbox(
            "Show in menu bar",
            isOn: settingsManager.showInMenuBar,
            action: #selector(toggleShowInMenuBar(_:))
        ))

        stack.addArrangedSubview(createCheckbox(
            "Switch keyboard after conversion",
            isOn: settingsManager.switchLayoutAfterConversion,
            action: #selector(toggleSwitchLayout(_:))
        ))

        section.contentStack.addArrangedSubview(stack)

        return section.container
    }

    // MARK: - Components

    private func createSection(title: String) -> (container: NSView, contentStack: NSStackView) {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 6
        container.translatesAutoresizingMaskIntoConstraints = false

        // Header
        let header = NSTextField(labelWithString: title)
        header.font = .systemFont(ofSize: 12, weight: .medium)
        header.textColor = .secondaryLabelColor
        container.addArrangedSubview(header)

        // Glass box using NSVisualEffectView
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .popover
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 10
        visualEffect.layer?.masksToBounds = true
        visualEffect.translatesAutoresizingMaskIntoConstraints = false

        // Content stack inside glass box
        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.edgeInsets = NSEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)

        visualEffect.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            visualEffect.widthAnchor.constraint(equalToConstant: 380)
        ])

        container.addArrangedSubview(visualEffect)

        return (container, contentStack)
    }

    private func createLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor
        return label
    }

    private func createCheckbox(_ title: String, isOn: Bool, action: Selector) -> NSButton {
        let checkbox = NSButton(checkboxWithTitle: title, target: self, action: action)
        checkbox.state = isOn ? .on : .off
        checkbox.font = .systemFont(ofSize: 13)
        return checkbox
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

    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        settingsManager.launchAtLogin = sender.state == .on
    }

    @objc private func toggleShowInMenuBar(_ sender: NSButton) {
        settingsManager.showInMenuBar = sender.state == .on
    }

    @objc private func toggleSwitchLayout(_ sender: NSButton) {
        settingsManager.switchLayoutAfterConversion = sender.state == .on
    }
}
