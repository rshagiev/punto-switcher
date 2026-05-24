import ApplicationServices
import AppKit
import PuntoCore

/// Observes focused app accessibility state that invalidates Punto's typed-tail state.
public final class AccessibilityStateObserver {
    private var observer: AXObserver?
    private var observedApplicationElement: AXUIElement?
    private var observedPID: pid_t?
    private var observedBundleID: String?
    private let onStateInvalidated: (String, String?) -> Void

    public init(onStateInvalidated: @escaping (String, String?) -> Void) {
        self.onStateInvalidated = onStateInvalidated
    }

    deinit {
        stop()
    }

    public func observe(runningApplication: NSRunningApplication?) {
        guard let runningApplication else {
            stop()
            return
        }

        let pid = runningApplication.processIdentifier
        if observedPID == pid {
            return
        }

        stop()

        guard pid > 0 else {
            PuntoLog.info("AccessibilityStateObserver: invalid process id")
            return
        }

        var createdObserver: AXObserver?
        let createResult = AXObserverCreate(
            pid,
            { _, element, notification, refcon in
                guard let refcon else { return }
                let observer = Unmanaged<AccessibilityStateObserver>.fromOpaque(refcon).takeUnretainedValue()
                observer.handleNotification(
                    element: element,
                    notificationName: notification as String
                )
            },
            &createdObserver
        )

        guard createResult == .success, let createdObserver else {
            PuntoLog.info("AccessibilityStateObserver: failed to create observer for pid=\(pid), error=\(createResult.rawValue)")
            return
        }

        let applicationElement = AXUIElementCreateApplication(pid)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        var subscribed = 0
        for notificationName in AccessibilityNotificationPolicy.observedNotifications {
            let result = AXObserverAddNotification(
                createdObserver,
                applicationElement,
                notificationName as CFString,
                refcon
            )
            if result == .success {
                subscribed += 1
            } else {
                PuntoLog.debug("AccessibilityStateObserver: notification \(notificationName) unsupported for pid=\(pid), error=\(result.rawValue)")
            }
        }

        guard subscribed > 0 else {
            PuntoLog.info("AccessibilityStateObserver: no supported notifications for pid=\(pid)")
            return
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(createdObserver), .commonModes)
        observer = createdObserver
        observedApplicationElement = applicationElement
        observedPID = pid
        observedBundleID = runningApplication.bundleIdentifier
        PuntoLog.info("AccessibilityStateObserver: observing \(subscribed) notification(s) for app '\(runningApplication.localizedName ?? "?")'")
    }

    public func stop() {
        guard let observer else {
            observedApplicationElement = nil
            observedPID = nil
            observedBundleID = nil
            return
        }

        if let observedApplicationElement {
            for notificationName in AccessibilityNotificationPolicy.observedNotifications {
                AXObserverRemoveNotification(observer, observedApplicationElement, notificationName as CFString)
            }
        }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        self.observer = nil
        observedApplicationElement = nil
        observedPID = nil
        observedBundleID = nil
        PuntoLog.info("AccessibilityStateObserver stopped")
    }

    private func handleNotification(element: AXUIElement, notificationName: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onStateInvalidated(notificationName, self.observedBundleID)
        }
    }
}
