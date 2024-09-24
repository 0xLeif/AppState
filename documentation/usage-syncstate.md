# SyncState Usage

`SyncState` is a component of the **AppState** library that allows you to synchronize app state across multiple devices using iCloud. This is especially useful for keeping user preferences, settings, or other important data consistent across devices.

## Overview

`SyncState` leverages iCloud’s `NSUbiquitousKeyValueStore` to keep small amounts of data in sync across devices. This makes it ideal for syncing lightweight application state such as preferences or user settings.

### Key Features

- **iCloud Synchronization**: Automatically sync state across all devices logged into the same iCloud account.
- **Persistent Storage**: Data is stored persistently in iCloud, meaning it will persist even if the app is terminated or restarted.
- **Near Real-Time Sync**: Changes to the state are propagated to other devices almost instantly.

## SyncState: Near Real-Time State Synchronization

`SyncState` offers near real-time synchronization of application state across multiple devices using Apple's `NSUbiquitousKeyValueStore`. This allows for a consistent application state across various devices in your ecosystem. If your application operates on multiple platforms, `SyncState` ensures that all instances share the same state in near real-time.

`NSUbiquitousKeyValueStore` provides a lightweight, quick setup solution to store small amounts of data that are available ubiquitously across a user's multiple devices. The data is stored in iCloud and automatically syncs to all devices signed in to the same iCloud account, making it an ideal solution for synchronizing application state.

### Storage Limits

The total amount of space available in your app’s key-value store, for a given user, is 1 MB. There is a per-key value size limit of 1 MB, and a maximum of 1024 keys. If you attempt to write data that exceeds these quotas, the write attempt fails and no change is made to your iCloud key-value storage. In this scenario, the system posts the `didChangeExternallyNotification` notification with a change reason of `NSUbiquitousKeyValueStoreQuotaViolationChange`.

For more information on synchronizing app preferences with iCloud, you can refer to [Apple's official documentation](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore).

## Example Usage

### Defining a SyncState

You can define a `SyncState` by extending the `Application` object and declaring the state properties that should be synced.

```swift
import AppState

extension Application {
    var darkModeEnabled: SyncState<Bool> {
        syncState(initial: false, id: "darkModeEnabled")
    }
}
```

### Accessing and Modifying the Synced State

You can modify the `SyncState` in the same way as any other state, but the value will be synced across all devices connected to the user’s iCloud account.

```swift
@SyncState(\.darkModeEnabled) var isDarkModeEnabled: Bool

// Toggle dark mode
isDarkModeEnabled.toggle()

// Check the current value
print(isDarkModeEnabled)  // Prints true or false depending on the current state
```

### Handling Synchronization Across Devices

`SyncState` automatically handles syncing the state across all devices. Any updates made on one device will be reflected on other devices that use the same iCloud account.

### Handling Absence of iCloud

If iCloud is unavailable, `SyncState` will continue to function locally, but changes will not be synced until iCloud becomes available again.

```swift
if isDarkModeEnabled {
    print("Dark Mode is enabled")
} else {
    print("Dark Mode is disabled")
}
```

## Best Practices

- **Use for Lightweight Data**: `SyncState` is best suited for small, user-specific settings or preferences that need to be consistent across devices.
- **Monitor iCloud Availability**: Ensure that your app handles cases where iCloud is not available. For example, provide users with an option to manually sync their settings.
- **Error Handling**: While `SyncState` manages synchronization automatically, ensure that your app gracefully handles any errors, such as network failures or issues with iCloud.

## Conclusion

`SyncState` is a powerful tool for ensuring that your app’s state is consistent across all devices using iCloud. This makes it an ideal choice for syncing user settings, preferences, and other lightweight data. Explore other components of the **AppState** library, such as [SecureState](usage-securestate.md) and [StoredState](usage-state-dependency.md), to manage your app’s state and data effectively.
