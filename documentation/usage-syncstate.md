# SyncState Usage

`SyncState` is a component of the **AppState** library that allows you to synchronize app state across multiple devices using iCloud. This is especially useful for keeping user preferences, settings, or other important data consistent across devices.

## Overview

`SyncState` leverages iCloud’s `NSUbiquitousKeyValueStore` to keep small amounts of data in sync across devices. This makes it ideal for syncing lightweight application state such as preferences or user settings.

### Key Features

- **iCloud Synchronization**: Automatically sync state across all devices logged into the same iCloud account.
- **Persistent Storage**: Data is stored persistently in iCloud, meaning it will persist even if the app is terminated or restarted.
- **Near Real-Time Sync**: Changes to the state are propagated to other devices almost instantly.

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

### SyncState: Notes on iCloud Storage

While `SyncState` allows easy synchronization, it's important to remember the limitations of `NSUbiquitousKeyValueStore`:

- **Storage Limit**: You can store up to 1 MB of data in iCloud using `NSUbiquitousKeyValueStore`, with a per-key value size limit of 1 MB.
