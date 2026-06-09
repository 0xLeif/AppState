import AppState
import Foundation

// MARK: - Application + Settings

extension Application {
    /// The persisted user settings, backed by `UserDefaults`.
    ///
    /// Accessing this property from multiple call sites always returns the same
    /// `StoredState` instance because `storedState(initial:feature:id:)` caches
    /// by `(feature, id)` pair.
    public var settings: StoredState<Settings> {
        storedState(initial: .default, feature: "SettingsKit", id: "settings")
    }
}
