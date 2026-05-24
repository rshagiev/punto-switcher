import AppKit
import Carbon.HIToolbox
import PuntoCore

/// Custom view for recording keyboard shortcuts - native pill button style
final class HotkeyRecorderView: NSView {

    private var hotkey: Hotkey
    private let onRecord: (Hotkey) -> Void

    private var isRecording = false
    private var button: NSButton!
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var flagsMonitor: Any?
    private let recordingStateMachine = HotkeyRecordingStateMachine()

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
        recordingStateMachine.reset()
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
        recordingStateMachine.reset()
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

        let snapshot = ModifierFlagsSnapshot(
            command: hasCommand,
            option: hasOption,
            shift: hasShift,
            control: hasControl
        )

        switch recordingStateMachine.handleFlagsChanged(flags: snapshot) {
        case .previewModifierOnly(let preview):
            button.title = preview.displayString
        case .record(let newHotkey):
            hotkey = newHotkey
            onRecord(newHotkey)
            stopRecording()
        case .none, .cancel, .reject, .passThrough:
            break
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard isRecording else { return false }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let snapshot = ModifierFlagsSnapshot(
            command: flags.contains(.command),
            option: flags.contains(.option),
            shift: flags.contains(.shift),
            control: flags.contains(.control)
        )

        switch recordingStateMachine.handleKeyDown(keyCode: event.keyCode, flags: snapshot) {
        case .cancel:
            stopRecording()
            return true
        case .reject:
            NSSound.beep()
            return true
        case .passThrough:
            return false
        case .record(let newHotkey):
            hotkey = newHotkey
            onRecord(newHotkey)
            stopRecording()
            return true
        case .none, .previewModifierOnly:
            return true
        }
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
