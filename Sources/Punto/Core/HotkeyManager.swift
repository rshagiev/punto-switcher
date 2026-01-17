import AppKit
import Carbon.HIToolbox

/// Manages global hotkeys using CGEvent Tap
final class HotkeyManager {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private let settingsManager: SettingsManager
    private let onConvertLayout: () -> Void
    private let onToggleCase: () -> Void
    private let onKeyPress: (UInt16, String?) -> Void

    private var isRunning = false

    // Thread-safe flag to ignore events during text replacement
    private let stateQueue = DispatchQueue(label: "com.punto.hotkeymanager.state")
    private var _ignoreEvents = false
    var ignoreEvents: Bool {
        get { stateQueue.sync { _ignoreEvents } }
        set { stateQueue.sync { _ignoreEvents = newValue } }
    }

    // Track modifier state for modifier-only hotkeys (accessed from event tap thread)
    private var modifiersWerePressed = false
    private var lastTriggerTime: Date = .distantPast

    init(
        settingsManager: SettingsManager,
        onConvertLayout: @escaping () -> Void,
        onToggleCase: @escaping () -> Void,
        onKeyPress: @escaping (UInt16, String?) -> Void
    ) {
        self.settingsManager = settingsManager
        self.onConvertLayout = onConvertLayout
        self.onToggleCase = onToggleCase
        self.onKeyPress = onKeyPress
    }

    deinit {
        stop()
    }

    // MARK: - Start/Stop

    func start() {
        guard !isRunning else {
            PuntoLog.info("HotkeyManager already running")
            return
        }

        // Create event tap for keyDown and flagsChanged events
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

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
    }

