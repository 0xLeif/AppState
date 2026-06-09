---
spec: swiftdata.spec.md
---

## Tasks

- [x] Write spec
- [x] Add `ModelContainer` dependency support (`Application.modelContext(_:)` + `modelContainer(_:)` registration convenience)
- [x] Implement `Application.ModelState` (`value` get/set, `context`, `insert`, `delete`, `save`, `reset`) and the `modelState(...)` factories/accessors plus `Application.reset(modelState:)`
- [x] Implement the `@ModelState` property wrapper (wrappedValue + projected value exposing `insert`/`delete`/`save`)
- [x] Gate the module behind `#if canImport(SwiftData)` with the iOS 17 / macOS 14 platform floor
- [x] Write tests (`ModelStateTests`)
