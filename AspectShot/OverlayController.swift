import AppKit
import SwiftUI
import AspectShotKit

/// Owns one overlay panel per screen and coordinates capture, cancellation, and teardown.
///
/// Each screen gets an independent `SelectionModel`, so all selection geometry stays local to a
/// single display — no global multi-display coordinate conversion. A selection therefore lives
/// on one screen at a time, which is the intended behavior.
@MainActor
final class OverlayController {
    private var panels: [OverlayPanel] = []
    private var models: [SelectionModel] = []
    private var keyMonitor: Any?
    private var captureCoordinator: CaptureCoordinator?

    /// Builds and shows the overlays, then activates the app so a panel can become key.
    func start() {
        for screen in NSScreen.screens {
            let model = SelectionModel(screenSize: screen.frame.size)
            let panel = OverlayPanel(screen: screen)

            let view = OverlayView(
                model: model,
                onShutter: { [weak self] in self?.capture(model: model, screen: screen) }
            )
            let hosting = NSHostingView(rootView: view)
            hosting.frame = panel.contentLayoutRect
            hosting.autoresizingMask = [.width, .height]
            panel.contentView = hosting

            panels.append(panel)
            models.append(model)
        }

        captureCoordinator = CaptureCoordinator(
            prepare: { [weak self] in
                // Hide all overlays so the dimming / frame chrome can't appear in the shot even
                // if window exclusion is imperfect, and so the user sees a clean capture.
                self?.panels.forEach { $0.orderOut(nil) }
            },
            onSuccess: { [weak self] in self?.quit() },
            onFailure: { [weak self] error in self?.handleCaptureFailure(error) }
        )

        installKeyMonitor()

        // Activation policy is already `.accessory` via LSUIElement + AppDelegate; activating
        // here lets a borderless panel become key to receive Esc and mouse events.
        NSApp.activate(ignoringOtherApps: true)
        for panel in panels {
            panel.orderFrontRegardless()
        }
        panels.first?.makeKey()
    }

    /// CoreGraphics window IDs for every overlay panel, so ScreenCaptureKit can exclude them.
    private var excludedWindowIDs: [CGWindowID] {
        panels.map { CGWindowID($0.windowNumber) }
    }

    // MARK: - Keyboard (Esc)

    private func installKeyMonitor() {
        // A local monitor reliably catches Esc regardless of SwiftUI focus / responder-chain
        // subtleties with borderless panels.
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 { // Esc
                self.handleEscape()
                return nil
            }
            return event
        }
    }

    /// Esc clears the active selection (so the user can redraw); pressing it with nothing
    /// selected quits the app.
    private func handleEscape() {
        if let model = activeModel(), model.hasSelection {
            model.reset()
        } else {
            quit()
        }
    }

    /// The model of whichever panel is currently key; falls back to any model with a selection.
    private func activeModel() -> SelectionModel? {
        if let key = NSApp.keyWindow as? OverlayPanel,
           let index = panels.firstIndex(where: { $0 === key }) {
            return models[index]
        }
        return models.first(where: { $0.hasSelection }) ?? models.first
    }

    // MARK: - Capture

    private func capture(model: SelectionModel, screen: NSScreen) {
        guard let rect = model.rect, let displayID = screen.displayID,
              let coordinator = captureCoordinator else { return }

        let scale = screen.backingScaleFactor
        let pointSize = screen.frame.size
        let excluded = excludedWindowIDs

        // The coordinator guards re-entrancy and runs prepare → capture → success / failure.
        Task {
            await coordinator.run {
                let full = try await ScreenCaptureService.captureDisplay(
                    displayID: displayID,
                    pointSize: pointSize,
                    scale: scale,
                    excludingWindowIDs: excluded
                )
                let cropped = try ScreenCaptureService.crop(full, toPointRect: rect, scale: scale)
                try ImageSaver.savePNG(cropped)
            }
        }
    }

    private func handleCaptureFailure(_ error: Error) {
        // The panels are still hidden (from the coordinator's `prepare`), so the alert shows over
        // the live screen rather than behind the shield-level dimming overlay.
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "撮影に失敗しました"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.runModal()

        // Bring the overlays back so the user can adjust and retry.
        for panel in panels {
            panel.orderFrontRegardless()
        }
        panels.first?.makeKey()
    }

    private func quit() {
        teardown()
        NSApp.terminate(nil)
    }

    private func teardown() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }
}
