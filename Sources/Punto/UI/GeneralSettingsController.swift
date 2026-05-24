import AppKit
import PuntoCore
import PuntoSettings

final class GeneralSettingsController: NSObject {
    private let settingsManager: SettingsManager
    private let setLoginItemEnabled: (Bool) -> Void
    private let showAutoCorrectionRulesEditor: () -> Void
    private let importAutoCorrectionRules: () -> Void
    private let showDisabledAppsEditor: () -> Void
    private let showResetOnReturnEditor: () -> Void
    private let showLayoutMemoryEditor: () -> Void

    private weak var advancedSettingsStack: NSStackView?
    private weak var preferredEnglishInputSourceIDField: NSTextField?
    private weak var preferredRussianInputSourceIDField: NSTextField?
    private weak var ruleCountLabel: NSTextField?
    private weak var disabledAppCountLabel: NSTextField?
    private weak var resetOnReturnCountLabel: NSTextField?
    private weak var layoutMemoryCountLabel: NSTextField?

    init(
        settingsManager: SettingsManager,
        setLoginItemEnabled: @escaping (Bool) -> Void,
        showAutoCorrectionRulesEditor: @escaping () -> Void,
        importAutoCorrectionRules: @escaping () -> Void,
        showDisabledAppsEditor: @escaping () -> Void,
        showResetOnReturnEditor: @escaping () -> Void,
        showLayoutMemoryEditor: @escaping () -> Void
    ) {
        self.settingsManager = settingsManager
        self.setLoginItemEnabled = setLoginItemEnabled
        self.showAutoCorrectionRulesEditor = showAutoCorrectionRulesEditor
        self.importAutoCorrectionRules = importAutoCorrectionRules
        self.showDisabledAppsEditor = showDisabledAppsEditor
        self.showResetOnReturnEditor = showResetOnReturnEditor
        self.showLayoutMemoryEditor = showLayoutMemoryEditor
    }

    func createView() -> NSView {
        let section = SettingsSectionFactory.createSection(title: "General", iconName: "slider.horizontal.3")

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

    func refreshRuleCount() {
        ruleCountLabel?.stringValue = "\(settingsManager.autoCorrectionRules.count)"
    }

    func refreshDisabledAppCount() {
        disabledAppCountLabel?.stringValue = "\(settingsManager.disabledApplicationBundleIDs.count)"
    }

    func refreshResetOnReturnCount() {
        resetOnReturnCountLabel?.stringValue = "\(settingsManager.resetOnReturnBundleComponents.count)"
    }

    func refreshLayoutMemoryCount() {
        layoutMemoryCountLabel?.stringValue = "\(settingsManager.rememberedApplicationLayouts.count)"
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

        return createLabeledGridRow(title: "Sound events", grid: grid)
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

        return createLabeledGridRow(title: "Cancel auto-correction after", grid: grid)
    }

    private func createLabeledGridRow(title: String, grid: NSView) -> NSView {
        let label = NSTextField(labelWithString: title)
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
        let countLabel = countLabel(text: "\(settingsManager.disabledApplicationBundleIDs.count)")
        disabledAppCountLabel = countLabel
        return createManagedCountRow(
            title: "Disabled applications",
            systemName: "nosign.app",
            countLabel: countLabel,
            buttons: [NSButton(title: "Manage...", target: self, action: #selector(showDisabledAppsEditor(_:)))]
        )
    }

    private func createResetOnReturnRow() -> NSView {
        let countLabel = countLabel(text: "\(settingsManager.resetOnReturnBundleComponents.count)")
        resetOnReturnCountLabel = countLabel
        return createManagedCountRow(
            title: "Return reset apps",
            systemName: "return",
            countLabel: countLabel,
            buttons: [NSButton(title: "Manage...", target: self, action: #selector(showResetOnReturnEditor(_:)))]
        )
    }

    private func createRememberedLayoutsRow() -> NSView {
        let countLabel = countLabel(text: "\(settingsManager.rememberedApplicationLayouts.count)")
        layoutMemoryCountLabel = countLabel
        return createManagedCountRow(
            title: "Remembered app layouts",
            systemName: "keyboard.badge.eye",
            countLabel: countLabel,
            buttons: [NSButton(title: "Manage...", target: self, action: #selector(showLayoutMemoryEditor(_:)))]
        )
    }

    private func createImportRulesRow() -> NSView {
        let countLabel = countLabel(text: "\(settingsManager.autoCorrectionRules.count)")
        ruleCountLabel = countLabel
        return createManagedCountRow(
            title: "Auto-correction rules",
            systemName: "square.and.arrow.down",
            countLabel: countLabel,
            buttons: [
                NSButton(title: "Edit...", target: self, action: #selector(showAutoCorrectionRulesEditor(_:))),
                NSButton(title: "Import...", target: self, action: #selector(importAutoCorrectionRules(_:)))
            ]
        )
    }

    private func countLabel(text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func createManagedCountRow(
        title: String,
        systemName: String,
        countLabel: NSTextField,
        buttons: [NSButton]
    ) -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor

        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor

        for button in buttons {
            button.bezelStyle = .rounded
            button.setContentHuggingPriority(.required, for: .horizontal)
        }

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [icon, label, countLabel, spacer] + buttons)
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return row
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSSwitch) {
        let isEnabled = sender.state == .on
        settingsManager.launchAtLogin = isEnabled
        setLoginItemEnabled(isEnabled)
    }

    @objc private func toggleShowInMenuBar(_ sender: NSSwitch) {
        settingsManager.showInMenuBar = sender.state == .on
    }

    @objc private func toggleShowAdvancedSettings(_ sender: NSSwitch) {
        let isVisible = sender.state == .on
        settingsManager.showAdvancedSettings = isVisible
        advancedSettingsStack?.isHidden = !isVisible
        advancedSettingsStack?.window?.layoutIfNeeded()
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
        showAutoCorrectionRulesEditor()
    }

    @objc private func showDisabledAppsEditor(_ sender: NSButton) {
        showDisabledAppsEditor()
    }

    @objc private func showResetOnReturnEditor(_ sender: NSButton) {
        showResetOnReturnEditor()
    }

    @objc private func showLayoutMemoryEditor(_ sender: NSButton) {
        showLayoutMemoryEditor()
    }

    @objc private func importAutoCorrectionRules(_ sender: NSButton) {
        importAutoCorrectionRules()
    }
}
