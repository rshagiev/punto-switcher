import AppKit
import Combine
import ServiceManagement
import PuntoCore

struct Preferences: Codable {
    var lunaEnabled = true
    static let lunaReviewShortcut = Shortcut(key:15,modifiers:Shortcut.control | Shortcut.option | Shortcut.command | Shortcut.shift)
    static let lunaShortcut = Shortcut(key:15,modifiers:Shortcut.control | Shortcut.option | Shortcut.command)
    var checkUpdates = true
    var noRepeatCorrection = false
    var automatic = false
    var showConversionFeedback = true
    var appProfiles: [String:AppMode] = [:]
    var sound = false
    var rememberLayout = false
    var switchAfterSelection = true
    var excludeManual = false
    var noTabEnter = false
    var cancelKeys: Set<UInt16> = []
    var learning = false
    var learningCounts: [String:Int] = [:]
    var showLearningPrompt = true
    var english = "com.apple.keylayout.ABC"
    var russian = "com.apple.keylayout.Russian"
    var exceptions: [String] = []
    var rules: [UserRule] = []
    var shortcuts: [Shortcut] = [Shortcut(), Shortcut(modifiers: Shortcut.command | Shortcut.option | Shortcut.shift), Shortcut(key: 6, modifiers: Shortcut.command | Shortcut.shift), Shortcut(), Self.lunaShortcut, Self.lunaReviewShortcut]
    var sounds: Set<String> = ["ru", "en", "selection", "auto", "undo", "misprint"]
}

