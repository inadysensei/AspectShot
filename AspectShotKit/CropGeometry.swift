import CoreGraphics

/// Pure pixel-space crop math, isolated from ScreenCaptureKit so it is unit-testable.
public enum CropGeometry {
    /// Converts a selection rect in points (top-left origin) to the integral pixel rect to crop
    /// from a full-display image, clamped to the image's pixel bounds.
    ///
    /// Returns `nil` when the intersection is empty (selection entirely outside the image).
    /// Both the image and the point rect share a top-left origin, so this is `rect * scale`.
    public static func pixelRect(forPointRect rect: CGRect, scale: CGFloat, imagePixelSize: CGSize) -> CGRect? {
        let pixel = CGRect(
            x: rect.minX * scale,
            y: rect.minY * scale,
            width: rect.width * scale,
            height: rect.height * scale
        ).integral

        let bounds = CGRect(origin: .zero, size: imagePixelSize)
        let clamped = pixel.intersection(bounds)

        guard !clamped.isNull, clamped.width >= 1, clamped.height >= 1 else { return nil }
        return clamped
    }
}
