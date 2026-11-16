---
change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
artifact: testing
---

# Testing

The change is itself tests. Locally, on an iOS 27.2 simulator:

```sh
cd Examples/DemoApp
xcodegen generate
xcodebuild test -project DemoApp.xcodeproj -scheme DemoApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

222 tests pass: 217 package tests inside the app and 5 UI tests. The simulator-picking step of the workflow was run locally as written. The iOS workflow runs on the pull request.
