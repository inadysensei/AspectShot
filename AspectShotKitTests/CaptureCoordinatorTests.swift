import XCTest
@testable import AspectShotKit

@MainActor
final class CaptureCoordinatorTests: XCTestCase {
    private enum TestError: Error { case boom }

    func testRunsPrepareThenCaptureThenSuccess() async {
        var events: [String] = []
        let coordinator = CaptureCoordinator(
            prepare: { events.append("prepare") },
            onSuccess: { events.append("success") },
            onFailure: { _ in events.append("failure") }
        )
        await coordinator.run { events.append("capture") }
        XCTAssertEqual(events, ["prepare", "capture", "success"])
        XCTAssertTrue(coordinator.isCapturing)
    }

    func testReentrantRunIsIgnoredWhileCapturing() async {
        var captureCount = 0
        let coordinator = CaptureCoordinator(prepare: {}, onSuccess: {}, onFailure: { _ in })
        await coordinator.run { captureCount += 1 }
        // A second shutter press must be a no-op: the first capture finished by quitting,
        // so the gate is still held.
        await coordinator.run { captureCount += 1 }
        XCTAssertEqual(captureCount, 1)
    }

    func testFailureResetsGateAndAllowsRetry() async {
        var events: [String] = []
        let coordinator = CaptureCoordinator(
            prepare: {},
            onSuccess: { events.append("success") },
            onFailure: { _ in events.append("failure") }
        )
        await coordinator.run { throw TestError.boom }
        XCTAssertFalse(coordinator.isCapturing)
        XCTAssertEqual(events, ["failure"])

        // Retry after a failure should proceed.
        await coordinator.run { events.append("capture") }
        XCTAssertEqual(events, ["failure", "capture", "success"])
    }
}
