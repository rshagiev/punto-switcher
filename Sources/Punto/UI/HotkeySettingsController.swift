import AppKit
import PuntoCore
import PuntoSettings

final class HotkeySettingsController: NSObject {
    private let settingsManager: SettingsManager
    private var convertLayoutRecorder: HotkeyRecorderView?
    private var toggleCaseRecorder: HotkeyRecorderView?
    private var toggleAutoCorrectionRecorder: HotkeyRecorderView?
    private var cancelLayoutChangeRecorder: HotkeyRecorderView?
    private var findInYandexRecorder: HotkeyRecorderView?
    private var findInSlovariRecorder: HotkeyRecorderView?

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

        addHotkeyRow(
            to: grid,
            slot: .convertLayout,
            title: "Convert Layout",
            systemName: "textformat.abc",
            tag: 0
        )
        addHotkeyRow(
            to: grid,
            slot: .toggleCase,
            title: "Toggle Case",
            systemName: "textformat",
            tag: 1
        )
        addHotkeyRow(
            to: grid,
            slot: .toggleAutoCorrection,
            title: "Toggle Auto-correction",
            systemName: "wand.and.stars",
            tag: 2
        )
        addHotkeyRow(
            to: grid,
            slot: .cancelLayoutChange,
            title: "Cancel Last Conversion",
            systemName: "arrow.uturn.backward",
            tag: 3
        )
        addHotkeyRow(
            to: grid,
            slot: .findInYandex,
            title: "Find in Yandex",
            systemName: "magnifyingglass",
            tag: 4
        )
        addHotkeyRow(
            to: grid,
            slot: .findInSlovari,
            title: "Find in Translate",
            systemName: "character.book.closed",
            tag: 5
        )

        section.contentStack.addArrangedSubview(grid)
        return section.container
    }

    private func addHotkeyRow(
        to grid: NSGridView,
        slot: HotkeySlot,
        title: String,
        systemName: String,
        tag: Int
    ) {
        let recorder = HotkeyRecorderView(
            hotkey: savedHotkey(for: slot),
            onRecord: { [weak self] hotkey in
                self?.recordHotkey(hotkey, for: slot)
            }
        )
        setRecorder(recorder, for: slot)
        grid.addRow(with: [
            SettingsSectionFactory.createIconLabel(title, systemName: systemName),
            recorder,
            createResetButton(tag: tag)
        ])
    }

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

    private func setRecorder(_ recorder: HotkeyRecorderView, for slot: HotkeySlot) {
        switch slot {
        case .convertLayout:
            convertLayoutRecorder = recorder
        case .toggleCase:
            toggleCaseRecorder = recorder
        case .toggleAutoCorrection:
            toggleAutoCorrectionRecorder = recorder
        case .cancelLayoutChange:
            cancelLayoutChangeRecorder = recorder
        case .findInYandex:
            findInYandexRecorder = recorder
        case .findInSlovari:
            findInSlovariRecorder = recorder
        }
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
        setHotkey(defaultHotkey(for: slot), for: slot)
        recorder(for: slot)?.updateHotkey(savedHotkey(for: slot))
    }

    private func slot(forTag tag: Int) -> HotkeySlot? {
        switch tag {
        case 0:
            return .convertLayout
        case 1:
            return .toggleCase
        case 2:
            return .toggleAutoCorrection
        case 3:
            return .cancelLayoutChange
        case 4:
            return .findInYandex
        case 5:
            return .findInSlovari
        default:
            return nil
        }
    }
}
