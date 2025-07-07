# Frequently Asked Questions

This short FAQ addresses common questions developers may have when using **AppState**.

## How do I reset a state value?

For states like `State`, `StoredState`, `FileState`, and `SyncState`, you can reset them to their initial values. The `Application` type provides static `reset` functions for this.

For example, if you have a `State<Int>` defined as `\.counter`:
```swift
extension Application {
    var counter: State<Int> { state(initial: 0) }
}
```

You can reset it like this:
```swift
// Somewhere in your code, typically in a ViewModel or an action handler
Application.reset(state: \.counter)
```
This will reset the counter back to `0`. Similar `reset` functions exist for `StoredState`, `FileState`, `SyncState`, and `SecureState`, prefixed accordingly (e.g., `Application.reset(storedState: \.myStoredValue)`).

Alternatively, you can get the state wrapper object and call `reset()` on it:
```swift
// Get the state wrapper
var counterState = Application.state(\.counter)
// Call reset on the wrapper
counterState.reset()
```
The property wrappers themselves (e.g., `@AppState`) provide direct access to the *value* of the state, not the state management object that has the `reset()` method.

## Can I use AppState with asynchronous tasks?

Yes. `State` and dependency values are thread-safe and work seamlessly with Swift Concurrency. You can access and modify them inside `async` functions without additional locking.

## Where should I define states and dependencies?

Keep all your states and dependencies in `Application` extensions. This ensures a single source of truth and makes it easier to discover all available values.

## Is AppState compatible with Combine?

You can use AppState alongside Combine by bridging `State` changes to publishers. Observe a `State` value and send updates through a `PassthroughSubject` or other Combine publisher if needed.

