import AppKit

/// Controller for the menu bar icon and dropdown menu
final class StatusBarController {

    private var statusItem: NSStatusItem?
    private let settingsManager: SettingsManager
    private let onSettingsClick: () -> Void
    private let onQuitClick: () -> Void

    private var enabledMenuItem: NSMenuItem?
    private var isFlashing = false
    private let menuBarIconName = "MenuBarIcon"

    init(settingsManager: SettingsManager, onSettingsClick: @escaping () -> Void, onQuitClick: @escaping () -> Void) {
        self.settingsManager = settingsManager
        self.onSettingsClick = onSettingsClick
        self.onQuitClick = onQuitClick

        setupStatusItem()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(named: menuBarIconName)
            button.image?.isTemplate = true
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        // Title
        let titleItem = NSMenuItem(title: "Punto", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // Enabled toggle
        enabledMenuItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledMenuItem?.target = self
        enabledMenuItem?.state = settingsManager.isEnabled ? .on : .off
        menu.addItem(enabledMenuItem!)

        menu.addItem(NSMenuItem.separator())

        // Hotkey info (non-clickable) - show actual hotkeys from settings
        let convertHotkey = settingsManager.convertLayoutHotkey
        let convertItem = NSMenuItem(title: "Convert Layout\t\(convertHotkey.displayString)", action: nil, keyEquivalent: "")
        convertItem.isEnabled = false
        menu.addItem(convertItem)

        let caseHotkey = settingsManager.toggleCaseHotkey
        let caseItem = NSMenuItem(title: "Toggle Case\t\(caseHotkey.displayString)", action: nil, keyEquivalent: "")
        caseItem.isEnabled = false
        menu.addItem(caseItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Punto", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        settingsManager.isEnabled.toggle()
        enabledMenuItem?.state = settingsManager.isEnabled ? .on : .off
    }

    @objc private func openSettings() {
        onSettingsClick()
    }

    @objc private func quit() {
        onQuitClick()
    }

    // MARK: - Visual Feedback

    func flashIcon() {
        guard !isFlashing else { return }
        isFlashing = true

        guard let button = statusItem?.button else {
            isFlashing = false
            return
        }

        let originalImage = button.image
        let originalTint = button.contentTintColor

        // Flash by tinting the template icon with the accent color.
        button.image = NSImage(named: menuBarIconName)
        button.image?.isTemplate = true
        button.contentTintColor = NSColor.controlAccentColor

        // Restore after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self, weak button] in
            button?.image = originalImage
            button?.contentTintColor = originalTint
            self?.isFlashing = false
        }
    }

    // MARK: - Visibility

    func updateVisibility() {
        if settingsManager.showInMenuBar {
            if statusItem == nil {
                setupStatusItem()
            }
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }

    func updateHotkeyDisplay() {
        // Update the menu to reflect new hotkeys
        setupMenu()
    }
}
