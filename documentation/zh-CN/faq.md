# 常见问题

这个简短的常见问题解答解决了开发人员在使用 **AppState** 时可能遇到的常见问题。

## 如何重置状态值？

对于像 `StoredState`、`FileState` 和 `SyncState` 这样的持久化状态，您可以使用 `Application` 类型上的静态 `reset` 函数将它们重置为初始值。

例如，要重置一个 `StoredState<Bool>`：
```swift
extension Application {
    var hasCompletedOnboarding: StoredState<Bool> { storedState(initial: false, id: "onboarding_complete") }
}

// 在您的代码中的某个地方
Application.reset(storedState: \.hasCompletedOnboarding)
```
这将把 `UserDefaults` 中的值重置为 `false`。`FileState`、`SyncState` 和 `SecureState` 也存在类似的 `reset` 函数。

对于非持久化的 `State`，您可以像持久化状态一样重置它：
```swift
extension Application {
    var counter: State<Int> { state(initial: 0) }
}

// 在您的代码中的某个地方
Application.reset(\.counter)
```

## 我可以在异步任务中使用 AppState 吗？

可以。`State` 和依赖项值是线程安全的，并且可以与 Swift Concurrency 无缝协作。您可以在 `async` 函数中访问和修改它们，而无需额外的锁定。

## 我应该在哪里定义状态和依赖项？

将您所有的状态和依赖项都放在 `Application` 扩展中。这确保了单一的真实来源，并使发现所有可用的值变得更加容易。

## AppState 与 Combine 兼容吗？

您可以通过将 `State` 的更改桥接到发布者来将 AppState 与 Combine 一起使用。观察一个 `State` 值，并在需要时通过 `PassthroughSubject` 或其他 Combine 发布者发送更新。

---
该译文由机器自动生成，可能存在错误。如果您是母语使用者，我们期待您通过 Pull Request 提出修改建议。
