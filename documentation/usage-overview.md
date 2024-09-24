# Usage Overview

This overview provides a quick introduction to using the key components of the **AppState** library. Each section includes simple examples to help you get started with **AppState** in your Swift projects.

## State

`State` allows you to define application-wide state that can be accessed and modified anywhere in your app.

### Example

```swift
import AppState

extension Application {
    var isLoading: State<Bool> {
        state(initial: false)
    }
}

var loadingState = Application.state(\.isLoading)
loadingState.value = true
print(loadingState.value)  // Prints "true"
```

This example shows how to define and modify an application-wide state.

## StoredState

`StoredState` persists state using `UserDefaults` to ensure that values are saved across app launches.

### Example

```swift
import AppState

extension Application {
    var userPreferences: StoredState<String> {
        storedState(id: "userPreferences", initial: "Default Preferences")
    }
}

var preferences = Application.state(\.userPreferences)
preferences.value = "New Preferences"
print(preferences.value)  // Prints "New Preferences"
```

This example demonstrates how to use `StoredState` to persist data using `UserDefaults`.

## SyncState

`SyncState` synchronizes app state across multiple devices using iCloud.

### Example

```swift
import AppState

extension Application {
    var darkModeEnabled: SyncState<Bool> {
        syncState(initial: false, id: "darkModeEnabled")
    }
}

@SyncState(\.darkModeEnabled) var isDarkModeEnabled: Bool
isDarkModeEnabled = true
```

This example shows how to use `SyncState` to synchronize data across devices via iCloud.

## SecureState

`SecureState` stores sensitive data securely in the Keychain.

### Example

```swift
import AppState

extension Application {
    var userToken: SecureState {
        secureState(id: "userToken")
    }
}

@SecureState(\.userToken) var userToken: String?
userToken = "secret_token"
```

This example shows how to securely store data in the Keychain using `SecureState`.

## Slicing State

`Slice` and `OptionalSlice` allow you to access specific parts of your application’s state.

### Example

```swift
import AppState

@Slice(\.user, \.username) var username: String

username = "New Username"
print(username)  // Prints "New Username"
```

This example demonstrates how to access and modify a specific slice of application state.

## Next Steps

For more in-depth details on each component, refer to the specific usage guides:

- [State and Dependency Usage](usage-state-dependency.md)
- [SendableValue Usage](usage-sendablevalue.md)
- [SyncState Usage](usage-syncstate.md)
- [SecureState Usage](usage-securestate.md)
- [Slicing State Usage](usage-slice.md)

These guides will help you explore each feature of **AppState** in more detail and provide additional examples.
