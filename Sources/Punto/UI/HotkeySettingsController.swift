import AppKit
import PuntoCore
import PuntoSettings

final class HotkeySettingsController: NSObject {
    private let settingsManager: SettingsManager
    private var recorders: [HotkeySlot: HotkeyRecorderView] = [:]

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }

    func createView() -> NSView {
        let section = SettingsSectionFactory.createSection(title: "Keyboard Shortcuts", iconName: "keyboard")

        let grid = NSGridView(numberOfColumns: 3, rows: 0)
        grid.rowSpacing = 10
        grid.columnSpacing = 12
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.column(at: 0).xPlacement = .leading
        grid.column(at: 1).xPlacement = .fill
        grid.column(at: 2).xPlacement = .trailing

        for command in HotkeyCommandPolicy.displayOrder {
            addHotkeyRow(to: grid, command: command)
        }

        section.contentStack.addArrangedSubview(grid)
        return section.container
    }

    private func addHotkeyRow(
        to grid: NSGridView,
        command: HotkeyCommandMetadata
    ) {
        let recorder = HotkeyRecorderView(
            hotkey: savedHotkey(for: command.slot),
            onRecord: { [weak self] hotkey in
                self?.recordHotkey(hotkey, for: command.slot)
            }
        )
        setRecorder(recorder, for: command.slot)
        grid.addRow(with: [
            SettingsSectionFactory.createIconLabel(command.title, systemName: command.systemName),
            recorder,
            createResetButton(tag: command.resetTag)
        ])
    }

    private var hotkeyAssignments: [HotkeyAssignment] {
        settingsManager.hotkeyAssignments
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
        settingsManager.hotkey(for: slot)
    }

    private func defaultHotkey(for slot: HotkeySlot) -> Hotkey {
        HotkeyCommandPolicy.defaultHotkey(for: slot)
    }

    private func setHotkey(_ hotkey: Hotkey, for slot: HotkeySlot) {
        settingsManager.setHotkey(hotkey, for: slot)
    }

    private func recorder(for slot: HotkeySlot) -> HotkeyRecorderView? {
        recorders[slot]
    }

    private func setRecorder(_ recorder: HotkeyRecorderView, for slot: HotkeySlot) {
        recorders[slot] = recorder
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

    @objc private func resetHotkey(_ sender: NSButton) {
        guard let slot = slot(forTag: sender.tag) else {
            return
        }
        settingsManager.resetHotkey(for: slot)
        recorder(for: slot)?.updateHotkey(savedHotkey(for: slot))
    }

    private func slot(forTag tag: Int) -> HotkeySlot? {
        HotkeyCommandPolicy.slot(forResetTag: tag)
    }
}
