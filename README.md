# AppState

AppState is a Swift Package that simplifies the management of application state in a thread-safe, type-safe, and SwiftUI-friendly way. Featuring dedicated struct types for managing state, AppState provides easy and coordinated access to this state across your application. Added to this, the package incorporates built-in logging mechanisms to aid debugging and error tracking. The AppState package also boasts a cache-based system to persistently store and retrieve any application-wide data at any given time.

**Requirements:** iOS 15.0+ / watchOS 8.0+ / macOS 11.0+ / tvOS 15.0+ / visionOS 1.0+ | Swift 5.9+ / Xcode 15+

**Non Apple Platform Support:** Linux & Windows

## Key Features

(🍎 Apple OS only)

### State Management

- **Application:** Centralized class for all application-wide data with built-in observability for reactive changes.
- **State:** Struct for encapsulating and broadcasting value changes.
- **StoredState:** Struct for encapsulating and broadcasting stored value changes, using `UserDefaults`.
- 🍎 **SyncState:** Struct for encapsulating and broadcasting stored value changes, using `iCloud`.
- 🍎 **SecureState:** Struct for securely encapsulating and broadcasting stored value changes, using the device's Keychain.

### Fine-Grained Control

- **Slice:** Struct that provides access to and modification of specific AppState's state parts.
- **OptionalSlice:** Struct that provides access to and modification of specific AppState's state parts. Useful if the state value is optional.

### Dependency Management

- **Dependency:** Struct for encapsulating dependencies within the app's scope.
- **Scope:** Represents a specific context within an app, defined by a unique name and ID.

### Property Wrappers

- **AppState:** Bridges `Application.State` with `SwiftUI`.
- **StoredState:** Stores its values to `UserDefaults`.
- 🍎 **SyncState:** Stores its values to `iCloud`.
- **Slice:** Allows users to access and modify specific AppState's state parts.
- **OptionalSlice:** Allows users to access and modify specific AppState's state parts. Useful if the state value is optional.
- **Constant:** Allows users to access a specific part of AppState's state.
- **OptionalConstant:** Allows users to access a specific part of AppState's state. Useful if the state value is optional.
- 🍎 **SecureState:** Securely stores its string values using the Keychain.
- **AppDependency:** Simplifies the handling of dependencies throughout your application.
- 🍎 **ObservedDependency:** Simplifies the handling of dependencies throughout your application. Backed by an `@ObservedObject` to publish changes to SwiftUI views.

## Getting Started

To integrate AppState into your Swift project, you'll need to use the Swift Package Manager (SPM). SPM makes it easy to manage Swift package dependencies. Here's what you need to do:

1. Add a package dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/AppState.git", from: "1.0.0")
]
```

If you're working with an App project, open your project in Xcode. Navigate to `File > Swift Packages > Add Package Dependency...` and enter `https://github.com/0xLeif/AppState.git`.

2. Next, don't forget to add AppState as a target to your project. This step is necessary for both Xcode and SPM Package.swift.

After successfully adding AppState as a dependency, you need to import AppState into your Swift file where you want to use it. Here's a code example:

```swift
import AppState
```

## Usage

<details close>
  <summary>Dependency Injection</summary>

```swift
import AppState

extension Application {
    var networkService: Dependency<NetworkServiceType> {
        dependency(NetworkService())
    }
}

struct ContentView: View {
    @AppDependency(\.networkService) var networkService

    // Your view code
}
```

</details>

<details close>
  <summary>Keychain Storage</summary>

```swift
import AppState

extension Application {
    var userToken: SecureState {
        secureState(id: "userToken")
    }
}

@SecureState(\.userToken) var userToken: String?
```

</details>

<details close>
  <summary>iCloud Synced State</summary>

```swift
import AppState

extension Application {
    var isDarkModeEnabled: SyncState<Bool> {
        syceState(inital: false, id: "isDarkModeEnabled")
    }
}

@SyncState(\.isDarkModeEnabled) var isDarkModeEnabled: Bool
```

</details>


<details close>
  <summary>Slicing</summary>

