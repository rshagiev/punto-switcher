import AppKit
import SwiftUI
import Carbon
import PuntoCore

final class LunaReview: ObservableObject {
    @Published var mode:LunaClient.Mode = .errors
    @Published var automaticDepth = false
    @Published var diff = ProofreadingDiff(original:"",corrected:"")
    @Published var rejected = Set<Int>()
    @Published var editsLocked = false
    var canReplace = false
    func toggle(_ id:Int) {
        guard !loading, !editsLocked, diff.edits.contains(where:{$0.id == id}) else { return }
        if !rejected.insert(id).inserted { rejected.remove(id) }
        corrected = diff.result(rejecting:rejected)
        canApply = canReplace && corrected != original
        message = corrected == original ? "Все правки отключены." : "Нажмите на подсветку, чтобы включить или отключить правку."
    }
    @Published var original = ""
    @Published var corrected = ""
    @Published var loading = false
    @Published var message = ""
    @Published var canApply = false
    @Published var canUndo = false
}

final class LunaCorrection: NSObject, NSWindowDelegate {
    let settings:Settings
    let engine:KeyboardEngine
    let state = LunaReview()
    let client = LunaClient()
    let hud = LunaHUD()
    private struct Variant { let corrected:String; let diff:ProofreadingDiff; let rejected:Set<Int> }
    private var variants:[LunaClient.Mode:Variant] = [:]
    func selectMode(_ mode:LunaClient.Mode) {
        guard mode != state.mode, !state.editsLocked, !state.original.isEmpty, state.corrected.isEmpty || state.diff.original == state.original else { return }
        if !state.loading && !state.corrected.isEmpty {
            variants[state.mode] = Variant(corrected:state.corrected,diff:state.diff,rejected:state.rejected)
        }
        quick = false; hud.hide(); watcher?.invalidate()
        client.cancel(); requestID = UUID(); let id = requestID
        state.mode = mode; state.automaticDepth = false; state.canUndo = false; state.loading = false
        if let saved = variants[mode] {
            state.corrected = saved.corrected; state.diff = saved.diff; state.rejected = saved.rejected
            state.canApply = state.canReplace && saved.corrected != state.original
            state.message = "Нажмите на подсветку, чтобы включить или отключить правку."
            return
        }
        state.corrected = ""; state.rejected = []; state.diff = ProofreadingDiff(original:"",corrected:"")
        state.canApply = false; state.loading = true; state.message = ""
        let text = state.original
        client.correct(text,mode:mode) { [weak self] result in
            guard let self, self.requestID == id else { return }
            switch result {
            case .failure(let error): self.state.loading = false; self.state.message = error.localizedDescription
            case .success(let corrected):
                DispatchQueue.global(qos:.userInitiated).async {
                    let diff = ProofreadingDiff(original:text,corrected:corrected,phrases:mode != .errors)
                    DispatchQueue.main.async { [weak self] in
                        guard let self, self.requestID == id else { return }
                        self.state.corrected = corrected; self.state.diff = diff; self.state.loading = false
                        self.state.canApply = self.state.canReplace && corrected != text
                        self.state.message = corrected == text ? "Изменения не нужны." : "Нажмите на подсветку, чтобы включить или отключить правку."
                    }
                }
            }
        }
    }
    private var quick = false
    private var quickInvalidated = false
    private var watcher:Timer?
    private var quickSelection:CFRange?
    func invalidateQuick() { if quick && state.loading { quickInvalidated = true } }
    func showLast() { quick = false; watcher?.invalidate(); hud.hide(); present() }
    var window:NSWindow?
    var onVisibility:((Bool)->Void)?
    private struct Source { let focus:Focus; let value:String; let range:CFRange }
    private var source:Source?
    private var appliedValue:String?
    private var appliedText:String?
    private var requestID = UUID()
    private var replacementFailure = ""
    init(settings:Settings,engine:KeyboardEngine) { self.settings = settings; self.engine = engine }

