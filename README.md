# AppState

AppState is a Swift Package that simplifies the management of application state in a thread-safe, type-safe, and SwiftUI-friendly way. Featuring dedicated struct types for managing state, AppState provides easy and coordinated access to this state across your application. Added to this, the package incorporates built-in logging mechanisms to aid debugging and error tracking. The AppState package also boasts a cache-based system to persistently store and retrieve any application-wide data at any given time.

## Key Features

- **Application:** Centralized class housing all application-wide data, equipped with built-in observability for reactive changes.

- **State:** Dedicated struct type for encapsulating and broadcasting value changes within the app's scope.

- **Dependency:** Dedicated struct type for encapsulating dependencies within the app's scope.

- **Scope:** Representation of a specific context within an app, defined by a unique name and ID.

- **AppState (property wrapper):** A property wrapper that elegantly bridges `Application.State` with `SwiftUI` for seamless integration.

- **AppDependency (property wrapper):** A property wrapper that simplifies the handling of dependencies throughout your application.

### Requirements

- Swift 5.7 or later

- iOS 16.0 or later
- watchOS 9.0 or later
- macOS 13.0 or later
- tvOS 16.0 or later

## Getting Started

To add `AppState` to your Swift project, use the Swift Package Manager. This involves adding a package dependency to your `Package.swift` file.

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/AppState.git", from: "0.2.0")
]
```

For App projects, open your project in Xcode and navigate to File > Swift Packages > Add Package Dependency... and enter `https://github.com/0xLeif/AppState.git`.

## Usage

AppState is designed to uphold application state management ease and intuitiveness. Here's how to use it:

### Define Application State

Defining an application-wide state requires extending the `Application` and declaring the variables that retain the state. Each state corresponds to an instance of the generic `Application.State` struct:

```swift
extension Application {
    var isLoading: State<Bool> {
        state(initial: false)
    }

    var username: State<String> {
        state(initial: "Leif")
    }

    var colors: State<[String: CGColor]> {
        state(initial: ["primary": CGColor(red: 1, green: 0, blue: 1, alpha: 1)])
    }
}
```

### Read and Write Application States

Once you define the state, it is straightforward to read and write it within your application:

```swift
var appState: Application.State = Application.state(\.username)

// Read the value
print(appState.value) // Output: "Leif"

// Modify the value
appState.value = "0xL"

print(Application.state(\.username).value) // Output: "0xL"
```

### Using the AppState Property Wrapper

The `AppState` property wrapper can directly bridge State of an `Application` to SwiftUI:

```swift
struct ContentView: View {
    @AppState(\.username) var username

    var body: some View {
        Button(
            action: { username = "Hello!" }.
            label: { Text("Hello, \(username)!") }
        )
    }
}
```

You can also use `AppState` in a SwiftUI `ObservableObject`:

```swift
class UserSettings: ObservableObject {
    @AppState(\.username) var username

    func updateUsername(newUsername: String) {
        username = newUsername
    }
}

struct ContentView: View {
    @ObservedObject private var settings = UserSettings()

    var body: some View {
        VStack {
            Text("User name: \(settings.username)")
            Button("Update Username") {
                settings.updateUsername(newUsername: "NewUserName")
            }
        }
    }
}
```

### Defining Dependencies

`Dependency` is a feature provided by AppState, allowing you to define shared resources or services in your application.

To define a dependency, you should extend the `Application` object. Here's an example of defining a `networkService` dependency:

```swift
extension Application {
    var networkService: Dependency<NetworkServiceType> {
        dependency(NetworkService())
    }
}
```

In this example, `Dependency<NetworkServiceType>` represents a type safe container for `NetworkService`.

### Reading and Using Dependencies

Once you've defined a dependency, you can access it anywhere in your app:

```swift
let networkService = Application.dependency(\.networkService)
```

This approach allows you to work with dependencies in a type-safe manner, avoiding the need to manually handle errors related to incorrect types.

### AppDependency Property Wrapper

AppState provides the `@AppDependency` property wrapper that simplifies access to dependencies. When you annotate a property with `@AppDependency`, it fetches the appropriate dependency from the `Application` object directly.

```swift
struct ContentView: View {
    @AppDependency(\.networkService) var networkService

    // Your view code
}
```

In this case, ContentView has access to the networkService dependency and can use it within its code.

### Using Dependency with ObservableObject

When your dependency is an `ObservableObject`, any changes to it will automatically update your SwiftUI views. Make sure your service conforms to the `ObservableObject` protocol. To do this, you should not use the `@AppDependency` property wrapper, but instead use the `@ObservedObject` property wrapper. 

Here's an example:

```swift
class DataService: ObservableObject {
    @AppState(\.someData) var data: [String]
}

extension Application {
    var dataService: Dependency<DataService> {
        dependency(DataService())
    }
}

struct ContentView: View {
    @ObservedObject var dataService = Application.dependency(\.dataService)

    var body: some View {
        List(dataService.data, id: \.self) { item in
            Text(item)
        }
        .onAppear {
            dataService.fetchData()
        }
    }
}
```

In this example, whenever data in `DataService` changes, SwiftUI automatically updates the `ContentView`.

### Testing with Mock Dependencies

One of the great advantages of using `Dependency` in AppState is the capability to replace dependencies with mock versions during testing. This is incredibly useful for isolating parts of your application for unit testing. 

You can replace a dependency by calling the `override(_:_:)` function. This function returns a `DependencyOverrideToken`, you'll want to hold onto this token for as long as you want the mock dependency to be effective. When the token is deallocated, the dependency reverts back to its original condition.

Here's an example:

```swift
// Real network service
extension Application {
    var networkService: Dependency<NetworkServiceType> {
        dependency(initial: NetworkService())
    }
}

// Mock network service
class MockNetworkService: NetworkServiceType {
    // Your mock implementation
}

func testNetworkService() {
    // Keep hold of the `DependencyOverride` for the duration of your test.
    let networkOverride = Application.override(\.networkService, with: MockNetworkService())

    let mockNetworkService = Application.dependency(\.networkService)
    
    // Once done, you can allow the `tokDependencyOverrideen` to be deallocated 
    // or call `override.cancel()` to revert back to the original service.
}
```

## License

AppState is released under the MIT License. See [LICENSE](https://github.com/0xLeif/AppState/blob/main/LICENSE) for more information.

## Communication and Contribution

- If you found a bug, open an issue.
- If you have a feature request, open an issue.
- If you want to contribute, submit a pull request.

***

This README is a work in progress. If you found any inaccuracies or areas that require clarification, please don't hesitate to create a pull request with improvements!
