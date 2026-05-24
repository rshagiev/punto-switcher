import Foundation
import PuntoCore
import ServiceManagement

enum LoginItemController {
    static func setEnabled(_ enabled: Bool, bundleIdentifier: String?) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                PuntoLog.error("Failed to update login item: \(error)")
            }
        } else {
            let identifier = bundleIdentifier ?? "com.rshagiev.Punto"
            SMLoginItemSetEnabled(identifier as CFString, enabled)
        }
    }
}
