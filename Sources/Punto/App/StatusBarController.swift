import AppKit
import PuntoCore

/// Controller for the menu bar icon and dropdown menu
final class StatusBarController: NSObject {

    private var statusItem: NSStatusItem?
    private let settingsManager: SettingsManager
    private let onSettingsClick: () -> Void
    private let onQuitClick: () -> Void
    private let onEnabledChanged: (Bool, Bool) -> Void
    private let onToggleCurrentAppDisabled: () -> Void
    private let isCurrentAppDisabled: () -> Bool
    private let currentAppBundleID: () -> String?
    private let currentAppName: () -> String?

    private var enabledMenuItem: NSMenuItem?
    private var soundEffectsMenuItem: NSMenuItem?
    private var disableCurrentAppMenuItem: NSMenuItem?
    private var convertHotkeyMenuItem: NSMenuItem?
    private var toggleCaseHotkeyMenuItem: NSMenuItem?
    private var toggleAutoCorrectionHotkeyMenuItem: NSMenuItem?
    private var cancelLayoutChangeHotkeyMenuItem: NSMenuItem?
    private var findInYandexHotkeyMenuItem: NSMenuItem?
    private var findInSlovariHotkeyMenuItem: NSMenuItem?
    private var isFlashing = false
    private var currentIconState: StatusIconState?

    init(
        settingsManager: SettingsManager,
        onSettingsClick: @escaping () -> Void,
        onQuitClick: @escaping () -> Void,
        onEnabledChanged: @escaping (Bool, Bool) -> Void,
        onToggleCurrentAppDisabled: @escaping () -> Void,
        isCurrentAppDisabled: @escaping () -> Bool,
        currentAppBundleID: @escaping () -> String?,
        currentAppName: @escaping () -> String?
    ) {
        self.settingsManager = settingsManager
        self.onSettingsClick = onSettingsClick
        self.onQuitClick = onQuitClick
        self.onEnabledChanged = onEnabledChanged
        self.onToggleCurrentAppDisabled = onToggleCurrentAppDisabled
        self.isCurrentAppDisabled = isCurrentAppDisabled
        self.currentAppBundleID = currentAppBundleID
        self.currentAppName = currentAppName

        super.init()

        setupStatusItem()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            applyIconState(to: button)
        }

