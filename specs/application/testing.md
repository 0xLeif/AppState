---
spec: application.spec.md
---

## Test Plan

### Unit Tests

- `ApplicationTests` — state/dependency definition and resolution by key path; `reset`; `override`/`promote`.
- `ObservationTests` — reading a wrapper registers an observation dependency and mutating the value fires `withObservationTracking`'s `onChange` (the `registerObservation()` / `notifyChange()` bridge); negative case asserts no notification without a mutation.
- `AppDependencyTests` — dependency injection and override lifetime.

### Integration Tests

- Reactive view updates (SwiftUI re-rendering on state change) require a real Apple target and are verified manually; CI covers compilation, unit tests, and `-warnings-as-errors`.