    func request(quick:Bool = false) {
        guard settings.value.lunaEnabled, settings.running, !engine.excluded(manual:true), !IsSecureEventInputEnabled() else { return }
        guard let focus = Focus.current(), !focus.secure else { return }
        self.quick = quick; quickInvalidated = false; quickSelection = focus.range
        var text = ""
        source = nil
        if focus.editable, let value = focus.value, let selected = focus.range {
            let ns = value as NSString
            guard selected.location >= 0, selected.length >= 0, selected.location <= ns.length, selected.length <= ns.length-selected.location else { return }
            var range = NSRange(location:selected.location,length:selected.length)
            if range.length == 0 {
                range = ns.paragraphRange(for:range)
                while range.length > 0, [10,13].contains(Int(ns.character(at:range.location+range.length-1))) { range.length -= 1 }
            }
            text = ns.substring(with:range)
            source = Source(focus:focus,value:value,range:CFRange(location:range.location,length:range.length))
        } else if let selected = focus.selected { text = selected }
        if text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || text == "Do anything" {
            showMessage("Выделите текст или поставьте курсор в абзац, который нужно исправить.")
            return
        }
        begin(text)
    }
    func demo() {
        quick = false; source = nil
        begin("Я не хочю менять 42 файла но где то ошибся. Сначала проверим результат, потом применим.")
    }
    private func begin(_ text:String) {
        variants = [:]
        state.automaticDepth = !quick && ProcessingDepth.suggestsStructure(text)
        state.mode = state.automaticDepth ? .structure : .errors
        client.cancel(); requestID = UUID()
        state.diff = ProofreadingDiff(original:"",corrected:"")
        state.rejected = []; state.editsLocked = false; state.canReplace = source != nil
        state.original = text; state.corrected = ""; state.message = ""; state.loading = true
        state.canApply = false; state.canUndo = false; appliedValue = nil; appliedText = nil
        watcher?.invalidate(); hud.hide()
        if quick {
            window?.orderOut(nil); onVisibility?(false)
            hud.show("Исправляю…",focus:source?.focus,loading:true,button:"Отмена",duration:0) { [weak self] in self?.cancel() }
            watcher = Timer.scheduledTimer(withTimeInterval:0.15,repeats:true) { [weak self] _ in
                guard let self, self.quick, self.state.loading else { return }
                if self.source?.focus.stillFocused() != true { self.quickInvalidated = true; self.hud.hide() }
            }
        } else { present() }
        let id = requestID
        let mode = state.mode
        client.correct(text,mode:mode) { [weak self] result in
            guard let self, self.requestID == id else { return }
            self.state.loading = false
            self.watcher?.invalidate()
            switch result {
            case .success(let corrected):
                self.state.corrected = corrected
                DispatchQueue.global(qos:.userInitiated).async {
                    let diff = ProofreadingDiff(original:text,corrected:corrected,phrases:mode != .errors)
                    DispatchQueue.main.async { [weak self] in
                        guard let self, self.requestID == id else { return }
                        self.state.diff = diff
                        if !diff.edits.isEmpty, !self.state.editsLocked { self.state.message = "Нажмите на подсветку, чтобы включить или отключить правку." }
                    }
                }
                self.state.canApply = self.source != nil && corrected != self.state.original
                self.state.message = corrected == self.state.original ? "Исправления не нужны." : (self.source == nil ? "Результат можно скопировать." : "Проверьте изменения перед заменой.")
                if self.quick {
                    if corrected == text { self.hud.show("Исправления не нужны",focus:self.source?.focus) }
                    else if let source = self.source, !self.quickInvalidated, source.focus.stillFocused(),
                            let range = source.focus.range, let selected = self.quickSelection,
                            range.location == selected.location, range.length == selected.length,
                            source.focus.value == source.value {
                        self.apply(automatically:true)
                    } else {
                        self.state.message = "Текст или поле изменились. Автоматическая замена отменена."
                        self.state.canApply = self.source.map { $0.focus.value == $0.value } ?? false
                        self.hud.show("Текст или поле изменились",focus:nil,symbol:"text.badge.checkmark",button:"Сравнить",duration:6) { [weak self] in self?.showLast() }
                    }
                }
            case .failure(let error):
                self.state.message = error.localizedDescription
                if self.quick { self.hud.show("Не удалось исправить",focus:self.source?.focus,symbol:"exclamationmark.circle",button:"Подробнее",duration:6) { [weak self] in self?.showLast() } }
            }
        }
    }
    private func showMessage(_ message:String) {
        variants = [:]; state.mode = .errors
        client.cancel(); requestID = UUID(); source = nil
        state.diff = ProofreadingDiff(original:"",corrected:"")
        state.rejected = []; state.editsLocked = false; state.canReplace = false
        state.original = ""; state.corrected = ""; state.loading = false
        state.canApply = false; state.canUndo = false; state.message = message
        if quick { hud.show("Выделите текст для исправления",focus:nil,symbol:"text.cursor") } else { present() }
    }
    private func present() {
        if window == nil {
            let view = LunaReviewView(state:state,selectMode:{ [weak self] in self?.selectMode($0) },apply:{ [weak self] in self?.apply() },undo:{ [weak self] in self?.undo() },close:{ [weak self] in self?.window?.close() })
            let w = NSWindow(contentRect:NSRect(x:0,y:0,width:820,height:520),styleMask:[.titled,.closable,.resizable],backing:.buffered,defer:false)
            w.title = "Корректура с Luna"; w.isReleasedWhenClosed = false; w.delegate = self
            let host = NSHostingView(rootView:view); host.sizingOptions = []
            w.contentView = host; w.contentMinSize = NSSize(width:720,height:420); w.center(); window = w
        }
        onVisibility?(true); NSApp.activate(ignoringOtherApps:true); window?.makeKeyAndOrderFront(nil)
    }
    func windowWillClose(_ notification:Notification) {
        client.cancel(); requestID = UUID(); state.loading = false; watcher?.invalidate(); hud.hide()
        DispatchQueue.main.async { [weak self] in self?.onVisibility?(false) }
    }
    func cancel() { client.cancel(); requestID = UUID(); state.loading = false; watcher?.invalidate(); hud.hide() }
    private func normalize(_ value:String) -> String { value.replacingOccurrences(of:"\u{00a0}",with:" ") }
    private func replace(expected:String,range:CFRange,text:String,activate:Bool = true,completion:@escaping(String?)->Void) {
        guard let source, let app = NSRunningApplication(processIdentifier:source.focus.pid) else { completion(nil); return }
        state.canApply = false; state.canUndo = false
        replacementFailure = ""
        let id = requestID
        if activate { app.activate(options:[]) }
        DispatchQueue.main.asyncAfter(deadline:.now()+0.15) { [weak self] in
            guard let self, self.requestID == id else { return }
            guard !self.engine.busy, !IsSecureEventInputEnabled() else { self.replacementFailure = "Ввод занят или защищён."; completion(nil); return }
            guard source.focus.stillFocused() else { self.replacementFailure = "Не удалось вернуть фокус в исходное поле."; completion(nil); return }
            guard let current = source.focus.value, self.normalize(current) == self.normalize(expected) else { self.replacementFailure = "Исходный текст изменился."; completion(nil); return }
            guard let element = source.focus.element else { self.replacementFailure = "Исходное поле недоступно."; completion(nil); return }
            var range = range
            guard let selection = AXValueCreate(.cfRange,&range),
                  AXUIElementSetAttributeValue(element,kAXSelectedTextRangeAttribute as CFString,selection) == .success else { self.replacementFailure = "Редактор не разрешил выделить текст."; completion(nil); return }
            // Electron acknowledges the setter before its selection readback updates.
            DispatchQueue.main.asyncAfter(deadline:.now()+0.08) { [weak self] in
                guard let self, self.requestID == id else { return }
                guard !self.engine.busy, !IsSecureEventInputEnabled(), source.focus.stillFocused(),
                      let current = source.focus.value, self.normalize(current) == self.normalize(expected),
                      let actual = source.focus.range, actual.location == range.location, actual.length == range.length else { self.replacementFailure = "Редактор не подтвердил выделение или сменился фокус."; completion(nil); return }
                self.engine.reset(); self.engine.busy = true
                self.engine.access.paste(text,into:source.focus) { [weak self] ok in
                    guard let self else { return }
                    self.engine.busy = false
                    defer { self.engine.drainInput() }
                    guard self.requestID == id else { return }
                    let desired = (expected as NSString).replacingCharacters(in:NSRange(location:range.location,length:range.length),with:text)
                    guard ok, let value = source.focus.value, self.normalize(value) == self.normalize(desired) else { self.replacementFailure = "Редактор не подтвердил вставку."; completion(nil); return }
                    completion(value)
                }
            }
        }
    }
    private func apply(automatically:Bool = false) {
        guard state.canApply, let source else { return }
        state.editsLocked = true
        let replacement = state.corrected
        replace(expected:source.value,range:source.range,text:replacement,activate:!automatically) { [weak self] actual in
            guard let self else { return }
            if let actual {
                self.appliedValue = actual; self.appliedText = replacement
                self.state.canUndo = true; self.state.message = "Текст заменён. Доступна отмена."
                if automatically { self.hud.show("Исправлено",focus:source.focus,button:"Отменить",duration:5) { [weak self] in self?.undo() } }
            } else { self.state.message = self.replacementFailure + " Проверьте исходное приложение; повторная замена не выполнялась."; if automatically {
                    self.hud.show("Замена не выполнена",focus:source.focus,symbol:"exclamationmark.circle",button:"Сравнить",duration:6) { [weak self] in self?.showLast() }
                } else { self.present() }
            }
        }
    }
    private func undo() {
        guard state.canUndo, let source, let expected = appliedValue, let replacement = appliedText else { return }
        replace(expected:expected,range:CFRange(location:source.range.location,length:(replacement as NSString).length),text:state.original) { [weak self] actual in
            guard let self else { return }
            self.state.message = actual == nil ? "Текст уже изменился. Автоматическая отмена не выполнена." : "Исходный текст восстановлен."
            self.state.canUndo = false
            if actual != nil { self.state.editsLocked = false; self.state.canApply = self.state.corrected != self.state.original }
            if self.quick { self.hud.show(actual == nil ? "Текст уже изменился" : "Исходный текст возвращён",focus:source.focus,symbol:actual == nil ? "exclamationmark.circle" : "arrow.uturn.backward") }
            else if actual == nil { self.present() }
        }
    }
}

