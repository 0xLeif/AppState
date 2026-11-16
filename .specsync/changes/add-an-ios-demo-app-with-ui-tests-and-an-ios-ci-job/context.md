---
change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
artifact: context
---

# Context

The package's tests ran on macOS, Linux and Windows, and built for WebAssembly, but never inside an iOS app. Two things could not be checked that way:

- On iOS the Keychain needs an app host. Run as a bare package on a simulator, 18 Keychain and SecureState tests fail, on `main` too.
- Nothing checked what a user sees: that a SwiftUI view updates, and that persisted state survives an app relaunch.

Writing the UI tests found a real defect in the new `didFailToPersist` method, which reported an unreadable file on every render. That is already fixed on the branch below this one.

The branch is stacked on the persistence-failure hook branch.
