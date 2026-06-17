import SwiftUI
import AspectShotKit

/// The full-screen overlay for one display: dimming with a punched-out crop frame, the frame
/// border, corner resize handles, and the centered shutter button.
///
/// Layering (bottom → top) controls hit-testing:
///   1. dimming — non-interactive, purely visual
///   2. full-screen capture layer — starts a *new* rubber-band selection
///   3. frame interior — *moves* the existing frame
///   4. border — non-interactive
///   5. corner handles — aspect-locked *resize*
///   6. shutter button
/// A single named coordinate space ("overlay") makes every gesture report locations in the
/// screen's top-left-origin point space, regardless of which subview it's attached to.
struct OverlayView: View {
    @ObservedObject var model: SelectionModel
    let onShutter: () -> Void

    private static let space = "aspectshot.overlay"

    var body: some View {
        ZStack {
            dimming

            // New-selection layer: a small drag threshold so a stray click doesn't spawn a frame.
            Color.clear
                .contentShape(Rectangle())
                .gesture(newSelectionGesture)

            if let rect = model.rect {
                if model.phase == .selected {
                    frameInterior(rect)
                }

                border(rect)

                if model.phase == .selected {
                    ForEach(Corner.allCases, id: \.self) { corner in
                        handle(corner, rect: rect)
                    }
                    ShutterButton(action: onShutter)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
        }
        .ignoresSafeArea()
        .coordinateSpace(.named(Self.space))
    }

    // MARK: - Visual layers

    private var dimming: some View {
        ZStack {
            Rectangle().fill(Color.black.opacity(Config.dimOpacity))
            if let rect = model.rect {
                // Punch a transparent hole so the user sees the live screen inside the frame.
                Rectangle()
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func border(_ rect: CGRect) -> some View {
        Rectangle()
            .strokeBorder(Color.white, lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .shadow(color: .black.opacity(0.4), radius: 1)
            .allowsHitTesting(false)
    }

    private func frameInterior(_ rect: CGRect) -> some View {
        Color.clear
            .frame(width: rect.width, height: rect.height)
            .contentShape(Rectangle())
            .position(x: rect.midX, y: rect.midY)
            .gesture(moveGesture)
    }

    private func handle(_ corner: Corner, rect: CGRect) -> some View {
        let point = corner.point(in: rect)
        return RoundedRectangle(cornerRadius: 2)
            .fill(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 2).stroke(.black.opacity(0.45), lineWidth: 1)
            )
            .frame(width: Config.handleSize, height: Config.handleSize)
            .shadow(color: .black.opacity(0.35), radius: 1)
            .position(x: point.x, y: point.y)
            .gesture(resizeGesture(corner))
    }

    // MARK: - Gestures

    private var newSelectionGesture: some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named(Self.space))
            .onChanged { value in
                if model.phase != .dragging {
                    model.beginDrag(at: value.startLocation)
                }
                model.updateDrag(to: value.location)
            }
            .onEnded { _ in
                model.endDrag()
            }
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
            .onChanged { value in model.move(by: value.translation) }
            .onEnded { _ in model.endMove() }
    }

    private func resizeGesture(_ corner: Corner) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
            .onChanged { value in model.resize(corner: corner, to: value.location) }
            .onEnded { _ in model.endResize() }
    }
}
