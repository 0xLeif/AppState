---
change: fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments
artifact: testing
---

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
