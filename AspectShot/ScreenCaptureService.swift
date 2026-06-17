import ScreenCaptureKit
import CoreGraphics
import AspectShotKit

enum CaptureError: LocalizedError {
    case displayNotFound
    case cropFailed

    var errorDescription: String? {
        switch self {
        case .displayNotFound: return "対象のディスプレイが見つかりませんでした。"
        case .cropFailed: return "選択範囲の切り抜きに失敗しました。"
        }
    }
}

/// Captures via ScreenCaptureKit.
///
/// Strategy (deliberately the deterministic one): capture the **entire display** at native
/// resolution, excluding our own overlay windows so the dimming / frame chrome / shutter never
/// appear, then crop the resulting `CGImage` in pixel space. This avoids relying on
/// `SCStreamConfiguration.sourceRect`, whose points-vs-pixels interpretation has varied across
/// OS versions — once we have the full-display image, the crop is plain, reviewable image math.
enum ScreenCaptureService {
    /// Capture the full display. `pointSize` is the display size in points and `scale` its
    /// backing scale factor; the output buffer is sized to `pointSize * scale`, which fixes the
    /// points→pixels mapping the crop relies on.
    static func captureDisplay(
        displayID: CGDirectDisplayID,
        pointSize: CGSize,
        scale: CGFloat,
        excludingWindowIDs: [CGWindowID]
    ) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw CaptureError.displayNotFound
        }

        let excluded = content.windows.filter { excludingWindowIDs.contains($0.windowID) }
        let filter = SCContentFilter(display: display, excludingWindows: excluded)

        let config = SCStreamConfiguration()
        // Output buffer sized to the display's native pixels, which fixes the points→pixels
        // mapping the crop relies on (no letterboxing, since aspect matches the display).
        config.width = Int((pointSize.width * scale).rounded())
        config.height = Int((pointSize.height * scale).rounded())
        config.showsCursor = false

        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    /// Crop a full-display image to the selection. `rect` is in points (top-left origin, within
    /// the display); both the image and `rect` share that origin, so the crop is `rect * scale`
    /// clamped to the image bounds.
    static func crop(_ image: CGImage, toPointRect rect: CGRect, scale: CGFloat) throws -> CGImage {
        let imageSize = CGSize(width: image.width, height: image.height)
        guard let pixelRect = CropGeometry.pixelRect(forPointRect: rect, scale: scale, imagePixelSize: imageSize),
              let cropped = image.cropping(to: pixelRect) else {
            throw CaptureError.cropFailed
        }
        return cropped
    }
}
