# State and Dependency Usage

**AppState** provides powerful tools for managing application-wide state and injecting dependencies throughout your Swift application. By centralizing your state and dependencies, you can make your application easier to maintain and extend.

## Overview

- **State**: Represents a value that can be shared across the app. State values can be modified and observed from anywhere within the application.
- **Dependency**: Represents a shared resource or service that can be injected and accessed in different parts of the app.

### Key Features

- **Centralized State**: Define and manage application-wide state in one place.
- **Dependency Injection**: Inject and access shared services and resources across different components of your application.
- **SwiftUI Integration**: `AppState` integrates easily with SwiftUI using property wrappers to provide reactive state management.

## Example Usage

### Defining Application State

To define application-wide state, extend the `Application` object and declare the state properties.

```swift
import AppState

struct User {
    var name: String
    var isLoggedIn: Bool
}

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }
}
```

### Accessing and Modifying State

You can access and modify state values from anywhere in your application using property wrappers.

```swift
@AppState(\.user) var user: User

// Modify the state
user.name = "John Doe"
user.isLoggedIn = true

// Access the updated state
print(user.name)  // Prints "John Doe"
```

### Injecting Dependencies

You can define dependencies in the `Application` object and inject them wherever needed. Dependencies are ideal for services like networking, database access, or API clients.

```swift
import AppState

protocol NetworkServiceType {
    func fetchData() -> String
}

class NetworkService: NetworkServiceType {
    func fetchData() -> String {
        return "Data from network"
    }
}

extension Application {
    var networkService: Dependency<NetworkServiceType> {
        dependency(NetworkService())
    }
}
```

### Accessing Dependencies

Once you’ve defined a dependency, you can access it anywhere in your app by using the `@AppDependency` property wrapper.

```swift
@AppDependency(\.networkService) var networkService: NetworkServiceType

// Use the injected service
let data = networkService.fetchData()
print(data)  // Prints "Data from network"
```

### Combining State and Dependencies

You can use state and dependencies together to build robust application logic. For example, you can use a dependency like `NetworkService` to fetch data and update the application state.

```swift
@AppState(\.user) var user: User
@AppDependency(\.networkService) var networkService: NetworkServiceType

func loginUser() {
    let data = networkService.fetchData()
    user.name = data
    user.isLoggedIn = true
}
```

## Best Practices

- **Centralize State**: Keep your application-wide state in one place to avoid duplication and ensure consistency.
- **Use Dependencies for Shared Services**: Inject dependencies like network services, databases, or other shared resources to avoid tight coupling between components.
- **Leverage SwiftUI**: Take advantage of `AppState` property wrappers for seamless integration with SwiftUI views and reactive data handling.

## Conclusion

With **AppState**, you can efficiently manage application-wide state and inject shared dependencies across your app. This pattern helps keep your app modular and maintainable. Explore other features of the **AppState** library, such as [SecureState](usage-securestate.md) and [SyncState](usage-syncstate.md), to further enhance your app's state management.
