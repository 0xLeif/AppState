# Frequently Asked Questions

This short FAQ addresses common questions developers may have when using **AppState**.

## How do I reset a state value?

For persistent states like `StoredState`, `FileState`, and `SyncState`, you can reset them to their initial values using the static `reset` functions on the `Application` type.

For example, to reset a `StoredState<Bool>`:
```swift
extension Application {
    var hasCompletedOnboarding: StoredState<Bool> { storedState(initial: false, id: "onboarding_complete") }
}

// Somewhere in your code
Application.reset(storedState: \.hasCompletedOnboarding)
```
This will reset the value in `UserDefaults` back to `false`. Similar `reset` functions exist for `FileState`, `SyncState`, and `SecureState`.

For a non-persistent `State`, there is no built-in `reset` function. You can achieve the same effect by manually setting it back to its initial value:
```swift
extension Application {
    var counter: State<Int> { state(initial: 0) }
}

// To reset:
var counterState = Application.state(\.counter)
counterState.value = 0
```

## Can I use AppState with asynchronous tasks?

Yes. `State` and dependency values are thread-safe and work seamlessly with Swift Concurrency. You can access and modify them inside `async` functions without additional locking.

## Where should I define states and dependencies?

Keep all your states and dependencies in `Application` extensions. This ensures a single source of truth and makes it easier to discover all available values.

## Is AppState compatible with Combine?

You can use AppState alongside Combine by bridging `State` changes to publishers. Observe a `State` value and send updates through a `PassthroughSubject` or other Combine publisher if needed.

