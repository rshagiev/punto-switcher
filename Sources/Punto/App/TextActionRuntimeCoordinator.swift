import AppKit
import Foundation
import PuntoCore
import PuntoSettings
import PuntoRuntime

/// App-side executor for shared text-action runtime effects.
///
/// PuntoCore policies still decide what should happen. This coordinator applies
/// those decisions to replacement-window state, tracked text, undo records,
/// layout switching, sound feedback, statistics, and secure-input diagnostics.
final class TextActionRuntimeCoordinator {
    private let settingsManager: SettingsManager
    private let textState: TextRuntimeStateCoordinator
    private let textAccessor: TextAccessor
    private let inputSourceManager: InputSourceManager
    private let commitRuntime: TextReplacementCommitRuntimeCoordinator
    private let currentApplicationBundleID: () -> String?
    private let runningApplicationBundleIDs: () -> [String?]
    private let isCurrentApplicationCompletelyDisabled: () -> Bool

    init(
        settingsManager: SettingsManager,
        textState: TextRuntimeStateCoordinator,
        textAccessor: TextAccessor,
        inputSourceManager: InputSourceManager,
        commitRuntime: TextReplacementCommitRuntimeCoordinator,
        currentApplicationBundleID: @escaping () -> String?,
        runningApplicationBundleIDs: @escaping () -> [String?],
        isCurrentApplicationCompletelyDisabled: @escaping () -> Bool
    ) {
        self.settingsManager = settingsManager
        self.textState = textState
        self.textAccessor = textAccessor
        self.inputSourceManager = inputSourceManager
        self.commitRuntime = commitRuntime
        self.currentApplicationBundleID = currentApplicationBundleID
        self.runningApplicationBundleIDs = runningApplicationBundleIDs
        self.isCurrentApplicationCompletelyDisabled = isCurrentApplicationCompletelyDisabled
    }

    func beginReplacementWindow() -> ReplacementWindowAction {
        textState.beginReplacementWindow()
    }

    func finishReplacementWindow() {
        textState.finishReplacementWindow()
    }

    func currentEnglishLayoutVariant() -> KeyboardLayoutVariant {
        commitRuntime.currentEnglishLayoutVariant()
    }

    func preflightTextAction(_ kind: TextActionKind) -> Bool {
        func handle(_ action: TextActionPreflightAction) -> Bool {
            switch action {
            case .proceed:
                return true

            case .skip:
                if let message = TextActionPreflightPolicy.logMessage(action: action, kind: kind) {
                    PuntoLog.info(message)
                }
                return false

            case .blockAndClear(let reason):
                clearTextStateForSecureInput(context: reason)
                if let message = TextActionPreflightPolicy.logMessage(action: action, kind: kind) {
                    PuntoLog.info(message)
                }
                return false
            }
        }

        let routeAction = TextActionRuntimePreflightPolicy.routeAction(
            kind: kind,
            isEnabled: settingsManager.isEnabled,
            isManualConversionDisabled: settingsManager.manualConversionDisabled,
            isConversionInProgress: textState.isConversionInProgress,
            isCurrentApplicationDisabled: isCurrentApplicationCompletelyDisabled()
        )
        guard handle(routeAction) else {
            return false
        }

        if textAccessor.isSecureInputEnabled() {
            return handle(TextActionRuntimePreflightPolicy.securityAction(
                kind: kind,
                isSecureInputEnabled: true,
                isPasswordField: false
            ))
        }

        if textAccessor.isPasswordField() {
            return handle(TextActionRuntimePreflightPolicy.securityAction(
                kind: kind,
                isSecureInputEnabled: false,
                isPasswordField: true
            ))
        }

        return true
    }

    func commitSuccessfulTextReplacement(_ plan: TextReplacementCommitPlan, contextID: String?) {
        commitRuntime.commitSuccessfulTextReplacement(plan, contextID: contextID)
    }

    func clearTextStateForSecureInput(context: String = "secure input") {
        let action = TextTrackingSecurityPolicy.clearAction(
            isSecureInputEnabled: context == "secure input",
            isPasswordField: context == "password field"
        )

        textState.apply(action)
        if action.shouldWriteDiagnostics, let diagnosticContext = action.diagnosticContext {
            writeSecureInputDiagnostics(context: diagnosticContext)
        }
        if let logMessage = action.logMessage {
            PuntoLog.info(logMessage)
        }
    }

    func clearTrackedTextAfterFailedReplacement(method: TextReplacementMethod) {
        let action = ReplacementFailurePolicy.actionAfterFailedReplacement(method: method)
        textState.apply(action)
    }

    func clearStateAfterFailedUndoReplacement(method: TextReplacementMethod) {
        let action = UndoReplacementPolicy.actionAfterFailedReplacement(method: method)
        textState.apply(action)
    }

    func clearStateAfterBlockedCapture(_ capturedText: CapturedText?) {
        let action = TextCapturePolicy.actionAfterBlockedCapture(capturedText)
        textState.apply(action)
    }

    func commitSuccessfulUndo(
        _ plan: UndoAppliedCommitPlan,
        contextID: String?,
        reloadAutoCorrectionRules: () -> Void
    ) {
        commitRuntime.commitSuccessfulUndo(
            plan,
            contextID: contextID,
            reloadAutoCorrectionRules: reloadAutoCorrectionRules
        )
    }

    private func writeSecureInputDiagnostics(context: String) {
        let snapshot = SecureInputDiagnosticsPolicy.snapshot(
            secureInputState: textAccessor.isSecureInputEnabled(),
            context: context,
            currentApp: currentApplicationBundleID(),
            runningApps: runningApplicationBundleIDs(),
            enabledLayouts: [
                inputSourceManager.languageLayoutID(.english),
                inputSourceManager.languageLayoutID(.russian),
                inputSourceManager.currentLayoutID()
            ]
        )
        let dictionary = SecureInputDiagnosticsPolicy.plistDictionary(from: snapshot)
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(SecureInputDiagnosticsPolicy.secureInputDiagnosticsPlistFilename)

        do {
            let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
            try data.write(to: url, options: .atomic)
            PuntoLog.info("Wrote secure input diagnostics to \(url.path)")
        } catch {
            PuntoLog.error("Failed to write secure input diagnostics: \(error)")
        }
    }
}
