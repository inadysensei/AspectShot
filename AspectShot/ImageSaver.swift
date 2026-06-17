import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import AspectShotKit

enum SaveError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "PNG への変換に失敗しました。"
        }
    }
}

/// Writes a captured image to the user's Downloads folder as a timestamped PNG.
enum ImageSaver {
    /// Saves `image` to `~/Downloads/ScreenShot_yyyyMMdd_HHmmss.png` and returns the file URL.
    ///
    /// Uses `CGImageDestination` so the captured image's own color space / ICC profile is
    /// preserved (important on P3 / HDR displays), rather than round-tripping through a bitmap
    /// representation that can color-shift.
    @discardableResult
    static func savePNG(_ image: CGImage) throws -> URL {
        let downloads = try FileManager.default.url(
            for: .downloadsDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let url = downloads.appendingPathComponent(ScreenshotNaming.filename(for: Date()))

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw SaveError.encodingFailed
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw SaveError.encodingFailed
        }
        return url
    }
}
