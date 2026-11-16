# DemoApp

A small SwiftUI app that uses `State`, `Slice`, `StoredState`, `FileState`, `SecureState`, a dependency override and `didFailToPersist(_:)`. It exists to test AppState in a real iOS app.

It hosts two test bundles:

- **HostedUnitTests** runs the package's unit tests (`Tests/AppStateTests`) inside the app. On iOS the Keychain needs an app host, so the Keychain and `SecureState` tests pass here and fail in a bare `xcodebuild test` of the package.
- **DemoUITests** taps through the app and relaunches it. It checks that views update, that a write made right after a first read is kept, that persisted state survives a relaunch, that a failed write reaches `didFailToPersist(_:)`, and that an override held by the app lasts for the session.

## Run

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) and is not checked in.

```sh
cd Examples/DemoApp
xcodegen generate
xcodebuild test \
  -project DemoApp.xcodeproj \
  -scheme DemoApp \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Use the name of any iOS 17 or later simulator you have installed. CI runs the same command in the iOS workflow.
