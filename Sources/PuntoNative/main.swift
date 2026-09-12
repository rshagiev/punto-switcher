import AppKit
import ApplicationServices
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let settings = Settings()
    lazy var engine = KeyboardEngine(settings:settings)
    lazy var correction = LunaCorrection(settings:settings,engine:engine)
    lazy var updates = Updates(settings:settings)
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
        correction.onVisibility = { [weak self] visible in
            NSApp.setActivationPolicy(visible || self?.window?.isVisible == true ? .regular : .accessory)
        }
        engine.onProofread = { [weak self] quick in self?.correction.request(quick:quick) }
        engine.onUserInteraction = { [weak self] in self?.correction.invalidateQuick() }
        engine.onStatus = { [weak self] in self?.updateMenu() }
        engine.onLearning = { [weak self] word in
            guard let self else { return }
            let alert = NSAlert(); alert.messageText = "Запоминать отменённые исправления?"; alert.informativeText = "Punto будет добавлять такие слова в исключения. Первое слово: «\(word)»."; alert.addButton(withTitle:"Включить"); alert.addButton(withTitle:"Не сейчас"); alert.showsSuppressionButton = true; alert.suppressionButton?.title = "Больше не предлагать"
            let previousApp = NSWorkspace.shared.frontmostApplication
            NSApp.activate(ignoringOtherApps:true)
            if alert.runModal() == .alertFirstButtonReturn { self.settings.value.learning = true; self.engine.learn(word) }
            if alert.suppressionButton?.state == .on { self.settings.value.showLearningPrompt = false }
            previousApp?.activate()
        }
        if CommandLine.arguments.contains("--enable-login") { settings.setLogin(true) }
        updateMenu()
        // The original keeps handling input until the user explicitly switches to this app.
        if NSRunningApplication.runningApplications(withBundleIdentifier:"ru.yandex.desktop.PuntoSwitcher").isEmpty { engine.start() }
        else { settings.permission = AXIsProcessTrusted(); settings.message = "Punto Яндекса запущен. Завершите его, затем нажмите «Начать работу»." }
        if !settings.permission { showSettings() }
    }
    func updateMenu() {
        let menu = NSMenu()
        let auto = NSMenuItem(title:"Переключать раскладку автоматически",action:#selector(toggleAuto),keyEquivalent:""); auto.state = settings.value.automatic ? .on : .off; auto.target = self; menu.addItem(auto)
        let sounds = NSMenuItem(title:"Использовать звуковые эффекты",action:#selector(toggleSound),keyEquivalent:""); sounds.state = settings.value.sound ? .on : .off; sounds.target = self; menu.addItem(sounds)
        menu.addItem(.separator())
        for (title,action) in [("Luna: исправить сразу",#selector(proofread)),("Luna: проверить перед заменой",#selector(reviewText)),("Последнее исправление",#selector(lastCorrection))] {
            let item = NSMenuItem(title:title,action:action,keyEquivalent:""); item.target = self; menu.addItem(item)
        }
        menu.addItem(.separator())
        for (title,action,key) in [("Настройки…",#selector(showSettings),","),("О программе",#selector(showAbout),""),("Выйти",#selector(quit),"q")] {
            let item = NSMenuItem(title:title,action:action,keyEquivalent:key); item.target = self; menu.addItem(item)
        }
        status.menu = menu
        status.button?.appearsDisabled = !settings.running
    }
    @objc func proofread() { correction.request(quick:true) }
    @objc func reviewText() { correction.request() }
    @objc func lastCorrection() { correction.showLast() }
    @objc func toggleAuto() { settings.value.automatic.toggle(); engine.reset(); updateMenu() }
    @objc func toggleSound() { settings.value.sound.toggle(); updateMenu() }
    @objc func showAbout() { settings.selectedSection = "О программе"; showSettings() }
    @objc func showSettings() {
        if window == nil {
            let view = SettingsView(settings:settings,engine:engine,updates:updates,onLunaDemo:{ [weak self] in self?.correction.demo() })
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
        NSApp.setActivationPolicy(correction.window?.isVisible == true ? .regular : .accessory)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication) -> Bool { false }
    @objc func quit() { NSApp.terminate(nil) }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply { correction.cancel(); engine.stop(); settings.flush(); return .terminateNow }
    func applicationShouldHandleReopen(_ sender:NSApplication,hasVisibleWindows:Bool) -> Bool { showSettings(); return true }
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
