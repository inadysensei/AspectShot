import Foundation

/// Builds the output filename for a captured screenshot.
public enum ScreenshotNaming {
    /// `ScreenShot_yyyyMMdd_HHmmss.png`, e.g. `ScreenShot_20260618_074900.png`.
    ///
    /// `timeZone` is injectable so the format is deterministically testable; production callers
    /// use the current time zone.
    public static func filename(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "ScreenShot_\(formatter.string(from: date)).png"
    }
}
