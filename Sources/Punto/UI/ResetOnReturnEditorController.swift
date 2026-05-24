import AppKit
import PuntoSettings

final class ResetOnReturnEditorController: NSWindowController {
    private let settingsManager: SettingsManager
    private let onChange: () -> Void
    private let tableView = NSTableView()
    private let statusLabel = NSTextField(labelWithString: "")
    private var bundleComponents: [String] = []

    init(settingsManager: SettingsManager, onChange: @escaping () -> Void) {
        self.settingsManager = settingsManager
        self.onChange = onChange

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 340),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Return Reset Apps"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        setupUI()
        reload()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showAndActivate() {
        reload()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        root.translatesAutoresizingMaskIntoConstraints = false

        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = true
        tableView.dataSource = self
        tableView.delegate = self
        addColumn(identifier: "resetOnReturnComponent", title: "Bundle ID component", width: 460)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = tableView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        let addTelegramButton = NSButton(title: "Add Telegram", target: self, action: #selector(addTelegram(_:)))
        let addButton = NSButton(title: "Add", target: self, action: #selector(addComponent(_:)))
        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeSelectedComponents(_:)))
        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeEditor(_:)))

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        let buttonRow = NSStackView(views: [addTelegramButton, addButton, removeButton, spacer, closeButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        root.addArrangedSubview(scrollView)
        root.addArrangedSubview(statusLabel)
        root.addArrangedSubview(buttonRow)

        contentView.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: contentView.topAnchor),
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scrollView.widthAnchor.constraint(equalTo: root.widthAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 240),
            statusLabel.widthAnchor.constraint(equalTo: root.widthAnchor),
            buttonRow.widthAnchor.constraint(equalTo: root.widthAnchor)
        ])
    }

    private func addColumn(identifier: String, title: String, width: CGFloat) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(identifier))
        column.title = title
        column.width = width
        tableView.addTableColumn(column)
    }

    private func reload() {
        bundleComponents = Array(settingsManager.resetOnReturnBundleComponents).sorted()
        tableView.reloadData()
        statusLabel.stringValue = bundleComponents.isEmpty
            ? "Return-key text tracking reset is disabled for every app."
            : "\(bundleComponents.count) bundle component\(bundleComponents.count == 1 ? "" : "s")"
    }

    private func setComponents(_ components: [String]) {
        settingsManager.resetOnReturnBundleComponents = Set(components)
        reload()
        onChange()
    }

    private func uniqueDraftComponent() -> String {
        let existing = Set(bundleComponents)
        if !existing.contains("bundle") {
            return "bundle"
        }

        var suffix = 2
        while existing.contains("bundle\(suffix)") {
            suffix += 1
        }
        return "bundle\(suffix)"
    }

    @objc private func addTelegram(_ sender: NSButton) {
        setComponents(bundleComponents + ["telegram"])
        if let row = bundleComponents.firstIndex(of: "telegram") {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }

    @objc private func addComponent(_ sender: NSButton) {
        let draft = uniqueDraftComponent()
        setComponents(bundleComponents + [draft])
        guard let row = bundleComponents.firstIndex(of: draft) else { return }
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        tableView.editColumn(0, row: row, with: nil, select: true)
    }

    @objc private func removeSelectedComponents(_ sender: NSButton) {
        let selectedRows = tableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }

        var components = bundleComponents
        for row in selectedRows.reversed() where row < components.count {
            components.remove(at: row)
        }
        setComponents(components)
    }

    @objc private func closeEditor(_ sender: NSButton) {
        close()
    }
}

extension ResetOnReturnEditorController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        bundleComponents.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < bundleComponents.count else { return nil }

        let textField = NSTextField()
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.isEditable = true
        textField.delegate = self
        textField.tag = row
        textField.identifier = NSUserInterfaceItemIdentifier("resetOnReturnComponent")
        textField.stringValue = bundleComponents[row]
        textField.placeholderString = "telegram"
        return textField
    }
}

extension ResetOnReturnEditorController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
              textField.identifier?.rawValue == "resetOnReturnComponent",
              textField.tag >= 0,
              textField.tag < bundleComponents.count else {
            return
        }

        var components = bundleComponents
        components[textField.tag] = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        setComponents(components)
    }
}
