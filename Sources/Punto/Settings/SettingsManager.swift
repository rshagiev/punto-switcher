import Foundation
import ServiceManagement

/// Manages application settings using UserDefaults
final class SettingsManager {

    // MARK: - Keys

    private enum Keys {
        static let isEnabled = "isEnabled"
        static let isFirstLaunch = "isFirstLaunch"
        static let showInMenuBar = "showInMenuBar"
        static let launchAtLogin = "launchAtLogin"
        static let convertLayoutHotkey = "convertLayoutHotkey"
        static let toggleCaseHotkey = "toggleCaseHotkey"
        static let switchLayoutAfterConversion = "switchLayoutAfterConversion"
    }

    // MARK: - Properties

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Whether the app functionality is enabled
    var isEnabled: Bool {
        get { defaults.bool(forKey: Keys.isEnabled) }
        set { defaults.set(newValue, forKey: Keys.isEnabled) }
    }

    /// Whether this is the first launch
    var isFirstLaunch: Bool {
        get {
            // Default to true if key doesn't exist
            if defaults.object(forKey: Keys.isFirstLaunch) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.isFirstLaunch)
        }
        set { defaults.set(newValue, forKey: Keys.isFirstLaunch) }
    }

    /// Whether to show the icon in the menu bar
    var showInMenuBar: Bool {
        get {
            // Default to true
            if defaults.object(forKey: Keys.showInMenuBar) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.showInMenuBar)
        }
        set { defaults.set(newValue, forKey: Keys.showInMenuBar) }
    }

    /// Whether to launch at login
    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
            updateLoginItem(enabled: newValue)
        }
    }

    /// Hotkey for converting layout
    var convertLayoutHotkey: Hotkey {
        get {
            guard let data = defaults.data(forKey: Keys.convertLayoutHotkey),
                  let hotkey = try? decoder.decode(Hotkey.self, from: data) else {
                return Hotkey.defaultConvertLayout
            }
            return hotkey
        }
        set {
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: Keys.convertLayoutHotkey)
            }
        }
    }

    /// Hotkey for toggling case
    var toggleCaseHotkey: Hotkey {
        get {
            guard let data = defaults.data(forKey: Keys.toggleCaseHotkey),
                  let hotkey = try? decoder.decode(Hotkey.self, from: data) else {
                return Hotkey.defaultToggleCase
            }
            return hotkey
        }
        set {
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: Keys.toggleCaseHotkey)
            }
        }
    }

    /// Переключать раскладку после конвертации
    var switchLayoutAfterConversion: Bool {
        get { defaults.bool(forKey: Keys.switchLayoutAfterConversion) }
        set { defaults.set(newValue, forKey: Keys.switchLayoutAfterConversion) }
    }

    // MARK: - Initialization

    init() {
        // Register defaults
        defaults.register(defaults: [
            Keys.isEnabled: true,
            Keys.showInMenuBar: true,
            Keys.launchAtLogin: false,
            Keys.switchLayoutAfterConversion: false
        ])
    }

    // MARK: - Reset to Defaults

    func resetConvertLayoutHotkey() {
        convertLayoutHotkey = Hotkey.defaultConvertLayout
    }

    func resetToggleCaseHotkey() {
        toggleCaseHotkey = Hotkey.defaultToggleCase
    }

    // MARK: - Launch at Login

    private func updateLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update login item: \(error)")
            }
        } else {
            // For older macOS versions, use the deprecated API
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.rshagiev.Punto"
            SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled)
        }
    }
}
