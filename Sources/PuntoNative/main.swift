import AppKit
import ApplicationServices
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    let settings = Settings()
    lazy var engine = KeyboardEngine(settings:settings)
    lazy var correction = LunaCorrection(settings:settings,engine:engine)
    let analytics = UsageAnalytics()
    lazy var updates = Updates(analytics: analytics)
    private let statusMenu = NSMenu()
    var status: NSStatusItem!
    var window: NSWindow?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title:"Punto Native")
        let preferences = NSMenuItem(title:"Настройки…",action:#selector(showSettings),keyEquivalent:",")
        preferences.target = self; appMenu.addItem(preferences)
        appMenu.addItem(NSMenuItem(title:"Закрыть окно",action:#selector(NSWindow.performClose(_:)),keyEquivalent:"w"))
        appMenu.addItem(.separator())
        let hide = NSMenuItem(title:"Скрыть Punto Native",action:#selector(NSApplication.hide(_:)),keyEquivalent:"h")
        hide.target = NSApp; appMenu.addItem(hide)
        let quit = NSMenuItem(title:"Выйти из Punto Native",action:#selector(quit),keyEquivalent:"q")
        quit.target = self; appMenu.addItem(quit)
        appItem.submenu = appMenu; mainMenu.addItem(appItem); NSApp.mainMenu = mainMenu
        status = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
        status.button?.image = NSImage(systemSymbolName:"character.cursor.ibeam",accessibilityDescription:"Punto Native")
        statusMenu.delegate = self
        statusMenu.autoenablesItems = false
        status.menu = statusMenu
        correction.onVisibility = { [weak self] visible in
            NSApp.setActivationPolicy(visible || self?.window?.isVisible == true ? .regular : .accessory)
        }
        engine.onProofread = { [weak self] quick in self?.correction.request(quick:quick) }
        engine.onUserInteraction = { [weak self] in self?.correction.invalidateQuick() }
        engine.onStatus = { [weak self] in
            self?.updateStatus()
            if self?.settings.running == true { self?.analytics.noteKeyboardReady() }
        }
        engine.onLayoutConversion = { [weak self] in
            self?.analytics.noteActiveDay()
        }
        engine.onLearning = { [weak self] word in
            guard let self else { return }
            let alert = NSAlert(); alert.messageText = "Запоминать отменённые исправления?"; alert.informativeText = "Punto будет добавлять такие слова в исключения. Первое слово: «\(word)»."; alert.addButton(withTitle:"Включить"); alert.addButton(withTitle:"Не сейчас"); alert.showsSuppressionButton = true; alert.suppressionButton?.title = "Больше не предлагать"
            let previousApp = NSWorkspace.shared.frontmostApplication
            NSApp.activate(ignoringOtherApps:true)
            if alert.runModal() == .alertFirstButtonReturn {
                self.settings.value.learning = true
                self.engine.learn(word)
            } else {
                self.settings.value.learningCounts.removeValue(forKey: word)
            }
            if alert.suppressionButton?.state == .on { self.settings.value.showLearningPrompt = false }
            previousApp?.activate()
        }
        if CommandLine.arguments.contains("--enable-login") { settings.setLogin(true) }
        updateStatus()
        analytics.prepareInstall(existing: settings.existingInstall)
        analytics.start(keyboardReady: false)
        menuNeedsUpdate(statusMenu)
        updates.start(automaticallyCheck: settings.value.checkUpdates)
        // The original keeps handling input until the user explicitly switches to this app.
        if NSRunningApplication.runningApplications(withBundleIdentifier:"ru.yandex.desktop.PuntoSwitcher").isEmpty { engine.start() }
        else { settings.permission = AXIsProcessTrusted(); settings.message = "Punto Яндекса запущен. Завершите его, затем нажмите «Начать работу»." }
        if !settings.permission { showSettings() }
    }
    private func updateStatus() {
        status.button?.appearsDisabled = !settings.running
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === statusMenu else { return }
        menu.removeAllItems()
        let application = NSWorkspace.shared.frontmostApplication
        let bundleID = application?.bundleIdentifier
        let mode = bundleID.map { settings.appMode(for: $0) } ?? .global
        if let application, let id = bundleID, application.activationPolicy != .prohibited,
           application.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            let name = application.localizedName ?? id
            let shortName = name.count > 32 ? String(name.prefix(31)) + "…" : name
            let tile = NSMenuItem(title: name, action: nil, keyEquivalent: "")
            tile.view = AppMenuTile(application: application, title: name,
                                    subtitle: mode == .disabled ? "Punto отключён" : appModeLabel(mode))
            menu.addItem(tile)
            if mode != .disabled {
                let enabled = mode.automaticEnabled(global: settings.value.automatic) && settings.value.canConvertLayout
                let automatic = item(enabled ? "Выключить автоконвертацию" : "Включить автоконвертацию",
                                     icon: "bolt", #selector(toggleAppAutomatic(_:)))
                automatic.representedObject = id
                automatic.isEnabled = settings.value.canConvertLayout
                menu.addItem(automatic)
            }
            let pause = item(mode == .disabled ? "Включить Punto для \(shortName)" : "Отключить Punto для \(shortName)",
                             icon: mode == .disabled ? "play.circle" : "pause.circle", #selector(toggleAppPause(_:)))
            pause.representedObject = id
            menu.addItem(pause)
            menu.addItem(.separator())
        }

        let auto = item("Переключать раскладку автоматически", icon: "arrow.left.arrow.right", #selector(toggleAuto))
        auto.state = settings.value.automatic ? .on : .off
        menu.addItem(auto)
        let sounds = item("Использовать звуковые эффекты", icon: "speaker.wave.2", #selector(toggleSound))
        sounds.state = settings.value.sound ? .on : .off
        menu.addItem(sounds)
        menu.addItem(.separator())
        for (title, icon, action) in [("Luna: исправить сразу", "sparkles", #selector(proofread(_:))),
                                      ("Luna: проверить перед заменой", "text.magnifyingglass", #selector(reviewText(_:)))] {
            let actionItem = item(title, icon: icon, action)
            actionItem.isEnabled = mode.manualEnabled && settings.running && settings.value.lunaEnabled
            actionItem.representedObject = application?.processIdentifier
            menu.addItem(actionItem)
        }
        menu.addItem(item("Последнее исправление", icon: "clock.arrow.circlepath", #selector(lastCorrection)))
        menu.addItem(.separator())
        menu.addItem(item("Настройки…", icon: "gearshape", #selector(showSettings), key: ","))
        menu.addItem(item("О программе", icon: "info.circle", #selector(showAbout)))
        let star = item("Поставить звезду на GitHub", icon: "star.fill", #selector(openRepository))
        star.image?.isTemplate = false
        star.image = star.image?.withSymbolConfiguration(.init(paletteColors: [.systemOrange]))
        if #available(macOS 14.4, *) { star.subtitle = "Поддержать Punto Native" }
        menu.addItem(star)
        menu.addItem(item("Выйти", icon: "power", #selector(quit), key: "q"))
    }

    private func item(_ title: String, icon: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
        // macOS 27 hides default item images. The runtime check also permits builds with older SDKs.
        if item.responds(to: NSSelectorFromString("setPreferredImageVisibility:")) {
            item.setValue(1, forKey: "preferredImageVisibility") // NSMenuItemImageVisibility.visible
        }
        return item
    }

    @objc func proofread(_ sender: NSMenuItem) { requestLuna(sender, quick: true) }
    @objc func reviewText(_ sender: NSMenuItem) { requestLuna(sender, quick: false) }
    private func requestLuna(_ sender: NSMenuItem, quick: Bool) {
        guard let pid = sender.representedObject as? pid_t,
              NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else { return }
        correction.request(quick: quick)
    }

    @objc func lastCorrection() { correction.showLast() }
    @objc func toggleAuto() { settings.value.automatic.toggle(); engine.reset() }
    @objc func toggleSound() { settings.value.sound.toggle() }
    @objc func toggleAppAutomatic(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String, settings.value.canConvertLayout else { return }
        let mode = settings.appMode(for: id)
        guard mode.manualEnabled else { return }
        settings.setAppMode(mode.automaticEnabled(global: settings.value.automatic) ? .manual : .automatic, for: id)
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == id { engine.reset() }
    }
    @objc func toggleAppPause(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        settings.toggleAppPause(for: id)
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == id { engine.reset() }
    }
    @objc func openRepository() {
        guard let url = URL(string: "https://github.com/rshagiev/punto-switcher") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc func showAbout() { openSettings(section: "О программе") }
    @objc func showSettings() { openSettings(section: settings.running ? "Сегодня" : "Основные") }
    private func openSettings(section: String) {
        settings.selectedSection = section
        if window == nil {
            let view = SettingsView(settings: settings, activity: settings.activity, engine: engine, updates: updates,
                                    analytics: analytics, onLunaDemo: { [weak self] in self?.correction.demo() })
            let w = NSWindow(contentRect:NSRect(x:0,y:0,width:900,height:680),styleMask:[.titled,.closable,.miniaturizable,.resizable,.fullSizeContentView],backing:.buffered,defer:false)
            w.title = "Punto Native"; w.titlebarAppearsTransparent = true; w.isReleasedWhenClosed = false; w.delegate = self
            let hosting = NSHostingView(rootView:GeometryReader { geometry in view.frame(width:geometry.size.width,height:geometry.size.height) })
            hosting.sizingOptions = []
            w.contentMinSize = NSSize(width:810,height:600)
            w.contentView = hosting; w.center(); w.setFrameAutosaveName("settings"); window = w
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps:true); window?.makeKeyAndOrderFront(nil)
    }
    func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow, closing === window else { return }
        window = nil
        NSApp.setActivationPolicy(correction.window?.isVisible == true ? .regular : .accessory)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication) -> Bool { false }
    @objc func quit() { NSApp.terminate(nil) }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        correction.cancel(); engine.stop(); settings.activity.flush(); settings.flush()
        return .terminateNow
    }
    func applicationShouldHandleReopen(_ sender:NSApplication,hasVisibleWindows:Bool) -> Bool { showSettings(); return true }
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
