import AppKit

/// A borderless, transparent, full-screen panel that hosts one screen's overlay UI.
///
/// `canBecomeKey` is overridden so the panel can receive keyboard (Esc) and mouse events —
/// borderless windows refuse key status by default. We deliberately do **not** use
/// `.nonactivatingPanel`, since that would prevent the panel from becoming key.
final class OverlayPanel: NSPanel {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Sit above everything, including the menu bar, like the system screenshot tool.
        level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        isMovableByWindowBackground = false
        acceptsMouseMovedEvents = true

        // Stay put across Spaces and over full-screen apps.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        setFrame(screen.frame, display: true)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
