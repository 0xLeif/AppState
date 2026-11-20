---
module: application
version: 6
status: active
files:
  - Sources/AppState/Application/Application.swift
  - Sources/AppState/Application/Application+public.swift
  - Sources/AppState/Application/Application+internal.swift
  - Sources/AppState/Application/Types/Dependency/Slice/Application+DependencySlice.swift
  - Sources/AppState/Application/Types/Dependency/Application+Dependency.swift
  - Sources/AppState/Application/Types/Helper/Application+ApplicationPreview.swift
  - Sources/AppState/Application/Types/Helper/Application+PersistenceFailure.swift
  - Sources/AppState/Application/Types/Helper/Application+Scope.swift
  - Sources/AppState/Application/Types/Helper/ApplicationLogger.swift
  - Sources/AppState/Application/Types/Helper/FileManager+AppState.swift
  - Sources/AppState/Application/Types/Helper/FileManaging.swift
  - Sources/AppState/Application/Types/Helper/Loggable.swift
  - Sources/AppState/Application/Types/Helper/MutableApplicationState.swift
  - Sources/AppState/Application/Types/Helper/UbiquitousKeyValueStoreManaging.swift
  - Sources/AppState/Application/Types/Helper/UserDefaultsManaging.swift
  - Sources/AppState/Application/Types/State/Application+FileState.swift
  - Sources/AppState/Application/Types/State/Application+SecureState.swift
  - Sources/AppState/Application/Types/State/Application+State.swift
  - Sources/AppState/Application/Types/State/Application+StoredState.swift
  - Sources/AppState/Application/Types/State/Application+SyncState.swift
  - Sources/AppState/Application/Types/State/Slice/Application+OptionalSlice.swift
  - Sources/AppState/Application/Types/State/Slice/Application+OptionalSliceOptionalValue.swift
  - Sources/AppState/Application/Types/State/Slice/Application+Slice.swift
  - Sources/AppState/Dependencies/Keychain.swift

db_tables: []
depends_on: []
---

# Application

## Purpose

The `Application` singleton manages global app state, dependencies, and scoped state containers. It provides a centralized registry for `State` values, secure state (Keychain), stored state (`UserDefaults`), synced state (iCloud), and file-backed state, and it manages dependency injection via the `Dependency` and `DependencySlice` types.

As of AppState 3.0 the singleton adopts Apple's Observation framework (`@Observable`) instead of `ObservableObject`. State and dependency values still live in an untracked `Cache`; a private observation anchor bridges cache changes to Observation so that SwiftUI views update reactively.

## Public API

### Exported Functions

| Export | Description |
|--------|-------------|
| Application.state(_:) | Retrieve or define a `State` value |
| Application.storedState(_:) | Retrieve or define a `UserDefaults`-backed state |
| Application.secureState(_:) | `@MainActor` key-path read of a `SecureState` (`canImport(Security)`). `value` returns the generic-password item, or the captured initial `String?` when `Keychain.get` returns nil. That nil is fail-open: a missing item, non-UTF-8 bytes, and any non-`noErr` status (unavailable keychain or missing entitlement included) are the same result, and the status is not logged. The `initial:feature:id:` factory captures the fallback and does not write the keychain. |
| Application.syncState(_:) | Retrieve or define an iCloud-backed state (Apple platforms) |
| Application.fileState(_:) | Retrieve or define a file-backed state |
| Application.dependency(_:) | Retrieve or define a dependency |
| Application.override(_:with:) | Temporarily override a dependency (previews/tests) |
| Application.promote(to:) | Promote the shared instance to a custom `Application` subclass |
| Application.reset(_:) | Reset a state to its initial value |
| Application.logging(isEnabled:) | Enable or disable AppState's internal logging |

> SwiftData support (`Application.modelState(_:)`, `Application.modelContext(_:)`) is documented in the `swiftdata` spec.

### Structs & Enums

| Type | Description |
|------|-------------|
| Application | `@Observable` singleton managing all app-wide state and dependencies (subclass of `NSObject`) |
| Application.Scope | Scope (name + id) used to derive unique keys for state and dependencies |
| Application.Dependency | Read-only injected dependency value |
| Application.DependencyOverride | Token that reverts a dependency override when released |
| ApplicationLogger | Logging utility used on Linux/Windows |

### Exported Traits

| Trait | Description |
|-------|-------------|
| MutableApplicationState | Protocol for state types that expose a mutable `value` and a `reset()` |

