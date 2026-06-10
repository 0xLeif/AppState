import AppState
import Foundation

// MARK: - Application + SyncNotes State

#if !os(Linux) && !os(Windows)
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

    /// The draft text currently typed into the new-note input field.
    ///
    /// Stored in application state so it survives navigation and is
    /// testable without `ViewHosting`.
    public var newNoteText: State<String> {
        state(initial: "")
    }
}
#endif
