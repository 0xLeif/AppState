---
spec: application.spec.md
---

## User Stories

- As a developer, I want to define a piece of state once in an `Application` extension and access it anywhere by key path.
- As a developer, I want SwiftUI views to update automatically when shared state changes.
- As a developer, I want to inject and override dependencies for previews and tests.
- As a developer, I want to react to external iCloud changes and refresh my UI.

## Acceptance Criteria

- Reading a value through a property wrapper in a SwiftUI view body registers an observation dependency for that view.
- Mutating a value notifies observers so dependent views update.
- Dependency overrides apply for the lifetime of the returned token and revert when it is released.
- The library compiles warning-free under Swift 6 language mode with `ExistentialAny` and `-warnings-as-errors`.

## Constraints

- Minimum platforms: iOS 17 / macOS 14 / tvOS 17 / watchOS 10 / visionOS 1; also Linux and Windows for the non-Apple feature set.
- `Application.shared` is main-actor isolated; all dependency values must be `Sendable`.

## Out of Scope

- Fine-grained, per-key observation (the anchor intentionally provides coarse, whole-registry change notification).
- Persisting `State` (use `StoredState`/`FileState`/`SyncState`/`ModelState` for persistence).
