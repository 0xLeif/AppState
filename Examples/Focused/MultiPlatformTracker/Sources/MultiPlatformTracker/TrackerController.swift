import AppState
import Foundation

// MARK: - TrackerController

/// A platform-agnostic controller that drives the habit-tracker count.
///
/// All mutations go through `Application`'s `StoredState`, so every change is
/// automatically persisted to `UserDefaults` and reflected across any view or
/// actor that observes the same key-path.  There is no SwiftUI dependency here,
/// making this layer fully testable in headless environments (Linux, CI, etc.).
@MainActor
public final class TrackerController: Sendable {

    // MARK: - Public Interface

    /// The current persisted count.
    public var count: Int {
        Application.storedState(\.trackerCount).value
    }

    /// Increments the tracker count by one.
    public func increment() {
        var state = Application.storedState(\.trackerCount)
        state.value += 1
    }

    /// Decrements the tracker count by one, clamping at zero.
    public func decrement() {
        var state = Application.storedState(\.trackerCount)
        state.value = max(0, state.value - 1)
    }

    /// Resets the tracker count to its initial value of zero.
    public func reset() {
        Application.reset(storedState: \.trackerCount)
    }
}
