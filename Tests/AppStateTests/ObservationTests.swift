#if !os(Linux) && !os(Windows)
import Observation
import XCTest
@testable import AppState

fileprivate extension Application {
    var observationCounter: Application.State<Int> {
        state(initial: 0)
    }
}

@MainActor
fileprivate struct ObservationCounterHolder {
    @AppState(\.observationCounter) var count: Int
}

/// Verifies the Observation bridge that backs SwiftUI reactivity: reading a property wrapper
/// registers an observation dependency on `Application`, and mutating the underlying state notifies
/// observers. This exercises the same `registerObservation()` / `notifyChange()` mechanism SwiftUI
/// relies on, without requiring a running SwiftUI view.
final class ObservationTests: XCTestCase {
    /// A `Sendable` flag the `@Sendable` `onChange` closure can write to.
    private final class ChangeFlag: @unchecked Sendable {
        var didChange = false
    }

    @MainActor
    override func setUp() async throws {
        Application.reset(\.observationCounter)
    }

    @MainActor
    override func tearDown() async throws {
        Application.reset(\.observationCounter)
    }

    @MainActor
    func testMutatingStateNotifiesObservers() {
        let holder = ObservationCounterHolder()
        let flag = ChangeFlag()

        withObservationTracking {
            // Reading the wrapped value calls `registerObservation()`, registering this tracking
            // scope as dependent on AppState — exactly what happens inside a SwiftUI view body.
            _ = holder.count
        } onChange: {
            flag.didChange = true
        }

        XCTAssertFalse(flag.didChange)

        // Mutating the state writes through the cache, which bumps the observation anchor and should
        // synchronously fire the registered `onChange`.
        holder.count = 1

        XCTAssertTrue(flag.didChange, "Expected an observation change when the state was mutated")
        XCTAssertEqual(holder.count, 1)
    }

    @MainActor
    func testReadingWithoutTrackedMutationDoesNotNotify() {
        let flag = ChangeFlag()

        withObservationTracking {
            _ = Application.state(\.observationCounter).value
        } onChange: {
            flag.didChange = true
        }

        // No mutation occurred, so no observation change should be delivered.
        XCTAssertFalse(flag.didChange)
    }
}
#endif
