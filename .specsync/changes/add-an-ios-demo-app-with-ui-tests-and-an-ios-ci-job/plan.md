---
change: add-an-ios-demo-app-with-ui-tests-and-an-ios-ci-job
artifact: plan
---

# Plan

## Approach

Add `Examples/DemoApp`, an XcodeGen project with a small SwiftUI app, a unit-test bundle that compiles `Tests/AppStateTests` and runs it inside the app, and a UI-test bundle. Add an iOS workflow that generates the project and runs both bundles on a simulator.

## Out of scope

- Any change to library source or to the specs.
- tvOS, watchOS and visionOS runs.
- iCloud, which needs an entitlement and an account.

## Steps

1. Add the app, the UI tests, `project.yml` and a README.
2. Add `.github/workflows/iOS.yml`.
3. Add a line to the 3.1.0 changelog section.
4. Run the scheme locally on an iOS simulator, then on the pull request.

## Risks

- UI tests are slower and less steady than unit tests. The job has a 30-minute limit and the tests wait up to thirty seconds for each value.
- The workflow picks the newest iPhone simulator on the runner, so a runner image change can change the iOS version tested.
- The generated Xcode project is not checked in, so XcodeGen is needed to run the tests.

## Constraints consulted

- AGENTS.md: no commit or push without being asked; Leif asked for this in chat.
- `.gitignore` already ignores `Examples/DemoApp/*.xcodeproj` and `Examples/DemoApp/.build-dd`.
