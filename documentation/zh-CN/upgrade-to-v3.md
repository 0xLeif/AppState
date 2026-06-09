# 升级到 AppState 3.0

AppState 3.0 围绕 Swift 6 和苹果的 Observation 框架对库进行了现代化改造。本指南介绍了重大变更以及如何进行适配。

## 1. 提高了平台要求

为了利用现代 Swift 和 SwiftData/Observation API，最低部署目标已被提高：

| 平台 | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux 和 Windows 继续支持非苹果功能集。

如果您必须继续支持较旧的操作系统版本，请保留在 2.x 发布线上。

## 2. 严格的 Swift 6

该包现在固定使用 Swift 6 语言模式（`swiftLanguageModes: [.v6]`）和 `ExistentialAny` 即将推出的特性，并且 CI 构建将警告视为错误。对于大多数应用程序而言，这不需要任何更改。如果您实现了 AppState 的任何公共协议（例如自定义的 `FileManaging`、`UserDefaultsManaging` 或 `UbiquitousKeyValueStoreManaging`），您可能需要使用显式的 `any` 来编写存在类型（例如 `any FileManaging`）。

## 3. Observation 取代 ObservableObject

`Application` 现在使用 [`@Observable`](https://developer.apple.com/documentation/observation) 宏，而不是遵循 `ObservableObject`。

**典型用法不需要任何更改。** 属性包装器——`@AppState`、`@StoredState`、`@FileState`、`@SyncState`、`@SecureState`、`@Slice`、`@OptionalSlice`、`@DependencySlice` 和 `@ModelState`——在 SwiftUI 视图中继续工作，视图也像以前一样更新。遵循 `ObservableObject` 并托管这些包装器的视图模型仍然受支持。

变更内容：

- `Application` 不再遵循 `ObservableObject`，因此 `Application.shared.objectWillChange` 不再可用。
- 一个新方法 `Application.notifyChange()`，用于请求观察者（SwiftUI 视图）更新。AppState 自己的设置器会为您调用它。

如果您子类化了 `Application` 并手动触发更新——例如从响应传入 iCloud 更改的 `didChangeExternally(notification:)` 覆盖中——请将 `objectWillChange.send()` 替换为 `notifyChange()`：

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            // 之前 (2.x)：
            // self.objectWillChange.send()

            // 之后 (3.0)：
            self.notifyChange()
        }
    }
}
```

> 注意：`@ObservedDependency` 未发生变化。它仍然观察遵循 `ObservableObject` 的依赖项值。

## 4. 新增：SwiftData 支持

3.0 添加了一流的 SwiftData 集成：将共享的 `ModelContainer` 作为依赖项注入，并通过 `ModelState` 读取/写入 `@Model` 对象。请参阅 [ModelState 用法指南](usage-modelstate.md)。这是附加的且可选的。

---
该译文由机器自动生成，可能存在错误。如果您是母语使用者，我们期待您通过 Pull Request 提出修改建议。
