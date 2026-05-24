import AppKit
import PuntoCore
import PuntoSettings

final class AutoCorrectionRulesEditorController: NSWindowController {
    private let settingsManager: SettingsManager
    private let onChange: () -> Void
    private let tableView = NSTableView()
    private let searchField = NSSearchField()
    private let statusLabel = NSTextField(labelWithString: "")
    private var filteredRuleIndexes: [Int] = []

    init(settingsManager: SettingsManager, onChange: @escaping () -> Void) {
        self.settingsManager = settingsManager
        self.onChange = onChange

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Auto-correction Rules"
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

    func importRules(attachedTo parentWindow: NSWindow?) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json, .plainText, .commaSeparatedText, .tabSeparatedText]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            let result = try settingsManager.importAutoCorrectionRules(from: data, merge: true)
            reload()
            onChange()

            showAlert(
                title: "Imported \(result.rules.count) rules",
                message: result.skippedLines.isEmpty
                    ? "Auto-correction rules were merged with existing rules."
                    : "Skipped \(result.skippedLines.count) malformed lines.",
                style: .informational,
                attachedTo: parentWindow
            )
        } catch {
            showAlert(
                title: "Could not import rules",
                message: "\(error)",
                style: .warning,
                attachedTo: parentWindow
            )
        }
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        root.translatesAutoresizingMaskIntoConstraints = false

        searchField.placeholderString = "Search rules"
        searchField.target = self
        searchField.action = #selector(filterRules(_:))
        searchField.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = false
        tableView.dataSource = self
        tableView.delegate = self
        addColumn(identifier: "trigger", title: "Trigger", width: 190)
        addColumn(identifier: "replacement", title: "Replacement", width: 250)
        addColumn(identifier: "matchMode", title: "Match", width: 130)
        addColumn(identifier: "preserveCase", title: "Case", width: 80)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = tableView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let addButton = NSButton(title: "Add", target: self, action: #selector(addRule(_:)))
        let deleteButton = NSButton(title: "Delete", target: self, action: #selector(deleteSelectedRule(_:)))
        let importButton = NSButton(title: "Import...", target: self, action: #selector(importRulesFromButton(_:)))
        let exportButton = NSButton(title: "Export...", target: self, action: #selector(exportRules(_:)))
        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeEditor(_:)))

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        let buttonRow = NSStackView(views: [addButton, deleteButton, importButton, exportButton, spacer, closeButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        root.addArrangedSubview(searchField)
        root.addArrangedSubview(scrollView)
        root.addArrangedSubview(statusLabel)
        root.addArrangedSubview(buttonRow)

        contentView.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: contentView.topAnchor),
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            searchField.widthAnchor.constraint(equalTo: root.widthAnchor),
            scrollView.widthAnchor.constraint(equalTo: root.widthAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 300),
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
        let rules = settingsManager.autoCorrectionRules
        filteredRuleIndexes = AutoCorrectionRuleCatalog.filteredRuleIndexes(
            in: rules,
            query: searchField.stringValue
        )
        tableView.reloadData()
        updateStatus()
    }

    private func updateStatus() {
        let rules = settingsManager.autoCorrectionRules
        let issues = AutoCorrectionRuleCatalog.validationIssues(for: rules)
        let errors = issues.filter { $0.severity == .error }.count
        let warnings = issues.filter { $0.severity == .warning }.count

        var parts = ["\(filteredRuleIndexes.count)/\(rules.count) shown"]
        if errors > 0 { parts.append("\(errors) error\(errors == 1 ? "" : "s")") }
        if warnings > 0 { parts.append("\(warnings) warning\(warnings == 1 ? "" : "s")") }
        statusLabel.stringValue = parts.joined(separator: "  -  ")

        if errors > 0 {
            statusLabel.textColor = .systemRed
        } else if warnings > 0 {
            statusLabel.textColor = .systemOrange
        } else {
            statusLabel.textColor = .secondaryLabelColor
        }
    }

    private func validationMessage(forRuleAt index: Int) -> (AutoCorrectionRuleValidationIssue.Severity, String)? {
        let issues = AutoCorrectionRuleCatalog.validationIssues(for: settingsManager.autoCorrectionRules)
            .filter { $0.ruleIndex == index }
        if let error = issues.first(where: { $0.severity == .error }) {
            return (.error, error.message)
        }
        if let warning = issues.first(where: { $0.severity == .warning }) {
            return (.warning, warning.message)
        }
        return nil
    }

    @objc private func filterRules(_ sender: NSSearchField) {
        reload()
    }

    @objc private func addRule(_ sender: NSButton) {
        var rules = settingsManager.autoCorrectionRules
        rules.append(AutoCorrectionRule(trigger: "trigger", replacement: "replacement", matchMode: .exact, preserveCase: true))
        settingsManager.autoCorrectionRules = rules
        reload()
        onChange()
        if let row = filteredRuleIndexes.firstIndex(of: rules.count - 1) {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            tableView.editColumn(0, row: row, with: nil, select: true)
        }
    }

    @objc private func deleteSelectedRule(_ sender: NSButton) {
        guard tableView.selectedRow >= 0 else { return }
        var rules = settingsManager.autoCorrectionRules
        guard tableView.selectedRow < filteredRuleIndexes.count else { return }
        rules.remove(at: filteredRuleIndexes[tableView.selectedRow])
        settingsManager.autoCorrectionRules = rules
        reload()
        onChange()
    }

    @objc private func importRulesFromButton(_ sender: NSButton) {
        importRules(attachedTo: window)
    }

    @objc private func exportRules(_ sender: NSButton) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "punto-auto-correction-rules.json"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try settingsManager.exportAutoCorrectionRules()
            try data.write(to: url, options: .atomic)

            showAlert(
                title: "Exported \(settingsManager.autoCorrectionRules.count) rules",
                message: "Auto-correction rules were written as JSON.",
                style: .informational,
                attachedTo: window
            )
        } catch {
            showAlert(
                title: "Could not export rules",
                message: "\(error)",
                style: .warning,
                attachedTo: window
            )
        }
    }

    @objc private func closeEditor(_ sender: NSButton) {
        close()
    }

    private func showAlert(title: String, message: String, style: NSAlert.Style, attachedTo parentWindow: NSWindow?) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: parentWindow ?? window ?? NSWindow())
    }
}

