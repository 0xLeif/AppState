import AppState
import Foundation

// MARK: - Application + MultiPlatformTracker State

extension Application {

    /// The persisted habit-tracker count, backed by `UserDefaults`.
    ///
    /// Using `StoredState` means the count survives app launches on every
    /// supported platform (iOS, macOS, watchOS, tvOS, visionOS, Linux, Windows).
    /// The same key-path works identically in SwiftUI property wrappers and in
    /// headless tests — no platform guards required at the call site.
    public var trackerCount: StoredState<Int> {
        storedState(initial: 0, feature: "MultiPlatformTracker", id: "trackerCount")
    }
}
