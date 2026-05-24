import AppKit
import PuntoCore
import PuntoSettings

/// Controller for the settings window - liquid glass macOS style
final class SettingsWindowController: NSWindowController {

    private let settingsManager: SettingsManager
    private let currentApplication: () -> (bundleID: String, name: String?)?
    private var convertLayoutRecorder: HotkeyRecorderView?
    private var toggleCaseRecorder: HotkeyRecorderView?
    private var toggleAutoCorrectionRecorder: HotkeyRecorderView?
    private var cancelLayoutChangeRecorder: HotkeyRecorderView?
    private var findInYandexRecorder: HotkeyRecorderView?
    private var findInSlovariRecorder: HotkeyRecorderView?
    private var preferredEnglishInputSourceIDField: NSTextField?
    private var preferredRussianInputSourceIDField: NSTextField?
    private var rulesWindow: NSWindow?
    private var rulesTableView: NSTableView?
    private var rulesSearchField: NSSearchField?
    private var rulesStatusLabel: NSTextField?
    private var filteredRuleIndexes: [Int] = []
    private var disabledAppsWindow: NSWindow?
    private var disabledAppsTableView: NSTableView?
    private var disabledAppsStatusLabel: NSTextField?
    private var disabledAppBundleIDs: [String] = []
    private var resetOnReturnWindow: NSWindow?
    private var resetOnReturnTableView: NSTableView?
    private var resetOnReturnStatusLabel: NSTextField?
    private var resetOnReturnBundleComponents: [String] = []
    private var layoutMemoryWindow: NSWindow?
    private var layoutMemoryTableView: NSTableView?
    private var layoutMemoryStatusLabel: NSTextField?
    private var rememberedLayoutRows: [(bundleID: String, layoutID: String)] = []
    private weak var advancedSettingsStack: NSStackView?

