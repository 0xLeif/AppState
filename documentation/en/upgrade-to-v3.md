# Upgrading to AppState 3.0

AppState 3.0 modernizes the library around Swift 6 and Apple's Observation
framework. This guide covers the breaking changes and how to adapt.

## 1. Raised platform requirements

The minimum deployment targets were raised to take advantage of modern Swift and
SwiftData/Observation APIs:

| Platform | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux and Windows continue to be supported for the non-Apple feature set.

If you must continue to support older OS versions, stay on the 2.x release line.

## 2. Strict Swift 6

The package now pins the Swift 6 language mode (`swiftLanguageModes: [.v6]`) and the
`ExistentialAny` upcoming feature, and CI builds with warnings treated as errors.
For most apps this requires no changes. If you implemented any of AppState's
public protocols (for example a custom `FileManaging`, `UserDefaultsManaging`, or
`UbiquitousKeyValueStoreManaging`), you may need to write existential types with an
explicit `any` (e.g. `any FileManaging`).

## 3. Observation replaces ObservableObject

`Application` now uses the [`@Observable`](https://developer.apple.com/documentation/observation)
macro instead of conforming to `ObservableObject`.

**No change is required for typical usage.** The property wrappers — `@AppState`,
`@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`,
`@OptionalSlice`, `@DependencySlice`, and `@ModelState` — continue to work inside
SwiftUI views and views update as before. View models that conform to
`ObservableObject` and host these wrappers are still supported.

Why the change? AppState's observation has always been coarse: under the previous
`ObservableObject` design, any change to the shared registry notified every
observer. The move to `@Observable` keeps that behavior but adopts the modern,
standard-library Observation framework (available on Linux and Windows too) and
removes the `NSObject` + Combine `ObservableObject` coupling. Finer-grained,
per-key observation is a possible future enhancement and is not part of 3.0.

What changed:

- `Application` no longer conforms to `ObservableObject`, so
  `Application.shared.objectWillChange` is no longer available.
- A new method, `Application.notifyChange()`, asks observers (SwiftUI views) to
  update. AppState's own setters call it for you.

If you subclassed `Application` and triggered updates manually — for example from a
`didChangeExternally(notification:)` override that reacts to incoming iCloud
changes — replace `objectWillChange.send()` with `notifyChange()`:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            // Before (2.x):
            // self.objectWillChange.send()

            // After (3.0):
            self.notifyChange()
        }
    }
}
```

> Note: `@ObservedDependency` is unchanged. It still observes dependency values
> that conform to `ObservableObject`.

## 4. New: SwiftData support

3.0 adds first-class SwiftData integration: inject a shared `ModelContainer` as a
dependency and read/write `@Model` objects through `ModelState`. See the
[ModelState Usage Guide](usage-modelstate.md). This is additive and optional.
