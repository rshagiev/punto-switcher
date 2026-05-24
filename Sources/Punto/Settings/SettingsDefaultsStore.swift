import Foundation
import PuntoCore

/// Thin typed boundary around UserDefaults so SettingsManager can stay focused on settings policy composition.
final class SettingsDefaultsStore {
    let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func register(defaults registrationDictionary: [String: Any]) {
        defaults.register(defaults: registrationDictionary)
    }

    func hasStoredValue(forKey key: String) -> Bool {
        persistentValue(forKey: key) != nil
    }

    func persistentValue(forKey key: String) -> Any? {
        storedDefaults[key]
    }

    func object(forKey key: String) -> Any? {
        defaults.object(forKey: key)
    }

    func bool(forKey key: String) -> Bool? {
        guard let value = persistentValue(forKey: key) else {
            return nil
        }
        return SettingsPersistencePolicy.boolValue(value)
    }

    func integer(forKey key: String) -> Int? {
        guard hasStoredValue(forKey: key) else {
            return nil
        }
        return defaults.integer(forKey: key)
    }

    func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    func stringArray(forKey key: String) -> [String]? {
        defaults.stringArray(forKey: key)
    }

    func dictionary(forKey key: String) -> [String: Any]? {
        defaults.dictionary(forKey: key)
    }

    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func removeObject(forKey key: String) {
        defaults.removeObject(forKey: key)
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        data(forKey: key).flatMap { try? decoder.decode(type, from: $0) }
    }

    func encodeAndSet<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? encoder.encode(value) else {
            return
        }
        set(data, forKey: key)
    }

    var storedDefaults: [String: Any] {
        guard let domainName = Bundle.main.bundleIdentifier else {
            return [:]
        }
        return defaults.persistentDomain(forName: domainName) ?? [:]
    }
}
