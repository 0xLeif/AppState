---
change: fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments
artifact: design
---

# Design

**State cache.** The `State` and `FileState` getters seed the cache synchronously on a miss. The XCTest probe and the deferred `Task` go. `Application.state(initial:feature:id:)` returns the cached `State` for its scope when there is one and otherwise builds one, evaluating `initial` once, and seeds the cache with it. The `State` setter stores the new value with the state's original initial, so a cached `State` still resets to the first value.

**Enclosing-instance setters.** Each setter sends `objectWillChange` when it is an `ObservableObjectPublisher`, then always writes. `OptionalSlice` keeps its `canStore` guard.

**StoredState.** The setter encodes first. On success it updates the cache and stores the data. On failure it falls back to the raw value only when `PropertyListSerialization.propertyList(_:isValidFor:)` accepts it, which keeps a top-level `Double.infinity` working. Otherwise it logs and writes nothing.

**FileState reading.** `FileManager.in` decodes the Base64 reading when the file is valid Base64. If that decode throws, it decodes the raw bytes, and rethrows the first error when both fail. `FileManaging` keeps its signature.

**promote(to:).** `Application` records that it registered for external changes. The `icloudStore` factory calls one internal `observeExternalChanges()`. `promote(to:)` calls it on the new instance when the old one had registered.

**defaultFileStatePath.** Uses `path(percentEncoded: false)`.

**DependencyOverride.** The restore closure moves into a small main-actor box with a `didRestore` flag. `cancel()` runs it on the main actor. `deinit` runs it synchronously when on the main thread and otherwise hops to the main actor. `ApplicationPreview` keeps its overrides in `@State` so they live as long as the preview's identity.

**Docs.** The restricted example reads its id from a file-private constant. The dependency example marks the protocol `Sendable`, the class `final`, and writes `any NetworkServiceType`. Both edits go into all eight languages.
