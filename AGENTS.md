# AGENTS.md

Rules for an agent working in this checkout.

## Process

- SpecSync is strict, and `source_dirs` is `Sources`. Chough sessions live in `.chough/`. Before you edit `Sources` or a spec, run `chough next`, then continue the open draft with `specsync`.
- Do not approve, ship, or close a human gate. Leif does that.
- Do not commit or push unless the user asks.
- `fledge.toml` defines the tasks: build is `swift build`, test is `swift test`, and lint is `APPSTATE_STRICT=1 swift build && APPSTATE_STRICT=1 swift test`.
- Local workers use `hc`, with one agent per separate git clone, not a shared worktree. Do not trust a local flint model on SwiftData relationship behavior.

## Code

- Swift 6, with explicit access control.
- No force-unwrap, `try!`, or `as!` in library code.
- Do not add `@unchecked Sendable` to pass a build.

## Tests

- `Keychain.get`, `set`, and `remove` share one lock. A lock-free `get` beside a `remove` of the same key can deadlock inside Security.framework. Keep `testKeychainConcurrentSameKey` in the suite.
- `@MainActor` XCTest methods in this package are `async`.
- `SecureState`, `SyncState`, and `Keychain` are compiled only inside `#if canImport(Security)`. SwiftData and `ModelState` need `canImport(SwiftData)`. Linux and Windows CI run `swift test`, so a test that touches those symbols outside the guard fails the build.

## How the library behaves

- A host that uses an enclosing-instance subscript (`@AppState`, `@Slice`, `@OptionalSlice`, `@StoredState`, `@FileState`, `@SecureState`, `@SyncState`) must conform to `ObservableObject`. `@ModelState` does not require it.
- `Application.state(...).value = x` does not compile, because the call returns a copy. Bind `var state = Application.state(...)` and then set `state.value`.
- `ModelState.models` is a live fetch. Mutations are on the projected value, and they do not bump `Application`'s observation anchor. A SwiftUI view that should refresh uses `@Query` on the same `ModelContainer`.
- `@Constant`, `@OptionalConstant`, and `@DependencyConstant` do not call `registerObservation()`. `@Slice` and `@OptionalSlice` do.
- A `DependencySlice` of a struct must be written back to the cache. `Application.dependencySlice` reloads the cached `Dependency` on each read and write.
- `dependency(someFunction)`, where `someFunction` is already a `() -> Value`, matches the autoclosure overload and stores the function instead of calling it. Pass a call expression.
