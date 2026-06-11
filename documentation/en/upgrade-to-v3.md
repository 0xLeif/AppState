# Upgrading to AppState 3.0

AppState 3.0 is built around Swift 6 and Apple's Observation framework. Below are the breaking changes and how to adapt.

## Breaking changes at a glance

- **Platform minimums raised** — iOS 17, macOS 14, tvOS 17, watchOS 10
- **Swift 6 strict concurrency** — `ExistentialAny` enabled; explicit `any` required on protocol existentials
- **`ObservableObject` removed** — `Application` uses `@Observable`; `objectWillChange` is gone, replace with `notifyChange()`
- **New (additive): SwiftData support** — `ModelState` / `@ModelState` for `@Model` objects

---

## 1. Raised platform requirements

| Platform | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux and Windows continue to be supported for the non-Apple feature set.

Stay on the 2.x release line if you need to support older OS versions.

## 2. Strict Swift 6

The package pins the Swift 6 language mode (`swiftLanguageModes: [.v6]`) and enables the `ExistentialAny` upcoming feature. CI builds with warnings as errors.

Most apps require no changes. If you implemented any of AppState's public protocols — `FileManaging`, `UserDefaultsManaging`, or `UbiquitousKeyValueStoreManaging` — you may need to write existential types with an explicit `any`:

```swift
// Before (2.x)
var fileManager: FileManaging

// After (3.0)
var fileManager: any FileManaging
```

## 3. Observation replaces ObservableObject

`Application` now uses [`@Observable`](https://developer.apple.com/documentation/observation) instead of `ObservableObject`.

**Property wrappers are unchanged.** `@AppState`, `@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`, `@OptionalSlice`, `@DependencySlice`, and `@ModelState` all continue to work inside SwiftUI views. View models that conform to `ObservableObject` and host these wrappers are still supported.

What changed:

- `Application.shared.objectWillChange` no longer exists.
- `Application.notifyChange()` replaces it. AppState's own setters call it automatically.
- Reading `Application.state(_:).value` directly now participates in Observation — not just the `@AppState` wrapper. This means any code (not just SwiftUI views) can observe state changes:

  ```swift
  withObservationTracking {
      _ = Application.state(\.counter).value
  } onChange: {
      // runs when the value changes — no SwiftUI required
  }
  ```

If you subclassed `Application` and called `objectWillChange.send()` manually (e.g., from a `didChangeExternally` override), replace it with `notifyChange()`:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            self.notifyChange()
        }
    }
}
```

> `@ObservedDependency` is unchanged — it still observes dependency values that conform to `ObservableObject`.

## 4. New: SwiftData support

3.0 adds SwiftData integration. Inject a shared `ModelContainer` as a dependency and read/write `@Model` objects through `ModelState`. This is additive and optional — see the [ModelState Usage Guide](usage-modelstate.md).
