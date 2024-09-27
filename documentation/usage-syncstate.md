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

### Data Model

Assume we have a struct named `Settings` that conforms to `Codable`:

```swift
struct Settings: Codable {
    var text: String
    var isShowingSheet: Bool
    var isDarkMode: Bool
}
```

### Defining a SyncState

You can define a `SyncState` by extending the `Application` object and declaring the state properties that should be synced:

```swift
extension Application {
    var settings: SyncState<Settings> {
        syncState(
            initial: Settings(
                text: "Hello, World!",
                isShowingSheet: false,
                isDarkMode: false
            ),
            id: "settings"
        )
    }
}
```

### Handling External Changes

To ensure the app responds to external changes from iCloud, override the `didChangeExternally` function by creating a custom `Application` subclass:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
```

### Creating Views to Modify and Sync State

In the following example, we have two views: `ContentView` and `ContentViewInnerView`. These views share and sync the `Settings` state between them. `ContentView` allows the user to modify the `text` and toggle `isDarkMode`, while `ContentViewInnerView` displays the same text and updates it when tapped.

```swift
struct ContentView: View {
    @SyncState(\.settings) private var settings: Settings

    var body: some View {
        VStack {
            TextField("", text: $settings.text)

            Button(settings.isDarkMode ? "Light" : "Dark") {
                settings.isDarkMode.toggle()
            }

            Button("Show") { settings.isShowingSheet = true }
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        .sheet(isPresented: $settings.isShowingSheet, content: ContentViewInnerView.init)
    }
}

struct ContentViewInnerView: View {
    @Slice(\.settings, \.text) private var text: String

    var body: some View {
        Text("\(text)")
            .onTapGesture {
                text = Date().formatted()
            }
    }
}
```

### Setting Up the App

Finally, set up the application in the `@main` struct. In the initialization, promote the custom application, enable logging, and load the iCloud store dependency for syncing:

```swift
@main
struct SyncStateExampleApp: App {
    init() {
        Application
            .promote(to: CustomApplication.self)
            .logging(isEnabled: true)
            .load(dependency: \.icloudStore)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Enabling iCloud Key-Value Store

To enable iCloud syncing, make sure you follow this guide to enable the iCloud Key-Value Store capability: [Starting to use SyncState](https://github.com/0xLeif/AppState/wiki/Starting-to-use-SyncState).

### SyncState: Notes on iCloud Storage

While `SyncState` allows easy synchronization, it's important to remember the limitations of `NSUbiquitousKeyValueStore`:

- **Storage Limit**: You can store up to 1 MB of data in iCloud using `NSUbiquitousKeyValueStore`, with a per-key value size limit of 1 MB.

### Migration Considerations

When updating your data model, it's important to account for potential migration challenges, especially when working with persisted data using **StoredState**, **FileState**, or **SyncState**. Without proper migration handling, changes like adding new fields or modifying data formats can cause issues when older data is loaded.

Here are some key points to keep in mind:
- **Adding New Non-Optional Fields**: Ensure new fields are either optional or have default values to maintain backward compatibility.
- **Handling Data Format Changes**: If the structure of your model changes, implement custom decoding logic to support old formats.
- **Versioning Your Models**: Use a `version` field in your models to help with migrations and apply logic based on the data’s version.

To learn more about how to manage migrations and avoid potential issues, refer to the [Migration Considerations Guide](migration-considerations.md).

## SyncState Implementation Guide

For detailed instructions on how to configure iCloud and set up SyncState in your project, see the [SyncState Implementation Guide](syncstate-implementation.md).

## Best Practices

- **Use for Small, Critical Data**: `SyncState` is ideal for synchronizing small, important pieces of state such as user preferences, settings, or feature flags.
- **Monitor iCloud Storage**: Ensure that your usage of `SyncState` stays within iCloud storage limits to prevent data sync issues.
- **Handle External Updates**: If your app needs to respond to state changes initiated on another device, override the `didChangeExternally` function to update the app's state in real time.

## Conclusion

`SyncState` provides a powerful way to synchronize small amounts of application state across devices via iCloud. It is ideal for ensuring that user preferences and other key data remain consistent across all devices logged into the same iCloud account. For more advanced use cases, explore other features of **AppState**, such as [SecureState](usage-securestate.md) and [FileState](usage-filestate.md).