    init(
        settingsManager: SettingsManager,
        currentApplication: @escaping () -> (bundleID: String, name: String?)? = { nil }
    ) {
        self.settingsManager = settingsManager
        self.currentApplication = currentApplication

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 750),
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
                self?.recordHotkey(hotkey, for: .convertLayout)
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
                self?.recordHotkey(hotkey, for: .toggleCase)
            }
        )
        self.toggleCaseRecorder = toggleRecorder
        grid.addRow(with: [
            createIconLabel("Toggle Case", systemName: "textformat"),
            toggleRecorder,
            createResetButton(tag: 1)
        ])

        // Toggle Auto-correction
        let toggleAutoCorrectionRecorder = HotkeyRecorderView(
            hotkey: settingsManager.toggleAutoCorrectionHotkey,
            onRecord: { [weak self] hotkey in
                self?.recordHotkey(hotkey, for: .toggleAutoCorrection)
            }
        )
        self.toggleAutoCorrectionRecorder = toggleAutoCorrectionRecorder
        grid.addRow(with: [
            createIconLabel("Toggle Auto-correction", systemName: "wand.and.stars"),
            toggleAutoCorrectionRecorder,
            createResetButton(tag: 2)
        ])

        // Cancel Last Conversion
        let cancelLayoutChangeRecorder = HotkeyRecorderView(
            hotkey: settingsManager.cancelLayoutChangeHotkey,
            onRecord: { [weak self] hotkey in
                self?.recordHotkey(hotkey, for: .cancelLayoutChange)
            }
        )
        self.cancelLayoutChangeRecorder = cancelLayoutChangeRecorder
        grid.addRow(with: [
            createIconLabel("Cancel Last Conversion", systemName: "arrow.uturn.backward"),
            cancelLayoutChangeRecorder,
            createResetButton(tag: 3)
        ])

        // Find in Yandex
        let findInYandexRecorder = HotkeyRecorderView(
            hotkey: settingsManager.findInYandexHotkey,
            onRecord: { [weak self] hotkey in
                self?.recordHotkey(hotkey, for: .findInYandex)
            }
        )
        self.findInYandexRecorder = findInYandexRecorder
        grid.addRow(with: [
            createIconLabel("Find in Yandex", systemName: "magnifyingglass"),
            findInYandexRecorder,
            createResetButton(tag: 4)
        ])

        // Find in Translate
        let findInSlovariRecorder = HotkeyRecorderView(
            hotkey: settingsManager.findInSlovariHotkey,
            onRecord: { [weak self] hotkey in
                self?.recordHotkey(hotkey, for: .findInSlovari)
            }
        )
        self.findInSlovariRecorder = findInSlovariRecorder
        grid.addRow(with: [
            createIconLabel("Find in Translate", systemName: "character.book.closed"),
            findInSlovariRecorder,
            createResetButton(tag: 5)
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

        stack.addArrangedSubview(createToggleRow(
            "Auto-correct typed rules",
            isOn: settingsManager.autoCorrectionEnabled,
            action: #selector(toggleAutoCorrection(_:)),
            systemName: "wand.and.stars"
        ))

        stack.addArrangedSubview(createToggleRow(
            "Sound effects",
            isOn: settingsManager.soundEffectsEnabled,
            action: #selector(toggleSoundEffects(_:)),
            systemName: "speaker.wave.2"
        ))

        stack.addArrangedSubview(createToggleRow(
            "Show advanced settings",
            isOn: settingsManager.showAdvancedSettings,
            action: #selector(toggleShowAdvancedSettings(_:)),
            systemName: "gearshape.2"
        ))

        let advancedStack = NSStackView()
        advancedStack.orientation = .vertical
        advancedStack.alignment = .leading
        advancedStack.spacing = 10
        advancedStack.isHidden = !settingsManager.showAdvancedSettings
        self.advancedSettingsStack = advancedStack

        advancedStack.addArrangedSubview(createToggleRow(
            "Switch keyboard for selected text",
            isOn: settingsManager.switchLayoutAfterSelectedTextConversion,
            action: #selector(toggleSwitchLayoutForSelectedText(_:)),
            systemName: "selection.pin.in.out"
        ))

        advancedStack.addArrangedSubview(createToggleRow(
            "Search selected text by double-click",
            isOn: settingsManager.searchSelectedTextByDoubleClick,
            action: #selector(toggleSearchSelectedTextByDoubleClick(_:)),
            systemName: "cursorarrow.click.2"
        ))

        advancedStack.addArrangedSubview(createRussianKeyboardLayoutTypeRow())
        advancedStack.addArrangedSubview(createPreferredInputSourceIDRow(
            title: "English layout ID",
            sourceID: settingsManager.preferredEnglishInputSourceID,
            systemName: "keyboard",
            fieldStore: { [weak self] field in self?.preferredEnglishInputSourceIDField = field },
            fieldAction: #selector(changePreferredEnglishInputSourceID(_:)),
            resetAction: #selector(resetPreferredEnglishInputSourceID(_:))
        ))
        advancedStack.addArrangedSubview(createPreferredInputSourceIDRow(
            title: "Russian layout ID",
            sourceID: settingsManager.preferredRussianInputSourceID,
            systemName: "keyboard.onehanded.right",
            fieldStore: { [weak self] field in self?.preferredRussianInputSourceIDField = field },
            fieldAction: #selector(changePreferredRussianInputSourceID(_:)),
            resetAction: #selector(resetPreferredRussianInputSourceID(_:))
        ))

        advancedStack.addArrangedSubview(createToggleRow(
            "Disable manual conversion",
            isOn: settingsManager.manualConversionDisabled,
            action: #selector(toggleManualConversionDisabled(_:)),
            systemName: "keyboard.badge.eye"
        ))

        advancedStack.addArrangedSubview(createToggleRow(
            "Remember layout for each app",
            isOn: settingsManager.rememberInputSourceForEachApp,
            action: #selector(toggleRememberLayoutPerApp(_:)),
            systemName: "rectangle.stack.person.crop"
        ))

        advancedStack.addArrangedSubview(createToggleRow(
            "Auto-correct on Return and Tab",
            isOn: settingsManager.autoCorrectOnEnterAndTab,
            action: #selector(toggleAutoCorrectOnEnterAndTab(_:)),
            systemName: "return"
        ))

        advancedStack.addArrangedSubview(createToggleRow(
            "Learn from undone auto-corrections",
            isOn: settingsManager.autoCorrectionUndoLearningEnabled,
            action: #selector(toggleAutoCorrectionUndoLearning(_:)),
            systemName: "arrow.uturn.backward.circle"
        ))

        advancedStack.addArrangedSubview(createToggleRow(
            "Skip auto-correct after manual conversion",
            isOn: settingsManager.suppressAutoCorrectionAfterManualConversion,
            action: #selector(toggleSuppressAutoCorrectionAfterManualConversion(_:)),
            systemName: "arrow.trianglehead.2.clockwise.rotate.90"
        ))

        advancedStack.addArrangedSubview(createCancellingKeyTogglesGrid())
        advancedStack.addArrangedSubview(createSoundResourceTogglesGrid())

        advancedStack.addArrangedSubview(createImportRulesRow())
        advancedStack.addArrangedSubview(createRememberedLayoutsRow())
        advancedStack.addArrangedSubview(createResetOnReturnRow())
        advancedStack.addArrangedSubview(createToggleRow(
            "Fully disable in exception apps",
            isOn: settingsManager.completelyDisableInExceptionApplications,
            action: #selector(toggleCompletelyDisableInExceptionApps(_:)),
            systemName: "nosign"
        ))
        advancedStack.addArrangedSubview(createDisabledAppsRow())
        stack.addArrangedSubview(advancedStack)

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

    private func createSoundResourceTogglesGrid() -> NSView {
        let rows: [[(title: String, resourceName: String)]] = [
            [("Replace", "replace"), ("Reverse", "reverse")],
            [("Misprint", "misprint"), ("Switch", "switch")],
            [("English", "en"), ("Russian", "ru")],
            [("Typed EN", "typeeng"), ("Typed RU", "typerus")]
        ]

        let grid = NSGridView(numberOfColumns: 2, rows: 0)
        grid.rowSpacing = 4
        grid.columnSpacing = 18
        grid.translatesAutoresizingMaskIntoConstraints = false

        for row in rows {
            grid.addRow(with: row.map { item in
                let checkbox = NSButton(
                    checkboxWithTitle: item.title,
                    target: self,
                    action: #selector(toggleSoundResource(_:))
                )
                checkbox.identifier = NSUserInterfaceItemIdentifier(item.resourceName)
                checkbox.state = settingsManager.isSoundResourceEnabled(item.resourceName) ? .on : .off
                checkbox.font = .systemFont(ofSize: 12)
                checkbox.setContentHuggingPriority(.required, for: .horizontal)
                return checkbox
            })
        }

        let label = NSTextField(labelWithString: "Sound events")
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.setContentHuggingPriority(.required, for: .horizontal)

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [label, spacer, grid])
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = 8
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return row
    }

    private func createCancellingKeyTogglesGrid() -> NSView {
        let grid = NSGridView(numberOfColumns: 3, rows: 0)
        grid.rowSpacing = 4
        grid.columnSpacing = 12
        grid.translatesAutoresizingMaskIntoConstraints = false

        let items = AutoCorrectionCancellingKeyPolicy.displayOrder
        for start in stride(from: 0, to: items.count, by: 3) {
            let rowItems = Array(items[start..<min(start + 3, items.count)])
            grid.addRow(with: rowItems.map { item in
                let checkbox = NSButton(
                    checkboxWithTitle: item.title,
                    target: self,
                    action: #selector(toggleAutoCorrectionCancellingKey(_:))
                )
                checkbox.identifier = NSUserInterfaceItemIdentifier(item.name)
                checkbox.state = settingsManager.isAutoCorrectionCancellingKeyEnabled(item.name) ? .on : .off
                checkbox.font = .systemFont(ofSize: 12)
                checkbox.setContentHuggingPriority(.required, for: .horizontal)
                return checkbox
            })
        }

        let label = NSTextField(labelWithString: "Cancel auto-correction after")
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.setContentHuggingPriority(.required, for: .horizontal)

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [label, spacer, grid])
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = 8
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return row
    }

    private func createRussianKeyboardLayoutTypeRow() -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "keyboard.chevron.compact.down", accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor

        let label = NSTextField(labelWithString: "Russian keyboard layout")
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor

        let segmented = NSSegmentedControl(labels: ["Mac", "Windows"], trackingMode: .selectOne, target: self, action: #selector(changeRussianKeyboardLayoutType(_:)))
        segmented.segmentStyle = .rounded
        segmented.selectedSegment = settingsManager.russianKeyboardLayoutType == .windows ? 1 : 0

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [icon, label, spacer, segmented])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        segmented.setContentHuggingPriority(.required, for: .horizontal)

        return row
    }

    private func createPreferredInputSourceIDRow(
        title: String,
        sourceID: String?,
        systemName: String,
        fieldStore: (NSTextField) -> Void,
        fieldAction: Selector,
        resetAction: Selector
    ) -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor

        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor

        let field = NSTextField(string: sourceID ?? "")
        field.placeholderString = "Auto"
        field.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        field.target = self
        field.action = fieldAction
        field.tag = -1
        field.lineBreakMode = .byTruncatingMiddle
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        fieldStore(field)

        let resetButton = NSButton(title: "Auto", target: self, action: resetAction)
        resetButton.bezelStyle = .rounded

        let row = NSStackView(views: [icon, label, field, resetButton])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        NSLayoutConstraint.activate([
            field.widthAnchor.constraint(equalToConstant: 145)
        ])

        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        resetButton.setContentHuggingPriority(.required, for: .horizontal)

        return row
    }

    private func createDisabledAppsRow() -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "nosign.app", accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor

        let label = NSTextField(labelWithString: "Disabled applications")
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor

        let countLabel = NSTextField(labelWithString: "\(settingsManager.disabledApplicationBundleIDs.count)")
        countLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        countLabel.textColor = .secondaryLabelColor
        countLabel.tag = 102

        let manageButton = NSButton(title: "Manage...", target: self, action: #selector(showDisabledAppsEditor(_:)))
        manageButton.bezelStyle = .rounded

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [icon, label, countLabel, spacer, manageButton])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        manageButton.setContentHuggingPriority(.required, for: .horizontal)

        return row
    }

    private func createResetOnReturnRow() -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "return", accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor

        let label = NSTextField(labelWithString: "Return reset apps")
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor

        let countLabel = NSTextField(labelWithString: "\(settingsManager.resetOnReturnBundleComponents.count)")
        countLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        countLabel.textColor = .secondaryLabelColor
        countLabel.tag = 103

        let manageButton = NSButton(title: "Manage...", target: self, action: #selector(showResetOnReturnEditor(_:)))
        manageButton.bezelStyle = .rounded

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [icon, label, countLabel, spacer, manageButton])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        manageButton.setContentHuggingPriority(.required, for: .horizontal)

        return row
    }

    private func createRememberedLayoutsRow() -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "keyboard.badge.eye", accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor

        let label = NSTextField(labelWithString: "Remembered app layouts")
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor

        let countLabel = NSTextField(labelWithString: "\(settingsManager.rememberedApplicationLayouts.count)")
        countLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        countLabel.textColor = .secondaryLabelColor
        countLabel.tag = 104

        let manageButton = NSButton(title: "Manage...", target: self, action: #selector(showLayoutMemoryEditor(_:)))
        manageButton.bezelStyle = .rounded

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [icon, label, countLabel, spacer, manageButton])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        manageButton.setContentHuggingPriority(.required, for: .horizontal)

        return row
    }

    private func createImportRulesRow() -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor

        let label = NSTextField(labelWithString: "Auto-correction rules")
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor

        let countLabel = NSTextField(labelWithString: "\(settingsManager.autoCorrectionRules.count)")
        countLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        countLabel.textColor = .secondaryLabelColor
        countLabel.tag = 101

        let editButton = NSButton(title: "Edit...", target: self, action: #selector(showAutoCorrectionRulesEditor(_:)))
        editButton.bezelStyle = .rounded

        let importButton = NSButton(title: "Import...", target: self, action: #selector(importAutoCorrectionRules(_:)))
        importButton.bezelStyle = .rounded

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [icon, label, countLabel, spacer, editButton, importButton])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        editButton.setContentHuggingPriority(.required, for: .horizontal)
        importButton.setContentHuggingPriority(.required, for: .horizontal)

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

    private var hotkeyAssignments: [HotkeyAssignment] {
        [
            HotkeyAssignment(slot: .convertLayout, hotkey: settingsManager.convertLayoutHotkey),
            HotkeyAssignment(slot: .toggleCase, hotkey: settingsManager.toggleCaseHotkey),
            HotkeyAssignment(slot: .toggleAutoCorrection, hotkey: settingsManager.toggleAutoCorrectionHotkey),
            HotkeyAssignment(slot: .cancelLayoutChange, hotkey: settingsManager.cancelLayoutChangeHotkey),
            HotkeyAssignment(slot: .findInYandex, hotkey: settingsManager.findInYandexHotkey),
            HotkeyAssignment(slot: .findInSlovari, hotkey: settingsManager.findInSlovariHotkey)
        ]
    }

    private func recordHotkey(_ hotkey: Hotkey, for slot: HotkeySlot) {
        let normalized = HotkeyValidationPolicy.normalized(hotkey, fallback: defaultHotkey(for: slot))
        guard HotkeyCollisionPolicy.canAllowShortcut(normalized, in: hotkeyAssignments, excluding: slot) else {
            NSSound.beep()
            recorder(for: slot)?.updateHotkey(savedHotkey(for: slot))
            return
        }

        setHotkey(normalized, for: slot)
        recorder(for: slot)?.updateHotkey(savedHotkey(for: slot))
    }

    private func savedHotkey(for slot: HotkeySlot) -> Hotkey {
        switch slot {
        case .convertLayout:
            return settingsManager.convertLayoutHotkey
        case .toggleCase:
            return settingsManager.toggleCaseHotkey
        case .toggleAutoCorrection:
            return settingsManager.toggleAutoCorrectionHotkey
        case .cancelLayoutChange:
            return settingsManager.cancelLayoutChangeHotkey
        case .findInYandex:
            return settingsManager.findInYandexHotkey
        case .findInSlovari:
            return settingsManager.findInSlovariHotkey
        }
    }

    private func defaultHotkey(for slot: HotkeySlot) -> Hotkey {
        switch slot {
        case .convertLayout:
            return Hotkey.defaultConvertLayout
        case .toggleCase:
            return Hotkey.defaultToggleCase
        case .toggleAutoCorrection:
            return Hotkey.defaultToggleAutoCorrection
        case .cancelLayoutChange:
            return Hotkey.defaultCancelLayoutChange
        case .findInYandex:
            return Hotkey.defaultFindInYandex
        case .findInSlovari:
            return Hotkey.defaultFindInSlovari
        }
    }

    private func setHotkey(_ hotkey: Hotkey, for slot: HotkeySlot) {
        switch slot {
        case .convertLayout:
            settingsManager.convertLayoutHotkey = hotkey
        case .toggleCase:
            settingsManager.toggleCaseHotkey = hotkey
        case .toggleAutoCorrection:
            settingsManager.toggleAutoCorrectionHotkey = hotkey
        case .cancelLayoutChange:
            settingsManager.cancelLayoutChangeHotkey = hotkey
        case .findInYandex:
            settingsManager.findInYandexHotkey = hotkey
        case .findInSlovari:
            settingsManager.findInSlovariHotkey = hotkey
        }
    }

    private func recorder(for slot: HotkeySlot) -> HotkeyRecorderView? {
        switch slot {
        case .convertLayout:
            return convertLayoutRecorder
        case .toggleCase:
            return toggleCaseRecorder
        case .toggleAutoCorrection:
            return toggleAutoCorrectionRecorder
        case .cancelLayoutChange:
            return cancelLayoutChangeRecorder
        case .findInYandex:
            return findInYandexRecorder
        case .findInSlovari:
            return findInSlovariRecorder
        }
    }

    @objc private func resetHotkey(_ sender: NSButton) {
        if sender.tag == 0 {
            settingsManager.resetConvertLayoutHotkey()
            convertLayoutRecorder?.updateHotkey(settingsManager.convertLayoutHotkey)
        } else if sender.tag == 1 {
            settingsManager.resetToggleCaseHotkey()
            toggleCaseRecorder?.updateHotkey(settingsManager.toggleCaseHotkey)
        } else if sender.tag == 2 {
            settingsManager.resetToggleAutoCorrectionHotkey()
            toggleAutoCorrectionRecorder?.updateHotkey(settingsManager.toggleAutoCorrectionHotkey)
        } else if sender.tag == 3 {
            settingsManager.resetCancelLayoutChangeHotkey()
            cancelLayoutChangeRecorder?.updateHotkey(settingsManager.cancelLayoutChangeHotkey)
        } else if sender.tag == 4 {
            settingsManager.resetFindInYandexHotkey()
            findInYandexRecorder?.updateHotkey(settingsManager.findInYandexHotkey)
        } else if sender.tag == 5 {
            settingsManager.resetFindInSlovariHotkey()
            findInSlovariRecorder?.updateHotkey(settingsManager.findInSlovariHotkey)
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSSwitch) {
        settingsManager.launchAtLogin = sender.state == .on
    }

    @objc private func toggleShowInMenuBar(_ sender: NSSwitch) {
        settingsManager.showInMenuBar = sender.state == .on
    }

    @objc private func toggleShowAdvancedSettings(_ sender: NSSwitch) {
        let isVisible = sender.state == .on
        settingsManager.showAdvancedSettings = isVisible
        advancedSettingsStack?.isHidden = !isVisible
        window?.layoutIfNeeded()
    }

    @objc private func toggleSwitchLayout(_ sender: NSSwitch) {
        settingsManager.switchLayoutAfterConversion = sender.state == .on
    }

    @objc private func toggleSwitchLayoutForSelectedText(_ sender: NSSwitch) {
        settingsManager.switchLayoutAfterSelectedTextConversion = sender.state == .on
    }

    @objc private func toggleSearchSelectedTextByDoubleClick(_ sender: NSSwitch) {
        settingsManager.searchSelectedTextByDoubleClick = sender.state == .on
    }

    @objc private func toggleManualConversionDisabled(_ sender: NSSwitch) {
        settingsManager.manualConversionDisabled = sender.state == .on
    }

    @objc private func changeRussianKeyboardLayoutType(_ sender: NSSegmentedControl) {
        settingsManager.russianKeyboardLayoutType = sender.selectedSegment == 1 ? .windows : .mac
    }

    @objc private func changePreferredEnglishInputSourceID(_ sender: NSTextField) {
        settingsManager.preferredEnglishInputSourceID = sender.stringValue
        sender.stringValue = settingsManager.preferredEnglishInputSourceID ?? ""
    }

    @objc private func changePreferredRussianInputSourceID(_ sender: NSTextField) {
        settingsManager.preferredRussianInputSourceID = sender.stringValue
        sender.stringValue = settingsManager.preferredRussianInputSourceID ?? ""
    }

    @objc private func resetPreferredEnglishInputSourceID(_ sender: NSButton) {
        settingsManager.preferredEnglishInputSourceID = nil
        preferredEnglishInputSourceIDField?.stringValue = ""
    }

    @objc private func resetPreferredRussianInputSourceID(_ sender: NSButton) {
        settingsManager.preferredRussianInputSourceID = nil
        preferredRussianInputSourceIDField?.stringValue = ""
    }

    @objc private func toggleRememberLayoutPerApp(_ sender: NSSwitch) {
        settingsManager.rememberInputSourceForEachApp = sender.state == .on
    }

    @objc private func toggleCompletelyDisableInExceptionApps(_ sender: NSSwitch) {
        settingsManager.completelyDisableInExceptionApplications = sender.state == .on
    }

    @objc private func toggleAutoCorrection(_ sender: NSSwitch) {
        settingsManager.autoCorrectionEnabled = sender.state == .on
    }

    @objc private func toggleAutoCorrectOnEnterAndTab(_ sender: NSSwitch) {
        settingsManager.autoCorrectOnEnterAndTab = sender.state == .on
    }

    @objc private func toggleAutoCorrectionUndoLearning(_ sender: NSSwitch) {
        settingsManager.autoCorrectionUndoLearningEnabled = sender.state == .on
    }

    @objc private func toggleSuppressAutoCorrectionAfterManualConversion(_ sender: NSSwitch) {
        settingsManager.suppressAutoCorrectionAfterManualConversion = sender.state == .on
    }

    @objc private func toggleAutoCorrectionCancellingKey(_ sender: NSButton) {
        guard let keyName = sender.identifier?.rawValue else {
            return
        }
        settingsManager.setAutoCorrectionCancellingKey(keyName, enabled: sender.state == .on)
    }

    @objc private func toggleSoundEffects(_ sender: NSSwitch) {
        settingsManager.soundEffectsEnabled = sender.state == .on
    }

    @objc private func toggleSoundResource(_ sender: NSButton) {
        guard let resourceName = sender.identifier?.rawValue else {
            return
        }
        settingsManager.setSoundResource(resourceName, enabled: sender.state == .on)
    }

    @objc private func showAutoCorrectionRulesEditor(_ sender: NSButton) {
        if let rulesWindow {
            rulesWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let editorWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        editorWindow.title = "Auto-correction Rules"
        editorWindow.center()
        editorWindow.isReleasedWhenClosed = false
        editorWindow.delegate = self

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        root.translatesAutoresizingMaskIntoConstraints = false

        let searchField = NSSearchField()
        searchField.placeholderString = "Search rules"
        searchField.target = self
        searchField.action = #selector(filterAutoCorrectionRules(_:))
        searchField.translatesAutoresizingMaskIntoConstraints = false

        let statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        let tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = false
        tableView.dataSource = self
        tableView.delegate = self

        addRuleColumn(to: tableView, identifier: "trigger", title: "Trigger", width: 190)
        addRuleColumn(to: tableView, identifier: "replacement", title: "Replacement", width: 250)
        addRuleColumn(to: tableView, identifier: "matchMode", title: "Match", width: 130)
        addRuleColumn(to: tableView, identifier: "preserveCase", title: "Case", width: 80)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = tableView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let addButton = NSButton(title: "Add", target: self, action: #selector(addAutoCorrectionRule(_:)))
        let deleteButton = NSButton(title: "Delete", target: self, action: #selector(deleteSelectedAutoCorrectionRule(_:)))
        let importButton = NSButton(title: "Import...", target: self, action: #selector(importAutoCorrectionRules(_:)))
        let exportButton = NSButton(title: "Export...", target: self, action: #selector(exportAutoCorrectionRules(_:)))
        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeRulesEditor(_:)))

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        let buttonRow = NSStackView(views: [addButton, deleteButton, importButton, exportButton, spacer, closeButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        root.addArrangedSubview(searchField)
        root.addArrangedSubview(scrollView)
        root.addArrangedSubview(statusLabel)
        root.addArrangedSubview(buttonRow)

        editorWindow.contentView?.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: editorWindow.contentView!.topAnchor),
            root.leadingAnchor.constraint(equalTo: editorWindow.contentView!.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: editorWindow.contentView!.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: editorWindow.contentView!.bottomAnchor),
            searchField.widthAnchor.constraint(equalTo: root.widthAnchor),
            scrollView.widthAnchor.constraint(equalTo: root.widthAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 300),
            statusLabel.widthAnchor.constraint(equalTo: root.widthAnchor),
            buttonRow.widthAnchor.constraint(equalTo: root.widthAnchor)
        ])

        rulesWindow = editorWindow
        rulesTableView = tableView
        rulesSearchField = searchField
        rulesStatusLabel = statusLabel
        reloadRulesEditor()
        editorWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showDisabledAppsEditor(_ sender: NSButton) {
        if let disabledAppsWindow {
            disabledAppsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let editorWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        editorWindow.title = "Disabled Applications"
        editorWindow.center()
        editorWindow.isReleasedWhenClosed = false
        editorWindow.delegate = self

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        root.translatesAutoresizingMaskIntoConstraints = false

        let tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = true
        tableView.dataSource = self
        tableView.delegate = self

        addRuleColumn(to: tableView, identifier: "appName", title: "Application", width: 220)
        addRuleColumn(to: tableView, identifier: "bundleID", title: "Bundle ID", width: 360)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = tableView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor

        let addCurrentButton = NSButton(title: "Add Current App", target: self, action: #selector(addCurrentDisabledApplication(_:)))
        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeSelectedDisabledApplications(_:)))
        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeDisabledAppsEditor(_:)))

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        let buttonRow = NSStackView(views: [addCurrentButton, removeButton, spacer, closeButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        root.addArrangedSubview(scrollView)
        root.addArrangedSubview(statusLabel)
        root.addArrangedSubview(buttonRow)

        editorWindow.contentView?.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: editorWindow.contentView!.topAnchor),
            root.leadingAnchor.constraint(equalTo: editorWindow.contentView!.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: editorWindow.contentView!.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: editorWindow.contentView!.bottomAnchor),
            scrollView.widthAnchor.constraint(equalTo: root.widthAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 260),
            statusLabel.widthAnchor.constraint(equalTo: root.widthAnchor),
            buttonRow.widthAnchor.constraint(equalTo: root.widthAnchor)
        ])

        disabledAppsWindow = editorWindow
        disabledAppsTableView = tableView
        disabledAppsStatusLabel = statusLabel
        reloadDisabledAppsEditor()
        editorWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showResetOnReturnEditor(_ sender: NSButton) {
        if let resetOnReturnWindow {
            resetOnReturnWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let editorWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 340),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        editorWindow.title = "Return Reset Apps"
        editorWindow.center()
        editorWindow.isReleasedWhenClosed = false
        editorWindow.delegate = self

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        root.translatesAutoresizingMaskIntoConstraints = false

        let tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = true
        tableView.dataSource = self
        tableView.delegate = self

        addRuleColumn(to: tableView, identifier: "resetOnReturnComponent", title: "Bundle ID component", width: 460)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = tableView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        let addTelegramButton = NSButton(title: "Add Telegram", target: self, action: #selector(addTelegramResetOnReturnComponent(_:)))
        let addButton = NSButton(title: "Add", target: self, action: #selector(addResetOnReturnComponent(_:)))
        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeSelectedResetOnReturnComponents(_:)))
        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeResetOnReturnEditor(_:)))

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        let buttonRow = NSStackView(views: [addTelegramButton, addButton, removeButton, spacer, closeButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        root.addArrangedSubview(scrollView)
        root.addArrangedSubview(statusLabel)
        root.addArrangedSubview(buttonRow)

        editorWindow.contentView?.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: editorWindow.contentView!.topAnchor),
            root.leadingAnchor.constraint(equalTo: editorWindow.contentView!.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: editorWindow.contentView!.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: editorWindow.contentView!.bottomAnchor),
            scrollView.widthAnchor.constraint(equalTo: root.widthAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 240),
            statusLabel.widthAnchor.constraint(equalTo: root.widthAnchor),
            buttonRow.widthAnchor.constraint(equalTo: root.widthAnchor)
        ])

        resetOnReturnWindow = editorWindow
        resetOnReturnTableView = tableView
        resetOnReturnStatusLabel = statusLabel
        reloadResetOnReturnEditor()
        editorWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showLayoutMemoryEditor(_ sender: NSButton) {
        if let layoutMemoryWindow {
            layoutMemoryWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let editorWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 380),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        editorWindow.title = "Remembered App Layouts"
        editorWindow.center()
        editorWindow.isReleasedWhenClosed = false
        editorWindow.delegate = self

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        root.translatesAutoresizingMaskIntoConstraints = false

        let tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = true
        tableView.dataSource = self
        tableView.delegate = self

        addRuleColumn(to: tableView, identifier: "layoutAppName", title: "Application", width: 210)
        addRuleColumn(to: tableView, identifier: "layoutBundleID", title: "Bundle ID", width: 260)
        addRuleColumn(to: tableView, identifier: "layoutID", title: "Layout ID", width: 250)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = tableView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeSelectedRememberedLayouts(_:)))
        let clearButton = NSButton(title: "Clear All", target: self, action: #selector(clearRememberedLayouts(_:)))
        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeLayoutMemoryEditor(_:)))

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        let buttonRow = NSStackView(views: [removeButton, clearButton, spacer, closeButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        root.addArrangedSubview(scrollView)
        root.addArrangedSubview(statusLabel)
        root.addArrangedSubview(buttonRow)

        editorWindow.contentView?.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: editorWindow.contentView!.topAnchor),
            root.leadingAnchor.constraint(equalTo: editorWindow.contentView!.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: editorWindow.contentView!.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: editorWindow.contentView!.bottomAnchor),
            scrollView.widthAnchor.constraint(equalTo: root.widthAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 280),
            statusLabel.widthAnchor.constraint(equalTo: root.widthAnchor),
            buttonRow.widthAnchor.constraint(equalTo: root.widthAnchor)
        ])

        layoutMemoryWindow = editorWindow
        layoutMemoryTableView = tableView
        layoutMemoryStatusLabel = statusLabel
        reloadLayoutMemoryEditor()
        editorWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func addRuleColumn(to tableView: NSTableView, identifier: String, title: String, width: CGFloat) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(identifier))
        column.title = title
        column.width = width
        tableView.addTableColumn(column)
    }

    @objc private func addAutoCorrectionRule(_ sender: NSButton) {
        var rules = settingsManager.autoCorrectionRules
        rules.append(AutoCorrectionRule(trigger: "trigger", replacement: "replacement", matchMode: .exact, preserveCase: true))
        settingsManager.autoCorrectionRules = rules
        reloadRulesEditor()
        refreshRuleCount()
        if let row = filteredRuleIndexes.firstIndex(of: rules.count - 1) {
            rulesTableView?.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            rulesTableView?.editColumn(0, row: row, with: nil, select: true)
        }
    }

    @objc private func deleteSelectedAutoCorrectionRule(_ sender: NSButton) {
        guard let tableView = rulesTableView, tableView.selectedRow >= 0 else { return }
        var rules = settingsManager.autoCorrectionRules
        guard tableView.selectedRow < filteredRuleIndexes.count else { return }
        rules.remove(at: filteredRuleIndexes[tableView.selectedRow])
        settingsManager.autoCorrectionRules = rules
        reloadRulesEditor()
        refreshRuleCount()
    }

    @objc private func closeRulesEditor(_ sender: NSButton) {
        rulesWindow?.close()
    }

    @objc private func importAutoCorrectionRules(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json, .plainText, .commaSeparatedText, .tabSeparatedText]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            let result = try settingsManager.importAutoCorrectionRules(from: data, merge: true)
            reloadRulesEditor()
            refreshRuleCount()

            let alert = NSAlert()
            alert.messageText = "Imported \(result.rules.count) rules"
            alert.informativeText = result.skippedLines.isEmpty
                ? "Auto-correction rules were merged with existing rules."
                : "Skipped \(result.skippedLines.count) malformed lines."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.beginSheetModal(for: window ?? NSWindow())
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not import rules"
            alert.informativeText = "\(error)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.beginSheetModal(for: window ?? NSWindow())
        }
    }

    @objc private func exportAutoCorrectionRules(_ sender: NSButton) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "punto-auto-correction-rules.json"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try settingsManager.exportAutoCorrectionRules()
            try data.write(to: url, options: .atomic)

            let alert = NSAlert()
            alert.messageText = "Exported \(settingsManager.autoCorrectionRules.count) rules"
            alert.informativeText = "Auto-correction rules were written as JSON."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.beginSheetModal(for: rulesWindow ?? window ?? NSWindow())
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not export rules"
            alert.informativeText = "\(error)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.beginSheetModal(for: rulesWindow ?? window ?? NSWindow())
        }
    }

    private func refreshRuleCount() {
        guard let contentView = window?.contentView else { return }
        if let label = findView(withTag: 101, in: contentView) as? NSTextField {
            label.stringValue = "\(settingsManager.autoCorrectionRules.count)"
        }
    }

    private func refreshDisabledAppCount() {
        guard let contentView = window?.contentView else { return }
        if let label = findView(withTag: 102, in: contentView) as? NSTextField {
            label.stringValue = "\(settingsManager.disabledApplicationBundleIDs.count)"
        }
    }

    private func refreshResetOnReturnCount() {
        guard let contentView = window?.contentView else { return }
        if let label = findView(withTag: 103, in: contentView) as? NSTextField {
            label.stringValue = "\(settingsManager.resetOnReturnBundleComponents.count)"
        }
    }

    private func refreshLayoutMemoryCount() {
        guard let contentView = window?.contentView else { return }
        if let label = findView(withTag: 104, in: contentView) as? NSTextField {
            label.stringValue = "\(settingsManager.rememberedApplicationLayouts.count)"
        }
    }

    @objc private func addTelegramResetOnReturnComponent(_ sender: NSButton) {
        setResetOnReturnComponents(resetOnReturnBundleComponents + ["telegram"])
        if let row = resetOnReturnBundleComponents.firstIndex(of: "telegram") {
            resetOnReturnTableView?.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }

    @objc private func addResetOnReturnComponent(_ sender: NSButton) {
        let draft = uniqueDraftResetOnReturnComponent()
        setResetOnReturnComponents(resetOnReturnBundleComponents + [draft])
        guard let row = resetOnReturnBundleComponents.firstIndex(of: draft) else { return }
        resetOnReturnTableView?.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        resetOnReturnTableView?.editColumn(0, row: row, with: nil, select: true)
    }

    @objc private func removeSelectedResetOnReturnComponents(_ sender: NSButton) {
        guard let tableView = resetOnReturnTableView else { return }
        let selectedRows = tableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }

        var components = resetOnReturnBundleComponents
        for row in selectedRows.reversed() where row < components.count {
            components.remove(at: row)
        }
        setResetOnReturnComponents(components)
    }

    @objc private func closeResetOnReturnEditor(_ sender: NSButton) {
        resetOnReturnWindow?.close()
    }

    @objc private func removeSelectedRememberedLayouts(_ sender: NSButton) {
        guard let tableView = layoutMemoryTableView else { return }
        let selectedRows = tableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }

        var layouts = settingsManager.rememberedApplicationLayouts
        for row in selectedRows where row < rememberedLayoutRows.count {
            layouts.removeValue(forKey: rememberedLayoutRows[row].bundleID)
        }
        settingsManager.rememberedApplicationLayouts = layouts
        reloadLayoutMemoryEditor()
        refreshLayoutMemoryCount()
    }

    @objc private func clearRememberedLayouts(_ sender: NSButton) {
        settingsManager.rememberedApplicationLayouts = [:]
        reloadLayoutMemoryEditor()
        refreshLayoutMemoryCount()
    }

    @objc private func closeLayoutMemoryEditor(_ sender: NSButton) {
        layoutMemoryWindow?.close()
    }

    @objc private func addCurrentDisabledApplication(_ sender: NSButton) {
        guard let app = currentApplication(),
              app.bundleID != Bundle.main.bundleIdentifier else {
            NSSound.beep()
            return
        }

        settingsManager.setApplicationDisabled(bundleID: app.bundleID, disabled: true)
        reloadDisabledAppsEditor()
        refreshDisabledAppCount()

        if let row = disabledAppBundleIDs.firstIndex(of: app.bundleID) {
            disabledAppsTableView?.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }

    @objc private func removeSelectedDisabledApplications(_ sender: NSButton) {
        guard let tableView = disabledAppsTableView else { return }
        let selectedRows = tableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }

        for row in selectedRows.reversed() where row < disabledAppBundleIDs.count {
            settingsManager.setApplicationDisabled(bundleID: disabledAppBundleIDs[row], disabled: false)
        }

        reloadDisabledAppsEditor()
        refreshDisabledAppCount()
    }

    @objc private func closeDisabledAppsEditor(_ sender: NSButton) {
        disabledAppsWindow?.close()
    }

    private func reloadDisabledAppsEditor() {
        disabledAppBundleIDs = Array(settingsManager.disabledApplicationBundleIDs).sorted {
            disabledAppDisplayName(for: $0).localizedCaseInsensitiveCompare(disabledAppDisplayName(for: $1)) == .orderedAscending
        }
        disabledAppsTableView?.reloadData()
        disabledAppsStatusLabel?.stringValue = disabledAppBundleIDs.isEmpty
            ? "Punto is active in every application."
            : "\(disabledAppBundleIDs.count) disabled application\(disabledAppBundleIDs.count == 1 ? "" : "s")"
    }

    private func reloadResetOnReturnEditor() {
        resetOnReturnBundleComponents = Array(settingsManager.resetOnReturnBundleComponents).sorted()
        resetOnReturnTableView?.reloadData()
        resetOnReturnStatusLabel?.stringValue = resetOnReturnBundleComponents.isEmpty
            ? "Return-key text tracking reset is disabled for every app."
            : "\(resetOnReturnBundleComponents.count) bundle component\(resetOnReturnBundleComponents.count == 1 ? "" : "s")"
    }

    private func reloadLayoutMemoryEditor() {
        rememberedLayoutRows = settingsManager.rememberedApplicationLayouts
            .map { (bundleID: $0.key, layoutID: $0.value) }
            .sorted {
                disabledAppDisplayName(for: $0.bundleID).localizedCaseInsensitiveCompare(
                    disabledAppDisplayName(for: $1.bundleID)
                ) == .orderedAscending
            }
        layoutMemoryTableView?.reloadData()
        layoutMemoryStatusLabel?.stringValue = rememberedLayoutRows.isEmpty
            ? "No application-specific layouts are remembered."
            : "\(rememberedLayoutRows.count) remembered application layout\(rememberedLayoutRows.count == 1 ? "" : "s")"
    }

    private func setResetOnReturnComponents(_ components: [String]) {
        settingsManager.resetOnReturnBundleComponents = Set(components)
        reloadResetOnReturnEditor()
        refreshResetOnReturnCount()
    }

    private func uniqueDraftResetOnReturnComponent() -> String {
        let existing = Set(resetOnReturnBundleComponents)
        if !existing.contains("bundle") {
            return "bundle"
        }

        var suffix = 2
        while existing.contains("bundle\(suffix)") {
            suffix += 1
        }
        return "bundle\(suffix)"
    }

    private func disabledAppDisplayName(for bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
              let bundle = Bundle(url: url) else {
            return bundleID
        }

        return bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent
    }

    @objc private func filterAutoCorrectionRules(_ sender: NSSearchField) {
        reloadRulesEditor()
    }

    private func reloadRulesEditor() {
        let rules = settingsManager.autoCorrectionRules
        filteredRuleIndexes = AutoCorrectionRuleCatalog.filteredRuleIndexes(
            in: rules,
            query: rulesSearchField?.stringValue ?? ""
        )
        rulesTableView?.reloadData()
        updateRulesStatus()
    }

    private func updateRulesStatus() {
        let rules = settingsManager.autoCorrectionRules
        let issues = AutoCorrectionRuleCatalog.validationIssues(for: rules)
        let errors = issues.filter { $0.severity == .error }.count
        let warnings = issues.filter { $0.severity == .warning }.count

        var parts = ["\(filteredRuleIndexes.count)/\(rules.count) shown"]
        if errors > 0 { parts.append("\(errors) error\(errors == 1 ? "" : "s")") }
        if warnings > 0 { parts.append("\(warnings) warning\(warnings == 1 ? "" : "s")") }
        rulesStatusLabel?.stringValue = parts.joined(separator: "  -  ")

        if errors > 0 {
            rulesStatusLabel?.textColor = .systemRed
        } else if warnings > 0 {
            rulesStatusLabel?.textColor = .systemOrange
        } else {
            rulesStatusLabel?.textColor = .secondaryLabelColor
        }
    }

    private func validationMessage(forRuleAt index: Int) -> (AutoCorrectionRuleValidationIssue.Severity, String)? {
        let issues = AutoCorrectionRuleCatalog.validationIssues(for: settingsManager.autoCorrectionRules)
            .filter { $0.ruleIndex == index }
        if let error = issues.first(where: { $0.severity == .error }) {
            return (.error, error.message)
        }
        if let warning = issues.first(where: { $0.severity == .warning }) {
            return (.warning, warning.message)
        }
        return nil
    }

    private func findView(withTag tag: Int, in view: NSView) -> NSView? {
        if view.tag == tag { return view }
        for subview in view.subviews {
            if let found = findView(withTag: tag, in: subview) {
                return found
            }
        }
        return nil
    }
}

