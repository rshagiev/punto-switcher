import AppKit
import PuntoCore

enum SettingsRowFactory {
    struct PreferredInputSourceIDRow {
        let row: NSView
        let field: NSTextField
    }

    static func toggleRow(
        metadata: SettingsToggleMetadata,
        isOn: Bool,
        target: AnyObject,
        action: Selector
    ) -> NSView {
        let toggle = NSSwitch()
        toggle.state = isOn ? .on : .off
        toggle.identifier = NSUserInterfaceItemIdentifier(metadata.slot.rawValue)
        toggle.target = target
        toggle.action = action
        toggle.setContentHuggingPriority(.required, for: .horizontal)

        return iconLabelRow(
            title: metadata.title,
            systemName: metadata.systemName,
            trailingViews: [toggle]
        )
    }

    static func russianKeyboardLayoutTypeRow(
        selectedType: KeyboardLayoutType,
        target: AnyObject,
        action: Selector
    ) -> NSView {
        let segmented = NSSegmentedControl(
            labels: ["Mac", "Windows"],
            trackingMode: .selectOne,
            target: target,
            action: action
        )
        segmented.segmentStyle = .rounded
        segmented.selectedSegment = selectedType == .windows ? 1 : 0
        segmented.setContentHuggingPriority(.required, for: .horizontal)

        return iconLabelRow(
            title: "Russian keyboard layout",
            systemName: "keyboard.chevron.compact.down",
            trailingViews: [segmented]
        )
    }

    static func preferredInputSourceIDRow(
        title: String,
        sourceID: String?,
        systemName: String,
        target: AnyObject,
        fieldAction: Selector,
        resetAction: Selector
    ) -> PreferredInputSourceIDRow {
        let field = NSTextField(string: sourceID ?? "")
        field.placeholderString = "Auto"
        field.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        field.target = target
        field.action = fieldAction
        field.tag = -1
        field.lineBreakMode = .byTruncatingMiddle
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let resetButton = NSButton(title: "Auto", target: target, action: resetAction)
        configureRoundedButton(resetButton)

        let row = iconLabelRow(
            title: title,
            systemName: systemName,
            trailingViews: [field, resetButton],
            includeSpacer: false
        )

        NSLayoutConstraint.activate([
            field.widthAnchor.constraint(equalToConstant: 145)
        ])

        return PreferredInputSourceIDRow(row: row, field: field)
    }

    static func checkbox(
        title: String,
        identifier: String,
        isOn: Bool,
        target: AnyObject,
        action: Selector
    ) -> NSButton {
        let checkbox = NSButton(checkboxWithTitle: title, target: target, action: action)
        checkbox.identifier = NSUserInterfaceItemIdentifier(identifier)
        checkbox.state = isOn ? .on : .off
        checkbox.font = .systemFont(ofSize: 12)
        checkbox.setContentHuggingPriority(.required, for: .horizontal)
        return checkbox
    }

    static func labeledGridRow(title: String, grid: NSView) -> NSView {
        let label = textLabel(title, fontSize: 12, textColor: .secondaryLabelColor)
        label.setContentHuggingPriority(.required, for: .horizontal)

        let spacer = spacerView()

        let row = NSStackView(views: [label, spacer, grid])
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = 8
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return row
    }

    static func countLabel(text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabelColor
        return label
    }

    static func managedCountRow(
        title: String,
        systemName: String,
        countLabel: NSTextField,
        buttons: [NSButton]
    ) -> NSView {
        for button in buttons {
            configureRoundedButton(button)
        }

        return iconLabelRow(
            title: title,
            systemName: systemName,
            trailingViews: [countLabel] + buttons
        )
    }

    private static func iconLabelRow(
        title: String,
        systemName: String,
        trailingViews: [NSView],
        includeSpacer: Bool = true
    ) -> NSStackView {
        let icon = iconView(systemName: systemName)
        let label = textLabel(title, fontSize: 13, textColor: .labelColor)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)

        var views: [NSView] = [icon, label]
        if includeSpacer {
            let spacer = spacerView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            views.append(spacer)
        }
        views.append(contentsOf: trailingViews)

        let row = NSStackView(views: views)
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        return row
    }

    private static func iconView(systemName: String) -> NSImageView {
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor
        return icon
    }

    private static func textLabel(
        _ title: String,
        fontSize: CGFloat,
        textColor: NSColor
    ) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: fontSize)
        label.textColor = textColor
        return label
    }

    private static func spacerView() -> NSView {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        return spacer
    }

    private static func configureRoundedButton(_ button: NSButton) {
        button.bezelStyle = .rounded
        button.setContentHuggingPriority(.required, for: .horizontal)
    }
}
