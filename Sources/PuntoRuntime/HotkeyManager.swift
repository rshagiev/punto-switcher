import AppKit
import Carbon.HIToolbox
import PuntoCore
import PuntoSettings

/// Manages global hotkeys using CGEvent Tap
public final class HotkeyManager {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private let settingsManager: SettingsManager
    private let onConvertLayout: () -> Void
    private let onToggleCase: () -> Void
    private let onToggleAutoCorrection: () -> Void
    private let onCancelLayoutChange: () -> Void
    private let onFindInYandex: () -> Void
    private let onFindInSlovari: () -> Void
    private let onSearchClick: () -> Void
    private let canDoSearchClick: () -> Bool
    private let onClearTrackedText: (String) -> Void
    private let onKeyPress: (UInt16, String?) -> Void
    private let isCurrentApplicationDisabled: () -> Bool

    private var isRunning = false

    // Thread-safe flag to ignore events during text replacement
    private let stateQueue = DispatchQueue(label: "com.punto.hotkeymanager.state")
    private var _ignoreEvents = false
    public var ignoreEvents: Bool {
        get { stateQueue.sync { _ignoreEvents } }
        set {
            stateQueue.sync {
                if _ignoreEvents != newValue {
                    PuntoLog.info("ignoreEvents: \(_ignoreEvents) → \(newValue)")
                }
                _ignoreEvents = newValue
            }
        }
    }

    // Track modifier state for modifier-only hotkeys (accessed from event tap thread)
    private let modifierOnlyStateMachine = ModifierOnlyHotkeyStateMachine()

    public init(
        settingsManager: SettingsManager,
        onConvertLayout: @escaping () -> Void,
        onToggleCase: @escaping () -> Void,
        onToggleAutoCorrection: @escaping () -> Void,
        onCancelLayoutChange: @escaping () -> Void,
        onFindInYandex: @escaping () -> Void,
        onFindInSlovari: @escaping () -> Void,
        onSearchClick: @escaping () -> Void,
        canDoSearchClick: @escaping () -> Bool,
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
        self.canDoSearchClick = canDoSearchClick
        self.onClearTrackedText = onClearTrackedText
        self.onKeyPress = onKeyPress
        self.isCurrentApplicationDisabled = isCurrentApplicationDisabled
    }

    deinit {
        stop()
    }

    // MARK: - Start/Stop

