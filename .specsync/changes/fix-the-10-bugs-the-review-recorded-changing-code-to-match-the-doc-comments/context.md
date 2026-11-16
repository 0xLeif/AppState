---
change: fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments
artifact: context
---

# Context

A read-through of every state and dependency type, the README and `documentation/en` found ten defects. Each was reproduced against 7e4eb92 in a scratch package outside the repo and recorded in `.chough/bugs/`. Leif decided in chat: "fix all of them, change the code to match the comments".

Eight are in the library:

- `State` and `FileState` seed the cache from a deferred `Task` when XCTest is not loaded, so a write made right after a first read is overwritten. The test suite takes the synchronous branch and cannot see it.
- The enclosing-instance setters return before writing when the host's `objectWillChange` is not an `ObservableObjectPublisher`.
- `StoredState` passes a raw Swift value to `UserDefaults` when JSON encoding fails, which raises `NSInvalidArgumentException`.
- `FileManager.in` Base64-decodes first, so an unencoded file whose JSON text is valid Base64 (`true`, `1234`) fails to decode and the state reads its initial value.
- `promote(to:)` removes the old instance as iCloud observer and copies the cached `icloudStore`, so the new instance is never registered.
- `FileManager.defaultFileStatePath` uses `URL.path()`, which percent-encodes.
- `state(initial:)` evaluates its initial value on every access, where its comment says once.
- `DependencyOverride` has no `deinit`, where the `override` comment and the application spec's acceptance criteria say a released token reverts.

Two are documentation examples, present in all eight languages: the "restricted state" example makes a new id on every access, and the `NetworkServiceType` example does not compile in Swift 6 mode.

The archived 3.0.2 change says not to run an unfiltered `swift test` in this checkout.
