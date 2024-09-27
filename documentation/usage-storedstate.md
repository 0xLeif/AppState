# StoredState Usage

`StoredState` is a component of the **AppState** library that allows you to store and persist small amounts of data using `UserDefaults`. It is ideal for storing lightweight, non-sensitive data that should persist across app launches.

## Overview

- **StoredState** is built on top of `UserDefaults`, which means it’s fast and efficient for storing small amounts of data (such as user preferences or app settings).
- Data saved in **StoredState** persists across app sessions, allowing you to restore application state on launch.

### Key Features

- **Persistent Storage**: Data saved in `StoredState` remains available between app launches.
- **Small Data Handling**: Best used for lightweight data like preferences, toggles, or small configurations.
- **Thread-Safe**: `StoredState` ensures that data access remains safe in concurrent environments.

## Example Usage

### Defining a StoredState

You can define a **StoredState** by extending the `Application` object and declaring the state property:

```swift
import AppState

extension Application {
    var userPreferences: StoredState<String> {
        storedState(initial: "Default Preferences", id: "userPreferences")
    }
}
```

### Accessing and Modifying StoredState in a View

You can access and modify **StoredState** values within SwiftUI views using the `@StoredState` property wrapper:

```swift
import AppState
import SwiftUI

struct PreferencesView: View {
    @StoredState(\.userPreferences) var userPreferences: String

    var body: some View {
        VStack {
            Text("Preferences: \(userPreferences)")
            Button("Update Preferences") {
                userPreferences = "Updated Preferences"
            }
        }
    }
}
```

## Handling Data Migration

As your app evolves, you may update the models that are persisted via **StoredState**. When updating your data model, ensure backward compatibility. For example, you might add new fields or version your model to handle migration.

For more information, refer to the [Migration Considerations Guide](migration-considerations.md).

### Migration Considerations

- **Adding New Non-Optional Fields**: Ensure new fields are either optional or have default values to maintain backward compatibility.
- **Versioning Models**: If your data model changes over time, include a `version` field to manage different versions of your persisted data.

## Best Practices

- **Use for Small Data**: Store lightweight, non-sensitive data that needs to persist across app launches, like user preferences.
- **Consider Alternatives for Larger Data**: If you need to store large amounts of data, consider using **FileState** instead.

## Conclusion

**StoredState** is a simple and efficient way to persist small pieces of data using `UserDefaults`. It is ideal for saving preferences and other small settings across app launches while providing safe access and easy integration with SwiftUI. For more complex persistence needs, explore other **AppState** features like [FileState](usage-filestate.md) or [SyncState](usage-syncstate.md).
