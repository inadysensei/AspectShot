import SwiftUI

/// Entry point.
///
/// AspectShot is an agent-style overlay tool (see `LSUIElement` in Info.plist), so it has no
/// main window and no Dock icon. All of the UI lives in borderless panels that the
/// `AppDelegate` creates programmatically once the screen-recording permission is confirmed.
/// The `Settings` scene below is intentionally empty — it exists only because `App` requires a
/// `Scene`, and a `Settings` scene does not open any window on launch.
@main
struct AspectShotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
