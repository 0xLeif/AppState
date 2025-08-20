# StoredState 用法

`StoredState` 是 **AppState** 库的一个组件，允许您使用 `UserDefaults` 存储和持久化少量数据。它非常适合存储需要在应用程序启动之间持久化的轻量级、非敏感数据。

## 概述

- **StoredState** 构建在 `UserDefaults` 之上，这意味着它对于存储少量数据（例如用户偏好或应用程序设置）来说是快速高效的。
- 保存在 **StoredState** 中的数据在应用程序会话之间保持持久，允许您在启动时恢复应用程序状态。

### 主要功能

- **持久性存储**：保存在 `StoredState` 中的数据在应用程序启动之间保持可用。
- **小数据处理**：最适合用于轻量级数据，如偏好、切换开关或小型配置。
- **线程安全**：`StoredState` 确保在并发环境中数据访问保持安全。

## 用法示例

### 定义 StoredState

您可以通过扩展 `Application` 对象并声明状态属性来定义 **StoredState**：

```swift
import AppState

extension Application {
    var userPreferences: StoredState<String> {
        storedState(initial: "Default Preferences", id: "userPreferences")
    }
}
```

### 在视图中访问和修改 StoredState

您可以使用 `@StoredState` 属性包装器在 SwiftUI 视图中访问和修改 **StoredState** 值：

```swift
import AppState
import SwiftUI

struct PreferencesView: View {
    @StoredState(\.userPreferences) var userPreferences: String

    var body: some View {
        VStack {
            Text("偏好设置: \(userPreferences)")
            Button("更新偏好设置") {
                userPreferences = "Updated Preferences"
            }
        }
    }
}
```

## 处理数据迁移

随着您的应用程序的发展，您可能会更新通过 **StoredState** 持久化的模型。在更新数据模型时，请确保向后兼容性。例如，您可能需要添加新字段或对模型进行版本控制以处理迁移。

有关更多信息，请参阅[迁移注意事项指南](migration-considerations.md)。

### 迁移注意事项

- **添加新的非可选字段**：确保新字段是可选的或具有默认值，以保持向后兼容性。
- **版本化模型**：如果您的数据模型随时间变化，请包含一个 `version` 字段来管理持久化数据的不同版本。

## 最佳实践

- **用于小数据**：存储需要在应用程序启动之间持久化的轻量级、非敏感数据，例如用户偏好。
- **考虑大数据的替代方案**：如果您需要存储大量数据，请考虑改用 **FileState**。

## 结论

**StoredState** 是使用 `UserDefaults` 持久化小块数据的简单有效的方法。它非常适合在应用程序启动之间保存偏好和其他小型设置，同时提供安全的访问和与 SwiftUI 的轻松集成。对于更复杂的持久化需求，请探索 **AppState** 的其他功能，例如 [FileState](usage-filestate.md) 或 [SyncState](usage-syncstate.md)。

---
这是使用 Jules 生成的，可能会出现错误。如果您是母语人士，请提出包含任何应有修复的拉取请求。
