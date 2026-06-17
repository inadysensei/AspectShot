import XCTest
@testable import AspectShotKit

final class CornerTests: XCTestCase {
    func testOppositeCorners() {
        XCTAssertEqual(Corner.topLeft.opposite(), .bottomRight)
        XCTAssertEqual(Corner.topRight.opposite(), .bottomLeft)
        XCTAssertEqual(Corner.bottomLeft.opposite(), .topRight)
        XCTAssertEqual(Corner.bottomRight.opposite(), .topLeft)
    }

    func testCornerPoints() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 50)
        XCTAssertEqual(Corner.topLeft.point(in: rect), CGPoint(x: 10, y: 20))
        XCTAssertEqual(Corner.topRight.point(in: rect), CGPoint(x: 110, y: 20))
        XCTAssertEqual(Corner.bottomLeft.point(in: rect), CGPoint(x: 10, y: 70))
        XCTAssertEqual(Corner.bottomRight.point(in: rect), CGPoint(x: 110, y: 70))
    }
}