extension AutoCorrectionRulesEditorController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        filteredRuleIndexes.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < filteredRuleIndexes.count,
              let identifier = tableColumn?.identifier.rawValue else {
            return nil
        }

        let sourceIndex = filteredRuleIndexes[row]
        let rule = settingsManager.autoCorrectionRules[sourceIndex]
        let textField = NSTextField()
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.isEditable = true
        textField.delegate = self
        textField.tag = sourceIndex
        textField.identifier = NSUserInterfaceItemIdentifier(identifier)

        switch identifier {
        case "trigger":
            textField.stringValue = rule.trigger
        case "replacement":
            textField.stringValue = rule.replacement
        case "matchMode":
            textField.stringValue = rule.matchMode.rawValue
            textField.placeholderString = "exact"
        case "preserveCase":
            textField.stringValue = rule.preserveCase ? "true" : "false"
            textField.placeholderString = "true"
        default:
            return nil
        }

        if let (severity, message) = validationMessage(forRuleAt: sourceIndex) {
            textField.toolTip = message
            textField.textColor = severity == .error ? .systemRed : .systemOrange
        }

        return textField
    }
}

extension AutoCorrectionRulesEditorController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
              let identifier = textField.identifier?.rawValue,
              textField.tag >= 0 else {
            return
        }

        var rules = settingsManager.autoCorrectionRules
        guard textField.tag < rules.count else { return }

        let old = rules[textField.tag]
        let value = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        let updated: AutoCorrectionRule
        switch identifier {
        case "trigger":
            updated = AutoCorrectionRule(
                trigger: value,
                replacement: old.replacement,
                matchMode: old.matchMode,
                preserveCase: old.preserveCase
            )
        case "replacement":
            updated = AutoCorrectionRule(
                trigger: old.trigger,
                replacement: value,
                matchMode: old.matchMode,
                preserveCase: old.preserveCase
            )
        case "matchMode":
            updated = AutoCorrectionRule(
                trigger: old.trigger,
                replacement: old.replacement,
                matchMode: AutoCorrectionRule.MatchMode(rawValue: value) ?? old.matchMode,
                preserveCase: old.preserveCase
            )
        case "preserveCase":
            updated = AutoCorrectionRule(
                trigger: old.trigger,
                replacement: old.replacement,
                matchMode: old.matchMode,
                preserveCase: ["true", "yes", "1", "on"].contains(value.lowercased())
            )
        default:
            return
        }

        rules[textField.tag] = updated
        settingsManager.autoCorrectionRules = rules
        reload()
        onChange()
    }
}
