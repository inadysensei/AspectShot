import CoreGraphics

/// Pure, stateless geometry for an aspect-locked crop frame, confined to a bounding size.
///
/// All coordinates are points with a top-left origin (the same space SwiftUI uses for a
/// full-screen overlay's local coordinates), which keeps the eventual crop a straight scale-up.
public struct AspectGeometry {
    public let aspectRatio: CGFloat   // width / height
    public let minWidth: CGFloat
    public let bounds: CGSize

    public init(aspectRatio: CGFloat, minWidth: CGFloat, bounds: CGSize) {
        self.aspectRatio = aspectRatio
        self.minWidth = minWidth
        self.bounds = bounds
    }

    /// Builds an aspect-correct rect anchored at `anchor`, extending toward `current`.
    ///
    /// The frame grows to cover the drag on its dominant axis, is floored at `minWidth`, and is
    /// uniformly scaled down if it would spill past the bounds — so the aspect ratio is
    /// preserved in every case.
    ///
    /// Note: the `minWidth` floor is best-effort. When the anchor sits within `minWidth` of an
    /// edge, the bounds-clamp can scale the frame below the minimum; `CropGeometry` still
    /// guarantees a valid (≥ 1px) capture, so this only affects very-near-edge selections.
    public func rect(anchor: CGPoint, current: CGPoint) -> CGRect {
        let dx = current.x - anchor.x
        let dy = current.y - anchor.y

        var w = abs(dx)
        var h = abs(dy)

        // Expand to the locked ratio using whichever axis the pointer pushed further.
        if w < h * aspectRatio {
            w = h * aspectRatio
        } else {
            h = w / aspectRatio
        }

        // Floor at the minimum size.
        if w < minWidth {
            w = minWidth
            h = w / aspectRatio
        }

        // Clamp within bounds by uniformly scaling down (keeps the ratio intact).
        let availableW = dx < 0 ? anchor.x : (bounds.width - anchor.x)
        let availableH = dy < 0 ? anchor.y : (bounds.height - anchor.y)
        var scale: CGFloat = 1
        if w > availableW, availableW > 0 { scale = min(scale, availableW / w) }
        if h > availableH, availableH > 0 { scale = min(scale, availableH / h) }
        if scale < 1 {
            w *= scale
            h *= scale
        }

        let originX = dx < 0 ? anchor.x - w : anchor.x
        let originY = dy < 0 ? anchor.y - h : anchor.y
        return CGRect(x: originX, y: originY, width: w, height: h)
    }

    /// Translates `rect` by `translation`, clamped so it stays fully within the bounds. The size
    /// is preserved; computing from a fixed start rect lets a reversing drag un-clamp correctly.
    public func moved(_ rect: CGRect, by translation: CGSize) -> CGRect {
        var origin = CGPoint(x: rect.minX + translation.width,
                             y: rect.minY + translation.height)
        origin.x = min(max(0, origin.x), bounds.width - rect.width)
        origin.y = min(max(0, origin.y), bounds.height - rect.height)
        return CGRect(origin: origin, size: rect.size)
    }
}
