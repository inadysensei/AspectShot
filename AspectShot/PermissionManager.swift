import AppKit
import CoreGraphics

/// Screen Recording (TCC) permission helpers.
///
/// ScreenCaptureKit requires the Screen Recording privacy permission. macOS only surfaces the
/// system grant prompt the first time capture is attempted, and — critically — the app must be
/// **relaunched** after the user enables it before capture actually works. The denied-path UI
/// reflects that.
enum PermissionManager {
    /// True if Screen Recording is already authorized (no prompt shown).
    static func hasPermission() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Triggers the one-time system prompt. Returns the current (pre-relaunch) status.
    @discardableResult
    static func requestPermission() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    /// Shown when permission is missing. Offers to open the right System Settings pane and then
    /// quits, because the grant only takes effect on the next launch.
    static func presentPermissionAlertAndQuit() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "画面収録の許可が必要です"
        alert.informativeText = """
        AspectShot で画面を撮影するには「画面収録」の権限が必要です。

        1. 「システム設定を開く」を押す
        2. プライバシーとセキュリティ → 画面収録 で AspectShot をオンにする
        3. AspectShot をもう一度起動する

        （macOS の仕様上、許可の反映には再起動が必要です）
        """
        alert.addButton(withTitle: "システム設定を開く")
        alert.addButton(withTitle: "終了")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openScreenRecordingSettings()
        }
        NSApp.terminate(nil)
    }

    private static func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
