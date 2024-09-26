# Constant Usage

`Constant` is a component of the **AppState** library that allows you to define and access fixed values that should not change over time. Constants are ideal for representing static information or configuration values that remain the same throughout the lifecycle of the app.

## Key Features

- **Immutable Values**: Constants provide immutable values that cannot be modified once set.
- **Scoped to Application**: Just like `State`, `Constant` is defined within the `Application` extension, making it easily accessible across the app.
- **Thread-Safe**: Even though constants are immutable, `Constant` ensures safe access in concurrent environments.

## Example Usage

### Defining Constants in Application

Here's how you define constants within the `Application` extension:

```swift
import AppState
import SwiftUI

extension Application {
    var appVersion: Constant<String> {
        constant("1.0.0")
    }
}

struct ConstantExampleView: View {
    @Constant(\.appVersion) var appVersion: String

    var body: some View {
        VStack {
            Text("App Version: \(appVersion)")
        }
    }
}
```

### Using Optional Constants

You can also define optional constants if the value might not always be present:

```swift
import AppState
import SwiftUI

extension Application {
    var supportEmail: OptionalConstant<String> {
        optionalConstant(nil)
    }
}

struct OptionalConstantExampleView: View {
    @OptionalConstant(\.supportEmail) var supportEmail: String?

    var body: some View {
        VStack {
            if let email = supportEmail {
                Text("Support Email: \(email)")
            } else {
                Text("Support email not available")
            }
        }
    }
}
```

## Best Practices

- **Use for Static Data**: `Constant` is perfect for storing static data like version numbers, configuration values, or any data that should not change.
- **Use `OptionalConstant` for Flexible Scenarios**: If there is a chance that the constant value may be absent, use `OptionalConstant` to safely handle `nil` values.
- **Thread Safety**: Even though constants are immutable, `Constant` provides thread-safe access in case multiple tasks read the value concurrently.

## Conclusion

`Constant` and `OptionalConstant` are valuable tools for managing fixed or immutable data within your app. They ensure that static values remain easily accessible throughout the application, while ensuring thread-safe access to the data.
