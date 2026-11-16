## ADDED

### REQUIREMENT REQ-property-wrappers-002

A write through the enclosing-instance subscript of @AppState, @StoredState, @FileState, @SecureState, @SyncState, @Slice or @OptionalSlice SHALL be stored whatever the type of the host's objectWillChange. The host's publisher SHALL be sent before the write when it is an ObservableObjectPublisher.

Acceptance Criteria

- A host that declares objectWillChange as a PassthroughSubject reads back the value it wrote through @AppState.
- A host with the synthesized publisher still receives objectWillChange once per write.
