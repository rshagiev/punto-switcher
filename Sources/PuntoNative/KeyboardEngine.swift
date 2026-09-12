import AppKit
import Carbon
import OSLog
import PuntoCore

final class KeyboardEngine {
    private let log = Logger(subsystem:"dev.rshagiev.PuntoNative",category:"Keyboard")
    let settings: Settings
    let access = TextAccess()
    let feedback = ConversionFeedback()
    var pendingFeedback: (pid:pid_t,source:String)?
    let rules: AutoRules
    var tap: CFMachPort?
    var tapSource: CFRunLoopSource?
    var buffer = TypingBuffer()
    var chord = ChordTracker()
    var owner: Focus?
    var ownerPID: pid_t = 0
    var ownerSource = ""
    var undo: (before: String, after: String, suffix: String, focus: Focus, source: String, automatic: Bool)?
    var justConverted = false
    var busy = false
    var deferredEvents: [CGEvent] = []
    var replayInFlight = false
    var fenceCounter: Int64 = 0
    var pendingFence: Int64?
    var pendingLearningPrompt: String?
    var generation: UInt64 = 0
    var recordingPeak: UInt64 = 0
    var appLayouts: [String: String] = [:]
    var lastApp = ""
    var workspaceObserver: NSObjectProtocol?
    var inputSourceObserver: NSObjectProtocol?
    var lastInputSource = ""
    var silentSourceChange: String?
    var maintenance: Timer?
    var diagnosticTimer: Timer?
    var lastTag: Int64 = 0
    var lastFence: Int64 = 0
    var maxCallbackSeconds: Double = 0
    var tapDisableCount = 0
    var onProofread: ((Bool) -> Void)?
    var onUserInteraction: (() -> Void)?
    var onStatus: (() -> Void)?
    var onLearning: ((String) -> Void)?
    var suppressedKeys: Set<UInt16> = []
    var soundCache: [String: NSSound] = [:]
    init(settings: Settings) {
        self.settings = settings
        let root = Bundle.main.resourceURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources")
        rules = AutoRules(dictionary: (try? String(contentsOf: root.appendingPathComponent("ps.dat.txt"), encoding: .utf8)) ?? "", triggers: (try? String(contentsOf: root.appendingPathComponent("triggers.dat.txt"), encoding: .utf8)) ?? "")
        lastApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        lastInputSource = Layouts.currentID
        inputSourceObserver = DistributedNotificationCenter.default().addObserver(forName: Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String), object:nil, queue:.main) { [weak self] _ in self?.inputSourceChanged() }
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] _ in self?.appChanged() }
    }
    func start() {
        settings.permission = AXIsProcessTrusted()
        guard NSRunningApplication.runningApplications(withBundleIdentifier:"ru.yandex.desktop.PuntoSwitcher").isEmpty else { settings.message = "Сначала завершите Punto Яндекса"; return }
        guard settings.permission else {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            settings.message = "macOS ещё не предоставила Универсальный доступ этой сборке"
            return
        }
        guard tap == nil else { return }
        let mask = [CGEventType.keyDown,.keyUp,.flagsChanged,.leftMouseDown,.rightMouseDown,.otherMouseDown,.leftMouseUp,.rightMouseUp,.otherMouseUp,.leftMouseDragged,.rightMouseDragged,.otherMouseDragged,.scrollWheel].reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: { _,type,event,context in
            guard let context else { return Unmanaged.passUnretained(event) }
            return Unmanaged<KeyboardEngine>.fromOpaque(context).takeUnretainedValue().handle(type,event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque())
        guard let tap else { settings.message = "macOS не разрешила обработку клавиатуры"; settings.running = false; return }
        tapSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault,tap,0)
        CFRunLoopAddSource(CFRunLoopGetMain(),tapSource,.commonModes)
        CGEvent.tapEnable(tap: tap,enable: true)
        settings.running = true; settings.message = "Готов к работе"; onStatus?()
        if CommandLine.arguments.contains("--diagnostics") {
            diagnosticTimer = Timer.scheduledTimer(withTimeInterval:0.1,repeats:true) { [weak self] _ in
                guard let self else { return }
                let state: [String:Any] = ["feedback":self.feedback.diagnostics,"maxCallbackMilliseconds":self.maxCallbackSeconds * 1000,"tapDisableCount":self.tapDisableCount,"pid":ProcessInfo.processInfo.processIdentifier,"busy":self.busy,"queued":self.deferredEvents.count,"inFlight":self.replayInFlight,"pendingFence":String(self.pendingFence ?? 0,radix:16),"lastTag":String(self.lastTag,radix:16),"lastFence":String(self.lastFence,radix:16)]
                if let data = try? JSONSerialization.data(withJSONObject:state) { try? data.write(to:self.settings.folder.appendingPathComponent("diagnostics.json"),options:.atomic) }
            }
        }
        maintenance = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.settings.flush()
            if let tap = self.tap, !CGEvent.tapIsEnabled(tap: tap) { self.reset(); CGEvent.tapEnable(tap: tap,enable:true) }
        }
    }
    func stop() {
        feedback.hide(); pendingFeedback = nil
        diagnosticTimer?.invalidate(); diagnosticTimer = nil
        maintenance?.invalidate(); maintenance = nil
        if let tapSource { CFRunLoopRemoveSource(CFRunLoopGetMain(),tapSource,.commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
        tap = nil; tapSource = nil; reset(); access.finish(); settings.running = false
        pendingFence = nil; busy = false; replayInFlight = false
        let pending = deferredEvents; deferredEvents.removeAll()
        for event in pending { access.forward(event,throughEngine:false) }
    }
    func reset() { generation &+= 1; justConverted = false; buffer.reset(); undo = nil; owner = nil; ownerPID = 0; ownerSource = "" }
    func appChanged() {
        feedback.hide(); pendingFeedback = nil
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier != Bundle.main.bundleIdentifier { settings.recording = nil; recordingPeak = 0 }
        if settings.value.rememberLayout, !excluded(manual:true) {
            if let app = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
                lastApp = app
                if let id = appLayouts[app], id != Layouts.currentID { silentSourceChange = id; _ = Layouts.select(id) }
                else { appLayouts[app] = Layouts.currentID }
            }
        }
        reset(); chord.reset()
    }
    func inputSourceChanged() {
        let id = Layouts.currentID
        guard id != lastInputSource else { return }
        lastInputSource = id
        guard !excluded(manual:true) else { silentSourceChange = nil; return }
        if settings.value.rememberLayout, let app = NSWorkspace.shared.frontmostApplication?.bundleIdentifier { appLayouts[app] = id }
        let silent = silentSourceChange == id
        silentSourceChange = nil
        if !silent {
            if id == settings.value.russian { sound("ru") }
            else if id == settings.value.english { sound("en") }
        }
        if !busy && !ownerSource.isEmpty && ownerSource != id { reset() }
    }
    func sound(_ event: String) {
        guard settings.value.sound, settings.value.sounds.contains(event) else { return }
        let names = ["ru":"ru", "en":"en", "selection":"replace", "auto":"switch", "undo":"reverse", "keystroke": Layouts.currentID == settings.value.russian ? "typerus" : "typeeng", "misprint":"misprint"]
        let name = names[event] ?? event
        if soundCache[name] == nil, let url = Bundle.main.url(forResource:name,withExtension:"wav") { soundCache[name] = NSSound(contentsOf:url,byReference:true) }
        soundCache[name]?.play()
    }
    func switchLayout(silent: Bool = false) {
        let target = Layouts.currentID == settings.value.english ? settings.value.russian : settings.value.english
        if silent { silentSourceChange = target }
        if !Layouts.select(target) { silentSourceChange = nil; settings.message = "Выбранная раскладка недоступна" }
    }
    func drainInput() {
        guard !busy, !replayInFlight else { return }
        guard !deferredEvents.isEmpty else {
            if let word = pendingLearningPrompt {
                pendingLearningPrompt = nil
                DispatchQueue.main.async { [weak self] in self?.onLearning?(word) }
            }
            return
        }
        let next = deferredEvents.removeFirst()
        replayInFlight = true
        access.forward(next,throughEngine:true)
    }
    func finishEdit(_ tag: Int64) {
        guard pendingFence == tag else { return }
        pendingFence = nil; busy = false
        if let request = pendingFeedback { pendingFeedback = nil; showFeedback(pid:request.pid,source:request.source) }
        drainInput()
    }
    func showFeedback(pid:pid_t,source:String) {
        guard settings.value.showConversionFeedback else { return }
        let text = source == settings.value.russian ? "РУ" : "A"
        DispatchQueue.main.asyncAfter(deadline:.now()+0.04) { [weak self] in
            guard let self, self.settings.running, self.settings.value.showConversionFeedback, Layouts.currentID == source, !self.excluded(manual:true) else { return }
            self.feedback.show(text,pid:pid)
        }
    }
    func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        let started = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = CFAbsoluteTimeGetCurrent() - started
            maxCallbackSeconds = max(maxCallbackSeconds,elapsed)
            if elapsed > 0.05 { log.warning("Keyboard callback exceeded 50 ms") }
        }
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            tapDisableCount += 1
            log.error("Event tap was disabled by the system"); reset()
            pendingFence = nil; busy = false; replayInFlight = false
            if let tap { CGEvent.tapEnable(tap:tap,enable:true) }
            DispatchQueue.main.async { [weak self] in self?.drainInput() }
            return Unmanaged.passUnretained(event)
        }
        let tag = event.getIntegerValueField(.eventSourceUserData)
        lastTag = tag
        if tag >= TextAccess.fenceBase && tag < TextAccess.fenceBase + 0x100000000 {
            lastFence = tag
            finishEdit(tag)
            return nil
        }
        if tag == TextAccess.marker { return Unmanaged.passUnretained(event) }
        if [.keyDown,.leftMouseDown,.rightMouseDown,.otherMouseDown,.scrollWheel].contains(type) { onUserInteraction?() }
        let replayed = tag == TextAccess.replayMarker
        if replayed { replayInFlight = false }
        if busy || (!replayed && (replayInFlight || !deferredEvents.isEmpty)) {
            if let copy = event.copy() { deferredEvents.append(copy); return nil }
        }
        defer {
            if replayed { DispatchQueue.main.async { [weak self] in self?.drainInput() } }
        }
        if [.leftMouseDown,.rightMouseDown,.otherMouseDown,.scrollWheel].contains(type) { reset(); chord.reset(); return Unmanaged.passUnretained(event) }
        let key = UInt16(event.getIntegerValueField(.keyboardEventKeycode)), flags = event.flags.rawValue & Shortcut.mask
        if type == .keyUp { if suppressedKeys.remove(key) != nil { return nil }; return Unmanaged.passUnretained(event) }
        if settings.recording != nil {
            if type == .flagsChanged {
                recordingPeak |= flags
                if flags == 0, recordingPeak != 0 { saveShortcut(Shortcut(modifiers: recordingPeak)) }
            } else if type == .keyDown {
                if key == 53 { settings.recording = nil; recordingPeak = 0 }
                else { saveShortcut(Shortcut(key:key,modifiers:flags)); suppressedKeys.insert(key) }
            }
            return nil
        }
        if IsSecureEventInputEnabled() { reset(); chord.reset(); return Unmanaged.passUnretained(event) }
        if excluded(manual:true) { reset(); chord.reset(); return Unmanaged.passUnretained(event) }
        if type == .flagsChanged {
            if let combo = chord.changed(flags), let index = settings.value.shortcuts.firstIndex(where: { $0.key == nil && $0.modifiers == combo && $0.enabled }) { command(index) }
            return Unmanaged.passUnretained(event)
        }
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }
        chord.keyPressed()
        if let index = settings.value.shortcuts.firstIndex(where: { $0.key == key && $0.modifiers == flags && $0.enabled }) {
            suppressedKeys.insert(key)
            if event.getIntegerValueField(.keyboardEventAutorepeat) == 0 { command(index) }
            return nil
        }
        guard flags & (Shortcut.command | Shortcut.control) == 0 else { reset(); return Unmanaged.passUnretained(event) }
        let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
        let source = Layouts.currentID
        if ownerPID != pid || (!ownerSource.isEmpty && ownerSource != source) { reset() }
        if key == 51 { justConverted = false; buffer.backspace(cancelAuto: settings.value.cancelKeys.contains(key)); undo = nil; return Unmanaged.passUnretained(event) }
        if [117,123,124,125,126,53,115,119,116,121].contains(key) {
            reset()
            if settings.value.cancelKeys.contains(key) { buffer.cancelAuto(); ownerPID = pid; ownerSource = source }
            return Unmanaged.passUnretained(event)
        }
        if buffer.text.isEmpty {
            owner = Focus.current(); ownerPID = pid; ownerSource = source
            if owner?.secure == true { reset(); return Unmanaged.passUnretained(event) }
        }
        guard source == settings.value.english || source == settings.value.russian else { reset(); return Unmanaged.passUnretained(event) }
        let boundaries: [UInt16:String] = [49:" ",36:"\n",76:"\n",48:"\t"]
        if let separator = boundaries[key] {
            let word = buffer.text
            let canAuto = automaticEnabled && !justConverted && !buffer.cancelled && !(settings.value.noTabEnter && key != 49) && !excluded(manual:false)
            if canAuto && shouldAutomaticallyConvert(word,completed:true), let owner, owner.stillFocused(), !word.isEmpty {
                let converted = convert(word)
                if converted != word {
                    if performTyped(before:word,after:converted,suffix:"",appendKey:key,focus:owner,automatic:true) {
                        suppressedKeys.insert(key)
                        return nil
                    }
                }
            }
            buffer.boundary(separator)
            if var previous = undo, previous.suffix.isEmpty { previous.suffix = separator; undo = previous } else { undo = nil }
            if key != 49 { reset() }
            return Unmanaged.passUnretained(event)
        }
        // CGEvent's Unicode payload can be empty or left in the previous layout.
        // The original obtains text from keycode + modifiers + the active TIS layout.
        let text = Layouts.text(key, flags: event.flags)
        guard !text.isEmpty, !text.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { reset(); return Unmanaged.passUnretained(event) }
        if var previous = undo, previous.suffix.isEmpty {
            previous.before += LayoutConversion.convert(text,toRussian:previous.source == settings.value.russian,pc:settings.value.russian.contains("Win"))
            previous.after += text; undo = previous
        } else { undo = nil }
        justConverted = false
        buffer.append(text); settings.count("symbols",amount:text.count); sound("keystroke")
        // The triggering key has not reached the editor yet. Suppress it and replay
        // the complete converted word, deleting only the already-delivered prefix.
        // Scheduling this after the callback raced the editor's input queue and could
        // discard the buffer or duplicate the triggering character.
        if automaticEnabled, !buffer.cancelled, !excluded(manual:false), shouldAutomaticallyConvert(buffer.text,completed:false), let owner {
            let word = buffer.text, after = convert(word)
            let delivered = String(word.dropLast(text.count))
            if word != after, performTyped(before:delivered,after:after,suffix:"",appendKey:nil,focus:owner,automatic:true,undoBefore:word) {
                suppressedKeys.insert(key)
                return nil
            }
        }
        return Unmanaged.passUnretained(event)
    }
    func shouldAutomaticallyConvert(_ word: String, completed: Bool) -> Bool {
        guard word.count < 32 else { return false }
        let normalized = normalize(word)
        guard rules.shouldConvert(normalized,completed:completed,userRules:settings.value.rules) else { return false }
        if completed, !settings.value.rules.contains(where: { $0.matches(normalized) }) {
            let target = ownerSource == settings.value.english ? settings.value.russian : settings.value.english
            // Original autocorrectWordLayout rejects a word that is also incorrect
            // in the destination layout, and plays the misprint sound (0x10003eec3).
            if rules.shouldConvert(normalize(convert(word),source:target),completed:true,userRules:[]) {
                sound("misprint"); return false
            }
        }
        return true
    }
    func normalize(_ word: String, source: String? = nil) -> String {
        guard (source ?? ownerSource) == settings.value.russian, settings.value.russian == "com.apple.keylayout.Russian" else { return word }
        let pairs = Dictionary(uniqueKeysWithValues: zip(Array(LayoutConversion.russian),Array(LayoutConversion.russianPC)))
        return String(word.map { pairs[$0] ?? $0 })
    }
    func convert(_ word: String) -> String { LayoutConversion.convert(word,toRussian:ownerSource == settings.value.english,pc:settings.value.russian.contains("Win")) }
    var currentMode: AppMode {
        let id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        if let mode = settings.value.appProfiles[id] { return mode }
        // Retain compatibility with imported exclusions and older preference files.
        if settings.value.exceptions.contains(id) { return settings.value.excludeManual ? .disabled : .manual }
        return .global
    }
    var automaticEnabled: Bool { currentMode.automaticEnabled(global:settings.value.automatic) }
    func excluded(manual: Bool) -> Bool {
        manual ? !currentMode.manualEnabled : !automaticEnabled
    }
    func saveShortcut(_ shortcut: Shortcut) {
        defer { settings.recording = nil; recordingPeak = 0; chord.reset() }
        guard let index = settings.recording else { return }
        if settings.value.shortcuts.enumerated().contains(where: { $0.offset != index && $0.element == shortcut }) { settings.message = "Это сочетание уже назначено другой команде"; return }
        settings.value.shortcuts[index] = shortcut
    }
    func command(_ index: Int) {
        guard !busy, !excluded(manual:true), !IsSecureEventInputEnabled() else { return }
        switch index {
        case 0: settings.value.automatic.toggle(); reset(); onStatus?()
        case 3: switchLayout(); reset()
        case 4,5:
            guard settings.value.lunaEnabled else { return }
            DispatchQueue.main.async { [weak self] in self?.onProofread?(index == 4) }
        default:
            // A focus change or a new keystroke must invalidate a delayed command.
            busy = true
            let generation = self.generation
            let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier
            DispatchQueue.main.asyncAfter(deadline:.now()+0.025) { [weak self] in
                guard let self else { return }
                self.busy = false
                if self.generation == generation, NSWorkspace.shared.frontmostApplication?.processIdentifier == pid {
                    self.manualConversion(changeCase:index == 2)
                }
                self.drainInput()
            }
        }
    }
    func manualConversion(changeCase: Bool) {
        guard !busy, let focus = Focus.current(), !focus.secure, !IsSecureEventInputEnabled() else { return }
        if let selection = focus.selected, !selection.isEmpty, changeCase || !focus.terminal || buffer.convertible.isEmpty {
            replaceSelection(selection, focus:focus, changeCase:changeCase)
            return
        }
        // Clicks / navigation invalidate the physical buffer, so a pointer selection
        // in an opaque renderer must use the original's clipboard acquisition path.
        if changeCase || (undo == nil && buffer.convertible.isEmpty) {
            busy = true
            let generation = self.generation
            access.copySelection(from:focus) { [weak self] selection in
                guard let self else { return }
                self.busy = false
                if let selection, self.generation == generation, focus.stillFocused() {
                    self.replaceSelection(selection, focus:focus, changeCase:changeCase)
                }
                self.drainInput()
            }
            return
        }
        guard !changeCase else { return }
        if let undo, undo.focus.stillFocused() {
            self.undo = nil
            performTyped(before:undo.after,after:undo.before,suffix:undo.suffix,appendKey:nil,focus:focus,automatic:false,targetSource:undo.source)
            if undo.automatic { registerCancellation(undo.before) }
            return
        }
        guard let owner, owner.stillFocused(), !buffer.convertible.isEmpty else { settings.message = "Нет выделения или набранного слова для конвертации"; return }
        let word = buffer.convertible, suffix = buffer.suffix
        performTyped(before:word,after:convert(word),suffix:suffix,appendKey:nil,focus:focus,automatic:false)
    }
    private func replaceSelection(_ selection: String, focus: Focus, changeCase: Bool) {
        let replacement = changeCase ? LayoutConversion.changeCase(selection) : LayoutConversion.selection(selection,pc:settings.value.russian.contains("Win"))
        guard replacement != selection, focus.stillFocused() else { return }
        busy = true; reset()
        let generation = self.generation
        // AX setters can report success without generating editor input events.
        // Command-V follows the same editor path as the original, including undo.
        access.paste(replacement,into:focus) { [weak self] ok in
            guard let self else { return }
            self.busy = false
            defer { self.drainInput() }
            if ok {
                self.settings.count("manual"); self.sound("selection")
                if !changeCase && self.settings.value.switchAfterSelection && self.generation == generation && focus.stillFocused() { self.switchLayout(silent:true); self.showFeedback(pid:focus.pid,source:Layouts.currentID) }
            }
        }
    }
    func registerCancellation(_ word: String) {
        // PuntoUndoManager registerCancellation: learns on the second cancellation,
        // ignores words shorter than three UTF-16 units and persists pending counts.
        guard automaticEnabled, settings.value.learning || settings.value.showLearningPrompt else {
            settings.value.learningCounts.removeAll(); return
        }
        guard word.utf16.count >= 3, !settings.value.rules.contains(where: { $0.text == word }) else { return }
        let count = settings.value.learningCounts[word,default:0] + 1
        settings.value.learningCounts[word] = count
        guard count >= 2 else { return }
        if settings.value.showLearningPrompt { pendingLearningPrompt = word }
        else if settings.value.learning { learn(word) }
    }
    func learn(_ word: String) {
        guard !settings.value.rules.contains(where: { $0.text == word }) else { return }
        settings.value.rules.append(UserRule(text:word,caseSensitive:true))
        settings.value.learningCounts.removeValue(forKey:word)
    }
    @discardableResult
    func performTyped(before: String, after: String, suffix: String, appendKey: UInt16?, focus: Focus, automatic: Bool, targetSource: String? = nil, undoBefore: String? = nil) -> Bool {
        guard !busy, before != after, focus.stillFocused(), !IsSecureEventInputEnabled() else { return false }
        // Never erase a selection in a normal editor as though it were the buffered tail.
        if !automatic, let selected = focus.selected, !selected.isEmpty, !focus.terminal { reset(); return false }
        if !automatic, !focus.terminal, focus.editable, let value = focus.value, let range = focus.range {
            let ns = value as NSString
            guard range.length == 0, range.location <= ns.length else { reset(); return false }
            let prefix = ns.substring(to:range.location)
            guard prefix.replacingOccurrences(of:"\u{00a0}",with:" ").hasSuffix((before+suffix).replacingOccurrences(of:"\u{00a0}",with:" ")) else { reset(); return false }
        }
        let source = ownerSource.isEmpty ? Layouts.currentID : ownerSource
        let target = targetSource ?? (source == settings.value.english ? settings.value.russian : settings.value.english)
        if automatic { silentSourceChange = target }
        guard Layouts.select(target) else { silentSourceChange = nil; settings.message = "Выбранная раскладка недоступна"; return false }
        busy = true
        fenceCounter &+= 1
        let fence = TextAccess.fenceBase + fenceCounter
        pendingFence = fence
        pendingFeedback = (focus.pid,target)
        access.erase((before+suffix).count)
        access.replay(after+suffix, layout:target)
        if let appendKey { access.key(appendKey) }
        buffer.reset(); owner = focus; ownerPID = focus.pid; ownerSource = target
        let ending = suffix + (appendKey == 49 ? " " : "")
        if appendKey == nil && suffix.isEmpty { buffer.append(after) }
        else if appendKey == 49 || suffix == " " { buffer.append(after); buffer.boundary(ending) }
        if settings.value.noRepeatCorrection { buffer.cancelAuto() }
        justConverted = true
        undo = (undoBefore ?? before,after,ending,focus,source,automatic)
        if automatic { settings.count("switches"); sound("auto") } else { settings.count("manual"); sound("undo") }
        settings.message = "Готов к работе"
        access.fence(fence)
        // A fence passes the same tap after every replacement event. Later physical
        // input is queued until then, so fast typing cannot overtake the replacement.
        DispatchQueue.main.asyncAfter(deadline:.now()+0.8) { [weak self] in
            guard let self, self.pendingFence == fence else { return }
            self.log.error("Replacement fence timed out; releasing queued input")
            self.finishEdit(fence)
        }
        return true
    }
}
