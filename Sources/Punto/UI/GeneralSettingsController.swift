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
        let englishSourceRow = createPreferredInputSourceIDRow(
            title: "English layout ID",
            sourceID: settingsManager.preferredEnglishInputSourceID,
            systemName: "keyboard",
            fieldAction: #selector(changePreferredEnglishInputSourceID(_:)),
            resetAction: #selector(resetPreferredEnglishInputSourceID(_:))
        )
        preferredEnglishInputSourceIDField = englishSourceRow.field
        advancedStack.addArrangedSubview(englishSourceRow.row)

        let russianSourceRow = createPreferredInputSourceIDRow(
            title: "Russian layout ID",
            sourceID: settingsManager.preferredRussianInputSourceID,
            systemName: "keyboard.onehanded.right",
            fieldAction: #selector(changePreferredRussianInputSourceID(_:)),
            resetAction: #selector(resetPreferredRussianInputSourceID(_:))
        )
        preferredRussianInputSourceIDField = russianSourceRow.field
        advancedStack.addArrangedSubview(russianSourceRow.row)
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
        SettingsRowFactory.toggleRow(
            metadata: metadata,
            isOn: settingsManager.bool(for: metadata.slot),
            target: self,
            action: #selector(toggleSetting(_:))
        )
    }

    private func createSoundResourceTogglesGrid() -> NSView {
        let grid = NSGridView(numberOfColumns: 2, rows: 0)
        grid.rowSpacing = 4
        grid.columnSpacing = 18
        grid.translatesAutoresizingMaskIntoConstraints = false

        for row in SoundFeedbackPolicy.displayRows {
            grid.addRow(with: row.map { item in
                SettingsRowFactory.checkbox(
                    title: item.title,
                    identifier: item.resourceName,
                    isOn: settingsManager.isSoundResourceEnabled(item.resourceName),
                    target: self,
                    action: #selector(toggleSoundResource(_:))
                )
            })
        }

        return SettingsRowFactory.labeledGridRow(title: "Sound events", grid: grid)
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
                SettingsRowFactory.checkbox(
                    title: item.title,
                    identifier: item.name,
                    isOn: settingsManager.isAutoCorrectionCancellingKeyEnabled(item.name),
                    target: self,
                    action: #selector(toggleAutoCorrectionCancellingKey(_:))
                )
            })
        }

        return SettingsRowFactory.labeledGridRow(title: "Cancel auto-correction after", grid: grid)
    }

    private func createRussianKeyboardLayoutTypeRow() -> NSView {
        SettingsRowFactory.russianKeyboardLayoutTypeRow(
            selectedType: settingsManager.russianKeyboardLayoutType,
            target: self,
            action: #selector(changeRussianKeyboardLayoutType(_:))
        )
    }

    private func createPreferredInputSourceIDRow(
        title: String,
        sourceID: String?,
        systemName: String,
        fieldAction: Selector,
        resetAction: Selector
    ) -> SettingsRowFactory.PreferredInputSourceIDRow {
        SettingsRowFactory.preferredInputSourceIDRow(
            title: title,
            sourceID: sourceID,
            systemName: systemName,
            target: self,
            fieldAction: fieldAction,
            resetAction: resetAction
        )
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
        SettingsRowFactory.countLabel(text: text)
    }

    private func createManagedCountRow(
        title: String,
        systemName: String,
        countLabel: NSTextField,
        buttons: [NSButton]
    ) -> NSView {
        SettingsRowFactory.managedCountRow(
            title: title,
            systemName: systemName,
            countLabel: countLabel,
            buttons: buttons
        )
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
