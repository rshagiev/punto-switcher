import Foundation

public enum SearchShortcutDestination: Equatable {
    case yandexSearch
    case yandexTranslate
}

public enum SearchShortcutPolicy {
    public static let yandexClid = "141986"
    public static let yandexSoft = "puntomac"

    public static func normalizedQuery(_ text: String) -> String? {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? nil : query
    }

    public static func url(for text: String, destination: SearchShortcutDestination) -> URL? {
        guard let query = normalizedQuery(text) else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "http"

        switch destination {
        case .yandexSearch:
            components.host = "yandex.ru"
            components.path = "/yandsearch"
            components.queryItems = [
                URLQueryItem(name: "text", value: query),
                URLQueryItem(name: "clid", value: yandexClid),
                URLQueryItem(name: "yasoft", value: yandexSoft)
            ]
        case .yandexTranslate:
            components.host = "translate.yandex.ru"
            components.path = "/"
            components.queryItems = [
                URLQueryItem(name: "text", value: query),
                URLQueryItem(name: "clid", value: yandexClid)
            ]
        }

        return components.url
    }
}
