import AppKit
import Carbon.HIToolbox

/// Custom view for recording keyboard shortcuts - native pill button style
final class HotkeyRecorderView: NSView {

    private var hotkey: Hotkey
    private let onRecord: (Hotkey) -> Void

    private var isRecording = false
    private var button: NSButton!
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var flagsMonitor: Any?
    private var pendingModifiers: (cmd: Bool, opt: Bool, shift: Bool, ctrl: Bool)?

    init(hotkey: Hotkey, onRecord: @escaping (Hotkey) -> Void) {
        self.hotkey = hotkey
        self.onRecord = onRecord

        super.init(frame: NSRect(x: 0, y: 0, width: 120, height: 24))

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopRecording()
    }

    // MARK: - Setup

    private func setupUI() {
        // Use a native rounded rect button
        button = NSButton(title: hotkey.displayString, target: self, action: #selector(buttonClicked))
        button.bezelStyle = .rounded
        button.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.controlSize = .small
        button.isBordered = true

        addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    @objc private func buttonClicked() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    // MARK: - Recording

    private func startRecording() {
        isRecording = true
        pendingModifiers = nil
        button.title = "Type shortcut…"
        button.contentTintColor = .controlAccentColor

        // Monitor local key events
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }

        // Monitor global key events
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            _ = self?.handleKeyEvent(event)
        }

        // Monitor modifier keys for modifier-only shortcuts
        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
    }

    private func stopRecording() {
        isRecording = false
        pendingModifiers = nil
        button.title = hotkey.displayString
        button.contentTintColor = nil

        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        guard isRecording else { return }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasCommand = flags.contains(.command)
        let hasOption = flags.contains(.option)
        let hasShift = flags.contains(.shift)
        let hasControl = flags.contains(.control)

        let modifierCount = [hasCommand, hasOption, hasShift, hasControl].filter { $0 }.count

        if modifierCount >= 2 {
            // Store pending modifiers when 2+ are pressed
            pendingModifiers = (hasCommand, hasOption, hasShift, hasControl)
            // Update button to show current combination
            var parts: [String] = []
            if hasControl { parts.append("⌃") }
            if hasOption { parts.append("⌥") }
            if hasShift { parts.append("⇧") }
            if hasCommand { parts.append("⌘") }
            button.title = parts.joined()
        } else if let pending = pendingModifiers, modifierCount < 2 {
            // Modifiers released - save modifier-only hotkey
            let newHotkey = Hotkey(
                keyCode: Hotkey.modifierOnlyKeyCode,
                command: pending.cmd,
                option: pending.opt,
                shift: pending.shift,
                control: pending.ctrl
            )
            hotkey = newHotkey
            onRecord(newHotkey)
            stopRecording()
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard isRecording else { return false }

        // Escape cancels
        if event.keyCode == 53 {
            stopRecording()
            return true
        }

        // Any key press clears pending modifiers (user wants key+modifier combo)
        pendingModifiers = nil

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasCommand = flags.contains(.command)
        let hasOption = flags.contains(.option)
        let hasShift = flags.contains(.shift)
        let hasControl = flags.contains(.control)

        // Need at least one modifier
        guard hasCommand || hasOption || hasControl else {
            return false
        }

        let newHotkey = Hotkey(
            keyCode: event.keyCode,
            command: hasCommand,
            option: hasOption,
            shift: hasShift,
            control: hasControl
        )

        hotkey = newHotkey
        onRecord(newHotkey)
        stopRecording()
        return true
    }

    // MARK: - Public

    func updateHotkey(_ newHotkey: Hotkey) {
        hotkey = newHotkey
        button.title = hotkey.displayString
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 120, height: 24)
    }
}
