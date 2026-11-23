import ApplicationServices
import CoreGraphics

enum KeyboardPermission {
    case accessibility
    case postEvents
    case inputMonitoring

    var isGranted: Bool {
        switch self {
        case .accessibility: return AXIsProcessTrusted()
        case .postEvents: return CGPreflightPostEventAccess()
        case .inputMonitoring: return CGPreflightListenEventAccess()
        }
    }

    static func firstMissing(check: (Self) -> Bool = { $0.isGranted }, canTapKeys: () -> Bool) -> Self? {
        if !check(.accessibility) { return .accessibility }
        if !check(.postEvents) { return .postEvents }
        if !check(.inputMonitoring) && !canTapKeys() { return .inputMonitoring }
        return nil
    }
}
