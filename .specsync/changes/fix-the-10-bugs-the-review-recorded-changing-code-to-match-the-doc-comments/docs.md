---
change: fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments
artifact: docs
---

# Docs

- `documentation/*/advanced-usage.md`, section 3.2: the restricted state and dependency read their id from a file-private constant, with a sentence saying why a `UUID()` inside the computed property does not work.
- `documentation/*/usage-state-dependency.md`: `protocol NetworkServiceType: Sendable`, `final class NetworkService`, and `any NetworkServiceType` at the three use sites.
- Doc comments: the `State.value` note, `state(initial:)`, `override`, and `DependencyOverride`.
- `CHANGELOG.md`: a 3.0.3 section listing the eight fixes and the changed override behaviour.
- The application and property-wrapper specs gain the new requirements and one changelog row each.
