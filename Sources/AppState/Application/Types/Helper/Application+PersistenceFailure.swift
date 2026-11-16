import Foundation

extension Application {
    /// A value that AppState could not read from, write to, or delete from its backing store.
    ///
    /// AppState keeps running after such a failure: a read falls back to the state's initial value
    /// and a write keeps what it could. Override ``Application/didFailToPersist(_:)`` to learn that it
    /// happened.
    public struct PersistenceFailure: Sendable {
        /// The kind of state whose backing store failed.
        public enum Store: Sendable, Equatable {
            /// A ``Application/FileState``, backed by a file.
            case fileState

            /// A ``Application/StoredState``, backed by `UserDefaults`.
            case storedState

            /// A `SyncState`, backed by the iCloud key-value store.
            case syncState
        }

        /// What AppState was doing when the store failed.
        public enum Operation: Sendable, Equatable {
            /// Reading a persisted value. The state's initial value was returned instead.
            case read

            /// Writing a value. The backing store does not hold it.
            case write

            /// Deleting a persisted value, which happens when `nil` is written.
            case delete
        }

        /// The kind of state whose backing store failed.
        public let store: Store

        /// What AppState was doing when the store failed.
        public let operation: Operation

        /// The key of the state's scope: `feature/id`, or the path and filename for a `FileState`.
        public let key: String

        /// The error the backing store or the coder reported.
        public let error: any Error
    }

    /// Whether `error` says the file is not there, which is how a `FileState` that was never
    /// written looks. That is the normal first read, not a failure.
    static func isMissingFile(_ error: any Error) -> Bool {
        if let cocoaError = error as? CocoaError {
            return cocoaError.code == .fileReadNoSuchFile || cocoaError.code == .fileNoSuchFile
        }

        let noSuchFileOrDirectory = 2
        let nsError = error as NSError

        return nsError.domain == NSPOSIXErrorDomain && nsError.code == noSuchFileOrDirectory
    }
}
