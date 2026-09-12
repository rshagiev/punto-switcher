import AppKit
import Security
import Combine

/// Local signed release channel. No network service is silently substituted for a release feed.
final class Updates: ObservableObject {
    @Published var status = ""
    @Published var lastChecked: Date?
    @Published var available = false
    @Published var checking = false
    let settings: Settings
    private var candidate: URL?
    private var timer: Timer?
    init(settings: Settings) {
        self.settings = settings
        timer = Timer.scheduledTimer(withTimeInterval:6*3600,repeats:true) { [weak self] _ in
            guard let self, self.settings.value.checkUpdates else { return }; self.check()
        }
        if settings.value.checkUpdates { DispatchQueue.main.asyncAfter(deadline:.now()+5) { [weak self] in self?.check() } }
    }
    static func isTrusted(_ url: URL) -> Bool {
        var current: SecCode?, currentStatic: SecStaticCode?, requirement: SecRequirement?, candidate: SecStaticCode?
        guard SecCodeCopySelf([], &current) == errSecSuccess, let current,
              SecCodeCopyStaticCode(current, [], &currentStatic) == errSecSuccess, let currentStatic,
              SecCodeCopyDesignatedRequirement(currentStatic, [], &requirement) == errSecSuccess, let requirement,
              SecStaticCodeCreateWithPath(url as CFURL, [], &candidate) == errSecSuccess, let candidate else { return false }
        return SecStaticCodeCheckValidity(candidate, SecCSFlags(rawValue:kSecCSStrictValidate), requirement) == errSecSuccess
    }
    func check() {
        guard !checking else { return }; checking = true
        defer { checking = false; lastChecked = Date() }
        guard let path = Bundle.main.object(forInfoDictionaryKey:"PuntoReleaseCandidate") as? String else { status = "Канал обновлений не настроен"; available = false; return }
        let url = URL(fileURLWithPath:path)
        guard url.standardizedFileURL != Bundle.main.bundleURL.standardizedFileURL,
              let info = NSDictionary(contentsOf:url.appendingPathComponent("Contents/Info.plist")) as? [String:Any],
              let build = info["CFBundleVersion"] as? String,
              let current = Bundle.main.object(forInfoDictionaryKey:"CFBundleVersion") as? String else {
            status = "Новых локальных сборок нет"; available = false; return
        }
        guard build.compare(current,options:.numeric) == .orderedDescending else { status = "Установлена последняя локальная сборка"; available = false; return }
        guard Self.isTrusted(url) else { status = "Подпись новой сборки не прошла проверку"; available = false; return }
        candidate = url; available = true; status = "Доступна новая локальная сборка"
    }
    func install() {
        guard let candidate, Self.isTrusted(candidate) else { status = "Не удалось проверить новую сборку"; return }
        let installed = Bundle.main.bundleURL
        guard installed.path.hasPrefix("/Applications/"), installed.lastPathComponent == "PuntoNative.app" else { status = "Сначала установите приложение в Программы"; return }
        do {
            let fm = FileManager.default
            let stage = installed.deletingLastPathComponent().appendingPathComponent(".PuntoNative-update-\(UUID().uuidString).app")
            try fm.copyItem(at:candidate,to:stage)
            guard Self.isTrusted(stage) else { try? fm.removeItem(at:stage); status = "Копия обновления не прошла проверку"; return }
            try fm.createDirectory(at:settings.folder,withIntermediateDirectories:true)
            let helper = settings.folder.appendingPathComponent("install-update.sh")
            let backup = settings.folder.appendingPathComponent("Previous-\(UUID().uuidString).app")
            let script = """
            #!/bin/sh
            set -eu
            for attempt in 1 2 3 4 5 6 7 8 9 10; do
              kill -0 "$1" 2>/dev/null || break
              sleep 1
            done
            if kill -0 "$1" 2>/dev/null; then exit 1; fi
            /bin/mv "$2" "$4"
            if /bin/mv "$3" "$2"; then
              /usr/bin/open "$2"
            else
              /bin/mv "$4" "$2"
              /usr/bin/open "$2"
              exit 1
            fi
            """
            try script.write(to:helper,atomically:true,encoding:.utf8)
            let process = Process(); process.executableURL = URL(fileURLWithPath:"/bin/sh")
            process.arguments = [helper.path,String(ProcessInfo.processInfo.processIdentifier),installed.path,stage.path,backup.path]
            try process.run(); NSApp.terminate(nil)
        } catch { status = error.localizedDescription }
    }
}
