import AppKit
import PuntoCore
import PuntoSettings

final class DisabledApplicationsEditorController: NSWindowController {
    private let settingsManager: SettingsManager
    private let currentApplication: () -> (bundleID: String, name: String?)?
    private let onChange: () -> Void
    private let tableView = NSTableView()
    private let statusLabel = NSTextField(labelWithString: "")
    private var bundleIDs: [String] = []

    init(
        settingsManager: SettingsManager,
        currentApplication: @escaping () -> (bundleID: String, name: String?)?,
        onChange: @escaping () -> Void
    ) {
        self.settingsManager = settingsManager
        self.currentApplication = currentApplication
        self.onChange = onChange

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Disabled Applications"
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
        addColumn(identifier: "appName", title: "Application", width: 220)
        addColumn(identifier: "bundleID", title: "Bundle ID", width: 360)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = tableView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor

        let addCurrentButton = NSButton(title: "Add Current App", target: self, action: #selector(addCurrentApplication(_:)))
        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeSelectedApplications(_:)))
        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeEditor(_:)))

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        let buttonRow = NSStackView(views: [addCurrentButton, removeButton, spacer, closeButton])
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
            scrollView.heightAnchor.constraint(equalToConstant: 260),
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
        bundleIDs = Array(settingsManager.disabledApplicationBundleIDs).sorted {
            ApplicationDisplayNameResolver.displayName(for: $0).localizedCaseInsensitiveCompare(
                ApplicationDisplayNameResolver.displayName(for: $1)
            ) == .orderedAscending
        }
        tableView.reloadData()
        statusLabel.stringValue = bundleIDs.isEmpty
            ? "Punto is active in every application."
            : "\(bundleIDs.count) disabled application\(bundleIDs.count == 1 ? "" : "s")"
    }

    @objc private func addCurrentApplication(_ sender: NSButton) {
        guard let app = currentApplication(),
              let bundleID = ApplicationBundleIDPolicy.normalized(app.bundleID),
              ApplicationDisablePolicy.canDisableApplication(
                  bundleID: bundleID,
                  ownBundleID: Bundle.main.bundleIdentifier
              ) else {
            NSSound.beep()
            return
        }

        settingsManager.setApplicationDisabled(bundleID: bundleID, disabled: true)
        reload()
        onChange()

        if let row = bundleIDs.firstIndex(of: bundleID) {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }

    @objc private func removeSelectedApplications(_ sender: NSButton) {
        let selectedRows = tableView.selectedRowIndexes
        guard !selectedRows.isEmpty else { return }

        for row in selectedRows.reversed() where row < bundleIDs.count {
            settingsManager.setApplicationDisabled(bundleID: bundleIDs[row], disabled: false)
        }

        reload()
        onChange()
    }

    @objc private func closeEditor(_ sender: NSButton) {
        close()
    }
}

extension DisabledApplicationsEditorController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        bundleIDs.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < bundleIDs.count,
              let identifier = tableColumn?.identifier.rawValue else {
            return nil
        }

        let bundleID = bundleIDs[row]
        let textField = NSTextField()
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.isEditable = false

        switch identifier {
        case "appName":
            textField.stringValue = ApplicationDisplayNameResolver.displayName(for: bundleID)
        case "bundleID":
            textField.stringValue = bundleID
            textField.textColor = .secondaryLabelColor
        default:
            return nil
        }

        return textField
    }
}
