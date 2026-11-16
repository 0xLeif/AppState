---
id: report-persistence-failures-to-an-overridable-application-method
state: approved
type: feature
base_commit: 194067d89470cad8e27fa81a9fe006986a802958
---

# Report persistence failures to an overridable Application method

## Intent

Report persistence failures to an overridable Application method

## Affected Canonical Specs

- `application`

## Acceptance Criteria

- PersistenceFailureTests passes: an Application subclass that overrides didFailToPersist hears a FileState read failure for a file that cannot be decoded, a FileState write failure, a rejected StoredState value and a SyncState value that cannot be encoded, each with the store, operation, key and error; it hears nothing for a successful round trip or for a FileState that was never written; an application without the override behaves as before; every test class passes on macOS under the strict build and in a release build, the Linux suite passes on Swift 6.1 and the WASI build passes

## No-spec Rationale

Not applicable
