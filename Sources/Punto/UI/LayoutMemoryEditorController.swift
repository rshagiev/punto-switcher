import AppKit
import PuntoSettings

final class LayoutMemoryEditorController: NSWindowController {
    private let settingsManager: SettingsManager
    private let onChange: () -> Void
    private let tableView = NSTableView()
    private let statusLabel = NSTextField(labelWithString: "")
    private var rows: [(bundleID: String, layoutID: String)] = []

    init(settingsManager: SettingsManager, onChange: @escaping () -> Void) {
        self.settingsManager = settingsManager
        self.onChange = onChange

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 380),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Remembered App Layouts"
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
        addColumn(identifier: "layoutAppName", title: "Application", width: 210)
        addColumn(identifier: "layoutBundleID", title: "Bundle ID", width: 260)
        addColumn(identifier: "layoutID", title: "Layout ID", width: 250)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = tableView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeSelectedLayouts(_:)))
        let clearButton = NSButton(title: "Clear All", target: self, action: #selector(clearLayouts(_:)))
        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeEditor(_:)))

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        let buttonRow = NSStackView(views: [removeButton, clearButton, spacer, closeButton])
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
            scrollView.heightAnchor.constraint(equalToConstant: 280),
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
        rows = settingsManager.rememberedApplicationLayouts
            .map { (bundleID: $0.key, layoutID: $0.value) }
            .sorted {
                ApplicationDisplayNameResolver.displayName(for: $0.bundleID).localizedCaseInsensitiveCompare(
                    ApplicationDisplayNameResolver.displayName(for: $1.bundleID)
                ) == .orderedAscending
            }
        tableView.reloadData()
        statusLabel.stringValue = rows.isEmpty
            ? "No application-specific layouts are remembered."
            : "\(rows.count) remembered application layout\(rows.count == 1 ? "" : "s")"
    }

    @objc private func removeSelectedLayouts(_ sender: NSButton) {
        let selectedRows = tableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }

        var layouts = settingsManager.rememberedApplicationLayouts
        for row in selectedRows where row < rows.count {
            layouts.removeValue(forKey: rows[row].bundleID)
        }
        settingsManager.rememberedApplicationLayouts = layouts
        reload()
        onChange()
    }

    @objc private func clearLayouts(_ sender: NSButton) {
        settingsManager.rememberedApplicationLayouts = [:]
        reload()
        onChange()
    }

    @objc private func closeEditor(_ sender: NSButton) {
        close()
    }
}

extension LayoutMemoryEditorController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        rows.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < rows.count,
              let identifier = tableColumn?.identifier.rawValue else {
            return nil
        }

        let rememberedLayout = rows[row]
        let textField = NSTextField()
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.isEditable = false

        switch identifier {
        case "layoutAppName":
            textField.stringValue = ApplicationDisplayNameResolver.displayName(for: rememberedLayout.bundleID)
        case "layoutBundleID":
            textField.stringValue = rememberedLayout.bundleID
            textField.textColor = .secondaryLabelColor
        case "layoutID":
            textField.stringValue = rememberedLayout.layoutID
            textField.textColor = .secondaryLabelColor
        default:
            return nil
        }

        return textField
    }
}
