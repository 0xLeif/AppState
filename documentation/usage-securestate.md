# SecureState Usage

`SecureState` is a component of the **AppState** library that allows you to store sensitive data securely in the Keychain. It's best suited for storing small pieces of data like tokens or passwords that need to be securely encrypted.

## Key Features

- **Secure Storage**: Data stored using `SecureState` is encrypted and securely saved in the Keychain.
- **Persistence**: The data remains persistent across app launches, allowing secure retrieval of sensitive values.

## Keychain Limitations

While `SecureState` is very secure, it has certain limitations:

- **Limited Storage Size**: Keychain is designed for small pieces of data. It is not suitable for storing large files or datasets.
- **Performance**: Accessing the Keychain is slower than accessing `UserDefaults`, so use it only when necessary to securely store sensitive data.

## Example Usage

### Storing a Secure Token

```swift
import AppState
import SwiftUI

extension Application {
    var userToken: SecureState {
        secureState(id: "userToken")
    }
}

struct SecureView: View {
    @SecureState(\.userToken) var userToken: String?

    var body: some View {
        VStack {
            if let token = userToken {
                Text("User token: \(token)")
            } else {
                Text("No token found.")
            }
            Button("Set Token") {
                userToken = "secure_token_value"
            }
        }
    }
}
```

### Handling Absence of Secure Data

When accessing the Keychain for the first time, or if there’s no value stored, `SecureState` will return `nil`. Ensure you handle this scenario properly:

```swift
if let token = userToken {
    print("Token: \(token)")
} else {
    print("No token available.")
}
```

## Best Practices

- **Use for Small Data**: Keychain should be used for storing small pieces of sensitive information like tokens, passwords, and keys.
- **Avoid Large Datasets**: If you need to store large datasets securely, consider using file-based encryption or other methods, as Keychain is not designed for large data storage.
- **Handle nil**: Always handle cases where the Keychain returns `nil` when no value is present.
