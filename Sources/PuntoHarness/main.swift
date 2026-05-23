import AppKit
import Carbon

final class HarnessDelegate: NSObject, NSApplicationDelegate, NSTextViewDelegate, NSTextFieldDelegate {
    private var window: NSWindow?
    private var textView: NSTextView?
    private var secureField: NSSecureTextField?
    private let outputPath = "/tmp/punto_harness_text.txt"
    private let secureOutputPath = "/tmp/punto_harness_secure_text.txt"
    private let readyPath = "/tmp/punto_harness_ready"
    private let commandPath = "/tmp/punto_harness_command.txt"
    private let commandDonePath = "/tmp/punto_harness_command_done.txt"

    func applicationDidFinishLaunching(_ notification: Notification) {
        try? "".write(toFile: outputPath, atomically: true, encoding: .utf8)
        try? "".write(toFile: secureOutputPath, atomically: true, encoding: .utf8)
        installMenu()

        let window = NSWindow(
            contentRect: NSRect(x: 120, y: 120, width: 720, height: 360),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Punto Harness"

        let root = NSStackView(frame: window.contentView?.bounds ?? .zero)
        root.orientation = .vertical
        root.spacing = 8
        root.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        root.autoresizingMask = [.width, .height]

        let secureField = NSSecureTextField()
        secureField.placeholderString = "Secure field"
        secureField.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
        secureField.delegate = self
        secureField.translatesAutoresizingMaskIntoConstraints = false

        let textView = NSTextView()
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.font = .monospacedSystemFont(ofSize: 18, weight: .regular)
        textView.delegate = self
        textView.string = ""

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        root.addArrangedSubview(secureField)
        root.addArrangedSubview(scrollView)
        window.contentView?.addSubview(root)
        NSLayoutConstraint.activate([
            secureField.heightAnchor.constraint(equalToConstant: 28),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260)
        ])
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(textView)
        NSApp.activate(ignoringOtherApps: true)
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.processCommand()
        }
        try? "ready".write(toFile: readyPath, atomically: true, encoding: .utf8)

        self.window = window
        self.textView = textView
        self.secureField = secureField
    }

    private func installMenu() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    }

    func textDidChange(_ notification: Notification) {
        let text = textView?.string ?? ""
        try? text.write(toFile: outputPath, atomically: true, encoding: .utf8)
    }

    func controlTextDidChange(_ obj: Notification) {
        let text = secureField?.stringValue ?? ""
        try? text.write(toFile: secureOutputPath, atomically: true, encoding: .utf8)
    }

    private func processCommand() {
        guard let command = try? String(contentsOfFile: commandPath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !command.isEmpty
        else {
            return
        }

        try? "".write(toFile: commandPath, atomically: true, encoding: .utf8)

        switch command {
        case "ping":
            break
        case "setEnglishLayout":
            selectKeyboardLayout(languagePrefix: "en", preferredSourceIDs: [
                "com.apple.keylayout.ABC",
                "com.apple.keylayout.US"
            ])
        case "setRussianLayout":
            selectKeyboardLayout(languagePrefix: "ru", preferredSourceIDs: [
                "com.apple.keylayout.Russian"
            ])
        case "focusText":
            focus(textView)
        case "focusSecure":
            focus(secureField)
        default:
            break
        }

        try? command.write(toFile: commandDonePath, atomically: true, encoding: .utf8)
    }

    private func focus(_ responder: NSResponder?) {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        if let responder {
            window?.makeFirstResponder(responder)
        }
    }

    private func selectKeyboardLayout(languagePrefix: String, preferredSourceIDs: [String]) {
        guard let sourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return
        }

        let candidates = sourceList.filter { source in
            isSelectableKeyboard(source)
                && isEnabledInputSource(source)
                && languages(for: source).contains { $0.lowercased().hasPrefix(languagePrefix) }
        }

        let selected = preferredSourceIDs.compactMap { preferredID in
            candidates.first { sourceID(for: $0) == preferredID }
        }.first ?? candidates.first

        if let selected {
            TISSelectInputSource(selected)
        }
    }

    private func isSelectableKeyboard(_ source: TISInputSource) -> Bool {
        guard property(source, kTISPropertyInputSourceCategory) as? String == kTISCategoryKeyboardInputSource as String else {
            return false
        }
        return property(source, kTISPropertyInputSourceIsSelectCapable) as? Bool ?? false
    }

    private func isEnabledInputSource(_ source: TISInputSource) -> Bool {
        property(source, kTISPropertyInputSourceIsEnabled) as? Bool ?? true
    }

    private func sourceID(for source: TISInputSource) -> String {
        property(source, kTISPropertyInputSourceID) as? String ?? ""
    }

    private func languages(for source: TISInputSource) -> [String] {
        property(source, kTISPropertyInputSourceLanguages) as? [String] ?? []
    }

    private func property(_ source: TISInputSource, _ key: CFString) -> Any? {
        guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue()
    }
}

let app = NSApplication.shared
let delegate = HarnessDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
