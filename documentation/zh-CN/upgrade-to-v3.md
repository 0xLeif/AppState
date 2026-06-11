# 升级到 AppState 3.0

AppState 3.0 围绕 Swift 6 和 Apple 的 Observation 框架构建。以下是重大变更以及如何适配。

## 重大变更速览

- **平台最低版本提升** — iOS 17、macOS 14、tvOS 17、watchOS 10
- **Swift 6 严格并发** — 启用 `ExistentialAny`；协议存在类型需显式标注 `any`
- **移除 `ObservableObject`** — `Application` 改用 `@Observable`；`objectWillChange` 已不存在，请改用 `notifyChange()`
- **新增（增量功能）：SwiftData 支持** — 为 `@Model` 对象提供 `ModelState` / `@ModelState`

---

## 1. 提升的平台要求

| 平台 | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux 和 Windows 继续支持非苹果平台的功能集。

如果你需要支持更旧的操作系统版本，请继续使用 2.x 发布线。

## 2. 严格的 Swift 6

该包锁定 Swift 6 语言模式（`swiftLanguageModes: [.v6]`），并启用 `ExistentialAny` 即将到来的特性。CI 构建将警告视为错误。

大多数应用无需任何更改。如果你实现了 AppState 的任何公共协议 —— `FileManaging`、`UserDefaultsManaging` 或 `UbiquitousKeyValueStoreManaging` —— 你可能需要用显式的 `any` 来书写存在类型：

```swift
// Before (2.x)
var fileManager: FileManaging

// After (3.0)
var fileManager: any FileManaging
```

## 3. Observation 取代 ObservableObject

`Application` 现在使用 [`@Observable`](https://developer.apple.com/documentation/observation) 而非 `ObservableObject`。

**属性包装器保持不变。** `@AppState`、`@StoredState`、`@FileState`、`@SyncState`、`@SecureState`、`@Slice`、`@OptionalSlice`、`@DependencySlice` 和 `@ModelState` 都继续在 SwiftUI 视图中正常工作。遵循 `ObservableObject` 并承载这些包装器的视图模型仍受支持。

变更内容：

- `Application.shared.objectWillChange` 不再存在。
- `Application.notifyChange()` 取而代之。AppState 自身的 setter 会自动调用它。
- 直接读取 `Application.state(_:).value` 现在也会参与 Observation —— 而不仅限于 `@AppState` 包装器。这意味着任何代码（不只是 SwiftUI 视图）都可以观察状态变更：

  ```swift
  withObservationTracking {
      _ = Application.state(\.counter).value
  } onChange: {
      // runs when the value changes — no SwiftUI required
  }
  ```

如果你子类化了 `Application` 并手动调用 `objectWillChange.send()`（例如在 `didChangeExternally` 重写中），请将其替换为 `notifyChange()`：

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            self.notifyChange()
        }
    }
}
```

> `@ObservedDependency` 保持不变 —— 它仍然观察遵循 `ObservableObject` 的依赖值。

## 4. 新增：SwiftData 支持

3.0 增加了 SwiftData 集成。将共享的 `ModelContainer` 作为依赖注入，并通过 `ModelState` 读写 `@Model` 对象。这是增量且可选的 —— 参见 [ModelState 用法指南](usage-modelstate.md)。

---
该译文由机器自动生成，可能存在错误。如果您是母语使用者，我们期待您通过 Pull Request 提出修改建议。
