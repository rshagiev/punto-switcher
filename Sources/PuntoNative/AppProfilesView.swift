import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PuntoCore

struct AppProfilesView: View {
    @ObservedObject var settings: Settings
    let engine: KeyboardEngine
    @State private var targeted = false
    @State private var error = ""

    private func appURL(_ id: String) -> URL? { NSWorkspace.shared.urlForApplication(withBundleIdentifier:id) }
    private func appName(_ id: String) -> String {
        guard let url = appURL(id) else { return id }
        return FileManager.default.displayName(atPath:url.path).replacingOccurrences(of:".app",with:"")
    }
    private var apps: [String] { settings.value.appProfiles.keys.sorted { appName($0).localizedStandardCompare(appName($1)) == .orderedAscending } }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment:.leading,spacing:16) {
                HStack {
                    Text("Приложения").font(.headline)
                    Spacer()
                    Button("Добавить…",systemImage:"plus",action:chooseApps).controlSize(.large)
                }
                ScrollView {
                    VStack(spacing:0) {
                        if apps.isEmpty {
                            VStack(spacing:12) {
                                Image(systemName:"arrow.down.app").font(.system(size:30)).foregroundStyle(.secondary)
                                Text("Перетащите сюда приложения").font(.headline)
                                Text("Или выберите их кнопкой «Добавить». Пока список пуст, везде действуют общие настройки.")
                                    .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth:360)
                            }.padding(28).frame(maxWidth:.infinity,minHeight:190)
                        } else {
                            ForEach(apps,id:\.self) { id in
                                HStack(spacing:12) {
                                    if let url = appURL(id) {
                                        Image(nsImage:NSWorkspace.shared.icon(forFile:url.path)).resizable().frame(width:28,height:28)
                                    } else { Image(systemName:"app").font(.system(size:25)).frame(width:28) }
                                    Text(appName(id)).lineLimit(1).truncationMode(.middle).help(id)
                                    Spacer(minLength:8)
                                    Picker("Режим для \(appName(id))",selection:Binding(get:{settings.value.appProfiles[id] ?? .global},set:{settings.value.appProfiles[id] = $0; engine.reset()})) {
                                        ForEach(AppMode.allCases,id:\.self) { mode in Text(appModeLabel(mode)).tag(mode) }
                                    }.labelsHidden().frame(width:210)
                                    Button { settings.value.appProfiles.removeValue(forKey:id); settings.value.exceptions.removeAll { $0 == id }; engine.reset() } label: {
                                        Image(systemName:"minus.circle").foregroundStyle(.secondary)
                                    }.buttonStyle(.borderless).help("Убрать профиль \(appName(id))").accessibilityLabel("Убрать профиль \(appName(id))")
                                }.padding(.horizontal,14).padding(.vertical,12)
                                if id != apps.last { Divider().padding(.leading,54) }
                            }
                            Text("Можно перетащить сюда ещё приложения").font(.caption).foregroundStyle(.secondary).padding(14)
                        }
                    }
                    .frame(maxWidth:.infinity)
                    .background(Color(nsColor:.controlBackgroundColor),in:RoundedRectangle(cornerRadius:12))
                    .overlay(RoundedRectangle(cornerRadius:12).strokeBorder(targeted ? Color.accentColor : Color.primary.opacity(0.08),lineWidth:targeted ? 2 : 1))
                    .contentShape(Rectangle())
                    .onDrop(of:[UTType.fileURL.identifier],isTargeted:$targeted,perform:receiveDrop)
                    VStack(alignment:.leading,spacing:6) {
                        Text("Режим приложения действует вместо общего переключателя.")
                        Text("«Только вручную» — исправление по сочетанию клавиш. «Отключено» — Punto не обрабатывает ввод.")
                    }.font(.caption).foregroundStyle(.secondary).frame(maxWidth:.infinity,alignment:.leading).padding(.top,12)
                    if !error.isEmpty { Text(error).font(.callout).foregroundStyle(.red).frame(maxWidth:.infinity,alignment:.leading).padding(.top,8) }
                }
            }.padding(.horizontal,26).padding(.bottom,24).frame(width:geometry.size.width,height:geometry.size.height,alignment:.top)
        }
    }
    private func receiveDrop(_ providers:[NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }
        for provider in providers {
            provider.loadItem(forTypeIdentifier:UTType.fileURL.identifier,options:nil) { item,_ in
                let url:URL?
                if let value = item as? URL { url = value }
                else if let data = item as? Data { url = URL(dataRepresentation:data,relativeTo:nil) }
                else { url = nil }
                DispatchQueue.main.async { if let url { addApps([url]) } }
            }
        }
        return true
    }
    @discardableResult private func addApps(_ urls:[URL]) -> Bool {
        var accepted = false
        for url in urls {
            guard url.isFileURL, url.pathExtension.lowercased() == "app", let bundle = Bundle(url:url), let id = bundle.bundleIdentifier else { continue }
            if settings.value.appProfiles[id] == nil { settings.value.appProfiles[id] = .global }
            accepted = true
        }
        error = accepted ? "" : "Перетащите приложение в формате .app."
        return accepted
    }
    private func chooseApps() {
        let panel = NSOpenPanel()
        panel.title = "Добавить приложения"
        panel.prompt = "Добавить"
        panel.message = "Выберите приложения, для которых нужен отдельный режим."
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath:"/Applications")
        panel.allowsMultipleSelection = true
        let completion: (NSApplication.ModalResponse) -> Void = { response in
            if response == .OK { addApps(panel.urls) }
        }
        if let window = NSApp.keyWindow { panel.beginSheetModal(for:window,completionHandler:completion) }
        else { panel.begin(completionHandler:completion) }
    }
}
