import CoreGraphics

/// The four resize handles. `opposite()` returns the corner that stays pinned while this one is
/// dragged, which becomes the anchor for the aspect-locked resize math.
public enum Corner: CaseIterable, Hashable {
    case topLeft, topRight, bottomLeft, bottomRight

    public func opposite() -> Corner {
        switch self {
        case .topLeft: return .bottomRight
        case .topRight: return .bottomLeft
        case .bottomLeft: return .topRight
        case .bottomRight: return .topLeft
        }
    }

    /// The point of this corner on a given rect (top-left origin space).
    public func point(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft: return CGPoint(x: rect.minX, y: rect.minY)
        case .topRight: return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft: return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight: return CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }
}
