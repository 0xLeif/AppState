# Constant Usage

`Constant` in the **AppState** library provides read-only access to values within your application's state. It works similarly to `Slice`, but ensures that the accessed values are immutable. This makes `Constant` ideal for accessing values that may otherwise be mutable but should remain read-only in certain contexts.

## Key Features

- **Read-Only Access**: Constants provide access to mutable state, but the values cannot be modified.
- **Scoped to Application**: Like `Slice`, `Constant` is defined within the `Application` extension and scoped to access specific parts of the state.
- **Thread-Safe**: `Constant` ensures safe access to state in concurrent environments.

## Example Usage

### Defining a Constant in Application

Here’s how you define a `Constant` in the `Application` extension to access a read-only value:

```swift
import AppState
import SwiftUI

struct ExampleValue {
    var username: String?
    var isLoading: Bool
    let value: String
    var mutableValue: String
}

extension Application {
    var exampleValue: State<ExampleValue> {
        state(
            initial: ExampleValue(
                username: "Leif",
                isLoading: false,
                value: "value",
                mutableValue: ""
            )
        )
    }
}
```

### Accessing the Constant in a SwiftUI View

In a SwiftUI view, you can use the `@Constant` property wrapper to access the constant state in a read-only manner:

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.exampleValue, \.value) var constantValue: String

    var body: some View {
        Text("Constant Value: \(constantValue)")
    }
}
```

### Read-Only Access to Mutable State

Even if the value is mutable elsewhere, when accessed through `@Constant`, the value becomes immutable:

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.exampleValue, \.mutableValue) var constantMutableValue: String

    var body: some View {
        Text("Read-Only Mutable Value: \(constantMutableValue)")
    }
}
```

## Best Practices

- **Use for Read-Only Access**: Use `Constant` to access parts of the state that should not be modified within certain contexts, even if they are mutable elsewhere.
- **Thread-Safe**: Like other AppState components, `Constant` ensures thread-safe access to state.
- **Use `OptionalConstant` for Optional Values**: If the part of the state you're accessing may be `nil`, use `OptionalConstant` to safely handle the absence of a value.

## Conclusion

`Constant` and `OptionalConstant` provide an efficient way to access specific parts of your app's state in a read-only manner. They ensure that values which may otherwise be mutable are treated as immutable when accessed within a view, ensuring safety and clarity in your code.