final class Settings: ObservableObject {
    @Published var value: Preferences { didSet { save() } }
    @Published var selectedSection = "Основные"
    @Published var permission = false
    @Published var running = false
    @Published var message = ""
    @Published var recording: Int?
    @Published var symbols = 0
    @Published var switches = 0
    @Published var manual = 0
    @Published var loginError = ""
    let folder = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/PuntoNative")
    private var saveTask: DispatchWorkItem?
    init() {
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/PuntoNative/settings.json")
        if let data = try? Data(contentsOf: url), var object = (try? JSONSerialization.jsonObject(with:data)) as? [String:Any] {
            if object["lunaEnabled"] == nil { object["lunaEnabled"] = true }
            if object["showConversionFeedback"] == nil { object["showConversionFeedback"] = true }
            if object["appProfiles"] == nil {
                let mode = object["excludeManual"] as? Bool == true ? "disabled" : "manual"
                object["appProfiles"] = Dictionary(uniqueKeysWithValues:Set(object["exceptions"] as? [String] ?? []).map { ($0,mode) })
            }
            if object["learningCounts"] == nil { object["learningCounts"] = [String:Int]() }
            if object["checkUpdates"] == nil { object["checkUpdates"] = true }
            if object["noRepeatCorrection"] == nil { object["noRepeatCorrection"] = false }
            if let migrated = try? JSONSerialization.data(withJSONObject:object), var p = try? JSONDecoder().decode(Preferences.self,from:migrated) {
                if p.shortcuts.count == 4 { p.shortcuts.append(Preferences.lunaShortcut) }
                if p.shortcuts.count == 5 { p.shortcuts.append(p.shortcuts.contains(Preferences.lunaReviewShortcut) ? Shortcut() : Preferences.lunaReviewShortcut) }
                value = p
            }
            else { value = Self.importOriginal() }
        }
        else { value = Self.importOriginal() }
        let d = UserDefaults.standard
        if d.string(forKey: "statisticsDay") == Self.day { symbols = d.integer(forKey: "symbols"); switches = d.integer(forKey: "switches"); manual = d.integer(forKey: "manual") }
    }
    static var day: String {
        let date = Calendar.current.dateComponents([.year,.month,.day], from: Date())
        return String(format:"%04d-%02d-%02d",date.year ?? 0,date.month ?? 0,date.day ?? 0)
    }
    func count(_ kind: String, amount: Int = 1) {
        let d = UserDefaults.standard
        if d.string(forKey: "statisticsDay") != Self.day { symbols = 0; switches = 0; manual = 0; d.set(Self.day, forKey: "statisticsDay") }
        switch kind { case "symbols": symbols += amount; case "switches": switches += amount; default: manual += amount }
    }
    func flush() {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if let d = try? JSONEncoder().encode(value) { try? d.write(to: folder.appendingPathComponent("settings.json"), options: .atomic) }
        let d = UserDefaults.standard
        d.set(Self.day, forKey: "statisticsDay"); d.set(symbols, forKey: "symbols"); d.set(switches, forKey: "switches"); d.set(manual, forKey: "manual")
    }
    private func save() { saveTask?.cancel(); let t = DispatchWorkItem { [weak self] in self?.flush() }; saveTask = t; DispatchQueue.main.asyncAfter(deadline: .now()+0.4, execute: t) }
    func setLogin(_ enabled: Bool) {
        do { if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }; loginError = "" }
        catch { loginError = error.localizedDescription }
    }
    static func importOriginal() -> Preferences {
        var p = Preferences()
        guard let d = UserDefaults(suiteName: "ru.yandex.punto")?.persistentDomain(forName: "ru.yandex.punto") else { return p }
        p.automatic = d["isAutocorrectionActive"] as? Bool ?? false
        p.sound = d["isSoundOn"] as? Bool ?? false
        p.checkUpdates = d["shouldCheckForUpdatesAutomatically"] as? Bool ?? true
        if let bits = d["enabledSounds"] as? Int {
            p.sounds = Set([("en",2),("ru",4),("misprint",8),("selection",16),("undo",32),("auto",64),("keystroke",384)].compactMap { bits & $0.1 != 0 ? $0.0 : nil })
        }
        if let apps = d["disabledApps"] as? [[String]] { p.exceptions = apps.compactMap { $0.count > 1 ? $0[1] : nil } }
        if let rows = d["userRulesDictionary"] as? [[Any]] {
            p.rules = rows.compactMap { row in
                guard row.count >= 4, let text = row[0] as? String, let bits = row[1] as? Int else { return nil }
                let regex = row.count > 4 && (row[4] as? Bool == true)
                let mode: UserRule.Mode = regex ? .regex : (bits & 4 != 0 ? .exact : (bits & 2 != 0 ? .prefix : .contains))
                var rule = UserRule(text:text,mode:mode,caseSensitive:bits & 8 != 0,switches:row[2] as? Bool ?? false)
                rule.enabled = row[3] as? Bool ?? true
                return rule
            }
        }
        p.rememberLayout = d["shouldRememberInputSourceForEachApp"] as? Bool ?? false
        p.switchAfterSelection = d["switchLayoutOnSelectedTextSwitch"] as? Bool ?? true
        p.excludeManual = d["CompletelyDisableInExceptionApps"] as? Bool ?? false
        p.noTabEnter = d["shouldNotAutoconvertWithTabOrEnter"] as? Bool ?? false
        if let mask = d["cancellingKeys"] as? Int {
            p.cancelKeys = Set([(UInt16(51),32),(117,64),(123,4),(124,2),(125,16),(126,8)].compactMap { mask & $0.1 != 0 ? $0.0 : nil })
        }
        p.noRepeatCorrection = d["shouldNotAutoconvertAfterConvertion"] as? Bool ?? false
        p.english = d["englishLayoutID"] as? String ?? p.english; p.russian = d["russianLayoutID"] as? String ?? p.russian
        if let learn = d["undoLearning"] as? [String: Any] { p.learningCounts = learn["undoDictionary"] as? [String:Int] ?? [:]; p.learning = learn["undoCollectionEnabled"] as? Bool ?? false; p.showLearningPrompt = learn["mustShowUndoWindow"] as? Bool ?? true }
        for (i,key) in ["shortcutSwitchAutocorrection", "shortcutCancelLayoutChange", "shortcutChangeCase", "shortcutChangeLayout"].enumerated() {
            guard let s = d[key] as? [String: Any] else { continue }
            var flags: UInt64 = 0
            for (k,b) in [("isCommandUsed",Shortcut.command),("isAltUsed",Shortcut.option),("isShiftUsed",Shortcut.shift),("isControlUsed",Shortcut.control)] where s[k] as? Bool == true { flags |= b }
            let code = s["charKeycode"] as? Int ?? 666
            p.shortcuts[i] = Shortcut(key: code == 666 ? nil : UInt16(clamping: code), modifiers: flags)
        }
        for id in p.exceptions { p.appProfiles[id] = p.excludeManual ? .disabled : .manual }
        return p
    }
}

func shortcutLabel(_ s: Shortcut) -> String {
    guard s.enabled else { return "Не задано" }
    var text = ""
    for (f,c) in [(Shortcut.control,"⌃"),(Shortcut.option,"⌥"),(Shortcut.shift,"⇧"),(Shortcut.command,"⌘")] where s.modifiers & f != 0 { text += c }
    if let k = s.key {
        let names: [UInt16:String] = [36:"↩",48:"⇥",49:"Пробел",51:"⌫",53:"⎋",117:"⌦",123:"←",124:"→",125:"↓",126:"↑"]
        text += names[k] ?? Layouts.keyName(k)
    }
    return text
}
