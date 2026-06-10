#if !os(Linux) && !os(Windows)
import AppState
import SwiftUI
import ViewInspector
import XCTest

@testable import MultiPlatformTracker

// MARK: - TrackerViewTests

/// Exercises the SwiftUI layer (`TrackerView`) with ViewInspector so that the
/// declarative view body, its action closures, and every branch within those
/// closures are covered alongside the headless `TrackerController` tests.
@MainActor
final class TrackerViewTests: XCTestCase {

    // MARK: - Properties

    private var userDefaultsOverride: Application.DependencyOverride?

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        userDefaultsOverride = Application.override(
            \.userDefaults,
            with: InMemoryUserDefaults() as UserDefaultsManaging
        )
        Application.reset(storedState: \.trackerCount)
    }

    override func tearDown() async throws {
        Application.reset(storedState: \.trackerCount)
        await userDefaultsOverride?.cancel()
        userDefaultsOverride = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    /// Returns the current persisted tracker count.
    private func currentCount() -> Int {
        Application.storedState(\.trackerCount).value
    }

    /// Sets the persisted tracker count to a specific value.
    private func setCount(_ value: Int) {
        var state = Application.storedState(\.trackerCount)
        state.value = value
    }

    // MARK: - Tests: TrackerView initializer and body

    /// Verifies that `TrackerView` can be instantiated and its body renders
    /// a VStack containing the "Habit Tracker" title text.
    func testBodyRendersHabitTrackerTitle() throws {
        let sut = TrackerView()

        XCTAssertNoThrow(try sut.inspect().find(text: "Habit Tracker"))
    }

    /// Verifies that the count text reflects the current `trackerCount` state
    /// when the view is created with a non-zero value.
    func testBodyRendersCurrentCount() throws {
        setCount(7)

        let sut = TrackerView()

        XCTAssertNoThrow(try sut.inspect().find(text: "7"))
    }

    /// Verifies that the count text renders "0" when `trackerCount` is at its
    /// initial value.
    func testBodyRendersZeroCountInitially() throws {
        let sut = TrackerView()

        XCTAssertNoThrow(try sut.inspect().find(text: "0"))
    }

    // MARK: - Tests: Increment button

    /// Tapping the increment button increases `trackerCount` by one.
    func testIncrementButtonTapIncrementsCount() throws {
        setCount(3)

        let sut = TrackerView()
        let buttons = try sut.inspect().findAll(ViewType.Button.self)
        // Buttons in body order: [0] Decrement, [1] Increment, [2] Reset
        try buttons[1].tap()

        XCTAssertEqual(currentCount(), 4)
    }

    /// Incrementing from zero produces a count of one.
    func testIncrementButtonFromZeroProducesOne() throws {
        let sut = TrackerView()
        let buttons = try sut.inspect().findAll(ViewType.Button.self)
        try buttons[1].tap()

        XCTAssertEqual(currentCount(), 1)
    }

    // MARK: - Tests: Decrement button (positive count branch)

    /// Tapping decrement when `trackerCount` is positive decrements by one
    /// without triggering the reset path (the `count < 0` branch is false).
    func testDecrementButtonFromPositiveCountDecrementsWithoutReset() throws {
        setCount(5)

        let sut = TrackerView()
        let buttons = try sut.inspect().findAll(ViewType.Button.self)
        try buttons[0].tap()

        XCTAssertEqual(currentCount(), 4)
    }

    // MARK: - Tests: Decrement button (zero count branch — triggers reset)

    /// Tapping decrement when `trackerCount` is zero causes `count` to reach -1
    /// inside the closure, which triggers `controller.reset()`, clamping it back
    /// to zero.  This exercises the `if count < 0 { … }` true branch.
    func testDecrementButtonFromZeroTriggersResetClamp() throws {
        // count is already 0 from setUp reset
        let sut = TrackerView()
        let buttons = try sut.inspect().findAll(ViewType.Button.self)
        try buttons[0].tap()

        XCTAssertEqual(currentCount(), 0)
    }

    // MARK: - Tests: Reset button

    /// Tapping the Reset button resets `trackerCount` to zero.
    func testResetButtonTapResetsCountToZero() throws {
        setCount(10)

        let sut = TrackerView()
        let buttons = try sut.inspect().findAll(ViewType.Button.self)
        // The Reset button is the third button (index 2)
        try buttons[2].tap()

        XCTAssertEqual(currentCount(), 0)
    }

    /// Tapping the Reset button when count is already zero leaves it at zero.
    func testResetButtonWhenAlreadyZeroRemainsZero() throws {
        let sut = TrackerView()
        let buttons = try sut.inspect().findAll(ViewType.Button.self)
        try buttons[2].tap()

        XCTAssertEqual(currentCount(), 0)
    }
}
#endif