### Exported Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| state | `static func state<Value>(_: KeyPath<Application, State<Value>>) -> State<Value>` | Access a state value by key path |
| dependency | `static func dependency<Value>(_: KeyPath<Application, Dependency<Value>>) -> Value` | Resolve a dependency by key path |
| notifyChange | `func notifyChange()` | Ask observers (SwiftUI views) to update; called by AppState's setters and available for manual use (e.g. in `didChangeExternally` overrides) |
| `logger` | TODO | Document caller-visible behavior and constraints. |
| `notifyChange` | TODO | Document caller-visible behavior and constraints. |
| `didFailToPersist` | TODO | Document caller-visible behavior and constraints. |
| `didChangeExternally` | TODO | Document caller-visible behavior and constraints. |
| `init` | TODO | Document caller-visible behavior and constraints. |
| `slice` | TODO | Document caller-visible behavior and constraints. |
| `dependencySlice` | TODO | Document caller-visible behavior and constraints. |
| `description` | TODO | Document caller-visible behavior and constraints. |
| `promote` | TODO | Document caller-visible behavior and constraints. |
| `logging` | TODO | Document caller-visible behavior and constraints. |
| `load` | TODO | Document caller-visible behavior and constraints. |
| `dependency` | TODO | Document caller-visible behavior and constraints. |
| `preview` | TODO | Document caller-visible behavior and constraints. |
| `reset` | TODO | Document caller-visible behavior and constraints. |
| `state` | TODO | Document caller-visible behavior and constraints. |
| `storedState` | TODO | Document caller-visible behavior and constraints. |
| `syncState` | TODO | Document caller-visible behavior and constraints. |
| `secureState` | `@MainActor static func secureState(_ keyPath: KeyPath<Application, SecureState>, _ fileID: StaticString, _ function: StaticString, _ line: Int, _ column: Int) -> SecureState`; `func secureState(initial: @autoclosure () -> String?, feature: String = "App", id: String) -> SecureState`; `func secureState(feature: String = "App", id: String) -> SecureState` | The key-path function is `@MainActor` and returns the struct from that property. It does not itself write the keychain. When `Application.logging(isEnabled:)` is on, it debug-logs through `Application.logger` (`Logger` subsystem `AppState`, category `Application` where OSLog exists). A DEBUG build puts the current `value` in that string, which reads the keychain and can contain the secret; other builds log the key path only. Logging is off by default, and this is not an error log: the `OSStatus` is never included. The `initial` factory evaluates the autoclosure immediately, stores that `String?` as the fallback, and does not write or cache a `SecureState`. Its doc comment says a missing item is created and the initial value is persisted; the function body does not. `secureState(feature:id:)` is that factory with a nil initial value. Neither factory is `@MainActor`. The account string is `Scope.key`, `"\(feature)/\(id)"`, with no escaping, hashing, or version. Each read of a computed property runs the factory again. |
| `fileState` | TODO | Document caller-visible behavior and constraints. |
| `value` | TODO | Document caller-visible behavior and constraints. |
| `logValue` | TODO | Document caller-visible behavior and constraints. |
| `cancel` | TODO | Document caller-visible behavior and constraints. |
| `store` | TODO | Document caller-visible behavior and constraints. |
| `operation` | TODO | Document caller-visible behavior and constraints. |
| `key` | TODO | Document caller-visible behavior and constraints. |
| `error` | TODO | Document caller-visible behavior and constraints. |
| `read` | TODO | Document caller-visible behavior and constraints. |
| `write` | TODO | Document caller-visible behavior and constraints. |
| `delete` | TODO | Document caller-visible behavior and constraints. |
| `name` | TODO | Document caller-visible behavior and constraints. |
| `id` | TODO | Document caller-visible behavior and constraints. |
| `debug` | TODO | Document caller-visible behavior and constraints. |
| `generalError` | TODO | Document caller-visible behavior and constraints. |
| `defaultFileStatePath` | TODO | Document caller-visible behavior and constraints. |
| `removeItem` | TODO | Document caller-visible behavior and constraints. |
| `Value` | TODO | Document caller-visible behavior and constraints. |
| `emoji` | TODO | Document caller-visible behavior and constraints. |
| `data` | TODO | Document caller-visible behavior and constraints. |
| `set` | `Keychain.set(value:forKey:)` is `func set(value: String, forKey key: Key)`. The same export name also exists on `UserDefaultsManaging` and the iCloud key-value store; those write their own stores and are not this contract. | `Keychain.set` stores UTF-8 bytes of `value` as `kSecValueData` on a `kSecClassGenericPassword` item whose `kSecAttrAccount` is `key`. It sets no service, access group, accessibility, access-control, synchronizable, or data-protection-keychain attribute, on update or on add. If UTF-8 encoding returns nil, it returns without writing and without touching the index. Otherwise, under the shared `securityLock`, it calls `SecItemUpdate` with `kSecValueData`. When that status is `errSecItemNotFound` it calls `SecItemAdd`. Every other update status, and the add status, is ignored. There is no log, no throw, and no `didFailToPersist`. This is a silent drop: the caller sees a normal return whether or not the item was stored. After the lock, the key is inserted into this instance's index anyway. Overwrite replaces `kSecValueData` in place. It does not change the account, write a version, or rotate a key. The update-then-add pair is one lock hold. Not `@MainActor`. |
| `removeObject` | TODO | Document caller-visible behavior and constraints. |
| `object` | TODO | Document caller-visible behavior and constraints. |
| `fileManager` | TODO | Document caller-visible behavior and constraints. |
| `keychain` | `var keychain: Dependency<Keychain>` | `canImport(Security)` only. The getter calls `dependency(Keychain())`, so the first resolution of this call site caches one `Keychain()` and later reads return it. That instance starts with an empty index. `Application.SecureState` uses it through `@AppDependency(\.keychain)`. `loadDefaultDependencies()` does not load it. An override of `\.keychain` replaces the instance later reads use; items already stored stay in the system keychain under their account strings. The property is not actor-isolated. Item class, omitted protection attributes, fail-open `get`, silent `set` and `remove`, and the shared Security lock are the `Keychain` contract. No entitlement is read. |
| `userDefaults` | TODO | Document caller-visible behavior and constraints. |
| `icloudStore` | TODO | Document caller-visible behavior and constraints. |
| `Key` | TODO | Document caller-visible behavior and constraints. |
| `get` | `func get<Output>(_ key: Key, as: Output.Type) -> Output?` | Reads one `kSecClassGenericPassword` item with `kSecAttrAccount` = `key`, `kSecReturnData`, and `kSecMatchLimitOne`. It does not set service, access group, accessibility, access control, synchronizable, or data-protection-keychain. `SecItemCopyMatching` runs inside the process-wide `securityLock` shared with `set` and `remove`, including across `Keychain` instances. The source comment says this lock exists because a lock-free `get` beside a `remove` of the same key can deadlock inside Security.framework on the macOS file-based keychain. Returns UTF-8 `String` data cast to `Output`, otherwise nil. Nil is a missing item, any status other than `noErr` (the status is discarded and not logged), bytes that are not UTF-8, or an `Output` other than `String`. That is fail-open: absence and failure look the same. Does not update the in-memory index and does not rotate anything. Not `@MainActor`. A same-file `get(_ key) -> String?` forwards here. |
| `resolve` | `func resolve<Output>(_ key: Key, as: Output.Type) throws -> Output` | Calls `get` and throws `MissingRequiredKeysError(keys: [key])` when that returns nil. Fail-closed for the caller: it does not substitute a default. The error is still the missing-key error for every `get` failure, including a down keychain, a missing entitlement, non-UTF-8 data, and a non-`String` `Output`. It carries no `OSStatus` and nothing is logged. Same generic-password query, omitted protection attributes, and `securityLock` as `get`. Not `@MainActor`. No rotation. A same-file `resolve(_ key) throws -> String` forwards here. |
| `remove` | `func remove(_ key: Key)` | Under `securityLock`, calls `SecItemDelete` for `kSecClassGenericPassword` plus `kSecAttrAccount` = `key`. No other attributes are set. The status is discarded. The key is then removed from this instance's index even when the delete failed, so `values()` can hide an item that `get` still returns. No log, no throw, no `didFailToPersist`. A failed delete is a silent drop: the caller sees a normal return. Not `@MainActor`. Serialized with `get` and `set` by the same lock. Does not rotate or version the account. |
| `contains` | `func contains(_ key: Key) -> Bool` | `get(key, as: String.self) != nil`. False when the item is absent, the Security status is not `noErr`, or the bytes are not UTF-8. Fail-open: an unavailable keychain or a missing entitlement looks like absence. No separate query, no log, and no status is kept. Same generic-password item and `securityLock` as `get`. Not `@MainActor`. Does not write or rotate. |
| `require` | `func require(keys: Set<Key>) throws -> Self`; `func require(_ key: Key) throws -> Self` | `require(_:)` calls `require(keys:)`. Each key is checked with `contains`, so each check takes and releases `securityLock` on its own. The set is not one snapshot. Keys for which `contains` is false are thrown as `MissingRequiredKeysError`. That is fail-closed on the `contains` result, and it uses the same fail-open read: a keychain failure is reported as a missing key, with no `OSStatus` and no log. Returns `self` when every listed key reads back as a `String`. Not `@MainActor`. Does not write, delete, or rotate. |
| `values` | `@MainActor func values<Output>(ofType: Output.Type) -> [Key: Output]` | Not a keychain scan. Snapshots this instance's index, then calls `get` for each key and omits nils. `init()` starts from an empty index. `init(keys:)` only seeds that index; it does not read or write items. Keys stored by another `Keychain` instance are absent here. A key whose `set` failed can remain in the index and then be omitted because `get` returns nil. A key whose `remove` failed is already gone from the index, so a surviving secret is hidden. Same generic-password read and fail-open nil as `get`. Only a `String` survives the decode. The snapshot and the later reads are not one atomic view. The `@MainActor` `values() -> [Key: String]` overload calls this with `String.self`. |
| `Application` | TODO | Document caller-visible behavior and constraints. |
| `DependencySlice` | TODO | Document caller-visible behavior and constraints. |
| `Dependency` | TODO | Document caller-visible behavior and constraints. |
| `DependencyOverride` | TODO | Document caller-visible behavior and constraints. |
| `PersistenceFailure` | TODO | Document caller-visible behavior and constraints. |
| `Store` | TODO | Document caller-visible behavior and constraints. |
| `Operation` | TODO | Document caller-visible behavior and constraints. |
| `Scope` | TODO | Document caller-visible behavior and constraints. |
| `ApplicationLogger` | TODO | Document caller-visible behavior and constraints. |
| `LoggerError` | TODO | Document caller-visible behavior and constraints. |
| `FileManaging` | TODO | Document caller-visible behavior and constraints. |
| `MutableApplicationState` | TODO | Document caller-visible behavior and constraints. |
| `UbiquitousKeyValueStoreManaging` | TODO | Document caller-visible behavior and constraints. |
| `UserDefaultsManaging` | TODO | Document caller-visible behavior and constraints. |
| `SendableFileManager` | TODO | Document caller-visible behavior and constraints. |
| `FileState` | TODO | Document caller-visible behavior and constraints. |
| `SecureState` | `public struct SecureState: MutableApplicationState` | `canImport(Security)`. `MutableApplicationState` requires `value` and `reset()` to be `@MainActor`; `reset()` is also marked `@MainActor`. The getter reads `@AppDependency(\.keychain)` with `get(scope.key, as: String.self)`. On nil it returns the initial `String?` captured when this struct was built. That is fail-open: a missing item, non-UTF-8 data, and any failed Security status, including an unavailable keychain or a missing entitlement, all return the initial value. Nothing is logged and `didFailToPersist` is not called. Construction does not write the keychain. The setter calls `notifyChange()` first (that function asserts the main thread), then `remove` for nil or `set` for a string. Both ignore Security status, so a write can notify observers and still fail silently. `reset()` assigns `value = initial()`, which stores that string, or deletes the item only when the initial value is nil. The account is `scope.key`, `"\(name)/\(id)"`, with feature default `"App"`, no escaping, and no version. There is no key derivation and no protection class chosen here. The struct is a copy; the write sticks because `set` and `remove` run on the shared `Keychain` class. |
| `State` | TODO | Document caller-visible behavior and constraints. |
| `SendableUserDefaults` | TODO | Document caller-visible behavior and constraints. |
| `StoredState` | TODO | Document caller-visible behavior and constraints. |
| `SendableNSUbiquitousKeyValueStore` | TODO | Document caller-visible behavior and constraints. |
| `SyncState` | TODO | Document caller-visible behavior and constraints. |
| `OptionalSlice` | TODO | Document caller-visible behavior and constraints. |
| `OptionalSliceOptionalValue` | TODO | Document caller-visible behavior and constraints. |
| `Slice` | TODO | Document caller-visible behavior and constraints. |
| `Keychain` | `public final class Keychain: Sendable` | `canImport(Security)`. Stores a `String`'s UTF-8 bytes as `kSecValueData` on `kSecClassGenericPassword`, identified only by `kSecAttrAccount` = the caller key. It never sets `kSecAttrService`, `kSecAttrAccessGroup`, `kSecAttrAccessible`, `kSecAttrAccessControl`, `kSecAttrSynchronizable`, or `kSecUseDataProtectionKeychain`, and it never reads a protection class back. It is not an internet-password, key, or identity item. The header comment says it adopts `Cacheable`; the declaration conforms only to `Sendable`. No app-level encryption, key derivation, version attribute, or rotation API. `init()` starts an empty per-instance index. `init(keys:)` seeds that index and does not touch the keychain. `get` is fail-open (nil, status discarded, no log). `resolve` and `require` are fail-closed only by throwing `MissingRequiredKeysError` for that same nil. `set` and `remove` are silent: Security statuses other than the `errSecItemNotFound` branch in `set` are ignored, and the index is updated afterward even when the syscall failed. `get`, `set`, and `remove` serialize their Security calls on one process-wide `NSLock` shared by every instance, so those calls do not run at the same time. The index uses a separate lock, taken only after the Security lock is released, and it is not shared across instances. `values(ofType:)` is the only `@MainActor` method; the others are not actor-isolated. `values` lists the index, not the keychain. |