    func stop() {
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
            // Log when we're passing through events during ignore mode
            if type == .keyDown {
                let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                let flags = event.flags
                if flags.contains(.maskCommand) && (keyCode == 8 || keyCode == 9) {
                    PuntoLog.info("handleEvent: passing through Cmd+\(keyCode == 8 ? "C" : "V") (ignoreEvents=true)")
                }
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

        // Handle tap disabled (system may disable it under heavy load)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            PuntoLog.info("Event tap was disabled, re-enabling...")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        let flags = event.flags
        let hasCmd = flags.contains(.maskCommand)
        let hasOpt = flags.contains(.maskAlternate)
        let hasShift = flags.contains(.maskShift)
        let hasControl = flags.contains(.maskControl)

        // Handle flagsChanged for modifier-only hotkeys
        if type == .flagsChanged {
            let convertHotkey = settingsManager.convertLayoutHotkey

            if convertHotkey.isModifierOnly {
                // Check if all required modifiers are currently pressed
                let allModifiersPressed = hasCmd == convertHotkey.command &&
                                          hasOpt == convertHotkey.option &&
                                          hasShift == convertHotkey.shift &&
                                          hasControl == convertHotkey.control

                // Check if ALL modifiers are released (none pressed)
                let noModifiersPressed = !hasCmd && !hasOpt && !hasShift && !hasControl

                if allModifiersPressed {
                    // Mark that modifiers were pressed
                    modifiersWerePressed = true
                } else if modifiersWerePressed && noModifiersPressed {
                    // All modifiers were released - trigger if enough time passed
                    let now = Date()
                    if now.timeIntervalSince(lastTriggerTime) > 0.5 {
                        PuntoLog.info("Modifier-only hotkey triggered: \(convertHotkey.displayString)")
                        lastTriggerTime = now
                        DispatchQueue.main.async { [weak self] in
                            self?.onConvertLayout()
                        }
                    }
                    modifiersWerePressed = false
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
        modifiersWerePressed = false

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

        // Check for key-based hotkeys (like Cmd+Opt+Z for toggle case)
        if checkHotkey(keyCode: keyCode, flags: flags) {
            return nil
        }

        // Track key presses for word tracking (only for regular keys without modifiers)
        // Skip if any modifier is held (except Shift for capital letters)
        let hasModifier = hasCmd || hasOpt || hasControl
        if !hasModifier {
            let characters = getCharacters(from: event)
            PuntoLog.info("KeyDown: keyCode=\(keyCode), chars='\(characters ?? "nil")'")
            DispatchQueue.main.async { [weak self] in
                self?.onKeyPress(keyCode, characters)
            }
        }

        return Unmanaged.passUnretained(event)
    }

    private func checkHotkey(keyCode: UInt16, flags: CGEventFlags) -> Bool {
        let convertHotkey = settingsManager.convertLayoutHotkey
        let toggleCaseHotkey = settingsManager.toggleCaseHotkey

        // Check for convert layout hotkey
        if matchesHotkey(keyCode: keyCode, flags: flags, hotkey: convertHotkey) {
            PuntoLog.info("Convert layout hotkey matched! keyCode=\(keyCode)")
            DispatchQueue.main.async { [weak self] in
                self?.onConvertLayout()
            }
            return true
        }

        // Check for toggle case hotkey
        if matchesHotkey(keyCode: keyCode, flags: flags, hotkey: toggleCaseHotkey) {
            PuntoLog.info("Toggle case hotkey matched! keyCode=\(keyCode)")
            DispatchQueue.main.async { [weak self] in
                self?.onToggleCase()
            }
            return true
        }

        return false
    }

    private func matchesHotkey(keyCode: UInt16, flags: CGEventFlags, hotkey: Hotkey) -> Bool {
        // Check if key matches
        guard keyCode == hotkey.keyCode else { return false }

        // Check modifiers
        let hasCommand = flags.contains(.maskCommand)
        let hasOption = flags.contains(.maskAlternate)
        let hasShift = flags.contains(.maskShift)
        let hasControl = flags.contains(.maskControl)

        let matches = hasCommand == hotkey.command &&
                      hasOption == hotkey.option &&
                      hasShift == hotkey.shift &&
                      hasControl == hotkey.control

        return matches
    }

    private func getCharacters(from event: CGEvent) -> String? {
        var length = 0
        event.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)

        guard length > 0 else { return nil }

        var chars = [UniChar](repeating: 0, count: length)
        event.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &chars)

        return String(utf16CodeUnits: chars, count: length)
    }
}

// MARK: - Hotkey Structure

/// Represents a keyboard shortcut
struct Hotkey: Codable, Equatable {
    var keyCode: UInt16
    var command: Bool
    var option: Bool
    var shift: Bool
    var control: Bool

    /// Special keyCode value indicating modifier-only hotkey (no key, just modifiers)
    static let modifierOnlyKeyCode: UInt16 = UInt16.max

    /// Whether this is a modifier-only hotkey (triggered by pressing modifiers without a key)
    var isModifierOnly: Bool {
        return keyCode == Self.modifierOnlyKeyCode
    }

    /// Default hotkey for layout conversion: Cmd+Option+Shift (modifier-only)
    static let defaultConvertLayout = Hotkey(
        keyCode: modifierOnlyKeyCode,
        command: true,
        option: true,
        shift: true,
        control: false
    )

    /// Default hotkey for toggle case: Cmd+Option+Z
    static let defaultToggleCase = Hotkey(
        keyCode: 6, // Z key
        command: true,
        option: true,
        shift: false,
        control: false
    )

    var displayString: String {
        var parts: [String] = []

        if control { parts.append("\u{2303}") } // Control symbol
        if option { parts.append("\u{2325}") }  // Option symbol
        if shift { parts.append("\u{21E7}") }   // Shift symbol
        if command { parts.append("\u{2318}") } // Command symbol

        // Only show key name if not modifier-only
        if !isModifierOnly, let keyName = KeyCodeNames.name(for: keyCode) {
            parts.append(keyName)
        }

        return parts.joined(separator: "")
    }
}

// MARK: - Key Code Names

enum KeyCodeNames {
    private static let names: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
        44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space",
        50: "`", 51: "Delete", 53: "Escape", 55: "Command", 56: "Shift",
        57: "Caps Lock", 58: "Option", 59: "Control", 60: "Right Shift",
        61: "Right Option", 62: "Right Control", 63: "Function",
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
        103: "F11", 105: "F13", 107: "F14", 109: "F10", 111: "F12",
        113: "F15", 114: "Help", 115: "Home", 116: "Page Up", 117: "Forward Delete",
        118: "F4", 119: "End", 120: "F2", 121: "Page Down", 122: "F1", 123: "Left",
        124: "Right", 125: "Down", 126: "Up"
    ]

    static func name(for keyCode: UInt16) -> String? {
        return names[keyCode]
    }
}
