# Usage Overview

This overview provides a quick introduction to using the key components of the **AppState** library within a SwiftUI `View`. Each section includes simple examples that fit into the scope of a SwiftUI view structure.

## Defining Values in Application Extension

To define application-wide state or dependencies, you should extend the `Application` object. This allows you to centralize all your app’s state in one place. Here's an example of how to extend `Application` to create various states and dependencies:

```swift
import AppState

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }

    var userPreferences: StoredState<String> {
        storedState(initial: "Default Preferences", id: "userPreferences")
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

## Best Practices

- **Use `AppState` in SwiftUI Views**: Property wrappers like `@AppState`, `@StoredState`, `@SecureState`, and others are designed to be used within the scope of SwiftUI views.
- **Define State in Application Extension**: Centralize state management by extending `Application` to define your app’s state and dependencies.
- **Reactive Updates**: SwiftUI automatically updates views when state changes, so you don’t need to manually refresh the UI.

## Next Steps

After familiarizing yourself with the basic usage, you can explore more advanced topics:

- Explore using **FileState** for persisting large amounts of data to files in the [FileState Usage Guide](usage-filestate.md).
- Learn about **Constants** and how to use them for immutable values in your app's state in the [Constant Usage Guide](usage-constant.md).
- Investigate how **Dependency** is used in AppState to handle shared services, and see examples in the [State Dependency Usage Guide](usage-state-dependency.md).
- Delve deeper into **Advanced SwiftUI** techniques like using `ObservedDependency` for managing observable dependencies in views in the [ObservedDependency Usage Guide](usage-observeddependency.md).
