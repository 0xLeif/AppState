# Lesson bundle: fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments

Material for folding this change's lessons into each affected module's lesson file.
Synthesise from what actually happened below; do not restate the change description.

## What this change was

- **Title**: Fix the 10 bugs the review recorded, changing code to match the doc comments
- **Kind**: BugFix
- **Specs**: application, property-wrappers
- **Paths**: Sources/AppState/Application/Application+public.swift, Sources/AppState/Application/Application.swift, Sources/AppState/Application/Types/Dependency/Application+Dependency.swift, Sources/AppState/Application/Types/Helper/Application+ApplicationPreview.swift, Sources/AppState/Application/Types/Helper/Application+PersistenceFailure.swift, Sources/AppState/Application/Types/Helper/FileManager+AppState.swift, Sources/AppState/Application/Types/State/Application+FileState.swift, Sources/AppState/Application/Types/State/Application+State.swift, Sources/AppState/Application/Types/State/Application+StoredState.swift, Sources/AppState/Application/Types/State/Application+SyncState.swift, Sources/AppState/PropertyWrappers/State/AppState.swift, Sources/AppState/PropertyWrappers/State/FileState.swift, Sources/AppState/PropertyWrappers/State/SecureState.swift, Sources/AppState/PropertyWrappers/State/Slice/OptionalSlice.swift, Sources/AppState/PropertyWrappers/State/Slice/Slice.swift, Sources/AppState/PropertyWrappers/State/StoredState.swift, Sources/AppState/PropertyWrappers/State/SyncState.swift, Tests/AppStateTests, documentation, README.md, CHANGELOG.md, specs, .chough, .specsync, knowledge, .github/workflows/iOS.yml, Examples/DemoApp
- **Acceptance**: ReviewFixTests has a test for each of the 8 library bugs in .chough/bugs and all pass; six of them fail on the sources of 7e4eb92, and the write-after-read bug, which XCTest could not show, is shown fixed by a plain executable; the two corrected documentation examples compile in Swift 6 mode; every test class passes on macOS under the strict build

## Evidence

- Verification commit: `ef98934fe8b5762e39da415641692c0ff67d89f0`
- Base commit: `7e4eb923d14b7a05c8dfdb10099ae13d83352bdc`
- Verified by: `specsync check --spec application --spec property-wrappers`

## From the change's context.md

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

## From the change's design.md

# Design

**State cache.** The `State` and `FileState` getters seed the cache synchronously on a miss. The XCTest probe and the deferred `Task` go. `Application.state(initial:feature:id:)` returns the cached `State` for its scope when there is one and otherwise builds one, evaluating `initial` once, and seeds the cache with it. The `State` setter stores the new value with the state's original initial, so a cached `State` still resets to the first value.

**Enclosing-instance setters.** Each setter sends `objectWillChange` when it is an `ObservableObjectPublisher`, then always writes. `OptionalSlice` keeps its `canStore` guard.

**StoredState.** The setter encodes first. On success it updates the cache and stores the data. On failure it falls back to the raw value only when `PropertyListSerialization.propertyList(_:isValidFor:)` accepts it, which keeps a top-level `Double.infinity` working. Otherwise it logs and writes nothing.

**FileState reading.** `FileManager.in` decodes the Base64 reading when the file is valid Base64. If that decode throws, it decodes the raw bytes, and rethrows the first error when both fail. `FileManaging` keeps its signature.

**promote(to:).** `Application` records that it registered for external changes. The `icloudStore` factory calls one internal `observeExternalChanges()`. `promote(to:)` calls it on the new instance when the old one had registered.

**defaultFileStatePath.** Uses `path(percentEncoded: false)`.

**DependencyOverride.** The restore closure moves into a small main-actor box with a `didRestore` flag. `cancel()` runs it on the main actor. `deinit` runs it synchronously when on the main thread and otherwise hops to the main actor. `ApplicationPreview` keeps its overrides in `@State` so they live as long as the preview's identity.

**Docs.** The restricted example reads its id from a file-private constant. The dependency example marks the protocol `Sendable`, the class `final`, and writes `any NetworkServiceType`. Both edits go into all eight languages.

## From the change's testing.md

# Testing

`Tests/AppStateTests/ReviewFixTests.swift` is the check, with one test per library defect.

- `testWriteAfterFirstReadSurvivesQueuedMainActorJobs` reads a state, writes it, lets the main actor run its queued jobs, and reads the written value.
- `testStateInitialIsEvaluatedOnce` reads a state six times, writes twice, resets, and finds one evaluation of the initial expression and the first value restored.
- `testWriteThroughHostWithCustomObjectWillChangeIsStored` writes through a host whose `objectWillChange` is a `PassthroughSubject`, and checks a default host still receives one `objectWillChange` per write.
- `testStoredStateRejectsValueThatIsNeitherJSONNorPropertyList` writes a struct holding `Double.nan` through a recording `UserDefaults` fake. Only `Data` reaches the fake and the previous value stays. A top-level `Double.infinity` still round-trips.
- `testUnencodedFileStateReadsBackBase64LookingValues` writes `true` and `1234` without Base64 and `5678` with it, drops the cache entries, and reads all three back.
- `testDefaultFileStatePathIsNotPercentEncoded` passes a documents URL with a space and an accent to the path helper. It is skipped on Windows, where a file URL carries a drive letter.
- `testReleasingOverrideRestoresDependency` lets a token go out of scope and reads the original dependency on the next line.
- `testReleaseAfterCancelDoesNotUndoLaterOverride` cancels one override, installs a second, releases the first, and still reads the second.
- `testPromoteKeepsExternalChangeObserver` loads `icloudStore`, promotes, posts the external-change notification, and counts one call on the promoted instance.

Against the sources of 7e4eb92, six of these fail: the initial-evaluation, custom-publisher, `StoredState`, unencoded-file, release, and promote tests. The path test does not compile there, because it calls the new helper. Two pass on the old sources: the cancel-then-release test guards the new `deinit`, and the write-after-read test cannot fail under XCTest, where the old getter took its synchronous branch. That defect was shown with a plain executable in a scratch package, which printed `0` before the fix and `5` after.

## Requirement evidence

| Requirement | Evidence |
|---|---|
| REQ-application-002 | `testWriteAfterFirstReadSurvivesQueuedMainActorJobs`, `testStateInitialIsEvaluatedOnce`, and the scratch executable run |
| REQ-application-003 | `testStoredStateRejectsValueThatIsNeitherJSONNorPropertyList` |
| REQ-application-004 | `testUnencodedFileStateReadsBackBase64LookingValues`, `testDefaultFileStatePathIsNotPercentEncoded` |
| REQ-application-005 | `testPromoteKeepsExternalChangeObserver` |
| REQ-application-006 | `testReleasingOverrideRestoresDependency`, `testReleaseAfterCancelDoesNotUndoLaterOverride` |
| REQ-property-wrappers-002 | `testWriteThroughHostWithCustomObjectWillChangeIsStored` |

Run `APPSTATE_STRICT=1 swift build --build-tests`, then `swift test --skip-build --filter '<Class>'` for each test class. Every class was run on its own on macOS arm64 with Swift 6.4.2. Linux, Windows and WASI were not built locally.

The two documentation examples were compiled in a scratch Swift 6 target.

## Where these lessons go

- `specs/application/context.md`
- `specs/property-wrappers/context.md`