extension SettingsWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === rulesWindow {
            rulesWindow = nil
            rulesTableView = nil
            rulesSearchField = nil
            rulesStatusLabel = nil
            filteredRuleIndexes = []
        }
        if notification.object as? NSWindow === disabledAppsWindow {
            disabledAppsWindow = nil
            disabledAppsTableView = nil
            disabledAppsStatusLabel = nil
            disabledAppBundleIDs = []
        }
        if notification.object as? NSWindow === resetOnReturnWindow {
            resetOnReturnWindow = nil
            resetOnReturnTableView = nil
            resetOnReturnStatusLabel = nil
            resetOnReturnBundleComponents = []
        }
        if notification.object as? NSWindow === layoutMemoryWindow {
            layoutMemoryWindow = nil
            layoutMemoryTableView = nil
            layoutMemoryStatusLabel = nil
            rememberedLayoutRows = []
        }
    }
}

extension SettingsWindowController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView === disabledAppsTableView {
            return disabledAppBundleIDs.count
        }
        if tableView === resetOnReturnTableView {
            return resetOnReturnBundleComponents.count
        }
        if tableView === layoutMemoryTableView {
            return rememberedLayoutRows.count
        }
        return filteredRuleIndexes.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView === disabledAppsTableView {
            return disabledApplicationCell(tableColumn: tableColumn, row: row)
        }
        if tableView === resetOnReturnTableView {
            return resetOnReturnComponentCell(row: row)
        }
        if tableView === layoutMemoryTableView {
            return rememberedLayoutCell(tableColumn: tableColumn, row: row)
        }

        guard row < filteredRuleIndexes.count,
              let identifier = tableColumn?.identifier.rawValue else {
            return nil
        }

        let sourceIndex = filteredRuleIndexes[row]
        let rule = settingsManager.autoCorrectionRules[sourceIndex]
        let textField = NSTextField()
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.isEditable = true
        textField.delegate = self
        textField.tag = sourceIndex
        textField.identifier = NSUserInterfaceItemIdentifier(identifier)

        switch identifier {
        case "trigger":
            textField.stringValue = rule.trigger
        case "replacement":
            textField.stringValue = rule.replacement
        case "matchMode":
            textField.stringValue = rule.matchMode.rawValue
            textField.placeholderString = "exact"
        case "preserveCase":
            textField.stringValue = rule.preserveCase ? "true" : "false"
            textField.placeholderString = "true"
        default:
            return nil
        }

        if let (severity, message) = validationMessage(forRuleAt: sourceIndex) {
            textField.toolTip = message
            textField.textColor = severity == .error ? .systemRed : .systemOrange
        }

        return textField
    }

    private func disabledApplicationCell(tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < disabledAppBundleIDs.count,
              let identifier = tableColumn?.identifier.rawValue else {
            return nil
        }

        let bundleID = disabledAppBundleIDs[row]
        let textField = NSTextField()
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.isEditable = false

        switch identifier {
        case "appName":
            textField.stringValue = disabledAppDisplayName(for: bundleID)
        case "bundleID":
            textField.stringValue = bundleID
            textField.textColor = .secondaryLabelColor
        default:
            return nil
        }

        return textField
    }

    private func resetOnReturnComponentCell(row: Int) -> NSView? {
        guard row < resetOnReturnBundleComponents.count else { return nil }

        let textField = NSTextField()
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.isEditable = true
        textField.delegate = self
        textField.tag = row
        textField.identifier = NSUserInterfaceItemIdentifier("resetOnReturnComponent")
        textField.stringValue = resetOnReturnBundleComponents[row]
        textField.placeholderString = "telegram"
        return textField
    }

    private func rememberedLayoutCell(tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < rememberedLayoutRows.count,
              let identifier = tableColumn?.identifier.rawValue else {
            return nil
        }

        let rememberedLayout = rememberedLayoutRows[row]
        let textField = NSTextField()
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.isEditable = false

        switch identifier {
        case "layoutAppName":
            textField.stringValue = disabledAppDisplayName(for: rememberedLayout.bundleID)
        case "layoutBundleID":
            textField.stringValue = rememberedLayout.bundleID
            textField.textColor = .secondaryLabelColor
        case "layoutID":
            textField.stringValue = rememberedLayout.layoutID
            textField.textColor = .secondaryLabelColor
        default:
            return nil
        }

        return textField
    }
}

