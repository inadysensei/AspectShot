import SwiftUI

/// Drives one overlay's crop frame. All coordinates are in points with a top-left origin,
/// confined to a single screen of size `screenSize` — the same space SwiftUI uses for the
/// overlay's local coordinates, which keeps the eventual crop math a straight scale-up.
///
/// The geometry itself lives in the pure, unit-tested `AspectGeometry`; this type adds only the
/// observable state machine and transient gesture anchors.
@MainActor
public final class SelectionModel: ObservableObject {
    public enum Phase: Equatable {
        case idle       // nothing selected yet
        case dragging   // user is rubber-banding the initial frame
        case selected   // frame finalized; handles + shutter shown
    }

    @Published public private(set) var phase: Phase = .idle
    /// The crop frame, or nil when idle. Always aspect-correct and within the screen.
    @Published public private(set) var rect: CGRect?

    public let screenSize: CGSize
    private let geometry: AspectGeometry

    // Transient gesture anchors (not published; they don't drive the view directly).
    private var dragAnchor: CGPoint?
    private var moveStartRect: CGRect?
    private var resizeAnchor: CGPoint?

    public init(screenSize: CGSize, geometry: AspectGeometry? = nil) {
        self.screenSize = screenSize
        self.geometry = geometry ?? AspectGeometry(
            aspectRatio: Config.aspectRatio,
            minWidth: Config.minWidth,
            bounds: screenSize
        )
    }

    public var hasSelection: Bool { rect != nil }

    // MARK: - Initial rubber-band selection

    public func beginDrag(at point: CGPoint) {
        dragAnchor = point
        phase = .dragging
        rect = geometry.rect(anchor: point, current: point)
    }

    public func updateDrag(to point: CGPoint) {
        guard let anchor = dragAnchor else { return }
        rect = geometry.rect(anchor: anchor, current: point)
    }

    public func endDrag() {
        dragAnchor = nil
        phase = rect == nil ? .idle : .selected
    }

    // MARK: - Move (drag inside the frame)

    /// Translates the frame, clamped within the screen. The start rect is captured lazily on the
    /// first event so the whole move is computed from a fixed origin + the gesture's cumulative
    /// translation — re-clamping correctly when the pointer reverses off an edge.
    public func move(by translation: CGSize) {
        if moveStartRect == nil { moveStartRect = rect }
        guard let start = moveStartRect else { return }
        rect = geometry.moved(start, by: translation)
    }

    public func endMove() {
        moveStartRect = nil
    }

    // MARK: - Resize (drag a corner, aspect-locked)

    /// Aspect-locked resize. The opposite corner is captured as the fixed anchor on the first
    /// event and held for the rest of the gesture.
    public func resize(corner: Corner, to point: CGPoint) {
        if resizeAnchor == nil, let current = rect {
            resizeAnchor = corner.opposite().point(in: current)
        }
        guard let anchor = resizeAnchor else { return }
        rect = geometry.rect(anchor: anchor, current: point)
    }

    public func endResize() {
        resizeAnchor = nil
    }

    // MARK: - Cancel

    public func reset() {
        phase = .idle
        rect = nil
        dragAnchor = nil
        moveStartRect = nil
        resizeAnchor = nil
    }
}
