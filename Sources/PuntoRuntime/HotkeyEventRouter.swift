import AppKit
import PuntoCore
import PuntoSettings

final class HotkeyEventRouter {
    private let settingsManager: SettingsManager
    private let onConvertLayout: () -> Void
    private let onToggleCase: () -> Void
    private let onToggleAutoCorrection: () -> Void
    private let onCancelLayoutChange: () -> Void
    private let onFindInYandex: () -> Void
    private let onFindInSlovari: () -> Void
    private let onSearchClick: () -> Void
    private let onClearTrackedText: (String) -> Void
    private let onKeyPress: (UInt16, String?) -> Void
    private let isCurrentApplicationDisabled: () -> Bool

    private let modifierOnlyStateMachine = ModifierOnlyHotkeyStateMachine()

    init(
        settingsManager: SettingsManager,
        onConvertLayout: @escaping () -> Void,
        onToggleCase: @escaping () -> Void,
        onToggleAutoCorrection: @escaping () -> Void,
        onCancelLayoutChange: @escaping () -> Void,
        onFindInYandex: @escaping () -> Void,
        onFindInSlovari: @escaping () -> Void,
        onSearchClick: @escaping () -> Void,
        onClearTrackedText: @escaping (String) -> Void,
        onKeyPress: @escaping (UInt16, String?) -> Void,
        isCurrentApplicationDisabled: @escaping () -> Bool
    ) {
        self.settingsManager = settingsManager
        self.onConvertLayout = onConvertLayout
        self.onToggleCase = onToggleCase
        self.onToggleAutoCorrection = onToggleAutoCorrection
        self.onCancelLayoutChange = onCancelLayoutChange
        self.onFindInYandex = onFindInYandex
        self.onFindInSlovari = onFindInSlovari
        self.onSearchClick = onSearchClick
        self.onClearTrackedText = onClearTrackedText
        self.onKeyPress = onKeyPress
        self.isCurrentApplicationDisabled = isCurrentApplicationDisabled
    }

    func route(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if let pointerResult = routePointerEventIfNeeded(type: type, event: event) {
            return pointerResult
        }

        let modifierFlags = modifierSnapshot(from: event.flags)

        if type == .flagsChanged {
            routeFlagsChanged(modifierFlags: modifierFlags)
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        return routeKeyDown(modifierFlags: modifierFlags, event: event)
    }

    private func routePointerEventIfNeeded(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch PointerEventPolicy.action(eventTypeRawValue: type.rawValue) {
        case .clearTrackedText(let reason):
            PuntoLog.info("Pointer event detected - will clear tracked text (\(reason))")
            let clickCount = Int(event.getIntegerValueField(.mouseEventClickState))
            let shouldSearchClick = SearchClickPolicy.shouldScheduleSelectedTextSearchAfterClick(
                eventTypeRawValue: type.rawValue,
                clickCount: clickCount,
                shouldSearchByDoubleClick: settingsManager.searchSelectedTextByDoubleClick
            )
            DispatchQueue.main.async { [weak self] in
                self?.onClearTrackedText(reason)
            }
            if shouldSearchClick {
                PuntoLog.info("Search click triggered after left double click")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.onSearchClick()
                }
            }
            return Unmanaged.passUnretained(event)

        case .ignore:
            return nil
        }
    }

    private func routeFlagsChanged(modifierFlags: ModifierFlagsSnapshot) {
        let convertHotkey = settingsManager.convertLayoutHotkey

        guard modifierOnlyStateMachine.handleFlagsChanged(flags: modifierFlags, hotkey: convertHotkey) else {
            return
        }

        switch HotkeyRoutingPolicy.action(
            kind: .modifierOnlyConvertLayout,
            isEnabled: settingsManager.isEnabled,
            isCurrentApplicationDisabled: isCurrentApplicationDisabled(),
            displayString: convertHotkey.displayString
        ) {
        case .passThrough(let logMessage):
            PuntoLog.info(logMessage)
        case .handle(let logMessage):
            PuntoLog.info(logMessage)
            DispatchQueue.main.asyncAfter(deadline: .now() + ModifierOnlyHotkeyStateMachine.actionDelay) { [weak self] in
                self?.onConvertLayout()
            }
        }
    }