private struct LunaReviewView:View {
    @ObservedObject var state:LunaReview
    let selectMode:(LunaClient.Mode)->Void
    let apply:()->Void
    let undo:()->Void
    let close:()->Void
    private func comparisonColumn(_ title:String,right:Bool) -> some View {
        VStack(alignment:.leading,spacing:10) {
            Text(title).font(.headline)
            LunaInteractiveText(diff:state.diff,plain:right ? state.corrected : state.original,
                right:right,rejected:state.rejected,enabled:!state.loading && !state.editsLocked,
                toggle:{ state.toggle($0) })
                .background(Color(nsColor:.textBackgroundColor).opacity(0.45),in:RoundedRectangle(cornerRadius:12))
                .clipShape(RoundedRectangle(cornerRadius:12))
                .overlay(RoundedRectangle(cornerRadius:12).strokeBorder(.primary.opacity(0.06)))
        }.frame(maxWidth:.infinity)
    }
    var body:some View {
        VStack(alignment:.leading,spacing:16) {
            HStack {
                VStack(alignment:.leading,spacing:4) {
                    Text(state.mode == .errors ? "Исправить ошибки" : state.mode.rawValue).font(.title2.bold())
                    Text("Luna сохраняет смысл, сленг и манеру речи.").foregroundStyle(.secondary)
                }
                Spacer()
                if state.loading { ProgressView().controlSize(.small); Text("Проверяю…").foregroundStyle(.secondary) }
            }
            HStack(spacing:14) {
                Picker("Обработка",selection:Binding(get:{state.mode},set:selectMode)) {
                    ForEach(LunaClient.Mode.allCases,id:\.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).labelsHidden().frame(width:350)
                    .disabled(state.editsLocked || state.original.isEmpty)
                Text(state.automaticDepth ? "Выбрано автоматически · можно сменить" : state.mode.detail)
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(alignment:.top,spacing:16) {
                comparisonColumn("Было",right:false)
                comparisonColumn("Стало",right:true)
            }.frame(maxHeight:.infinity)
            Text(state.message).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal:false,vertical:true)
            HStack {
                Button(state.loading ? "Отменить запрос" : "Закрыть",action:close).keyboardShortcut(.cancelAction)
                if state.canUndo { Button("Отменить замену",action:undo) }
                Spacer()
                Button("Скопировать") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(state.corrected,forType:.string) }.disabled(state.corrected.isEmpty || state.loading)
                Button("Применить",action:apply).buttonStyle(.borderedProminent).disabled(!state.canApply || state.loading)
            }
        }.padding(24).frame(maxWidth:.infinity,maxHeight:.infinity)
    }
}
