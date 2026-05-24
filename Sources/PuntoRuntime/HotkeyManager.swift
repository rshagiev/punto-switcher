import AppKit
import Carbon.HIToolbox
import PuntoCore
import PuntoSettings

/// Manages global hotkeys using CGEvent Tap
public final class HotkeyManager {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private let settingsManager: SettingsManager
    private let eventRouter: HotkeyEventRouter

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

    public init(
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
        self.eventRouter = HotkeyEventRouter(
            settingsManager: settingsManager,
            onConvertLayout: onConvertLayout,
            onToggleCase: onToggleCase,
            onToggleAutoCorrection: onToggleAutoCorrection,
            onCancelLayoutChange: onCancelLayoutChange,
            onFindInYandex: onFindInYandex,
            onFindInSlovari: onFindInSlovari,
            onSearchClick: onSearchClick,
            onClearTrackedText: onClearTrackedText,
            onKeyPress: onKeyPress,
            isCurrentApplicationDisabled: isCurrentApplicationDisabled
        )
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
        for command in HotkeyCommandPolicy.displayOrder {
            let hotkey = settingsManager.hotkey(for: command.slot)
            PuntoLog.info("\(command.title) hotkey: \(hotkey.displayString) (keyCode: \(hotkey.keyCode))")
        }
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

        return eventRouter.route(type: type, event: event)
    }
}