    private func routeKeyDown(modifierFlags: ModifierFlagsSnapshot, event: CGEvent) -> Unmanaged<CGEvent>? {
        modifierOnlyStateMachine.cancelPendingModifierOnlyChord()

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

        switch KeyDownEventPolicy.action(
            keyCode: keyCode,
            flags: modifierFlags,
            hotkeyAssignments: settingsManager.hotkeyAssignments
        ) {
        case .convertLayoutHotkey:
            return routeKeyBasedHotkey(kind: .convertLayout, keyCode: keyCode, event: event) { [weak self] in
                self?.onConvertLayout()
            }

        case .toggleCaseHotkey:
            return routeKeyBasedHotkey(kind: .toggleCase, keyCode: keyCode, event: event) { [weak self] in
                self?.onToggleCase()
            }

        case .toggleAutoCorrectionHotkey:
            return routeKeyBasedHotkey(kind: .toggleAutoCorrection, keyCode: keyCode, event: event) { [weak self] in
                self?.onToggleAutoCorrection()
            }

        case .cancelLayoutChangeHotkey:
            return routeKeyBasedHotkey(kind: .cancelLayoutChange, keyCode: keyCode, event: event) { [weak self] in
                self?.onCancelLayoutChange()
            }

        case .findInYandexHotkey:
            return routeKeyBasedHotkey(kind: .findInYandex, keyCode: keyCode, event: event) { [weak self] in
                self?.onFindInYandex()
            }

        case .findInSlovariHotkey:
            return routeKeyBasedHotkey(kind: .findInSlovari, keyCode: keyCode, event: event) { [weak self] in
                self?.onFindInSlovari()
            }

        case .clearTrackedText(let reason):
            PuntoLog.info("\(Self.clearTrackedTextLabel(for: reason)) detected - will clear WordTracker (\(reason))")
            DispatchQueue.main.async { [weak self] in
                self?.onClearTrackedText(reason)
            }
            return Unmanaged.passUnretained(event)

        case .trackKeyPress:
            let characters = getCharacters(from: event)
            PuntoLog.info("KeyDown: keyCode=\(keyCode), chars='\(characters ?? "nil")'")
            DispatchQueue.main.async { [weak self] in
                self?.onKeyPress(keyCode, characters)
            }

        case .ignore:
            break
        }

        return Unmanaged.passUnretained(event)
    }

    private func routeKeyBasedHotkey(
        kind: HotkeyRoutingKind,
        keyCode: UInt16,
        event: CGEvent,
        action: @escaping () -> Void
    ) -> Unmanaged<CGEvent>? {
        switch HotkeyRoutingPolicy.action(
            kind: kind,
            isEnabled: settingsManager.isEnabled,
            isCurrentApplicationDisabled: isCurrentApplicationDisabled(),
            keyCode: keyCode
        ) {
        case .passThrough(let logMessage):
            PuntoLog.info(logMessage)
            return Unmanaged.passUnretained(event)
        case .handle(let logMessage):
            PuntoLog.info(logMessage)
            scheduleKeyBasedHotkeyAction(action)
            return nil
        }
    }

    private func scheduleKeyBasedHotkeyAction(_ action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + KeyDownEventPolicy.keyBasedHotkeyActionDelay) {
            action()
        }
    }

    private func modifierSnapshot(from flags: CGEventFlags) -> ModifierFlagsSnapshot {
        ModifierFlagsSnapshot(
            command: flags.contains(.maskCommand),
            option: flags.contains(.maskAlternate),
            shift: flags.contains(.maskShift),
            control: flags.contains(.maskControl)
        )
    }

    private func getCharacters(from event: CGEvent) -> String? {
        var length = 0
        event.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)

        guard length > 0 else { return nil }

        var chars = [UniChar](repeating: 0, count: length)
        event.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &chars)

        return String(utf16CodeUnits: chars, count: length)
    }

    private static func clearTrackedTextLabel(for reason: String) -> String {
        switch reason {
        case "paste":
            return "Cmd+V"
        case "copy":
            return "Cmd+C"
        case "undo":
            return "Cmd+Z"
        case "cut":
            return "Cmd+X"
        case "selection":
            return "Cmd+A"
        case "modified deletion":
            return "modified deletion"
        case "modified navigation":
            return "modified navigation"
        case "modified shortcut":
            return "modified shortcut"
        default:
            return reason
        }
    }
}
