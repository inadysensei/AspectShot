import XCTest
@testable import AspectShotKit

final class CropGeometryTests: XCTestCase {
    private let image = CGSize(width: 1000, height: 1000)

    func testScalesPointRectToPixels() {
        let rect = CropGeometry.pixelRect(
            forPointRect: CGRect(x: 10, y: 20, width: 100, height: 50),
            scale: 2,
            imagePixelSize: image
        )
        XCTAssertEqual(rect, CGRect(x: 20, y: 40, width: 200, height: 100))
    }

    func testClampsToImageBounds() {
        let rect = CropGeometry.pixelRect(
            forPointRect: CGRect(x: 900, y: 900, width: 200, height: 200),
            scale: 1,
            imagePixelSize: image
        )
        XCTAssertEqual(rect, CGRect(x: 900, y: 900, width: 100, height: 100))
    }

    func testReturnsNilWhenFullyOutOfBounds() {
        let rect = CropGeometry.pixelRect(
            forPointRect: CGRect(x: 2000, y: 2000, width: 100, height: 100),
            scale: 1,
            imagePixelSize: image
        )
        XCTAssertNil(rect)
    }

    func testRoundsToIntegralPixels() {
        let rect = CropGeometry.pixelRect(
            forPointRect: CGRect(x: 0, y: 0, width: 10.4, height: 10.6),
            scale: 1,
            imagePixelSize: image
        )
        XCTAssertEqual(rect, CGRect(x: 0, y: 0, width: 11, height: 11))
    }
}
