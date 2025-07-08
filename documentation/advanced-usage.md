
# Advanced Usage of AppState

This guide covers advanced topics for using **AppState**, including Just-In-Time creation, preloading dependencies, managing state and dependencies effectively, and comparing **AppState** with **SwiftUI's Environment**.

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

While this approach is valid for sharing state and dependencies across the application by reusing the same string `id`, it is generally discouraged. It relies on manually managing these string IDs, which can lead to:
- Accidental ID collisions if the same ID is used for different intended states/dependencies.
- Difficulty in tracking where a state/dependency is defined versus accessed.
- Reduced code clarity and maintainability.
The `initial` value provided in subsequent definitions with the same ID will be ignored if the state/dependency has already been initialized by its first access. This behavior is more of a side effect of how the ID-based caching works in AppState, rather than a recommended primary pattern for defining shared data. Prefer defining states and dependencies as unique computed properties in `Application` extensions (which automatically generate unique internal IDs if no explicit `id` is provided to the factory method).

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

## 4. AppState vs SwiftUI's Environment

AppState and SwiftUI's Environment both offer ways to manage shared state and dependencies in your application, but they differ in scope, functionality, and use cases.

### 4.1 SwiftUI's Environment

SwiftUI’s Environment is a built-in mechanism that allows you to pass shared data down through a view hierarchy. It’s ideal for passing data that many views need access to, but it has limitations when it comes to more complex state management.

**Strengths:**
- Simple to use and well integrated with SwiftUI.
- Ideal for lightweight data that needs to be shared across multiple views in a hierarchy.

**Limitations:**
- Data is only available within the specific view hierarchy. Accessing the same data across different view hierarchies is not possible without additional work.
- Less control over thread safety and persistence compared to AppState.
- Lack of built-in persistence or synchronization mechanisms.

### 4.2 AppState

AppState provides a more powerful and flexible system for managing state across the entire application, with thread safety, persistence, and dependency injection capabilities.

**Strengths:**
- Centralized state management, accessible across the entire app, not just in specific view hierarchies.
- Built-in persistence mechanisms (`StoredState`, `FileState`, and `SyncState`).
- Type safety and thread safety guarantees, ensuring that state is accessed and modified correctly.
- Can handle more complex state and dependency management.

**Limitations:**
- Requires more setup and configuration compared to SwiftUI's Environment.
- Somewhat less integrated with SwiftUI compared to Environment, though still works well in SwiftUI apps.

### 4.3 When to Use Each

- Use **SwiftUI's Environment** when you have simple data that needs to be shared across a view hierarchy, like user settings or theming preferences.
- Use **AppState** when you need centralized state management, persistence, or more complex state that needs to be accessed across the entire app.

## Conclusion

By using these advanced techniques, such as just-in-time creation, preloading, state and dependency management, and understanding the differences between AppState and SwiftUI's Environment, you can build efficient and resource-conscious applications with **AppState**.
