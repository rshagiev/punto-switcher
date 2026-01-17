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
        button.bezelStyle = .roundRect
        button.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.controlSize = .small

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
    }

    private func stopRecording() {
        isRecording = false
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
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard isRecording else { return false }

        // Escape cancels
        if event.keyCode == 53 {
            stopRecording()
            return true
        }

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
