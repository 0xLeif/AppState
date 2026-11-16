---
id: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
state: implementing
type: operations
base_commit: 07cf51e1cee0e6ec4469b75db25738dd8642268f
---

# Add an iOS demo app with UI tests and an iOS CI job

## Intent

Add an iOS demo app with UI tests and an iOS CI job

## Affected Canonical Specs

- None

## Acceptance Criteria

- xcodegen generate then xcodebuild test of the DemoApp scheme passes on an iOS simulator: the package's unit tests run inside the app, including the Keychain and SecureState tests, and the five UI tests pass, including persisted state surviving an app relaunch; the iOS workflow passes on the pull request

## No-spec Rationale

The demo app, its UI tests and the CI workflow exercise existing behaviour and change no library source or canonical spec
