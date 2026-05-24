import AppKit
import PuntoSettings

/// Controller for the settings window - liquid glass macOS style
final class SettingsWindowController: NSWindowController {

    private let settingsManager: SettingsManager
    private let currentApplication: () -> (bundleID: String, name: String?)?
    private let setLoginItemEnabled: (Bool) -> Void
    private let hotkeySettingsController: HotkeySettingsController
    private lazy var generalSettingsController = GeneralSettingsController(
        settingsManager: settingsManager,
        setLoginItemEnabled: setLoginItemEnabled,
        showAutoCorrectionRulesEditor: { [weak self] in
            self?.autoCorrectionRulesEditorController().showAndActivate()
        },
        importAutoCorrectionRules: { [weak self] in
            self?.autoCorrectionRulesEditorController().importRules(attachedTo: self?.window)
        },
        showDisabledAppsEditor: { [weak self] in
            self?.showDisabledAppsEditor()
        },
        showResetOnReturnEditor: { [weak self] in
            self?.showResetOnReturnEditor()
        },
        showLayoutMemoryEditor: { [weak self] in
            self?.showLayoutMemoryEditor()
        }
    )
    private var autoCorrectionRulesEditor: AutoCorrectionRulesEditorController?
    private var disabledApplicationsEditor: DisabledApplicationsEditorController?
    private var resetOnReturnEditor: ResetOnReturnEditorController?
    private var layoutMemoryEditor: LayoutMemoryEditorController?

    init(
        settingsManager: SettingsManager,
        currentApplication: @escaping () -> (bundleID: String, name: String?)? = { nil },
        setLoginItemEnabled: @escaping (Bool) -> Void = { _ in }
    ) {
        self.settingsManager = settingsManager
        self.currentApplication = currentApplication
        self.setLoginItemEnabled = setLoginItemEnabled
        self.hotkeySettingsController = HotkeySettingsController(settingsManager: settingsManager)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 750),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Punto"
        window.center()
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear

        super.init(window: window)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let backgroundView = NSVisualEffectView()
        backgroundView.material = .underWindowBackground
        backgroundView.blendingMode = .behindWindow
        backgroundView.state = .active
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(backgroundView)

        // Main stack
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .centerX
        mainStack.spacing = 18
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        // Sections
        mainStack.addArrangedSubview(hotkeySettingsController.createView())
        mainStack.addArrangedSubview(generalSettingsController.createView())
        mainStack.addArrangedSubview(createFooter())
    }

    private func createFooter() -> NSView {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let label = NSTextField(labelWithString: "Punto v\(version)")
        label.font = .systemFont(ofSize: 11)
        label.textColor = .tertiaryLabelColor
        label.alignment = .center
        return label
    }

    // MARK: - Editor Windows

    private func showDisabledAppsEditor() {
        if disabledApplicationsEditor == nil {
            disabledApplicationsEditor = DisabledApplicationsEditorController(
                settingsManager: settingsManager,
                currentApplication: currentApplication,
                onChange: { [weak self] in self?.generalSettingsController.refreshDisabledAppCount() }
            )
        }
        disabledApplicationsEditor?.showAndActivate()
    }

    private func showResetOnReturnEditor() {
        if resetOnReturnEditor == nil {
            resetOnReturnEditor = ResetOnReturnEditorController(
                settingsManager: settingsManager,
                onChange: { [weak self] in self?.generalSettingsController.refreshResetOnReturnCount() }
            )
        }
        resetOnReturnEditor?.showAndActivate()
    }

    private func showLayoutMemoryEditor() {
        if layoutMemoryEditor == nil {
            layoutMemoryEditor = LayoutMemoryEditorController(
                settingsManager: settingsManager,
                onChange: { [weak self] in self?.generalSettingsController.refreshLayoutMemoryCount() }
            )
        }
        layoutMemoryEditor?.showAndActivate()
    }

    private func autoCorrectionRulesEditorController() -> AutoCorrectionRulesEditorController {
        if let autoCorrectionRulesEditor {
            return autoCorrectionRulesEditor
        }

        let editor = AutoCorrectionRulesEditorController(
            settingsManager: settingsManager,
            onChange: { [weak self] in self?.generalSettingsController.refreshRuleCount() }
        )
        autoCorrectionRulesEditor = editor
        return editor
    }
}