extension SettingsWindowController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
              let identifier = textField.identifier?.rawValue,
              textField.tag >= 0 else {
            return
        }

        if identifier == "resetOnReturnComponent" {
            guard textField.tag < resetOnReturnBundleComponents.count else { return }
            var components = resetOnReturnBundleComponents
            components[textField.tag] = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            setResetOnReturnComponents(components)
            return
        }

        var rules = settingsManager.autoCorrectionRules
        guard textField.tag < rules.count else { return }

        let old = rules[textField.tag]
        let value = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        let updated: AutoCorrectionRule
        switch identifier {
        case "trigger":
            updated = AutoCorrectionRule(
                trigger: value,
                replacement: old.replacement,
                matchMode: old.matchMode,
                preserveCase: old.preserveCase
            )
        case "replacement":
            updated = AutoCorrectionRule(
                trigger: old.trigger,
                replacement: value,
                matchMode: old.matchMode,
                preserveCase: old.preserveCase
            )
        case "matchMode":
            updated = AutoCorrectionRule(
                trigger: old.trigger,
                replacement: old.replacement,
                matchMode: AutoCorrectionRule.MatchMode(rawValue: value) ?? old.matchMode,
                preserveCase: old.preserveCase
            )
        case "preserveCase":
            updated = AutoCorrectionRule(
                trigger: old.trigger,
                replacement: old.replacement,
                matchMode: old.matchMode,
                preserveCase: ["true", "yes", "1", "on"].contains(value.lowercased())
            )
        default:
            return
        }

        rules[textField.tag] = updated
        settingsManager.autoCorrectionRules = rules
        reloadRulesEditor()
        refreshRuleCount()
    }
}
