import CoreGraphics

/// Centralized tunables. The aspect ratio lives here so it is trivial to change (or, later,
/// to wire up to a ratio picker).
public enum Config {
    /// Locked capture aspect ratio. Default 16:9.
    public static let aspectWidth: CGFloat = 16
    public static let aspectHeight: CGFloat = 9

    /// width / height — the invariant the crop frame always maintains.
    public static var aspectRatio: CGFloat { aspectWidth / aspectHeight }

    /// Smallest allowed frame width in points; guards against degenerate / zero-area captures.
    public static let minWidth: CGFloat = 96

    /// Dimming applied to everything outside the crop frame.
    public static let dimOpacity: Double = 0.45

    /// Side length (points) of the square corner resize handles.
    public static let handleSize: CGFloat = 14

    /// Diameter (points) of the floating shutter button.
    public static let shutterDiameter: CGFloat = 64
}
