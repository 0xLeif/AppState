# ObservedDependency Usage

`ObservedDependency` is a component of the **AppState** library that allows you to use dependencies that conform to `ObservableObject`. This is useful when you want the dependency to notify your SwiftUI views about changes, making your views reactive and dynamic.

## Key Features

- **Observable Dependencies**: Use dependencies that conform to `ObservableObject`, allowing the dependency to automatically update your views when its state changes.
- **Reactive UI Updates**: SwiftUI views automatically update when changes are published by the observed dependency.
- **Thread-Safe**: Like other AppState components, `ObservedDependency` ensures thread-safe access to the observed dependency.

## Example Usage

### Defining an Observable Dependency

Here's how to define an observable service as a dependency in the `Application` extension:

```swift
import AppState
import SwiftUI

@MainActor
class ObservableService: ObservableObject {
    @Published var count: Int = 0
}

extension Application {
    @MainActor
    var observableService: Dependency<ObservableService> {
        dependency(ObservableService())
    }
}
```

### Using the Observed Dependency in a SwiftUI View

In your SwiftUI view, you can access the observable dependency using the `@ObservedDependency` property wrapper. The observed object automatically updates the view whenever its state changes.

```swift
import AppState
import SwiftUI

struct ObservedDependencyExampleView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        VStack {
            Text("Count: \(service.count)")
            Button("Increment Count") {
                service.count += 1
            }
        }
    }
}
```

### Test Case

The following test case demonstrates the interaction with `ObservedDependency`:

```swift
import XCTest
@testable import AppState

@MainActor
fileprivate class ObservableService: ObservableObject {
    @Published var count: Int

    init() {
        count = 0
    }
}

fileprivate extension Application {
    @MainActor
    var observableService: Dependency<ObservableService> {
        dependency(ObservableService())
    }
}

@MainActor
fileprivate struct ExampleDependencyWrapper {
    @ObservedDependency(\.observableService) var service

    func test() {
        service.count += 1
    }
}

final class ObservedDependencyTests: XCTestCase {
    @MainActor
    func testDependency() async {
        let example = ExampleDependencyWrapper()

        XCTAssertEqual(example.service.count, 0)

        example.test()

        XCTAssertEqual(example.service.count, 1)
    }
}
```

### Reactive UI Updates

Since the dependency conforms to `ObservableObject`, any changes to its state will trigger a UI update in the SwiftUI view. You can bind the state directly to UI elements like a `Picker`:

```swift
import AppState
import SwiftUI

struct ReactiveView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        Picker("Select Count", selection: $service.count) {
            ForEach(0..<10) { count in
                Text("\(count)").tag(count)
            }
        }
    }
}
```

## Best Practices

- **Use for Observable Services**: `ObservedDependency` is ideal when your dependency needs to notify views of changes, especially for services that provide data or state updates.
- **Leverage Published Properties**: Ensure your dependency uses `@Published` properties to trigger updates in your SwiftUI views.
- **Thread-Safe**: Like other AppState components, `ObservedDependency` ensures thread-safe access and modifications to the observable service.

## Conclusion

`ObservedDependency` is a powerful tool for managing observable dependencies within your app. By leveraging Swift's `ObservableObject` protocol, it ensures that your SwiftUI views remain reactive and up-to-date with changes in the service or resource.
