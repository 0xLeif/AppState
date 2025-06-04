# Frequently Asked Questions

This short FAQ addresses common questions developers may have when using **AppState**.

## How do I reset a state value?

Each `State` provides a `reset()` function that restores the value to the `initial` one defined in your `Application` extension. Call `reset()` when you need to clear user data or return to a default configuration.

```swift
@AppState(\.counter) var counter: Int

func clearCounter() {
    counter.reset() // Resets to the initial value
}
```

## Can I use AppState with asynchronous tasks?

Yes. `State` and dependency values are thread-safe and work seamlessly with Swift Concurrency. You can access and modify them inside `async` functions without additional locking.

## Where should I define states and dependencies?

Keep all your states and dependencies in `Application` extensions. This ensures a single source of truth and makes it easier to discover all available values.

## Is AppState compatible with Combine?

You can use AppState alongside Combine by bridging `State` changes to publishers. Observe a `State` value and send updates through a `PassthroughSubject` or other Combine publisher if needed.