        setupMenu()
    }

    private func loadMenuBarIcon() -> NSImage? {
        return NSImage(named: "MenuBarIcon")
    }

    private func desiredIconState() -> StatusIconState {
        StatusIconPolicy.state(
            isEnabled: settingsManager.isEnabled,
            isCurrentApplicationDisabled: isCurrentAppDisabled()
        )
    }

    private func applyIconState(to button: NSStatusBarButton) {
        let state = desiredIconState()
        currentIconState = state

        button.image = loadMenuBarIcon()
        button.image?.isTemplate = true
        button.toolTip = StatusIconPolicy.accessibilityDescription(for: state)

        switch state {
        case .active:
            button.contentTintColor = nil
        case .inactive:
            button.contentTintColor = .secondaryLabelColor
        case .disabled:
            button.contentTintColor = .tertiaryLabelColor
        }
    }

    private func updateIconState() {
        guard !isFlashing, let button = statusItem?.button else { return }
        let state = desiredIconState()
        guard currentIconState != state else { return }
        applyIconState(to: button)
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self

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

        soundEffectsMenuItem = NSMenuItem(title: "Sound Effects", action: #selector(toggleSoundEffects), keyEquivalent: "")
        soundEffectsMenuItem?.target = self
        soundEffectsMenuItem?.state = settingsManager.soundEffectsEnabled ? .on : .off
        menu.addItem(soundEffectsMenuItem!)

        disableCurrentAppMenuItem = NSMenuItem(title: "Disable in Current App", action: #selector(toggleCurrentAppDisabled), keyEquivalent: "")
        disableCurrentAppMenuItem?.target = self
        menu.addItem(disableCurrentAppMenuItem!)

        menu.addItem(NSMenuItem.separator())

        // Hotkey info (non-clickable) - show actual hotkeys from settings
        convertHotkeyMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        convertHotkeyMenuItem?.isEnabled = false
        menu.addItem(convertHotkeyMenuItem!)

        toggleCaseHotkeyMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        toggleCaseHotkeyMenuItem?.isEnabled = false
        menu.addItem(toggleCaseHotkeyMenuItem!)

        toggleAutoCorrectionHotkeyMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        toggleAutoCorrectionHotkeyMenuItem?.isEnabled = false
        menu.addItem(toggleAutoCorrectionHotkeyMenuItem!)

        cancelLayoutChangeHotkeyMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        cancelLayoutChangeHotkeyMenuItem?.isEnabled = false
        menu.addItem(cancelLayoutChangeHotkeyMenuItem!)

        findInYandexHotkeyMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        findInYandexHotkeyMenuItem?.isEnabled = false
        menu.addItem(findInYandexHotkeyMenuItem!)

        findInSlovariHotkeyMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        findInSlovariHotkeyMenuItem?.isEnabled = false
        menu.addItem(findInSlovariHotkeyMenuItem!)
        updateHotkeyDisplay()

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
        let wasEnabled = settingsManager.isEnabled
        settingsManager.isEnabled.toggle()
        let isEnabled = settingsManager.isEnabled
        enabledMenuItem?.state = isEnabled ? .on : .off
        onEnabledChanged(wasEnabled, isEnabled)
        updateIconState()
    }

    @objc private func toggleSoundEffects() {
        settingsManager.soundEffectsEnabled.toggle()
        soundEffectsMenuItem?.state = settingsManager.soundEffectsEnabled ? .on : .off
    }

    @objc private func toggleCurrentAppDisabled() {
        onToggleCurrentAppDisabled()
        updateCurrentAppMenuItem()
        updateIconState()
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
        button.image = loadMenuBarIcon()
        button.image?.isTemplate = true
        button.contentTintColor = NSColor.controlAccentColor

        // Restore after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self, weak button] in
            button?.image = originalImage
            button?.contentTintColor = originalTint
            self?.isFlashing = false
            self?.updateIconState()
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
        convertHotkeyMenuItem?.title = "Convert Layout\t\(settingsManager.convertLayoutHotkey.displayString)"
        toggleCaseHotkeyMenuItem?.title = "Toggle Case\t\(settingsManager.toggleCaseHotkey.displayString)"
        toggleAutoCorrectionHotkeyMenuItem?.title = "Toggle Auto-correction\t\(settingsManager.toggleAutoCorrectionHotkey.displayString)"
        cancelLayoutChangeHotkeyMenuItem?.title = "Cancel Last Conversion\t\(settingsManager.cancelLayoutChangeHotkey.displayString)"
        findInYandexHotkeyMenuItem?.title = "Find in Yandex\t\(settingsManager.findInYandexHotkey.displayString)"
        findInSlovariHotkeyMenuItem?.title = "Find in Translate\t\(settingsManager.findInSlovariHotkey.displayString)"
    }

    func refreshCurrentApplicationState() {
        updateCurrentAppMenuItem()
        updateIconState()
    }

    private func updateCurrentAppMenuItem() {
        guard let item = disableCurrentAppMenuItem else { return }
        let state = ApplicationDisablePolicy.menuStateForCurrentApplication(
            bundleID: currentAppBundleID(),
            ownBundleID: Bundle.main.bundleIdentifier,
            displayName: currentAppName(),
            isCurrentlyDisabled: isCurrentAppDisabled()
        )
        item.title = state.title
        item.state = state.isChecked ? .on : .off
        item.isEnabled = state.isEnabled
    }
}

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        enabledMenuItem?.state = settingsManager.isEnabled ? .on : .off
        soundEffectsMenuItem?.state = settingsManager.soundEffectsEnabled ? .on : .off
        updateHotkeyDisplay()
        updateCurrentAppMenuItem()
        updateIconState()
    }
}
