import Foundation
import PuntoCore

final class SettingsApplicationStore {
    private let store: SettingsDefaultsStore
    private let resolver: SettingsValueResolver
    private unowned let notificationObject: AnyObject

    init(
        store: SettingsDefaultsStore,
        resolver: SettingsValueResolver,
        notificationObject: AnyObject
    ) {
        self.store = store
        self.resolver = resolver
        self.notificationObject = notificationObject
    }

    var russianKeyboardLayoutType: KeyboardLayoutType {
        get {
            resolver.russianKeyboardLayoutType(
                nativeKey: SettingsStorageKeys.russianKeyboardLayoutType,
                legacyKey: SettingsImportKeys.kbdLayoutType
            )
        }
        set {
            store.set(newValue.rawValue, forKey: SettingsStorageKeys.russianKeyboardLayoutType)
            post(.puntoRussianKeyboardLayoutTypeChanged)
            post(.puntoInputSourcePreferencesChanged)
        }
    }

    var preferredEnglishInputSourceID: String? {
        get {
            resolver.inputSourceID(
                nativeKey: SettingsStorageKeys.preferredEnglishInputSourceID,
                legacyKey: SettingsImportKeys.englishLayoutID
            )
        }
        set {
            setPreferredInputSourceID(newValue, nativeKey: SettingsStorageKeys.preferredEnglishInputSourceID)
        }
    }

    var preferredRussianInputSourceID: String? {
        get {
            resolver.inputSourceID(
                nativeKey: SettingsStorageKeys.preferredRussianInputSourceID,
                legacyKey: SettingsImportKeys.russianLayoutID
            )
        }
        set {
            setPreferredInputSourceID(newValue, nativeKey: SettingsStorageKeys.preferredRussianInputSourceID)
        }
    }

    var rememberedApplicationLayouts: [String: String] {
        get {
            ApplicationLayoutMemory.normalizedSnapshot(
                store.dictionary(forKey: SettingsStorageKeys.rememberedApplicationLayouts) as? [String: String] ?? [:]
            )
        }
        set {
            store.set(
                ApplicationLayoutMemory.normalizedSnapshot(newValue),
                forKey: SettingsStorageKeys.rememberedApplicationLayouts
            )
        }
    }

    var disabledApplicationBundleIDs: Set<String> {
        get {
            resolver.disabledApplicationBundleIDs(
                nativeKey: SettingsStorageKeys.disabledApplicationBundleIDs,
                legacyKey: SettingsImportKeys.disabledApps
            )
        }
        set {
            let normalized = Array(ApplicationDisablePolicy.normalizedSet(newValue)).sorted()
            store.set(normalized, forKey: SettingsStorageKeys.disabledApplicationBundleIDs)
        }
    }

    var resetOnReturnBundleComponents: Set<String> {
        get {
            resolver.resetOnReturnBundleComponents(
                nativeKey: SettingsStorageKeys.resetOnReturnBundleComponents,
                legacyKey: SettingsImportKeys.switcherResetOnReturn
            )
        }
        set {
            let normalized = Array(ApplicationReturnKeyPolicy.normalizedResetBundleComponents(newValue)).sorted()
            store.set(
                normalized,
                forKey: SettingsStorageKeys.resetOnReturnBundleComponents
            )
        }
    }

    func isApplicationDisabled(bundleID: String?) -> Bool {
        ApplicationDisablePolicy.isApplicationDisabled(
            bundleID: bundleID,
            disabledBundleIDs: disabledApplicationBundleIDs
        )
    }

    func isApplicationCompletelyDisabled(bundleID: String?, completelyDisableInExceptionApplications: Bool) -> Bool {
        ApplicationDisablePolicy.isApplicationCompletelyDisabled(
            bundleID: bundleID,
            disabledBundleIDs: disabledApplicationBundleIDs,
            completelyDisableInExceptionApplications: completelyDisableInExceptionApplications
        )
    }

    func setApplicationDisabled(bundleID: String?, disabled: Bool) {
        disabledApplicationBundleIDs = ApplicationDisablePolicy.disabledBundleIDsAfterSet(
            bundleID: bundleID,
            disabled: disabled,
            disabledBundleIDs: disabledApplicationBundleIDs
        )
    }

    private func setPreferredInputSourceID(_ sourceID: String?, nativeKey: String) {
        if let normalized = InputSourceSelectionPolicy.normalizedSourceID(sourceID) {
            store.set(normalized, forKey: nativeKey)
        } else {
            store.removeObject(forKey: nativeKey)
        }
        post(.puntoInputSourcePreferencesChanged)
    }

    private func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: notificationObject)
    }
}
