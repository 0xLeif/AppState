# Lesson bundle: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job

Material for folding this change's lessons into each affected module's lesson file.
Synthesise from what actually happened below; do not restate the change description.

## What this change was

- **Title**: Add an iOS demo app with UI tests and an iOS CI job
- **Kind**: Operations
- **Paths**: Examples, .github, CHANGELOG.md, .chough, .specsync/change.lock
- **Acceptance**: xcodegen generate then xcodebuild test of the DemoApp scheme passes on an iOS simulator: the package's unit tests run inside the app, including the Keychain and SecureState tests, and the five UI tests pass, including persisted state surviving an app relaunch; the iOS workflow passes on the pull request

## Evidence

- Verification commit: `93c9ee5eb170ac7bd82323b23d49fa14e230b2bb`
- Base commit: `07cf51e1cee0e6ec4469b75db25738dd8642268f`
- Verified by: `specsync check (no spec in scope)`

## From the change's context.md

# Context

The package's tests ran on macOS, Linux and Windows, and built for WebAssembly, but never inside an iOS app. Two things could not be checked that way:

- On iOS the Keychain needs an app host. Run as a bare package on a simulator, 18 Keychain and SecureState tests fail, on `main` too.
- Nothing checked what a user sees: that a SwiftUI view updates, and that persisted state survives an app relaunch.

Writing the UI tests found a real defect in the new `didFailToPersist` method, which reported an unreadable file on every render. That is already fixed on the branch below this one.

The branch is stacked on the persistence-failure hook branch.

## From the change's design.md

# Design

One Xcode project with three targets:

- `DemoApp`, a SwiftUI app that links the package by relative path and shows one row per kind of state, each with an accessibility identifier and a button that changes it. It installs an `Application` subclass that counts `didFailToPersist` calls, and reads two launch arguments: `-reset` clears persisted state, `-mock` installs a dependency override that the app holds.
- `HostedUnitTests`, which compiles the package's own test sources and uses the app as its host.
- `DemoUITests`, five XCUITest cases that tap the buttons, read the labels, and relaunch the app.

The unit-test bundle does not link the package again. It resolves the library from the host app, so there is one `Application.shared`.

## From the change's testing.md

# Testing

The change is itself tests. Locally, on an iOS 27.2 simulator:

```sh
cd Examples/DemoApp
xcodegen generate
xcodebuild test -project DemoApp.xcodeproj -scheme DemoApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

222 tests pass: 217 package tests inside the app and 5 UI tests. The simulator-picking step of the workflow was run locally as written. The iOS workflow runs on the pull request.

## Where these lessons go

This change declared no affected specs, so there is no module context to fold into.
