import AppState
import Foundation

// MARK: - Application + SyncNotes State

#if !os(Linux) && !os(Windows)
@available(watchOS 9.0, *)
extension Application {

    /// The cloud-synced list of all user notes.
    ///
    /// Backed by `NSUbiquitousKeyValueStore` so additions and deletions
    /// propagate to every device signed into the same iCloud account.
    /// Falls back to `UserDefaults` when iCloud is unavailable.
    ///
    /// - Note: Only available on Apple platforms; iCloud is not supported on Linux or Windows.
    public var notes: SyncState<[Note]> {
        syncState(initial: [], feature: "SyncNotes", id: "notes")
    }
}
#endif
