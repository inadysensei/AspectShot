import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: OverlayController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Agent app: no Dock icon, no menu bar app — just the overlay.
        NSApp.setActivationPolicy(.accessory)

        guard PermissionManager.hasPermission() else {
            // First run (or revoked): trigger the system prompt, then guide the user. The grant
            // only takes effect after a relaunch, so we quit rather than continue.
            PermissionManager.requestPermission()
            PermissionManager.presentPermissionAlertAndQuit()
            return
        }

        let controller = OverlayController()
        self.controller = controller
        controller.start()
    }

    /// Agent apps have no windows to close, so termination is driven explicitly (capture / Esc).
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
