import XCTest
import AppState
@testable import MultiPlatformTracker

// MARK: - MultiPlatformTrackerTests

/// Tests for the platform-agnostic tracker state layer.
///
/// These tests run identically on macOS, Linux, and Windows — no SwiftUI or
/// Apple-platform-only APIs are required.  Each test method resets the
/// `trackerCount` `StoredState` so tests remain fully isolated from one
/// another regardless of execution order.
@MainActor
final class MultiPlatformTrackerTests: XCTestCase {

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        Application.reset(storedState: \.trackerCount)
    }

    override func tearDown() async throws {
        Application.reset(storedState: \.trackerCount)
        try await super.tearDown()
    }

    // MARK: - Initial State

    /// The count must start at zero after reset.
    func testInitialCountIsZero() {
        XCTAssertEqual(Application.storedState(\.trackerCount).value, 0)
    }

    // MARK: - Increment

    /// A single increment moves the count from 0 to 1.
    func testIncrementOnce() {
        let controller = TrackerController()

        controller.increment()

        XCTAssertEqual(controller.count, 1)
    }

    /// Multiple increments accumulate correctly.
    func testIncrementMultipleTimes() {
        let controller = TrackerController()

        controller.increment()
        controller.increment()
        controller.increment()

        XCTAssertEqual(controller.count, 3)
    }

    /// Mutations via `Application.storedState` are visible through the controller.
    func testDirectStateMutationReflectsInController() {
        var state = Application.storedState(\.trackerCount)
        state.value = 10

        let controller = TrackerController()

        XCTAssertEqual(controller.count, 10)
    }

    // MARK: - Decrement

    /// Decrement from a positive value reduces the count by one.
    func testDecrementFromPositive() {
        let controller = TrackerController()

        controller.increment()
        controller.increment()
        controller.decrement()

        XCTAssertEqual(controller.count, 1)
    }

    /// Decrement from zero is clamped — count must not go below zero.
    func testDecrementClampsAtZero() {
        let controller = TrackerController()

        controller.decrement()

        XCTAssertEqual(controller.count, 0)
    }

    /// Repeated decrements from zero all remain at zero.
    func testRepeatedDecrementAtZeroRemainsZero() {
        let controller = TrackerController()

        for _ in 0 ..< 5 {
            controller.decrement()
        }

        XCTAssertEqual(controller.count, 0)
    }

    // MARK: - Reset

    /// Reset after increments returns the count to zero.
    func testResetAfterIncrements() {
        let controller = TrackerController()

        controller.increment()
        controller.increment()
        controller.reset()

        XCTAssertEqual(controller.count, 0)
    }

    /// Two independent controller instances share the same underlying state.
    func testTwoControllersShareState() {
        let first = TrackerController()
        let second = TrackerController()

        first.increment()
        first.increment()

        XCTAssertEqual(second.count, 2)
    }

    /// Reset via `Application` API is reflected in the controller.
    func testApplicationResetReflectsInController() {
        let controller = TrackerController()
        var state = Application.storedState(\.trackerCount)
        state.value = 99

        Application.reset(storedState: \.trackerCount)

        XCTAssertEqual(controller.count, 0)
    }

    // MARK: - Persistence Semantics

    /// Verifies that the `StoredState` persists the value to `UserDefaults`
    /// and that a fresh read of the same key-path retrieves the persisted value.
    func testStoredStatePersistsAcrossReads() {
        var state = Application.storedState(\.trackerCount)
        state.value = 42

        let freshRead = Application.storedState(\.trackerCount)

        XCTAssertEqual(freshRead.value, 42)
    }
}
