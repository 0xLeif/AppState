---
change: report-persistence-failures-to-an-overridable-application-method
artifact: requirements
---

# Requirements

- `Application` has an overridable `didFailToPersist(_:)` method, called on the main actor.
- It is called when a `FileState` file cannot be decoded, written or deleted, and when a `StoredState` or `SyncState` value cannot be encoded.
- The failure names the kind of state, the operation, the key of the state and the underlying error.
- A `FileState` whose file does not exist is not reported, on a read or on a write of `nil`.
- The default implementation does nothing. Logging, fallback values and every existing declaration stay as they are.
