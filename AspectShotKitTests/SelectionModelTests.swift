import XCTest
@testable import AspectShotKit

@MainActor
final class SelectionModelTests: XCTestCase {
    private func makeModel(_ size: CGSize = CGSize(width: 2000, height: 2000)) -> SelectionModel {
        SelectionModel(screenSize: size)
    }

    func testInitialState() {
        let model = makeModel()
        XCTAssertEqual(model.phase, .idle)
        XCTAssertNil(model.rect)
        XCTAssertFalse(model.hasSelection)
    }

    func testBeginDragEntersDraggingWithAFrame() {
        let model = makeModel()
        model.beginDrag(at: CGPoint(x: 100, y: 100))
        XCTAssertEqual(model.phase, .dragging)
        XCTAssertNotNil(model.rect)
    }

    func testEndDragFinalizesSelection() {
        let model = makeModel()
        model.beginDrag(at: .zero)
        model.updateDrag(to: CGPoint(x: 320, y: 180))
        model.endDrag()
        XCTAssertEqual(model.phase, .selected)
        XCTAssertTrue(model.hasSelection)
        XCTAssertEqual(model.rect!.width / model.rect!.height, 16.0 / 9.0, accuracy: 0.001)
    }

    func testResizeKeepsOppositeCornerPinnedAndAspectLocked() {
        let model = makeModel()
        model.beginDrag(at: CGPoint(x: 100, y: 100))
        model.updateDrag(to: CGPoint(x: 420, y: 280)) // 320×180 at (100,100)
        model.endDrag()

        model.resize(corner: .bottomRight, to: CGPoint(x: 740, y: 300))
        let rect = model.rect!
        XCTAssertEqual(rect.minX, 100, accuracy: 0.001, "top-left anchor must stay pinned")
        XCTAssertEqual(rect.minY, 100, accuracy: 0.001)
        XCTAssertEqual(rect.width / rect.height, 16.0 / 9.0, accuracy: 0.001)
    }

    func testMoveTranslatesAndClamps() {
        let model = makeModel(CGSize(width: 1000, height: 800))
        model.beginDrag(at: CGPoint(x: 100, y: 100))
        model.updateDrag(to: CGPoint(x: 420, y: 280))
        model.endDrag()

        model.move(by: CGSize(width: -500, height: 0)) // pushes past the left edge
        XCTAssertEqual(model.rect!.minX, 0, accuracy: 0.001)
        XCTAssertEqual(model.rect!.minY, 100, accuracy: 0.001)
        model.endMove()
    }

    func testResetReturnsToIdle() {
        let model = makeModel()
        model.beginDrag(at: .zero)
        model.updateDrag(to: CGPoint(x: 320, y: 180))
        model.endDrag()
        model.reset()
        XCTAssertEqual(model.phase, .idle)
        XCTAssertNil(model.rect)
        XCTAssertFalse(model.hasSelection)
    }
}
