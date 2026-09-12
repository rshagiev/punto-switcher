import SwiftUI
import AppKit
import Carbon
import UniformTypeIdentifiers
import ServiceManagement
import PuntoCore

struct SettingsView: View {
    @ObservedObject var settings: Settings
    let engine: KeyboardEngine
    @ObservedObject var updates: Updates
    let onLunaDemo: () -> Void
    @StateObject private var codex = CodexConnection()
    private var section: String { settings.selectedSection }
    @State private var newRule = false
    @State private var showHelp = false
    @State private var editing: UserRule?
    @State private var login = SMAppService.mainApp.status == .enabled
    private let panes = [("Основные","keyboard"),("Шорткаты","command"),("Правила","text.badge.checkmark"),("Профили","app.badge"),("Звуки","speaker.wave.2"),("Luna","sparkles"),("О программе","info.circle")]
    var body: some View {
        NavigationSplitView {
            VStack(alignment:.leading,spacing:20) {
                HStack(spacing:10) {
                    Image(systemName:"character.cursor.ibeam").font(.system(size:25,weight:.medium)).foregroundStyle(.white).frame(width:44,height:44).background(.blue.gradient,in:RoundedRectangle(cornerRadius:12))
                    VStack(alignment:.leading,spacing:3) { Text("Punto Native").font(.headline); Text("Раскладка под рукой").font(.caption).foregroundStyle(.secondary) }
                }.padding(.horizontal,14).padding(.top,22)
                List(selection:$settings.selectedSection) { ForEach(panes,id:\.0) { name,icon in Label(name,systemImage:icon).tag(name).padding(.vertical,4) } }.listStyle(.sidebar)
                Label(settings.running ? "Работает" : (settings.permission ? "Приостановлен" : "Нужен доступ"),systemImage:settings.running ? "checkmark.circle.fill" : "lock.fill").font(.caption).foregroundStyle(settings.running ? .green : .orange).padding(18)
            }.navigationSplitViewColumnWidth(min:205,ideal:220,max:250)
        } detail: {
            VStack(alignment:.leading,spacing:0) {
                VStack(alignment:.leading,spacing:5) { Text(section).font(.system(size:26,weight:.bold)); Text(subtitle).foregroundStyle(.secondary).font(.callout) }.padding(26)
                if !settings.permission { permissionCard.padding(.horizontal,26).padding(.bottom,12) }
                else if !settings.running {
                    HStack { Label("Обработка клавиатуры приостановлена",systemImage:"pause.circle"); Spacer(); Button("Начать работу") { engine.start() } }.padding(16).background(.quaternary,in:RoundedRectangle(cornerRadius:12)).padding(.horizontal,26)
                }
                content
                if !settings.message.isEmpty && settings.message != "Готов к работе" { Text(settings.message).font(.caption).foregroundStyle(.secondary).padding(.horizontal,26).padding(.bottom,14) }
            }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading).background(Color(nsColor:.windowBackgroundColor))
        }.frame(minWidth:810,minHeight:600)
        .sheet(isPresented:$showHelp) { HelpView(settings:settings) }
        .sheet(isPresented:$newRule) { RuleEditor(rule:editing ?? UserRule(text:"")) { rule in
            if let i = settings.value.rules.firstIndex(where:{$0.id == rule.id}) { settings.value.rules[i] = rule }
            else { settings.value.rules.append(rule) }
        } }
    }
    var subtitle: String {
        switch section {
        case "Основные": return "Русский и английский в привычных приложениях."
        case "Шорткаты": return "Назначьте клавиши или сочетание одних модификаторов."
        case "Правила": return "Какие слова исправлять, а какие оставлять как есть."
        case "Профили": return "Отдельный режим переключения для каждого приложения."
        case "Luna": return "Исправление ошибок по вашему запросу."
        case "Звуки": return "Звуковая обратная связь при работе с текстом."
        default: return "Нативное приложение для macOS."
        }
    }
    var permissionCard: some View {
        VStack(alignment:.leading,spacing:10) {
            Label("Разрешите работу с клавиатурой",systemImage:"hand.raised.fill").font(.headline)
            Text("В настройках macOS включите Punto Native в разделах «Универсальный доступ» и «Мониторинг ввода».").font(.callout).foregroundStyle(.secondary)
            HStack {
                Button("Универсальный доступ") { openPrivacy("Privacy_Accessibility") }
                Button("Мониторинг ввода") { openPrivacy("Privacy_ListenEvent") }
                Button("Проверить доступ") { engine.start() }.buttonStyle(.borderedProminent)
            }
        }.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(Color.orange.opacity(0.09),in:RoundedRectangle(cornerRadius:12))
    }
    @ViewBuilder var content: some View {
        switch section {
        case "Основные": general
        case "Шорткаты": shortcuts
        case "Правила": rules
        case "Профили": profiles
        case "Luna": luna
        case "Звуки": sounds
        default: about
        }
    }
    private func lunaShortcut(_ title:String,index:Int) -> some View {
        LabeledContent(title) {
            HStack(spacing:8) {
                Button { settings.recording = index; engine.recordingPeak = 0 } label: {
                    Text(settings.recording == index ? "Нажмите сочетание…" : shortcutLabel(settings.value.shortcuts[index]))
                        .frame(minWidth:130)
                }.disabled(!settings.running)
                .help("Нажмите и введите своё сочетание. Escape отменяет запись.")
                if settings.recording == index {
                    Button("Отмена") { settings.recording = nil; engine.recordingPeak = 0 }
                }
            }
        }
    }
    var luna: some View {
        Form {
            Section {
                HStack(spacing:12) {
                    if codex.status == .checking { ProgressView().controlSize(.small).frame(width:24) }
                    else {
                        Image(systemName:codex.status == .connected ? "checkmark.circle.fill" : "exclamationmark.circle")
                            .font(.system(size:22)).foregroundStyle(codex.status == .connected ? .green : .orange)
                    }
                    VStack(alignment:.leading,spacing:4) {
                        Text(codex.title).font(.headline)
                        Text(codex.detail).font(.callout).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Проверить") { codex.refresh() }.disabled(codex.status == .checking)
                        .help("Проверить установку Codex и вход в аккаунт. Запрос к модели не отправляется.")
                }.padding(.vertical,4)
                if codex.status == .missing || codex.status == .signedOut || codex.status == .unavailable {
                    Text("В Терминале выполните codex login, завершите вход в браузере и нажмите «Проверить». Если команда не найдена, сначала установите Codex CLI.")
                        .font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
                }
                Toggle("Корректура с Luna",isOn:$settings.value.lunaEnabled)
            }
            Section {
                lunaShortcut("Исправить сразу",index:4)
                lunaShortcut("Проверить перед заменой",index:5)
            } header: { Text("Команды") } footer: {
                Text("Выделите текст или поставьте курсор в абзац. В окне сравнения можно отключать отдельные правки кликом.")
            }
            Section {
                Button("Попробовать на примере",action:onLunaDemo)
                    .disabled(!settings.value.lunaEnabled || codex.status != .connected)
                Text("Проверит ответ Luna на готовом тексте. Расходует лимиты Codex.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                DisclosureGroup("Как это работает") {
                    Text("Luna сохраняет смысл и манеру речи. Текст отправляется только по вашей команде. Если продолжите ввод или смените поле, автоматической замены не будет.")
                    Text("Отмена и последнее исправление доступны через меню Punto. Используется ваш аккаунт Codex; отдельный API-ключ не нужен.")
                    Text("Статус сверху подтверждает локальный вход в Codex. Кнопка с примером проверяет доступ к модели и соединение.")
                }.font(.callout).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped)
        .onAppear { codex.refresh() }
        .onReceive(NotificationCenter.default.publisher(for:NSApplication.didBecomeActiveNotification)) { _ in
            if section == "Luna" { codex.refresh() }
        }
    }
    var general: some View {
        Form {
            Section {
                Toggle("Переключать раскладку автоматически",isOn:$settings.value.automatic).onChange(of:settings.value.automatic) { _,_ in engine.reset(); engine.onStatus?() }
                Toggle("Запоминать раскладку в приложениях",isOn:$settings.value.rememberLayout)
                Toggle("Показывать раскладку после исправления",isOn:$settings.value.showConversionFeedback).onChange(of:settings.value.showConversionFeedback) { _,enabled in if !enabled { engine.feedback.hide() } }
                Toggle("Переключать раскладку при конвертации выделения",isOn:$settings.value.switchAfterSelection)
                Toggle("Запускать при входе в macOS",isOn:$login).onChange(of:login) { _,v in settings.setLogin(v); login = SMAppService.mainApp.status == .enabled }
                if !settings.loginError.isEmpty { Text(settings.loginError).foregroundStyle(.red).font(.caption) }
            }
            Section("Раскладки клавиатуры") {
                Picker("Русская",selection:$settings.value.russian) { layoutOptions(russian:true) }
                Picker("Английская",selection:$settings.value.english) { layoutOptions(russian:false) }
            }
            Section("Автопереключение") {
                Toggle("Не переключать по Tab и Enter",isOn:$settings.value.noTabEnter)
                Toggle("Не исправлять слово повторно после конвертации",isOn:$settings.value.noRepeatCorrection)
                Text("Не исправлять слово после нажатия:").foregroundStyle(.secondary)
                HStack { ForEach([(UInt16(51),"⌫"),(117,"⌦"),(123,"←"),(124,"→"),(126,"↑"),(125,"↓")],id:\.0) { key,label in
                    Toggle(label,isOn:Binding(get:{settings.value.cancelKeys.contains(key)},set:{ if $0 { settings.value.cancelKeys.insert(key) } else { settings.value.cancelKeys.remove(key) } })).toggleStyle(.button)
                } }
            }
        }.formStyle(.grouped)
    }
    @ViewBuilder func layoutOptions(russian: Bool) -> some View {
        ForEach(Layouts.all.compactMap { s -> (String,String)? in
            guard let id = Layouts.property(s,kTISPropertyInputSourceID), let name = Layouts.property(s,kTISPropertyLocalizedName) else { return nil }
            return (id,name)
        },id:\.0) { id,name in Text(["com.apple.keylayout.Russian":"Русская", "com.apple.keylayout.RussianWin":"Русская — ПК" ][id] ?? name).tag(id) }
    }
    var shortcuts: some View {
        Form {
            Section {
                ForEach(Array(["Включить / выключить автопереключение","Исправить слово или выделение / отменить исправление","Сменить регистр выделенного текста","Сменить раскладку","Luna: исправить сразу","Luna: проверить перед заменой"].enumerated()),id:\.offset) { i,name in
                    VStack(alignment:.leading,spacing:12) {
                        Text(name)
                        HStack {
                            Button { settings.recording = i; engine.recordingPeak = 0 } label: {
                                Text(settings.recording == i ? "Нажмите сочетание…" : shortcutLabel(settings.value.shortcuts[i])).font(.system(size:settings.recording == i || !settings.value.shortcuts[i].enabled ? 13 : 20,weight:.medium)).frame(minWidth:170,minHeight:28)
                            }.disabled(!settings.running)
                            if settings.value.shortcuts[i].enabled { Button("Сбросить",systemImage:"xmark.circle") { settings.value.shortcuts[i] = Shortcut() }.labelStyle(.iconOnly).buttonStyle(.borderless) }
                        }
                    }.padding(.vertical,6)
                }
            } footer: { Text("Для ⌘⌥⇧ нажмите все три клавиши и отпустите. Escape отменяет запись. Сочетание с буквенной клавишей срабатывает при её нажатии.") }
            Button("По умолчанию") { settings.value.shortcuts = [Shortcut(),Shortcut(modifiers:Shortcut.option),Shortcut(key:6,modifiers:Shortcut.control | Shortcut.option),Shortcut(),Preferences.lunaShortcut,Preferences.lunaReviewShortcut] }
        }.formStyle(.grouped)
    }
    var rules: some View {
        VStack(spacing:0) {
            Form {
                Toggle("Включить самообучение",isOn:$settings.value.learning)
                Toggle("Предлагать самообучение после отмены исправления",isOn:$settings.value.showLearningPrompt)
            }.formStyle(.grouped).frame(height:140)
            if settings.value.rules.isEmpty {
                ContentUnavailableView("Правил пока нет",systemImage:"text.badge.plus",description:Text("Добавьте слово, сочетание букв или регулярное выражение."))
                    .frame(maxWidth:.infinity,maxHeight:.infinity)
            } else { List {
                ForEach($settings.value.rules) { $rule in
                    HStack {
                        Toggle("Включено",isOn:$rule.enabled).labelsHidden()
                        VStack(alignment:.leading,spacing:4) { Text(rule.text).font(.system(.body,design:.monospaced)); Text("\(modeLabel(rule.mode)) · \(rule.switches ? "Менять раскладку" : "Не менять раскладку")").font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        Button("Изменить") { editing = rule; newRule = true }.buttonStyle(.borderless)
                        Button("Удалить",systemImage:"minus.circle") { settings.value.rules.removeAll { $0.id == rule.id } }.labelStyle(.iconOnly).buttonStyle(.borderless)
                    }.padding(.vertical,5)
                }
            }.listStyle(.inset) }
            HStack { Button("Добавить правило",systemImage:"plus") { editing = nil; newRule = true }; Spacer(); Text("Правил: \(settings.value.rules.count)").foregroundStyle(.secondary).font(.caption) }.controlSize(.large).padding(24)
        }
    }
    var profiles: some View { AppProfilesView(settings:settings,engine:engine) }
    var sounds: some View {
        Form {
            Toggle("Использовать звуковые эффекты",isOn:$settings.value.sound)
            Section("Озвучивать события") {
                ForEach([("ru","Переход на русскую раскладку"),("en","Переход на английскую раскладку"),("selection","Конвертация выделенного текста"),("auto","Автопереключение"),("undo","Отмена автопереключения"),("keystroke","Нажатие клавиши"),("misprint","Опечатка")],id:\.0) { id,name in
                    HStack { Toggle(name,isOn:Binding(get:{settings.value.sounds.contains(id)},set:{ if $0 { settings.value.sounds.insert(id) } else { settings.value.sounds.remove(id) } })); Button("Прослушать",systemImage:"play.circle") { engine.sound(id) }.labelStyle(.iconOnly).buttonStyle(.borderless) }
                }
            }.disabled(!settings.value.sound)
        }.formStyle(.grouped)
    }
    var about: some View {
        Form {
            Section {
                LabeledContent("Версия",value:Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? "Из исходников")
                LabeledContent("Платформа",value:"Swift · AppKit · SwiftUI")
                LabeledContent("Языковых правил",value:"\(engine.rules.count)")
                Text("Переключение раскладки работает на этом Mac. Luna отправляет выбранный текст в Codex по вашей команде. История набора не сохраняется.").foregroundStyle(.secondary)
            }
            Section("Сегодня") {
                LabeledContent("Набрано символов",value:"\(settings.symbols)")
                LabeledContent("Автопереключений",value:"\(settings.switches)")
                LabeledContent("Ручных конвертаций",value:"\(settings.manual)")
            }
            Section {
                Button("Помощь") { showHelp = true }
                Button("Открыть папку настроек") { settings.flush(); NSWorkspace.shared.open(settings.folder) }
            }
            Section("Обновления") {
                if Bundle.main.object(forInfoDictionaryKey:"PuntoReleaseCandidate") != nil {
                Toggle("Проверять обновления автоматически",isOn:$settings.value.checkUpdates)
                HStack {
                    Button("Проверить обновления") { updates.check() }.disabled(updates.checking)
                    if updates.available { Button("Установить и перезапустить") { updates.install() }.buttonStyle(.borderedProminent) }
                }
                if let checked = updates.lastChecked { LabeledContent("Последняя проверка",value:checked.formatted(Date.FormatStyle(date:.abbreviated,time:.shortened).locale(Locale(identifier:"ru_RU")))) }
                Text(updates.status.isEmpty ? "Локальный канал сборок" : updates.status).font(.caption).foregroundStyle(.secondary)
                } else {
                    Link("Версии на GitHub",destination:URL(string:"https://github.com/rshagiev/punto-switcher/releases")!)
                    Text("Новые версии устанавливаются из раздела Releases.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }.formStyle(.grouped)
    }
    func openPrivacy(_ pane: String) { if let url = URL(string:"x-apple.systempreferences:com.apple.preference.security?\(pane)") { NSWorkspace.shared.open(url) } }
}

func modeLabel(_ mode: UserRule.Mode) -> String {
    switch mode { case .exact:return "Полное совпадение";case .prefix:return "Начинается с";case .contains:return "Содержит";case .regex:return "Регулярное выражение" }
}
struct RuleEditor: View {
    @Environment(\.dismiss) var dismiss
    @State var rule: UserRule
    let save: (UserRule) -> Void
    var body: some View {
        VStack(alignment:.leading,spacing:20) {
            Text("Правило переключения").font(.title2.bold())
            TextField("Слово или сочетание символов",text:$rule.text).textFieldStyle(.roundedBorder)
            Picker("Условие",selection:$rule.mode) { ForEach(UserRule.Mode.allCases,id:\.self) { Text(modeLabel($0)).tag($0) } }
            Toggle("Учитывать регистр",isOn:$rule.caseSensitive)
            Toggle("Менять раскладку при совпадении",isOn:$rule.switches)
            if !rule.text.isEmpty && !rule.valid { Text("Проверьте регулярное выражение").foregroundStyle(.red) }
            HStack { Spacer(); Button("Отмена") { dismiss() }.keyboardShortcut(.cancelAction); Button("Сохранить") { save(rule); dismiss() }.buttonStyle(.borderedProminent).disabled(!rule.valid).keyboardShortcut(.defaultAction) }
        }.padding(26).frame(width:420)
    }
}


struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings: Settings
    var body: some View {
        VStack(alignment:.leading,spacing:20) {
            Text("Как пользоваться Punto Native").font(.title2.bold())
            GeometryReader { geometry in
              ScrollView {
                VStack(alignment:.leading,spacing:18) {
                    entry("Исправить набранное слово", "Нажмите \(shortcutLabel(settings.value.shortcuts[1])). Повторное нажатие вернёт исходный текст. Можно исправить слово сразу после одного пробела.")
                    entry("Исправить выделение", "Выделите текст и нажмите то же сочетание. Для смены регистра используйте \(shortcutLabel(settings.value.shortcuts[2])). В терминале конвертация выделенного текста следует поведению вставки самого терминала.")
                    entry("Автопереключение", "Включается в меню Punto или в основных настройках. Исключения для слов задаются в разделе «Правила», для программ — в разделе «Профили».")
                    entry("Профили приложений", "В разделе «Профили» можно включить автоматическое переключение, оставить только ручное или полностью отключить Punto для отдельного приложения. Остальные приложения используют общие настройки.")
                    entry("Индикатор раскладки", "При обычном переключении используется системный индикатор macOS. После конвертации Punto на полсекунды показывает метку раскладки возле курсора. Её можно отключить в основных настройках.")
                    entry("Самообучение", "После двух отмен исправления одного слова Punto добавит его в правила, если самообучение включено. Слова короче трёх символов не запоминаются. Регистр учитывается.")
                    entry("Назначить сочетание", "Откройте «Шорткаты», нажмите кнопку нужной команды и новое сочетание. Если используются только модификаторы, отпустите все клавиши. Escape отменяет запись.")
                    entry("Если переключение недоступно", "Убедитесь, что работает только один Punto, а в настройках macOS новому приложению разрешён Универсальный доступ. Защищённые поля паролей и режим Secure Keyboard Entry не обрабатываются.")
                }.frame(width:max(0,geometry.size.width-24),alignment:.leading).padding(.trailing,24)
              }
            }
            HStack { Spacer(); Button("Готово") { dismiss() }.keyboardShortcut(.cancelAction) }
        }.padding(26).frame(width:540,height:590)
    }
    func entry(_ title: String, _ body: String) -> some View {
        VStack(alignment:.leading,spacing:6) { Text(title).font(.headline); Text(body).foregroundStyle(.secondary).fixedSize(horizontal:false,vertical:true) }
    }
}

func appModeLabel(_ mode: AppMode) -> String {
    switch mode {
    case .global: return "Как в общих настройках"
    case .automatic: return "Автоматически"
    case .manual: return "Только вручную"
    case .disabled: return "Отключено"
    }
}
