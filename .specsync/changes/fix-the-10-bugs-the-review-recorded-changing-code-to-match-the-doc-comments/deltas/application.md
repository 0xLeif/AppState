## ADDED

### REQUIREMENT REQ-application-002

A State or FileState read SHALL fill the cache before it returns, so a value written afterwards in the same main-actor turn SHALL remain the value read later. Application.state(initial:) SHALL evaluate its initial value once per scope while that state is cached, and reset() SHALL restore that first value after any number of writes.

Acceptance Criteria

- A State read and then written, with no suspension in between, reads the written value after the main actor has run its queued jobs.
- Five reads of a State evaluate its initial expression once.
- reset() after two writes restores the value the initial expression first produced.

### REQUIREMENT REQ-application-003

The StoredState setter SHALL NOT pass UserDefaults a value that is not a property list. A value that can be neither JSON-encoded nor stored as a property list SHALL be rejected: the previous value SHALL stay and no change SHALL be notified.

Acceptance Criteria

- Writing a struct that holds Double.nan to a StoredState stores nothing in UserDefaults and leaves the previous value readable.
- Writing Double.infinity to a StoredState of Double still stores and reads back infinity.

### REQUIREMENT REQ-application-004

A value written to a FileState with isBase64Encoded false SHALL read back equal after the cache entry is gone, for every JSON text including text that is valid Base64. FileManager.defaultFileStatePath SHALL be a plain file path without percent-encoding.

Acceptance Criteria

- true and 1234 written without Base64 read back as true and 1234 from the file.
- A Base64-encoded file still reads back its value.
- defaultFileStatePath contains no percent sign when the documents path has none.

### REQUIREMENT REQ-application-005

Application.promote(to:) SHALL register the promoted instance for the iCloud key-value store's external-change notification when the previous instance was registered.

Acceptance Criteria

- After icloudStore is loaded and the application is promoted, posting the external-change notification calls the promoted instance's didChangeExternally exactly once.

### REQUIREMENT REQ-application-006

A DependencyOverride SHALL restore the dependency it replaced when cancel() is called or when the token is released, whichever comes first, and SHALL restore it only once. A token released on the main thread SHALL have restored the dependency before the release returns.

Acceptance Criteria

- An override whose token goes out of scope on the main actor is no longer in effect on the next line.
- After cancel(), releasing the token does not undo an override installed in between.
