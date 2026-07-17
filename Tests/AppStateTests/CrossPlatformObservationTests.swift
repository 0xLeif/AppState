import Foundation
import Observation
import XCTest
@testable import AppState

fileprivate extension Application {
    var crossPlatformObservationCounter: Application.State<Int> {
        state(initial: 0, id: "crossPlatformObservationCounter")
    }
}

/// Cross-platform Observation delivery smoke tests.
///
/// These use `async` + `@MainActor` test entry points (the same pattern as
/// `AppStateTests`) so swift-corelibs-xctest on Linux/Windows can discover them.
/// Synchronous `@MainActor` XCTest methods are not discoverable there — that is why
/// `ObservationTests` / `ObservationBridgeTests` remain Apple-gated for the fuller suite.
final class CrossPlatformObservationTests: XCTestCase {
    /// A `Sendable` flag the `@Sendable` `onChange` closure can write to.
    private final class ChangeFlag: @unchecked Sendable {
        var didChange = false
    }

    override func setUp() async throws {
        try await super.setUp()

        await MainActor.run {
            Application.reset(\.crossPlatformObservationCounter)
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            Application.reset(\.crossPlatformObservationCounter)
        }

        try await super.tearDown()
    }

    @MainActor
    func testMutatingStateNotifiesObserversOnAllPlatforms() async {
        let flag = ChangeFlag()

        withObservationTracking {
            _ = Application.state(\.crossPlatformObservationCounter).value
        } onChange: {
            flag.didChange = true
        }

        XCTAssertFalse(flag.didChange)

        var state = Application.state(\.crossPlatformObservationCounter)
        state.value = 1

        XCTAssertTrue(
            flag.didChange,
            "Expected Observation delivery after mutation on every platform Observation supports"
        )
        XCTAssertEqual(Application.state(\.crossPlatformObservationCounter).value, 1)
    }

    @MainActor
    func testReadingWithoutTrackedMutationDoesNotNotifyOnAllPlatforms() async {
        let flag = ChangeFlag()

        withObservationTracking {
            _ = Application.state(\.crossPlatformObservationCounter).value
        } onChange: {
            flag.didChange = true
        }

        XCTAssertFalse(flag.didChange)
    }
}
