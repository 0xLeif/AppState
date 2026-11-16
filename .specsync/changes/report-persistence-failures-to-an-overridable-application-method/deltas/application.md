## ADDED

### REQUIREMENT REQ-application-007

Application SHALL call its overridable didFailToPersist method, on the main actor, when a FileState file cannot be decoded, written or deleted, and when a StoredState or SyncState value cannot be encoded. The failure SHALL carry the kind of state, the operation, the key of the state and the underlying error. A FileState whose file does not exist SHALL NOT be reported, on a read or on a write of nil. The default implementation SHALL do nothing, and existing logging and fallback values SHALL be unchanged.

Acceptance Criteria

- A FileState whose file holds text that is not JSON reads its initial value and reports a read failure with a DecodingError.
- A FileState whose directory is a regular file reports one write failure for one write.
- A StoredState given a struct that holds Double.nan keeps its previous value and reports one write failure with an EncodingError.
- A SyncState given a value that cannot be encoded reports one write failure.
- A FileState round trip that succeeds, a read of a FileState that was never written, and a write of nil to it report nothing.
- An Application that does not override the method reads the initial value from an unreadable file as before.
