# FileState Usage

`FileState` is a component of the **AppState** library that allows you to store and retrieve persistent data using the file system. It is useful for storing large data or complex objects that need to be saved between app launches and restored when needed.

## Key Features

- **Persistent Storage**: Data stored using `FileState` persists across app launches.
- **Large Data Handling**: Unlike `StoredState`, `FileState` is ideal for handling larger or more complex data.
- **Thread-Safe**: Like other AppState components, `FileState` ensures safe access to the data in concurrent environments.

## Example Usage

### Storing and Retrieving Data with FileState

Here's how to define a `FileState` in the `Application` extension to store and retrieve a large object:

```swift
import AppState
import SwiftUI

struct UserProfile: Codable {
    var name: String
    var age: Int
}

extension Application {
    var userProfile: FileState<UserProfile> {
        fileState(id: "userProfile", initial: UserProfile(name: "Guest", age: 25))
    }
}

struct FileStateExampleView: View {
    @FileState(\.userProfile) var userProfile: UserProfile

    var body: some View {
        VStack {
            Text("Name: \(userProfile.name), Age: \(userProfile.age)")
            Button("Update Profile") {
                userProfile = UserProfile(name: "UpdatedName", age: 30)
            }
        }
    }
}
```

### Handling Large Data with FileState

When you need to handle larger datasets or objects, `FileState` ensures the data is stored efficiently in the app's file system. This is useful for scenarios like caching or offline storage.

```swift
import AppState
import SwiftUI

extension Application {
    var largeDataset: FileState<[String]> {
        fileState(id: "largeDataset", initial: [])
    }
}

struct LargeDataView: View {
    @FileState(\.largeDataset) var largeDataset: [String]

    var body: some View {
        List(largeDataset, id: \.self) { item in
            Text(item)
        }
    }
}
```

### Migration Considerations

When updating your data model, it's important to account for potential migration challenges, especially when working with persisted data using **StoredState**, **FileState**, or **SyncState**. Without proper migration handling, changes like adding new fields or modifying data formats can cause issues when older data is loaded.

Here are some key points to keep in mind:
- **Adding New Non-Optional Fields**: Ensure new fields are either optional or have default values to maintain backward compatibility.
- **Handling Data Format Changes**: If the structure of your model changes, implement custom decoding logic to support old formats.
- **Versioning Your Models**: Use a `version` field in your models to help with migrations and apply logic based on the data’s version.

To learn more about how to manage migrations and avoid potential issues, refer to the [Migration Considerations Guide](migration-considerations.md).


## Best Practices

- **Use for Large or Complex Data**: If you're storing large data or complex objects, `FileState` is ideal over `StoredState`.
- **Thread-Safe Access**: Like other components of **AppState**, `FileState` ensures data is accessed safely even when multiple tasks interact with the stored data.
- **Combine with Codable**: When working with custom data types, ensure they conform to `Codable` to simplify encoding and decoding to and from the file system.

## Conclusion

`FileState` is a powerful tool for handling persistent data in your app, allowing you to store and retrieve larger or more complex objects in a thread-safe and persistent manner. It works seamlessly with Swift’s `Codable` protocol, ensuring your data can be easily serialized and deserialized for long-term storage.
