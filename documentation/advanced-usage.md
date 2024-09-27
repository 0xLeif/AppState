# Advanced Usage of AppState

This guide covers advanced topics for using **AppState**, including Just-In-Time creation, preloading dependencies, and managing state and dependencies effectively.

## 1. Just-In-Time Creation

AppState values, such as `State`, `Dependency`, `StoredState`, and `SyncState`, are created just-in-time. This means they are instantiated only when first accessed, improving the efficiency and performance of your application.

### Example

```swift
extension Application {
    var defaultState: State<Int> {
        state(initial: 0) // The value is not created until it's accessed
    }
}
```

In this example, `defaultState` is not created until it is accessed for the first time, optimizing resource usage.

## 2. Preloading Dependencies

In some cases, you may want to preload certain dependencies to ensure they are available when your application starts. AppState provides a `load` function that preloads dependencies.

### Example

```swift
extension Application {
    var databaseClient: Dependency<DatabaseClient> {
        dependency(DatabaseClient())
    }
}

// Preload in app initialization
Application.load(dependency: \.databaseClient)
```

In this example, `databaseClient` is preloaded during the app's initialization, ensuring that it is available when needed in your views.

## 3. State and Dependency Management

### 3.1 Shared State and Dependencies Across the Application

You can define shared state or dependencies in one part of your app and access them in another part using unique IDs.

### Example

```swift
private extension Application {
    var stateValue: State<Int> {
        state(initial: 0, id: "stateValue")
    }

    var dependencyValue: Dependency<SomeType> {
        dependency(SomeType(), id: "dependencyValue")
    }
}
```

This allows you to access the same `State` or `Dependency` elsewhere by using the same ID.

```swift
private extension Application {
    var theSameStateValue: State<Int> {
        state(initial: 0, id: "stateValue")
    }

    var theSameDependencyValue: Dependency<SomeType> {
        dependency(SomeType(), id: "dependencyValue")
    }
}
```

### 3.2 Restricted State and Dependency Access

To restrict access, use a unique ID like a UUID to ensure that only the right parts of the app can access specific states or dependencies.

### Example

```swift
private extension Application {
    var restrictedState: State<Int?> {
        state(initial: nil, id: UUID().uuidString)
    }

    var restrictedDependency: Dependency<SomeType> {
        dependency(SomeType(), id: UUID().uuidString)
    }
}
```

### 3.3 Unique IDs for States and Dependencies

When no ID is provided, AppState generates a default ID based on the location in the source code. This ensures that each `State` or `Dependency` is unique and protected from unintended access.

### Example

```swift
extension Application {
    var defaultState: State<Int> {
        state(initial: 0) // AppState generates a unique ID
    }

    var defaultDependency: Dependency<SomeType> {
        dependency(SomeType()) // AppState generates a unique ID
    }
}
```

### 3.4 File-Private State and Dependency Access

For even more restricted access within the same Swift file, use the `fileprivate` access level to protect states and dependencies from being accessed externally.

### Example

```swift
fileprivate extension Application {
    var fileprivateState: State<Int> {
        state(initial: 0)
    }

    var fileprivateDependency: Dependency<SomeType> {
        dependency(SomeType())
    }
}
```

### 3.5 Understanding AppState's Storage Mechanism

AppState uses a unified cache to store `State`, `Dependency`, `StoredState`, and `SyncState`. This ensures that these data types are efficiently managed across your app.

By default, AppState assigns a name value as "App", which ensures that all values associated with a module are tied to that name. This makes it harder to access these states and dependencies from other modules.

## Conclusion

By using these advanced techniques, such as just-in-time creation, preloading, and understanding how to manage state and dependencies, you can build efficient and resource-conscious applications with **AppState**.
