# Slicing State Usage

`Slice` and `OptionalSlice` are components of the **AppState** library that provide fine-grained access to specific parts of your application’s state. They allow you to focus on specific sections of state while keeping the overall state management centralized.

## Overview

`Slice` allows you to directly access and modify parts of a state, such as individual properties within a larger data structure. `OptionalSlice` serves a similar function but is designed for handling optional values.

### Key Features

- **Fine-Grained Control**: Access and modify specific parts of application state.
- **State Segmentation**: Keep your state management organized by isolating specific sections of state.
- **Optional Handling**: `OptionalSlice` is designed to work with optional values within your state, ensuring that nil values are handled gracefully.

## Example Usage

### Slicing a State

To access specific properties in your application’s state, you can use the `Slice` to create focused access points.

```swift
import AppState

struct User {
    let id: UUID
    var username: String
}

extension Application {
    var user: State<User> {
        state(initial: User(id: UUID(), username: "Guest"))
    }
}

@Slice(\.user, \.username) var username: String

// Modify the username
username = "NewUsername"
print(username)  // Prints "NewUsername"
```

### Optional Slicing

`OptionalSlice` allows you to safely access and modify optional values in your state. If the parent state is `nil`, you cannot modify the child value.

```swift
import AppState

struct Preferences {
    var isDarkModeEnabled: Bool
}

extension Application {
    var preferences: State<Preferences?> {
        state(initial: nil)
    }
}

@OptionalSlice(\.preferences, \.isDarkModeEnabled) var isDarkModeEnabled: Bool?

// Handle optional state safely
if let darkMode = isDarkModeEnabled {
    print("Dark Mode: \(darkMode)")
} else {
    print("Preferences not set")
}
```

### Dictionary Slicing

You can also use `Slice` and `OptionalSlice` to work with values stored in a dictionary.

```swift
import AppState

extension Application {
    var userMetadata: State<[String: String]> {
        state(initial: [:])
    }
}

@Slice(\.userMetadata, \.["loginTimestamp"]) var loginTimestamp: String?

// Set and access a value from the dictionary slice
loginTimestamp = "2024-01-01T00:00:00Z"
print(loginTimestamp ?? "No timestamp set")  // Prints the set timestamp
```

## Best Practices

- **Use `Slice` for Non-Optional State**: When dealing with non-optional state values, `Slice` provides direct access for efficient updates.
- **Use `OptionalSlice` for Optional Values**: Always prefer `OptionalSlice` when handling optional state to avoid unwrapping issues.
- **Handle `nil` Safely**: When working with `OptionalSlice`, ensure your app can handle `nil` values gracefully to avoid crashes.

## Conclusion

`Slice` and `OptionalSlice` provide granular control over your application’s state, making it easier to manage and update specific sections of state while keeping the rest of your state management centralized. Explore other components of the **AppState** library, such as [State and Dependency Management](usage-state-dependency.md) and [SecureState](usage-securestate.md), for additional state management tools.
