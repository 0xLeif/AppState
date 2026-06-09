---
spec: swiftdata.spec.md
---

## Tasks

- [x] Write spec
- [x] Add `ModelContainer` dependency support (`Application.modelContext(_:)` + `modelContainer(_:)` registration convenience)
- [x] Implement `Application.ModelState` (read-only `models`, `context`, `insert`, `delete`, `save`, `deleteAll`) and the `modelState(...)` factories/accessors
- [x] Implement the `@ModelState` property wrapper (read-only wrappedValue + projected value exposing `insert`/`delete`/`save`/`deleteAll`)
- [x] Gate the module behind `#if canImport(SwiftData)` with the iOS 17 / macOS 14 platform floor
- [x] Write tests (`ModelStateTests`)
