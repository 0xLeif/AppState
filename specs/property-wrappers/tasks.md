---
spec: property-wrappers.spec.md
---

## Tasks

- [x] Write spec
- [x] Implement module
- [x] Write tests
- [x] Adopt Observation-based reactivity: computed `app` + `registerObservation()` in getters; remove stored `@ObservedObject` from state wrappers
- [x] Route mutations through `Application` (`app.value(keyPath:)`) so setters trigger `notifyChange()`
- [x] Add `@ModelState` (SwiftData) with a read-only wrapped value and `insert`/`delete`/`save`/`deleteAll` on its projected value
- [x] Provide `Binding` projected values and the enclosing-instance subscript on Apple platforms
- [x] Gate `@SyncState`/`@SecureState` to Apple platforms and `@ModelState` to `canImport(SwiftData)`
