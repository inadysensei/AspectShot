import XCTest
@testable import AspectShotKit

final class ScreenshotNamingTests: XCTestCase {
    private let utc = TimeZone(identifier: "UTC")!

    func testFilenameForEpochInUTC() {
        let name = ScreenshotNaming.filename(for: Date(timeIntervalSince1970: 0), timeZone: utc)
        XCTAssertEqual(name, "ScreenShot_19700101_000000.png")
    }

    func testFilenameMatchesExpectedFormat() {
        // 2026-06-18 07:49:00 UTC
        let date = Date(timeIntervalSince1970: 1_781_768_940)
        let name = ScreenshotNaming.filename(for: date, timeZone: utc)
        XCTAssertEqual(name, "ScreenShot_20260618_074900.png")
    }

    func testFilenameHasPrefixAndExtension() {
        let name = ScreenshotNaming.filename(for: Date(), timeZone: utc)
        XCTAssertTrue(name.hasPrefix("ScreenShot_"))
        XCTAssertTrue(name.hasSuffix(".png"))
    }
}
