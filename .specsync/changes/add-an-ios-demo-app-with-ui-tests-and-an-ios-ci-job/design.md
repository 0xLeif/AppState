---
change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
artifact: design
---

# Design

One Xcode project with three targets:

- `DemoApp`, a SwiftUI app that links the package by relative path and shows one row per kind of state, each with an accessibility identifier and a button that changes it. It installs an `Application` subclass that counts `didFailToPersist` calls, and reads two launch arguments: `-reset` clears persisted state, `-mock` installs a dependency override that the app holds.
- `HostedUnitTests`, which compiles the package's own test sources and uses the app as its host.
- `DemoUITests`, five XCUITest cases that tap the buttons, read the labels, and relaunch the app.

The unit-test bundle does not link the package again. It resolves the library from the host app, so there is one `Application.shared`.