    public func start() {
        guard !isRunning else {
            PuntoLog.info("HotkeyManager already running")
            return
        }

        // Create event tap for keyboard shortcuts and pointer clicks that invalidate typed-tail state.
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
            | (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)
            | (1 << CGEventType.otherMouseDown.rawValue)

        // Create the event tap
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }

                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            PuntoLog.error("Failed to create event tap!")
            PuntoLog.error("Make sure Accessibility permissions are granted")
            return
        }

        eventTap = tap
        PuntoLog.info("Event tap created successfully")

        // Create run loop source and add to main run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)

        // Enable the tap
        CGEvent.tapEnable(tap: tap, enable: true)

        isRunning = true
        PuntoLog.info("HotkeyManager started")
        PuntoLog.info("Convert hotkey: \(settingsManager.convertLayoutHotkey.displayString) (keyCode: \(settingsManager.convertLayoutHotkey.keyCode))")
        PuntoLog.info("Toggle case hotkey: \(settingsManager.toggleCaseHotkey.displayString) (keyCode: \(settingsManager.toggleCaseHotkey.keyCode))")
        PuntoLog.info("Toggle auto-correction hotkey: \(settingsManager.toggleAutoCorrectionHotkey.displayString) (keyCode: \(settingsManager.toggleAutoCorrectionHotkey.keyCode))")
        PuntoLog.info("Cancel layout change hotkey: \(settingsManager.cancelLayoutChangeHotkey.displayString) (keyCode: \(settingsManager.cancelLayoutChangeHotkey.keyCode))")
        PuntoLog.info("Find in Yandex hotkey: \(settingsManager.findInYandexHotkey.displayString) (keyCode: \(settingsManager.findInYandexHotkey.keyCode))")
        PuntoLog.info("Find in Slovari hotkey: \(settingsManager.findInSlovariHotkey.displayString) (keyCode: \(settingsManager.findInSlovariHotkey.keyCode))")
    }

    public func stop() {
        guard isRunning else { return }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isRunning = false
        PuntoLog.info("HotkeyManager stopped")
    }

    // MARK: - Event Handling

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Ignore events during text replacement to prevent re-capture
        if ignoreEvents {
            // Log all keyDown events during ignore mode for debugging
            if type == .keyDown {
                let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                PuntoLog.debug("Skipping keyCode=\(keyCode) (ignoreEvents=true)")
            }
            return Unmanaged.passUnretained(event)
        }

        // Don't intercept hotkeys when our settings window is active (for hotkey recording)
        // Check by window class instead of title for localization safety
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           frontApp.bundleIdentifier == Bundle.main.bundleIdentifier,
           NSApp.keyWindow != nil,
           NSApp.keyWindow != NSApp.mainWindow {
            // Our app is frontmost with a key window - likely settings
            return Unmanaged.passUnretained(event)
        }

        switch EventTapLifecyclePolicy.action(
            isDisabledByTimeout: type == .tapDisabledByTimeout,
            isDisabledByUserInput: type == .tapDisabledByUserInput
        ) {
        case .reenableTap(let reason):
            PuntoLog.info("Event tap was disabled, re-enabling (\(reason))")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        case .ignore:
            break
        }

        switch PointerEventPolicy.action(eventTypeRawValue: type.rawValue) {
        case .clearTrackedText(let reason):
            PuntoLog.info("Pointer event detected - will clear tracked text (\(reason))")
            let clickCount = Int(event.getIntegerValueField(.mouseEventClickState))
            let shouldSearchByDoubleClick = settingsManager.searchSelectedTextByDoubleClick
            let shouldCheckSearchCapability = type.rawValue == PointerEventPolicy.leftMouseDownRawValue
                && clickCount >= 2
                && shouldSearchByDoubleClick
            let shouldSearchClick = SearchClickPolicy.shouldSearchSelectedTextAfterClick(
                eventTypeRawValue: type.rawValue,
                clickCount: clickCount,
                shouldSearchByDoubleClick: shouldSearchByDoubleClick,
                canDoSearchClick: shouldCheckSearchCapability && canDoSearchClick()
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
            break
        }

        let flags = event.flags
        let hasCmd = flags.contains(.maskCommand)
        let hasOpt = flags.contains(.maskAlternate)
        let hasShift = flags.contains(.maskShift)
        let hasControl = flags.contains(.maskControl)
        let modifierFlags = ModifierFlagsSnapshot(
            command: hasCmd,
            option: hasOpt,
            shift: hasShift,
            control: hasControl
        )

        // Handle flagsChanged for modifier-only hotkeys
        if type == .flagsChanged {
            let convertHotkey = settingsManager.convertLayoutHotkey

            if modifierOnlyStateMachine.handleFlagsChanged(flags: modifierFlags, hotkey: convertHotkey) {
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

            return Unmanaged.passUnretained(event)
        }

        // Process keyDown events
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        // Any key press cancels modifier-only hotkey detection
        // This prevents Cmd+V from triggering the hotkey
        modifierOnlyStateMachine.cancelPendingModifierOnlyChord()

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

        switch KeyDownEventPolicy.action(
            keyCode: keyCode,
            flags: modifierFlags,
            convertHotkey: settingsManager.convertLayoutHotkey,
            toggleCaseHotkey: settingsManager.toggleCaseHotkey,
            toggleAutoCorrectionHotkey: settingsManager.toggleAutoCorrectionHotkey,
            cancelLayoutChangeHotkey: settingsManager.cancelLayoutChangeHotkey,
            findInYandexHotkey: settingsManager.findInYandexHotkey,
            findInSlovariHotkey: settingsManager.findInSlovariHotkey
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

    private func getCharacters(from event: CGEvent) -> String? {
        var length = 0
        event.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)

        guard length > 0 else { return nil }

        var chars = [UniChar](repeating: 0, count: length)
        event.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &chars)

        return String(utf16CodeUnits: chars, count: length)
    }

    private func scheduleKeyBasedHotkeyAction(_ action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + KeyDownEventPolicy.keyBasedHotkeyActionDelay) {
            action()
        }
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
