import AppKit

extension NSScreen {
    /// The CoreGraphics display identifier for this screen, used to match against
    /// `SCDisplay.displayID` when building a ScreenCaptureKit content filter.
    var displayID: CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let number = deviceDescription[key] as? NSNumber else { return nil }
        return CGDirectDisplayID(number.uint32Value)
    }
}
