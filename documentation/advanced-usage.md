# Advanced Usage of AppState

This guide covers advanced topics for using **AppState**, including Just-In-Time creation and preloading dependencies.

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

## 3. Use Cases for Just-In-Time Creation and Preloading

- **Large or Complex Applications**: For applications with a large number of states and dependencies, just-in-time creation helps manage resource usage by only initializing values when needed.
- **Critical Dependencies**: Preload critical dependencies, such as network clients or databases, that must be available when the app starts.

## Conclusion

These advanced techniques help you optimize performance and ensure key dependencies are ready when needed. By leveraging just-in-time creation and preloading, you can build efficient, resource-conscious applications with **AppState**.