## Invariants

1. `Application` must always be a singleton; only one shared instance exists at runtime (`Application.shared`, main-actor isolated).
2. State and dependency values are stored in the `Cache`, which is `@ObservationIgnored`; observation is driven solely through the private change anchor via `registerObservation()` / `notifyChange()`.
3. Reading a value through a property wrapper registers an observation dependency; mutating a value notifies observers exactly once per change.
4. Dependency values are `Sendable`; dependency resolution must never cause retain cycles.
5. The library builds warning-free under the Swift 6 language mode with the `ExistentialAny` upcoming feature and `-warnings-as-errors`.
6. A `State` or `FileState` read fills the cache before it returns. A write made after a read in the same main-actor turn is the value later reads return.
7. `state(initial:)` evaluates its initial value once per scope while the state is cached, and `reset()` restores that first value.
8. A `DependencyOverride` restores the dependency it replaced on `cancel()` or on release, whichever comes first, and only once. Released on the main thread, it has restored before the release returns.
9. `promote(to:)` registers the promoted instance for the iCloud key-value store's external-change notification when the previous instance was registered.

## Behavioral Examples

```
Given an Application extension defining a state property
When the value is read via @AppState inside a SwiftUI view body
Then an observation dependency is registered for that view
And when the value is mutated, the view is asked to update via notifyChange()
```

