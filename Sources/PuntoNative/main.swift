import AppKit
import ApplicationServices
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    let settings = Settings()
    lazy var engine = KeyboardEngine(settings:settings)
    lazy var correction = LunaCorrection(settings:settings,engine:engine)
    let analytics = UsageAnalytics()
    lazy var support = SupportPrompt(analytics: analytics)
    lazy var updates = Updates(analytics: analytics)
    private let statusMenu = NSMenu()
    private var supportImpression: UUID?
    private var isStatusMenuOpen = false
    private var appCardExpanded = false
    private var appCardTarget: NSRunningApplication?
    private var pendingAppMenuReopen: UUID?
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
        let application = pendingAppMenuReopen != nil ? appCardTarget : NSWorkspace.shared.frontmostApplication
        let bundleID = application?.bundleIdentifier
        let mode = bundleID.map { settings.appMode(for: $0) } ?? .global
        if let application, let id = bundleID, !application.isTerminated, application.activationPolicy != .prohibited,
           application.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            appCardTarget = application
            let name = application.localizedName ?? id
            let automatic = mode.automaticEnabled(global: settings.value.automatic) && settings.value.canConvertLayout
            let subtitle = switch mode {
            case .global: automatic ? "Автоматически · по умолчанию" : "Только вручную · по умолчанию"
            case .automatic: automatic ? "Автоматически" : "Только вручную"
            case .manual: "Только вручную"
            case .disabled: "Punto приостановлен"
            }
            let tile = item(name, icon: "app", #selector(toggleAppCard(_:)), key: "0")
            tile.keyEquivalentModifierMask = [.option]
            tile.representedObject = application
            tile.state = appCardExpanded ? .on : .off
            tile.view = AppMenuTile(application: application, title: name, subtitle: subtitle,
                                    expanded: appCardExpanded, toggleDisclosure: { [weak self] in
                                        guard let self else { return }
                                        self.setAppCardExpanded(!self.appCardExpanded, for: application)
                                    })
            menu.addItem(tile)
            if appCardExpanded {
                let autoItem = item("Автопереключение для \(name)", icon: "bolt", #selector(toggleAppAutomatic(_:)), key: "1")
                autoItem.keyEquivalentModifierMask = [.option]
                let available = mode.manualEnabled && settings.value.canConvertLayout
                autoItem.representedObject = application
                autoItem.state = automatic ? .on : .off
                autoItem.isEnabled = available
                autoItem.view = AppMenuAutomaticRow(appName: name, automatic: automatic, available: available) { [weak self] enabled in
                    self?.setAppAutomatic(enabled, for: application)
                }
                menu.addItem(autoItem)

                let paused = mode == .disabled
                let pauseTitle = paused ? "Возобновить Punto" : "Приостановить Punto"
                let pauseItem = item(pauseTitle, icon: paused ? "play.circle" : "pause.circle", #selector(toggleAppPause(_:)), key: "2")
                pauseItem.keyEquivalentModifierMask = [.option]
                pauseItem.representedObject = application
                pauseItem.view = AppMenuPauseRow(title: pauseTitle, paused: paused) { [weak self] in
                    self?.changeAppPause(for: application)
                }
                menu.addItem(pauseItem)
            }
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
            menu.addItem(actionItem)
        }
        menu.addItem(item("Последнее исправление", icon: "clock.arrow.circlepath", #selector(lastCorrection)))
        menu.addItem(.separator())
        menu.addItem(item("Настройки…", icon: "gearshape", #selector(showSettings), key: ","))
        menu.addItem(item("О программе", icon: "info.circle", #selector(showAbout)))
        supportImpression = nil
        insertSupportItem(at: menu.numberOfItems)
        menu.addItem(item("Выйти", icon: "power", #selector(quit), key: "q"))
    }

    func menuWillOpen(_ menu: NSMenu) {
        guard menu === statusMenu else { return }
        isStatusMenuOpen = true
        pendingAppMenuReopen = nil
        support.closePopover()
        if let id = supportImpression { support.shown(id) }
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
        if pendingAppMenuReopen == nil {
            appCardExpanded = false
            appCardTarget = nil
        }
    }

    private func insertSupportItem(at index: Int) {
        guard supportImpression == nil, supportSetupComplete, let id = support.visibleID else { return }
        let supportItem = item(SupportMenuRow.title, icon: "star.fill", #selector(openInvitation))
        if #available(macOS 14.4, *) {
            supportItem.image?.isTemplate = false
            supportItem.image = supportItem.image?.withSymbolConfiguration(.init(paletteColors: [.systemOrange]))
            supportItem.subtitle = SupportMenuRow.subtitle
        } else {
            supportItem.view = SupportMenuRow(target: self, open: #selector(openInvitation))
        }
        statusMenu.insertItem(supportItem, at: index)
        supportImpression = id
    }

    private func recordSupportConversion() {
        guard support.recordConversion(), supportSetupComplete else { return }
        if isStatusMenuOpen {
            insertSupportItem(at: max(0, statusMenu.numberOfItems - 1))
            if let id = supportImpression { support.shown(id) }
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
        setAppCardExpanded(sender.state != .on, for: application)
    }

    private func setAppCardExpanded(_ expanded: Bool, for application: NSRunningApplication) {
        guard !application.isTerminated else { return }
        appCardTarget = application
        appCardExpanded = expanded
        refreshAppMenu()
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
        setAppCardExpanded(true, for: application)
    }

    @objc private func toggleAppPause(_ sender: NSMenuItem) {
        guard let application = sender.representedObject as? NSRunningApplication else { return }
        changeAppPause(for: application)
    }

    private func changeAppPause(for application: NSRunningApplication) {
        guard let id = application.bundleIdentifier, !application.isTerminated else { return }
        settings.toggleAppPause(for: id)
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == id { engine.reset() }
        setAppCardExpanded(true, for: application)
    }

    private func refreshAppMenu() {
        guard let button = status.button, pendingAppMenuReopen == nil else { return }
        // AppKit sizes a custom menu item before tracking. Reopen at the status
        // button to apply the new height while keeping the original app target.
        let reopen = UUID()
        pendingAppMenuReopen = reopen
        statusMenu.cancelTrackingWithoutAnimation()
        DispatchQueue.main.async { [weak self, weak button] in
            guard let self, self.pendingAppMenuReopen == reopen else { return }
            button?.performClick(nil)
            // A nested tracking loop can already have scheduled a different reopen.
            if self.pendingAppMenuReopen == reopen {
                self.pendingAppMenuReopen = nil
                self.appCardExpanded = false
                self.appCardTarget = nil
            }
        }
    }

    @objc func openInvitation() { statusMenu.cancelTracking(); support.openInvitation() }

    @objc func showAbout() { openSettings(section: "О программе") }
    @objc func showSettings() { openSettings(section: settings.running ? "Сегодня" : "Основные") }
    private func openSettings(section: String) {
        support.closePopover()
        settings.selectedSection = section
        if window == nil {
            let view = SettingsView(settings: settings, activity: settings.activity, engine: engine, updates: updates,
                                    analytics: analytics, support: support, onLunaDemo: { [weak self] in self?.correction.demo() })
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
