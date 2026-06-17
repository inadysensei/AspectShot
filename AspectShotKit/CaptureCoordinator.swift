import Foundation

/// Orchestrates the one-shot capture sequence and guards against re-entrancy.
///
/// All side effects are injected, so the sequence (prepare → capture → success / failure) and
/// the reentrancy gate are unit-testable without AppKit or ScreenCaptureKit. The app layer wires
/// in the concrete effects (hiding overlays, capturing + cropping + saving, quitting, error UI).
@MainActor
public final class CaptureCoordinator {
    /// True once a capture has started. Stays true on success (the app quits); a failure resets
    /// it so the user can retry.
    public private(set) var isCapturing = false

    private let prepare: () -> Void
    private let onSuccess: () -> Void
    private let onFailure: (Error) -> Void

    public init(
        prepare: @escaping () -> Void,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.prepare = prepare
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    /// Runs the capture sequence once. Calls made while a capture is already in flight (or after a
    /// successful one) are ignored, so repeated shutter presses can't fire overlapping captures.
    public func run(_ capture: () async throws -> Void) async {
        guard !isCapturing else { return }
        isCapturing = true
        prepare()
        do {
            try await capture()
            onSuccess()
        } catch {
            isCapturing = false
            onFailure(error)
        }
    }
}
