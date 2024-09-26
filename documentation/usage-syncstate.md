# SyncState Usage

`SyncState` is a component of the **AppState** library that allows you to synchronize app state across multiple devices using iCloud. This is especially useful for keeping user preferences, settings, or other important data consistent across devices.

## Overview

`SyncState` leverages iCloud’s `NSUbiquitousKeyValueStore` to keep small amounts of data in sync across devices. This makes it ideal for syncing lightweight application state such as preferences or user settings.

### Key Features

- **iCloud Synchronization**: Automatically sync state across all devices logged into the same iCloud account.
- **Persistent Storage**: Data is stored persistently in iCloud, meaning it will persist even if the app is terminated or restarted.
- **Near Real-Time Sync**: Changes to the state are propagated to other devices almost instantly.

> **Note**: `SyncState` is supported on watchOS 9.0 and later.

## Example Usage

### Defining a SyncState

You can define a `SyncState` by extending the `Application` object and declaring the state properties that should be synced:

```swift
import AppState

extension Application {
    var syncValue: SyncState<Int?> {
        syncState(id: "syncValue")
    }
}
```

### Accessing and Modifying the Synced State in a View

You can access and modify `SyncState` values within SwiftUI views using the `@SyncState` property wrapper. The value will sync across devices via iCloud:

```swift
import AppState
import SwiftUI

struct SyncStateView: View {
    @SyncState(\.syncValue) var count: Int?

    var body: some View {
        VStack {
            if let count = count {
                Text("Count: \(count)")
            } else {
                Text("No count set")
            }
            Button("Set Count") {
                self.count = 1
            }
        }
    }
}
```

### Using SyncState in a ViewModel

You can also use `SyncState` in a ViewModel to sync state between multiple devices and integrate it into your SwiftUI view.

```swift
@MainActor
class SyncStateViewModel: ObservableObject {
    @SyncState(\.syncValue) var count: Int?

    func updateCount() {
        count = 10
    }
}

struct SyncStateViewModelView: View {
    @ObservedObject private var viewModel = SyncStateViewModel()

    var body: some View {
        VStack {
            if let count = viewModel.count {
                Text("Count: \(count)")
            } else {
                Text("No count set")
            }
            Button("Update Count") {
                viewModel.updateCount()
            }
        }
    }
}
```

### SyncState: Notes on iCloud Storage

While `SyncState` allows easy synchronization, it's important to remember the limitations of `NSUbiquitousKeyValueStore`:

- **Storage Limit**: You can store up to 1 MB of data in iCloud using `NSUbiquitousKeyValueStore`, with a per-key value size limit of 1 MB.

## Best Practices

- **Use for Small, Critical Data**: `SyncState` is ideal for synchronizing small, important pieces of state such as user preferences, settings, or feature flags.
- **Monitor iCloud Storage**: Ensure that your usage of `SyncState` stays within iCloud storage limits to prevent data sync issues.

## Conclusion

`SyncState` provides a powerful way to synchronize small amounts of application state across devices via iCloud. It is ideal for ensuring that user preferences and other key data remain consistent across all devices logged into the same iCloud account. For more advanced use cases, explore other features of **AppState**, such as [SecureState](usage-securestate.md) and [SyncState](usage-syncstate.md).
