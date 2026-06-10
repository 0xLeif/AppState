import XCTest

@testable import AppState

#if !os(Linux) && !os(Windows)
import Observation
#endif

// MARK: - Fixtures

extension Application {
    /// A counter used to verify the imperative state accessor registers observation.
    fileprivate var regressionObservationCounter: State<Int> {
        state(initial: 0, feature: "Regression", id: "observationCounter")
    }
}

// MARK: - BugFixRegressionTests

/// Regression tests pinning the behavior of bugs surfaced by the adversarial suite and since fixed.
///
/// Each test documents the *fixed* contract so the bug cannot silently return.
final class BugFixRegressionTests: XCTestCase {

    // MARK: - Keychain index integrity (remove updates the in-memory key index)

    #if !os(Linux) && !os(Windows)
    @MainActor
    func testKeychainRemoveUpdatesValuesIndex() throws {
        let keychain = Keychain()
        let key = "regression.keychain.\(UUID().uuidString)"
        defer { keychain.remove(key) }

        keychain.set(value: "secret", forKey: key)
        XCTAssertEqual(keychain.values()[key], "secret")

        // Previously `remove` deleted the Keychain item but never updated the in-memory `keys`
        // index, so `values()` kept reporting the removed key. It must now be gone from both.
        keychain.remove(key)
        XCTAssertNil(keychain.values()[key])
        XCTAssertFalse(keychain.contains(key))
    }

    @MainActor
    func testKeychainSetUpdatesValuesIndexSynchronously() {
        let keychain = Keychain()
        let key = "regression.keychain.sync.\(UUID().uuidString)"
        defer { keychain.remove(key) }

        // Previously the index was updated via a fire-and-forget `Task`, so `values()` called
        // immediately after `set` on the same actor could miss the new key. It is now synchronous.
        keychain.set(value: "token", forKey: key)
        XCTAssertEqual(keychain.values()[key], "token")
    }
    #endif

    // MARK: - Observation: the imperative state accessor registers observation

    #if !os(Linux) && !os(Windows)
    @MainActor
    func testImperativeStateAccessorRegistersObservation() {
        Application.reset(\.regressionObservationCounter)

        final class Flag: @unchecked Sendable {
            var didChange = false
        }
        let flag = Flag()

        withObservationTracking {
            // Reading through the imperative `Application.state(_:).value` accessor — not a property
            // wrapper — must register the tracking scope so the change is observed.
            _ = Application.state(\.regressionObservationCounter).value
        } onChange: {
            flag.didChange = true
        }

        var state = Application.state(\.regressionObservationCounter)
        state.value = 1

        XCTAssertTrue(
            flag.didChange,
            "Application.state(_:).value must register observation so withObservationTracking fires."
        )

        Application.reset(\.regressionObservationCounter)
    }
    #endif
}