```swift
import AppState

struct Preferences: Codable {
    var isDarkModeEnabled: Bool
}

struct User {
    let id: UUID
    var username: String
    var metadata: [String: Any]
}

extension Application {
    // We can use iCloud to sync the preferences across the user's devices
    var preferences: SyncState<Preferences> {
        syncState(
            initial: Preferences(
                isDarkModeEnabled: false
            ),
            id: "preferences"
        )
    }

    // We can have an optional user state to signify if the user is logged in or not.
    var user: State<User?> {
        state(initial: nil)
    }

    var dictionary: State<[String: String]> {
        state(initial: [:])
    }
}

class ViewModel: ObservableObject {
    // State that isn't optional can use `Slice` and `Constant`. `Slice` values are mutable.
    @Slice(\.preferences, \.isDarkModeEnabled) var isDarkModeEnabled: Bool

    // If the state is optional though, you must use the `OptionalSlice` or `OptionalConstant`.
    // These values might be optional because of the root state, or the value might be optional too.
    // If the root state is `nil` you can't update the values.
    @OptionalConstant(\.user, \.id) var id: UUID?
    @OptionalSlice(\.user, \.username) var username: String?

    // You can slice into a Dictionary for a specific entry.
    @OptionalSlice(\.user, \.metadata["lastLogin"]) var lastLogin: Any?
    @Slice(\.dictionary, \.["error"]) var error: String?
}
```

</details>


## Documentation

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
var usernameState: Application.State = Application.state(\.username)

// Read the value
print(usernameState.value) // Output: "Leif"

// Modify the value
usernameState.value = "0xL"

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

When your dependency is an `ObservableObject`, any changes to it will automatically update your SwiftUI views. Make sure your service conforms to the `ObservableObject` protocol. To do this, you should not use the `@AppDependency` property wrapper, but instead use the `@ObservedDependency` property wrapper. 

Here's an example:

```swift
class DataService: ObservableObject {
    @Published var data: [String]

    func fetchData() { ... }
}

extension Application {
    var dataService: Dependency<DataService> {
        dependency(DataService())
    }
}

struct ContentView: View {
    @ObservedDependency(\.dataService) private var dataService

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

You can replace a dependency by calling the `Application.override` function. This function returns a `DependencyOverride`, you'll want to hold onto this token for as long as you want the mock dependency to be effective. When the token is deallocated, the dependency reverts back to its original condition.

Here's an example:

```swift
// Real network service
extension Application {
    var networkService: Dependency<NetworkServiceType> {
        dependency(NetworkService())
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
    
    // Once done, you can allow the `DependencyOverrideen` to be deallocated 
    // or call `networkOverride.cancel()` to revert back to the original service.
}
```

## Promoting the Application

In AppState, you have the ability to promote your custom Application subclass to a shared singleton instance. This can be particularly useful when your Application subclass needs to conform to a protocol.

Here's an example of how to use the `promote` function:

```swift
class CustomApplication: Application {
    func customFunction() { ... }
}

Application.promote(to: CustomApplication.self)
```

## SyncState: Near Real-Time State Synchronization

SyncState offers near real-time synchronization of application state across multiple devices using Apple's [NSUbiquitousKeyValueStore](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore). This allows for a consistent application state across various devices in your ecosystem. If your application operates on multiple platforms, SyncState ensures that all instances share the same state in near real-time.

NSUbiquitousKeyValueStore provides a lightweight, quick setup solution to store small amounts of data that are available ubiquitously across a user's multiple devices. The data is stored in iCloud and automatically syncs to all devices signed in to the same iCloud account, making it an ideal solution for synchronizing application state.

For more information on synchronizing app preferences with iCloud, you can refer to [Apple's official documentation](https://developer.apple.com/documentation/foundation/icloud/synchronizing_app_preferences_with_icloud).

By doing this, your custom Application subclass becomes the shared singleton instance that you can use throughout your application. This allows you to extend the functionalities of the Application class and utilize these extensions wherever you need in your application.

## License

AppState is released under the MIT License. See [LICENSE](https://github.com/0xLeif/AppState/blob/main/LICENSE) for more information.

## Communication and Contribution

- If you found a bug, open an issue.
- If you have a feature request, open an issue.
- If you want to contribute, submit a pull request.
