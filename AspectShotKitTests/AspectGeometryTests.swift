import XCTest
@testable import AspectShotKit

final class AspectGeometryTests: XCTestCase {
    private let aspect: CGFloat = 16.0 / 9.0

    private func makeGeometry(bounds: CGSize) -> AspectGeometry {
        AspectGeometry(aspectRatio: aspect, minWidth: 96, bounds: bounds)
    }

    private func assertAspect(_ rect: CGRect, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(rect.width / rect.height, aspect, accuracy: 0.001, "aspect not maintained", file: file, line: line)
    }

    func testHorizontalDominantDragDerivesHeightFromWidth() {
        let g = makeGeometry(bounds: CGSize(width: 4000, height: 4000))
        let rect = g.rect(anchor: .zero, current: CGPoint(x: 320, y: 10))
        assertAspect(rect)
        XCTAssertEqual(rect.origin, .zero)
        XCTAssertEqual(rect.width, 320, accuracy: 0.001)
        XCTAssertEqual(rect.height, 180, accuracy: 0.001)
    }

    func testVerticalDominantDragDerivesWidthFromHeight() {
        let g = makeGeometry(bounds: CGSize(width: 4000, height: 4000))
        let rect = g.rect(anchor: .zero, current: CGPoint(x: 10, y: 180))
        assertAspect(rect)
        XCTAssertEqual(rect.width, 320, accuracy: 0.001)
        XCTAssertEqual(rect.height, 180, accuracy: 0.001)
    }

    func testMinimumWidthIsEnforced() {
        let g = makeGeometry(bounds: CGSize(width: 4000, height: 4000))
        let rect = g.rect(anchor: .zero, current: CGPoint(x: 1, y: 1))
        assertAspect(rect)
        XCTAssertEqual(rect.width, 96, accuracy: 0.001)
        XCTAssertEqual(rect.height, 54, accuracy: 0.001)
    }

    func testNegativeDirectionAnchorsToTopLeftOfTheTwoPoints() {
        let g = makeGeometry(bounds: CGSize(width: 4000, height: 4000))
        // dx = -320, dy = -180 → frame extends up-left from the anchor.
        let rect = g.rect(anchor: CGPoint(x: 500, y: 500), current: CGPoint(x: 180, y: 320))
        assertAspect(rect)
        XCTAssertEqual(rect.origin.x, 180, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, 320, accuracy: 0.001)
        XCTAssertEqual(rect.width, 320, accuracy: 0.001)
        XCTAssertEqual(rect.height, 180, accuracy: 0.001)
    }

    func testFrameIsScaledDownUniformlyToStayWithinBounds() {
        let g = makeGeometry(bounds: CGSize(width: 400, height: 400))
        // Wants 800×450 but only 400×400 available → uniform 0.5 scale.
        let rect = g.rect(anchor: .zero, current: CGPoint(x: 800, y: 10))
        assertAspect(rect)
        XCTAssertLessThanOrEqual(rect.maxX, 400.001)
        XCTAssertLessThanOrEqual(rect.maxY, 400.001)
        XCTAssertEqual(rect.width, 400, accuracy: 0.001)
        XCTAssertEqual(rect.height, 225, accuracy: 0.001)
    }

    func testMoveClampsWithinBoundsAndPreservesSize() {
        let g = makeGeometry(bounds: CGSize(width: 1000, height: 800))
        let start = CGRect(x: 100, y: 100, width: 320, height: 180)

        let nudged = g.moved(start, by: CGSize(width: -200, height: -50))
        XCTAssertEqual(nudged.origin.x, 0, accuracy: 0.001)
        XCTAssertEqual(nudged.origin.y, 50, accuracy: 0.001)
        XCTAssertEqual(nudged.size, start.size)

        let shoved = g.moved(start, by: CGSize(width: 5000, height: 5000))
        XCTAssertEqual(shoved.origin.x, 1000 - 320, accuracy: 0.001)
        XCTAssertEqual(shoved.origin.y, 800 - 180, accuracy: 0.001)
        XCTAssertEqual(shoved.size, start.size)
    }
}
