# SecureState Usage

`SecureState` is a component of the **AppState** library that securely stores sensitive data using the Keychain. It ensures that important data, such as tokens or passwords, is protected on the device.

## Overview

`SecureState` is ideal for securely storing information that should not be exposed or stored in plain text. The data is stored in the Keychain and retrieved securely when needed.

### Key Features

- **Keychain Storage**: Data is stored securely in the device’s Keychain, offering protection for sensitive values.
- **Persistent Storage**: Values stored using `SecureState` persist even if the app is terminated or restarted.
- **Automatic Encryption**: The Keychain automatically encrypts the data, ensuring that it is only accessible by authorized apps on the device.

## Example Usage

### Creating a SecureState

You can create a `SecureState` by defining a secure key and setting an initial value for sensitive data.

```swift
import AppState

extension Application {
    var userToken: SecureState {
        secureState(id: "userToken")
    }
}

@SecureState(\.userToken) var userToken: String?
```

### Storing a Value

You can assign a value to `SecureState` just like any other state, but the value will be securely stored in the Keychain.

```swift
userToken = "my_secret_token"
```

### Accessing a Value

You can retrieve the value of a `SecureState` at any time. The value is decrypted and loaded from the Keychain when accessed.

```swift
if let token = userToken {
    print("User token: \(token)")
} else {
    print("No token found.")
}
```

### Handling Absence of Values

If a value doesn’t exist in the Keychain, the `SecureState` will return `nil`. This is useful for handling scenarios where sensitive data may not have been stored yet.

```swift
if userToken == nil {
    print("Token not set.")
}
```

## Best Practices

- **Use for Sensitive Data**: Utilize `SecureState` for any sensitive information that should not be stored in plain text or exposed through standard storage methods like `UserDefaults`.
- **Handle Absence Safely**: Ensure your app handles cases where a `SecureState` value is `nil`, particularly when checking for authentication tokens or passwords.
- **Avoid Storing Large Data**: The Keychain is best suited for storing small, sensitive values. Avoid using it for large datasets.

## Conclusion

`SecureState` provides a secure and convenient way to manage sensitive data in your Swift applications using the device’s Keychain. By leveraging `SecureState`, you ensure that critical information, such as user tokens or passwords, is stored and retrieved securely. Explore other components of the **AppState** library, such as [SyncState](usage-syncstate.md) and [StoredState](usage-state-dependency.md), to manage application-wide data securely and effectively.
