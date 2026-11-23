import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    let settings = Settings()
    lazy var engine = KeyboardEngine(settings:settings)
    lazy var correction = LunaCorrection(settings:settings,engine:engine)
    let analytics = UsageAnalytics()
    lazy var support = SupportPrompt(analytics: analytics)
    lazy var updates = Updates(analytics: analytics)
    private let statusMenu = NSMenu()
    private static let keyboardSetupExpiresKey = "keyboardSetupExpiresAt"
    private lazy var permissionSetup = PermissionSetup { [weak self] in self?.clearKeyboardSetup() }
    private var isTerminating = false
    private struct AppCardItems {
        let application: NSRunningApplication
        let tile: NSMenuItem
        let automatic: NSMenuItem
        let pause: NSMenuItem
    }

    private var supportMenuItem: NSMenuItem?
    private var isStatusMenuOpen = false
    private var appCardExpanded = false
    private var appCard: AppCardItems?
    private var lunaMenuItems: [NSMenuItem] = []
    private weak var highlightedAppCardRow: AppMenuCardRow?
    private var supportSetupComplete: Bool {
        settings.running && (analytics.existingInstall || !analytics.isConfigured || analytics.choice != nil)
    }
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
            guard let self else { return }
            self.analytics.noteActiveDay()
            self.recordSupportConversion()
        }
        engine.onLearning = { [weak self] word in
            guard let self else { return }
            let alert = NSAlert(); alert.messageText = "Запоминать отменённые исправления?"; alert.informativeText = "Punto будет добавлять такие слова в исключения. Первое слово: «\(word)»."; alert.addButton(withTitle:"Включить"); alert.addButton(withTitle:"Не сейчас"); alert.showsSuppressionButton = true; alert.suppressionButton?.title = "Больше не предлагать"
            let previousApp = NSWorkspace.shared.frontmostApplication
            NSApp.activate(ignoringOtherApps:true)
            let accepted = alert.runModal() == .alertFirstButtonReturn
            self.engine.resolveLearningPrompt(for: word, accepted: accepted,
                                             suppressFuturePrompts: alert.suppressionButton?.state == .on)
            previousApp?.activate()
        }
        if CommandLine.arguments.contains("--enable-login") { settings.setLogin(true) }
        updateStatus()
        analytics.prepareInstall(existing: settings.existingInstall)
        analytics.start(keyboardReady: false)
        menuNeedsUpdate(statusMenu)
        updates.start(automaticallyCheck: settings.value.checkUpdates)
        // The original keeps handling input until the user explicitly switches to this app.
        engine.start()
        if let blocker = settings.keyboardBlocker,
           blocker != .originalPuntoRunning || !KeyboardPermission.accessibility.isGranted {
            showSettings()
        }
        if case .permission = settings.keyboardBlocker,
           let expiry = UserDefaults.standard.object(forKey: Self.keyboardSetupExpiresKey) as? Date, expiry > Date() {
            continueKeyboardSetup()
        } else {
            clearKeyboardSetup()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if settings.keyboardBlocker != nil, window?.isVisible == true { engine.start() }
    }

    private func updateStatus() {
        status.button?.appearsDisabled = !settings.running
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === statusMenu, !isStatusMenuOpen else { return }
        menu.removeAllItems()
        appCardExpanded = false
        appCard = nil
        lunaMenuItems.removeAll()
        let application = NSWorkspace.shared.frontmostApplication
        let mode = application?.bundleIdentifier.map { settings.appMode(for: $0) } ?? .global
        if let application, let id = application.bundleIdentifier, !application.isTerminated,
           application.activationPolicy != .prohibited,
           application.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            let name = application.localizedName ?? id
            let tile = item(name, icon: "app", #selector(toggleAppCard(_:)), key: "0")
            tile.keyEquivalentModifierMask = [.option]
            tile.representedObject = application
            tile.view = AppMenuTile(application: application, title: name) { [weak self] in
                self?.toggleAppCard(tileTarget: application)
            }

            let automatic = item("Автопереключение для \(name)", icon: "bolt", #selector(toggleAppAutomatic(_:)), key: "1")
            automatic.keyEquivalentModifierMask = [.option]
            automatic.representedObject = application
            automatic.view = AppMenuAutomaticRow(appName: name) { [weak self] enabled in
                self?.setAppAutomatic(enabled, for: application)
            }

            let pause = item("Приостановить Punto", icon: "pause.circle", #selector(toggleAppPause(_:)), key: "2")
            pause.keyEquivalentModifierMask = [.option]
            pause.representedObject = application
            pause.view = AppMenuPauseRow { [weak self] in self?.changeAppPause(for: application) }

            appCard = AppCardItems(application: application, tile: tile, automatic: automatic, pause: pause)
            updateAppCard()
            menu.addItem(tile)
            menu.addItem(automatic)
            menu.addItem(pause)
            menu.addItem(.separator())
        }

        let auto = item("Автопереключение по умолчанию", icon: "arrow.left.arrow.right", #selector(toggleAuto))
        auto.state = settings.value.automatic ? .on : .off
        menu.addItem(auto)
        let sounds = item("Звуковые эффекты", icon: "speaker.wave.2", #selector(toggleSound))
        sounds.state = settings.value.sound ? .on : .off
        menu.addItem(sounds)
        menu.addItem(.separator())
        for (title, icon, action) in [("Luna: исправить сразу", "sparkles", #selector(proofread(_:))),
                                      ("Luna: проверить перед заменой", "text.magnifyingglass", #selector(reviewText(_:)))] {
            let actionItem = item(title, icon: icon, action)
            actionItem.isEnabled = mode.manualEnabled && settings.running && settings.value.lunaEnabled
            actionItem.representedObject = application?.processIdentifier
            lunaMenuItems.append(actionItem)
            menu.addItem(actionItem)
        }
        menu.addItem(item("Последнее исправление", icon: "clock.arrow.circlepath", #selector(lastCorrection)))
        menu.addItem(.separator())
        menu.addItem(item("Настройки…", icon: "gearshape", #selector(showSettings), key: ","))
        menu.addItem(item("О программе", icon: "info.circle", #selector(showAbout)))
        let github = item(SupportMenuRow.title, icon: "star", #selector(openSupportLink))
        supportMenuItem = github
        menu.addItem(github)
        updateSupportMenuItem()
        menu.addItem(item("Выйти", icon: "power", #selector(quit), key: "q"))
    }

    func menuWillOpen(_ menu: NSMenu) {
        guard menu === statusMenu else { return }
        isStatusMenuOpen = true
        support.closePopover()
        updateSupportMenuItem()
    }

    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        guard menu === statusMenu else { return }
        highlightedAppCardRow?.setHighlighted(false)
        highlightedAppCardRow = item?.view as? AppMenuCardRow
        highlightedAppCardRow?.setHighlighted(true)
    }

    func menuDidClose(_ menu: NSMenu) {
        guard menu === statusMenu else { return }
        highlightedAppCardRow?.setHighlighted(false)
        highlightedAppCardRow = nil
        isStatusMenuOpen = false
        appCardExpanded = false
    }

    private func updateSupportMenuItem() {
        let id = supportSetupComplete ? support.visibleID : nil
        var image = NSImage(systemSymbolName: id == nil ? "star" : "star.fill", accessibilityDescription: nil)
        if id != nil {
            image = image?.withSymbolConfiguration(.init(paletteColors: [.systemOrange]))
            image?.isTemplate = false
        }
        supportMenuItem?.image = image
        if isStatusMenuOpen, let id { support.shown(id) }
    }

    private func recordSupportConversion() {
        guard support.recordConversion(), supportSetupComplete else { return }
        if isStatusMenuOpen {
            updateSupportMenuItem()
        } else {
            let todayIsVisible = window?.isVisible == true && settings.selectedSection == "Сегодня"
            if !todayIsVisible, window?.isKeyWindow != true, let button = status.button {
                support.showPopover(under: button)
            }
        }
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
    @objc private func toggleAppCard(_ sender: NSMenuItem) {
        guard let application = sender.representedObject as? NSRunningApplication else { return }
        toggleAppCard(tileTarget: application)
    }

    private func toggleAppCard(tileTarget application: NSRunningApplication) {
        guard isStatusMenuOpen, !application.isTerminated,
              appCard?.application.processIdentifier == application.processIdentifier else { return }
        appCardExpanded.toggle()
        updateAppCard()
    }

    private func updateAppCard() {
        guard let card = appCard, let id = card.application.bundleIdentifier else { return }
        let mode = settings.appMode(for: id)
        let available = mode.manualEnabled && settings.value.canConvertLayout
        let automatic = available && mode.automaticEnabled(global: settings.value.automatic)
        let paused = mode == .disabled
        let subtitle: String
        if paused {
            subtitle = "Punto приостановлен"
        } else if !available {
            subtitle = "Конвертация недоступна"
        } else {
            let label = automatic ? "Автоматически" : "Только вручную"
            subtitle = mode == .global ? "\(label) · по умолчанию" : label
        }

        (card.tile.view as? AppMenuTile)?.update(subtitle: subtitle, expanded: appCardExpanded)
        card.automatic.state = automatic ? .on : .off
        card.automatic.isEnabled = available
        (card.automatic.view as? AppMenuAutomaticRow)?.update(automatic: automatic, available: available)
        let pauseTitle = paused ? "Возобновить Punto" : "Приостановить Punto"
        card.pause.title = pauseTitle
        (card.pause.view as? AppMenuPauseRow)?.update(title: pauseTitle, paused: paused)
        // Keep the tracked menu and its header. AppKit lays out the rows as
        // their visibility changes, without reopening the status menu.
        card.automatic.isHidden = !appCardExpanded
        card.pause.isHidden = !appCardExpanded

        for item in lunaMenuItems {
            item.isEnabled = mode.manualEnabled && settings.running && settings.value.lunaEnabled
        }
    }

    @objc private func toggleAppAutomatic(_ sender: NSMenuItem) {
        guard let application = sender.representedObject as? NSRunningApplication else { return }
        setAppAutomatic(sender.state != .on, for: application)
    }

    private func setAppAutomatic(_ enabled: Bool, for application: NSRunningApplication) {
        guard let id = application.bundleIdentifier, !application.isTerminated, settings.value.canConvertLayout,
              settings.appMode(for: id).manualEnabled else { return }
        settings.setAppMode(enabled ? .automatic : .manual, for: id)
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == id { engine.reset() }
        updateAppCard()
    }

    @objc private func toggleAppPause(_ sender: NSMenuItem) {
        guard let application = sender.representedObject as? NSRunningApplication else { return }
        changeAppPause(for: application)
    }

    private func changeAppPause(for application: NSRunningApplication) {
        guard let id = application.bundleIdentifier, !application.isTerminated else { return }
        settings.toggleAppPause(for: id)
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == id { engine.reset() }
        updateAppCard()
    }

    @objc private func openSupportLink() {
        statusMenu.cancelTracking()
        if supportSetupComplete, support.visibleID != nil {
            support.openInvitation()
        } else {
            NSWorkspace.shared.open(SupportPrompt.repository)
        }
    }

    @objc func showAbout() { openSettings(section: "О программе") }
    @objc func showSettings() { openSettings(section: settings.running ? "Сегодня" : "Основные") }
    private func openSettings(section: String) {
        support.closePopover()
        settings.selectedSection = section
        if window == nil {
            let view = SettingsView(settings: settings, activity: settings.activity, engine: engine, updates: updates,
                                    analytics: analytics, support: support, onLunaDemo: { [weak self] in self?.correction.demo() },
                                    onPermissionSetup: { [weak self] in self?.beginKeyboardSetup() })
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
    private func beginKeyboardSetup() {
        // macOS may quit and reopen Punto after an input permission changes.
        UserDefaults.standard.set(Date().addingTimeInterval(20 * 60), forKey: Self.keyboardSetupExpiresKey)
        continueKeyboardSetup()
    }

    private func continueKeyboardSetup() {
        settings.message = ""
        engine.start()
        guard case .permission(let permission) = settings.keyboardBlocker else {
            permissionSetup.dismiss()
            return
        }
        if !permissionSetup.show(permission, onGrant: { [weak self] in self?.continueKeyboardSetup() }) {
            permissionSetup.dismiss()
            settings.message = "Не удалось открыть настройки macOS. Откройте «Конфиденциальность и безопасность» и разрешите доступ для Punto Native."
        }
    }

    private func clearKeyboardSetup() {
        UserDefaults.standard.removeObject(forKey: Self.keyboardSetupExpiresKey)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow, closing === window else { return }
        if !isTerminating { permissionSetup.dismiss() }
        window = nil
        NSApp.setActivationPolicy(correction.window?.isVisible == true ? .regular : .accessory)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication) -> Bool { false }
    @objc func quit() { NSApp.terminate(nil) }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        isTerminating = true
        permissionSetup.close()
        correction.cancel(); engine.stop(); settings.activity.flush(); settings.flush()
        return .terminateNow
    }
    func applicationShouldHandleReopen(_ sender:NSApplication,hasVisibleWindows:Bool) -> Bool { showSettings(); return true }
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
