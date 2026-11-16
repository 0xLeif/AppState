---
change: fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments
artifact: research
---

# Research

Reproductions on macOS arm64, Swift 6.4.2, against 7e4eb92, in a scratch package with a path dependency on this checkout.

Plain executable, XCTest not loaded:

- `var s = Application.state(\.counter); s.value = 5` read `5` at once and `0` after the main actor ran its queued jobs.
- Two consecutive reads of `state(initial: UUID())` returned different ids.
- A `FileState` read then written in one turn returned the old file content afterwards, while the file held the new value.
- Writing `Reading(celsius: .nan)` to a `StoredState` terminated with `NSInvalidArgumentException: Attempt to insert non-property list object`.
- For a directory named `appstate path check`, `url.appending(path: "App").path()` returned a `%20` path, and a file written through `URL(filePath:)` landed in a literal `%20` directory.

XCTest, one process per test:

- A host with `let objectWillChange = PassthroughSubject<Void, Never>()` kept `3` after `count = 7`. The default-publisher control passed.
- Five reads of `state(initial: countedInitial())` ran the initial five times.
- An override left to go out of scope still returned `mock`.
- `FileState<Bool>` and `FileState<Int>` with `isBase64Encoded: false` read `false` and `0` after writing `true` and `1234` and dropping the cache entry. A three-digit control passed.
- Loading `icloudStore`, promoting, then posting `didChangeExternallyNotification` did not reach the override. Promoting first did.
- The restricted-state example read `nil` after writing `42`, and 100 reads added 102 cache entries.

Compiling every Swift block of the README and `documentation/en` in Swift 6 mode gave one real failure: `any NetworkServiceType` does not conform to `Sendable`. It builds in Swift 5 mode.

Base64 of a JSON document always starts with a letter that no JSON document starts with, and digits-only Base64 decodes to bytes at or above 0xD0, so trying the Base64 reading first and the raw reading second cannot misread either kind of file.
