# SendableValue Usage

`SendableValue` is a component of the **AppState** library that allows you to work with a thread-safe wrapper around a value that can be shared across different contexts. It ensures safe access and modification of data in concurrent environments.

## Key Features

- **Thread-Safety**: `SendableValue` ensures that access to the encapsulated value is safe even in concurrent environments.
- **Read and Write Access**: You can safely read and write values across multiple tasks or threads without worrying about race conditions.
- **Concurrency Support**: Built to integrate with Swift's concurrency model, `SendableValue` works seamlessly with async/await.

## Example Usage

### Simple Usage of SendableValue

In this example, we use `SendableValue` to create a thread-safe shared value that is safely updated from different contexts.

```swift
import AppState
import SwiftUI

struct SendableValueExampleView: View {
    @State private var sendableValue = SendableValue<Int>(42)
    @State private var result = 0

    var body: some View {
        VStack {
            Text("Current value: \(result)")
            Button("Set to 100") {
                Task {
                    await sendableValue.set(value: 100)
                    result = await sendableValue.value
                }
            }
        }
    }
}
```

### Async Access to SendableValue

In this example, we demonstrate how to access a `SendableValue` asynchronously using Swift's `async/await` model.

```swift
import AppState
import SwiftUI

struct AsyncSendableValueExampleView: View {
    @State private var sendableValue = SendableValue<String>("Initial Value")
    @State private var currentValue = ""

    var body: some View {
        VStack {
            Text("Value: \(currentValue)")
            Button("Update Value") {
                Task {
                    await sendableValue.set(value: "Updated Value")
                    currentValue = await sendableValue.value
                }
            }
        }
    }
}
```

### Thread-Safe Mutation of SendableValue

Here’s an example that shows how `SendableValue` can be safely mutated from different tasks without running into concurrency issues:

```swift
import AppState
import SwiftUI

struct ConcurrentSendableValueExampleView: View {
    @State private var sendableValue = SendableValue<Int>(0)
    @State private var result = 0

    var body: some View {
        VStack {
            Text("Final result: \(result)")
            Button("Run Concurrent Tasks") {
                Task {
                    await withTaskGroup(of: Void.self) { taskGroup in
                        for _ in 1...5 {
                            taskGroup.addTask {
                                let current = await sendableValue.value
                                await sendableValue.set(value: current + 1)
                            }
                        }
                    }
                    result = await sendableValue.value
                }
            }
        }
    }
}
```

## Best Practices

- **Use for Shared Data**: `SendableValue` is ideal when you need to share data between tasks or threads while ensuring thread safety.
- **Leverage Swift Concurrency**: Use `SendableValue` with `async/await` and task groups to avoid race conditions in concurrent programming.

## Conclusion

`SendableValue` provides an easy and efficient way to handle shared data in concurrent programming. By encapsulating the value in a thread-safe wrapper, it eliminates concerns about data races and allows for safe access and modification of the data across multiple tasks.
