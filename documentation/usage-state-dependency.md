# State and Dependency Usage

**AppState** provides powerful tools for managing application-wide state and injecting dependencies into SwiftUI views. By centralizing your state and dependencies, you can ensure your application remains consistent and maintainable.

## Overview

- **State**: Represents a value that can be shared across the app. State values can be modified and observed within your SwiftUI views.
- **Dependency**: Represents a shared resource or service that can be injected and accessed within SwiftUI views.

### Key Features

- **Centralized State**: Define and manage application-wide state in one place.
- **Dependency Injection**: Inject and access shared services and resources across different components of your application.

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

### Accessing and Modifying State in a View

You can access and modify state values directly within a SwiftUI view using the `@AppState` property wrapper.

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("Hello, \(user.name)!")
            Button("Log in") {
                user.name = "John Doe"
                user.isLoggedIn = true
            }
        }
    }
}
```

### Defining Dependencies

You can define shared resources, such as a network service, as dependencies in the `Application` object. These dependencies can be injected into SwiftUI views.

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

### Accessing Dependencies in a View

Access dependencies within a SwiftUI view using the `@AppDependency` property wrapper. This allows you to inject services like a network service into your view.

```swift
import AppState
import SwiftUI

struct NetworkView: View {
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("Data: \(networkService.fetchData())")
        }
    }
}
```

### Combining State and Dependencies in a View

State and dependencies can work together to build more complex application logic. For example, you can fetch data from a service and update the state:

```swift
import AppState
import SwiftUI

struct CombinedView: View {
    @AppState(\.user) var user: User
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("User: \(user.name)")
            Button("Fetch Data") {
                user.name = networkService.fetchData()
                user.isLoggedIn = true
            }
        }
    }
}
```

### Best Practices

- **Centralize State**: Keep your application-wide state in one place to avoid duplication and ensure consistency.
- **Use Dependencies for Shared Services**: Inject dependencies like network services, databases, or other shared resources to avoid tight coupling between components.

## Conclusion

With **AppState**, you can manage application-wide state and inject shared dependencies directly into your SwiftUI views. This pattern helps keep your app modular and maintainable. Explore other features of the **AppState** library, such as [SecureState](usage-securestate.md) and [SyncState](usage-syncstate.md), to further enhance your app's state management.
