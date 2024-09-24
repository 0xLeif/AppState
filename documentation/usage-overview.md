# Usage Overview

This overview provides a quick introduction to using the key components of the **AppState** library within a SwiftUI `View`. Each section includes simple examples that fit into the scope of a SwiftUI view structure, along with instructions on how to create these values by extending `Application`.

## Defining Values in Application Extension

To define application-wide state or dependencies, you should extend the `Application` object. This allows you to centralize all your app’s state in one place. Here's an example of how to extend `Application` to create various states and dependencies:

```swift
import AppState

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }

    var userPreferences: StoredState<String> {
        storedState(id: "userPreferences", initial: "Default Preferences")
    }

    var darkModeEnabled: SyncState<Bool> {
        syncState(initial: false, id: "darkModeEnabled")
    }

    var userToken: SecureState {
        secureState(id: "userToken")
    }
}
```

## State

`State` allows you to define application-wide state that can be accessed and modified anywhere in your app.

### Example

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("Hello, \(user.name)!")
            Button("Log in") {
                user.isLoggedIn.toggle()
            }
        }
    }
}
```

This example shows how to define and modify an application-wide state within a SwiftUI `View`.

## StoredState

`StoredState` persists state using `UserDefaults` to ensure that values are saved across app launches.

### Example

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

This example demonstrates how to use `StoredState` to persist data using `UserDefaults` within a SwiftUI view.

## SyncState

`SyncState` synchronizes app state across multiple devices using iCloud.

### Example

```swift
import AppState
import SwiftUI

struct SyncSettingsView: View {
    @SyncState(\.darkModeEnabled) var isDarkModeEnabled: Bool

    var body: some View {
        VStack {
            Toggle("Dark Mode", isOn: $isDarkModeEnabled)
        }
    }
}
```

This example shows how to use `SyncState` to synchronize data across devices via iCloud within a SwiftUI `View`.

## SecureState

`SecureState` stores sensitive data securely in the Keychain.

### Example

```swift
import AppState
import SwiftUI

struct SecureView: View {
    @SecureState(\.userToken) var userToken: String?

    var body: some View {
        VStack {
            if let token = userToken {
                Text("User token: \(token)")
            } else {
                Text("No token found.")
            }
            Button("Set Token") {
                userToken = "secure_token_value"
            }
        }
    }
}
```

This example shows how to securely store and access data in the Keychain using `SecureState` within a SwiftUI view.

## Slicing State

`Slice` and `OptionalSlice` allow you to access specific parts of your application’s state.

### Example

```swift
import AppState
import SwiftUI

struct SlicingView: View {
    @Slice(\.user, \.username) var username: String

    var body: some View {
        VStack {
            Text("Username: \(username)")
            Button("Update Username") {
                username = "NewUsername"
            }
        }
    }
}
```

This example demonstrates how to access and modify a specific slice of application state within a SwiftUI view.

## Best Practices

- **Use `AppState` in SwiftUI Views**: Property wrappers like `@AppState`, `@StoredState`, `@SecureState`, and others are designed to be used within the scope of SwiftUI views.
- **Define State in Application Extension**: Centralize state management by extending `Application` to define your app’s state and dependencies.
- **Reactive Updates**: SwiftUI automatically updates views when state changes, so you don’t need to manually refresh the UI.

## Conclusion

These examples demonstrate how to use **AppState**’s key components within SwiftUI views and how to define state and dependencies using an `Application` extension. By leveraging **AppState** in your views, you can effectively manage state, sync data across devices, and securely store sensitive information.