```
Given a custom Application subclass overriding didChangeExternally(notification:)
When an iCloud change arrives
Then the subclass calls notifyChange() to refresh SwiftUI views
```

## Error Cases

| Error | When | Behavior |
|-------|------|----------|
| Keychain read failed or item missing | `Application.SecureState.value` when `Keychain.get` returns nil: no item, non-UTF-8 bytes, or any status other than `noErr` (unavailable keychain and missing entitlement included). The status is discarded. | Fail-open: returns the initial `String?` captured for that value. No error is logged and `didFailToPersist` is not called. `Keychain.resolve` and `require` throw `MissingRequiredKeysError` for the same nil. `set` and `remove` ignore the Security status and return as if they had succeeded. |
| iCloud unavailable | SyncState accessed without iCloud capability | Falls back to the local value |
| Decode failure | Stored/File state data cannot be decoded | Returns the initial value; error logged |
| Encode failure | A `StoredState` value is neither JSON-encodable nor a property list | The write is ignored and logged; the previous value stays |

## Dependencies

- Cache (0xLeif/Cache) — underlying caching layer for state and dependency values
- Observation (Swift standard library) — `@Observable` reactivity
- Combine (Apple platforms) — bridges the cache's change notifications to the observation anchor

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1 | 2026-04-21 | Initial spec |
| 2 | 2026-06-09 | AppState 3.0: adopt Observation (`@Observable`); add `notifyChange()`; remove `ObservableObject` conformance; raise platform floors to iOS 17 / macOS 14; pin Swift 6 language mode + `ExistentialAny` |
| 3 | 2026-11-16 | make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick: Make ModelState.deleteAll remove related models, and make struct dependency slice writes stick |
| 4 | 2026-11-16 | fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments: Fix the 10 bugs the review recorded, changing code to match the doc comments |
| 5 | 2026-11-16 | report-persistence-failures-to-an-overridable-application-method: Report persistence failures to an overridable Application method |
| 6 | 2026-11-20 | Document Keychain and SecureState from source: generic-password items with no access-control attribute, fail-open reads, silent writes and deletes, no rotation, and one shared Security lock. The previous keychain error row said an error is logged; the source does not log that status. |
