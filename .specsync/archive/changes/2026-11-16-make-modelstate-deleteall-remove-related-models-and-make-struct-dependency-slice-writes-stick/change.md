---
id: make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick
state: archived
type: bug_fix
base_commit: 5053feab3497605386613e4309bc0cf8c95dc5c4
---

# Make ModelState.deleteAll remove related models, and make struct dependency slice writes stick

## Intent

Make ModelState.deleteAll remove related models, and make struct dependency slice writes stick

## Affected Canonical Specs

- `swiftdata`
- `property-wrappers`
- `application`

## Acceptance Criteria

- Filtered ModelState.deleteAll removes only matching related models, and a struct DependencySlice write stays visible on the stored dependency.

## No-spec Rationale

Not applicable
