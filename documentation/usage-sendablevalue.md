# SendableValue Usage

`SendableValue` is a component of the **AppState** library that allows for safe, thread-managed value storage. It ensures that values can be accessed and modified safely across different threads by using Swift's `Sendable` protocol.

## Overview

`SendableValue` is designed to handle concurrency in Swift by ensuring that any data it manages can be safely accessed by multiple tasks running concurrently. This makes it useful in scenarios where shared mutable state needs to be updated in a thread-safe manner.

### Key Features

- **Thread Safety**: Guarantees that the value can be accessed or modified across multiple threads safely.
- **Concurrency Support**: Ensures that values conform to the `Sendable` protocol for safe concurrent use.
- **Simplicity**: A simple API for getting and setting values asynchronously.

## Example Usage

### Creating a SendableValue

You can create a `SendableValue` by initializing it with a value that conforms to the `Sendable` protocol.

```swift
import AppState

let sendableValue = SendableValue<Int>(42)
```

### Accessing and Modifying the Value

You can set a new value asynchronously using the `set` method and access the value using the `value` property.

```swift
sendableValue.set(value: 100)

let value = sendableValue.value
print(value)  // Prints "100"
```

### Accessing the Value Asynchronously

To safely access the value from concurrent tasks, you can await the `value`.

```swift
Task {
    let currentValue = await sendableValue.value
    print(currentValue)  // Prints "100"
}
```

### Thread Safety in Action

`SendableValue` ensures that even in multi-threaded environments, values are protected from race conditions. This is especially useful when handling shared state in asynchronous tasks.

```swift
Task {
    sendableValue.set(value: 200)
}

Task {
    let currentValue = await sendableValue.value
    print(currentValue)  // Prints "200"
}
```

## Best Practices

- **Use for Shared State**: Use `SendableValue` when you need to share and modify a value across multiple tasks or threads.
- **Thread-Safe Access**: Always rely on `SendableValue` to handle thread-safe reads and writes when accessing shared mutable state.

## Conclusion

`SendableValue` provides a simple and safe mechanism for managing shared state across multiple threads in a Swift application. By utilizing this structure, you can ensure that your values are protected and safely accessed in concurrent programming environments. Explore other components of the **AppState** library, such as [State and Dependency Management](usage-state-dependency.md) and [SecureState](usage-securestate.md), to learn more about managing data safely in Swift applications.
