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
    private let onToggleChanged: (SettingsToggleChangeAction) -> Void

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
        showLayoutMemoryEditor: @escaping () -> Void,
        onToggleChanged: @escaping (SettingsToggleChangeAction) -> Void = { _ in }
    ) {
        self.settingsManager = settingsManager
        self.setLoginItemEnabled = setLoginItemEnabled
        self.showAutoCorrectionRulesEditor = showAutoCorrectionRulesEditor
        self.importAutoCorrectionRules = importAutoCorrectionRules
        self.showDisabledAppsEditor = showDisabledAppsEditor
        self.showResetOnReturnEditor = showResetOnReturnEditor
        self.showLayoutMemoryEditor = showLayoutMemoryEditor
        self.onToggleChanged = onToggleChanged
    }

    func createView() -> NSView {
        let section = SettingsSectionFactory.createSection(title: "General", iconName: "slider.horizontal.3")

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10

        for toggle in SettingsTogglePolicy.basicDisplayOrder {
            stack.addArrangedSubview(createToggleRow(toggle))
        }

        let advancedStack = NSStackView()
        advancedStack.orientation = .vertical
        advancedStack.alignment = .leading
        advancedStack.spacing = 10
        advancedStack.isHidden = !settingsManager.showAdvancedSettings
        self.advancedSettingsStack = advancedStack

        addAdvancedTogglesBeforeInputSourceRows(to: advancedStack)
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
        addAdvancedTogglesAfterInputSourceRows(to: advancedStack)
        advancedStack.addArrangedSubview(createCancellingKeyTogglesGrid())
        advancedStack.addArrangedSubview(createSoundResourceTogglesGrid())
        advancedStack.addArrangedSubview(createImportRulesRow())
        advancedStack.addArrangedSubview(createRememberedLayoutsRow())
        advancedStack.addArrangedSubview(createResetOnReturnRow())
        addAdvancedExceptionAppToggles(to: advancedStack)
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

    private func addAdvancedTogglesBeforeInputSourceRows(to stack: NSStackView) {
        addAdvancedToggleRows(
            [.switchLayoutAfterSelectedTextConversion, .searchSelectedTextByDoubleClick],
            to: stack
        )
    }

    private func addAdvancedTogglesAfterInputSourceRows(to stack: NSStackView) {
        addAdvancedToggleRows(
            [
                .manualConversionDisabled,
                .rememberInputSourceForEachApp,
                .autoCorrectOnEnterAndTab,
                .autoCorrectionUndoLearningEnabled,
                .suppressAutoCorrectionAfterManualConversion
            ],
            to: stack
        )
    }

    private func addAdvancedExceptionAppToggles(to stack: NSStackView) {
        addAdvancedToggleRows([.completelyDisableInExceptionApplications], to: stack)
    }

    private func addAdvancedToggleRows(_ slots: [SettingsToggleSlot], to stack: NSStackView) {
        for slot in slots {
            guard let toggle = SettingsTogglePolicy.metadata(for: slot) else {
                continue
            }
            stack.addArrangedSubview(createToggleRow(toggle))
        }
    }

    private func createToggleRow(_ metadata: SettingsToggleMetadata) -> NSView {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: metadata.systemName, accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor

        let label = NSTextField(labelWithString: metadata.title)
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor

        let toggle = NSSwitch()
        toggle.state = settingsManager.bool(for: metadata.slot) ? .on : .off
        toggle.identifier = NSUserInterfaceItemIdentifier(metadata.slot.rawValue)
        toggle.target = self
        toggle.action = #selector(toggleSetting(_:))

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
        let grid = NSGridView(numberOfColumns: 2, rows: 0)
        grid.rowSpacing = 4
        grid.columnSpacing = 18
        grid.translatesAutoresizingMaskIntoConstraints = false

        for row in SoundFeedbackPolicy.displayRows {
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

    @objc private func toggleSetting(_ sender: NSSwitch) {
        guard
            let rawSlot = sender.identifier?.rawValue,
            let slot = SettingsToggleSlot(rawValue: rawSlot)
        else {
            return
        }

        let wasEnabled = settingsManager.bool(for: slot)
        let isEnabled = sender.state == .on
        guard let action = SettingsTogglePolicy.changeAction(
            slot: slot,
            wasEnabled: wasEnabled,
            isEnabled: isEnabled
        ) else {
            return
        }

        settingsManager.setBool(isEnabled, for: slot)

        for effect in action.effects {
            switch effect {
            case let .setLoginItemEnabled(isEnabled):
                setLoginItemEnabled(isEnabled)
            case let .updateAdvancedSettingsVisibility(isEnabled):
                advancedSettingsStack?.isHidden = !isEnabled
                advancedSettingsStack?.window?.layoutIfNeeded()
            case .updateStatusBarVisibility,
                 .applyAutoCorrectionRuntimeChange,
                 .refreshCurrentApplicationState:
                break
            }
        }

        onToggleChanged(action)
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

    @objc private func toggleAutoCorrectionCancellingKey(_ sender: NSButton) {
        guard let keyName = sender.identifier?.rawValue else {
            return
        }
        settingsManager.setAutoCorrectionCancellingKey(keyName, enabled: sender.state == .on)
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
