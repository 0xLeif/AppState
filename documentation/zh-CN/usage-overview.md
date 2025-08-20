# 用法概述

本概述简要介绍了如何在 SwiftUI `View` 中使用 **AppState** 库的关键组件。每个部分都包含适合 SwiftUI 视图结构范围的简单示例。

## 在 Application 扩展中定义值

要定义应用程序范围的状态或依赖项，您应该扩展 `Application` 对象。这使您可以将应用程序的所有状态集中在一个地方。以下是如何扩展 `Application` 以创建各种状态和依赖项的示例：

```swift
import AppState

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }

    var userPreferences: StoredState<String> {
        storedState(initial: "Default Preferences", id: "userPreferences")
    }

    var darkModeEnabled: SyncState<Bool> {
        syncState(initial: false, id: "darkModeEnabled")
    }

    var userToken: SecureState {
        secureState(id: "userToken")
    }

    @MainActor
    var largeDataset: FileState<[String]> {
        fileState(initial: [], filename: "largeDataset")
    }
}
```

## State

`State` 允许您定义可在应用程序中任何位置访问和修改的应用程序范围状态。

### 示例

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("你好, \(user.name)!")
            Button("登录") {
                user.isLoggedIn.toggle()
            }
        }
    }
}
```

## StoredState

`StoredState` 使用 `UserDefaults` 持久化状态，以确保值在应用程序启动之间被保存。

### 示例

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

## SyncState

`SyncState` 使用 iCloud 在多个设备之间同步应用程序状态。

### 示例

```swift
import AppState
import SwiftUI

struct SyncSettingsView: View {
    @SyncState(\.darkModeEnabled) var isDarkModeEnabled: Bool

    var body: some View {
        VStack {
            Toggle("深色模式", isOn: $isDarkModeEnabled)
        }
    }
}
```

## FileState

`FileState` 用于使用文件系统持久地存储较大或更复杂的数据，使其非常适合缓存或保存不适合 `UserDefaults` 限制的数据。

### 示例

```swift
import AppState
import SwiftUI

struct LargeDataView: View {
    @FileState(\.largeDataset) var largeDataset: [String]

    var body: some View {
        List(largeDataset, id: \.self) { item in
            Text(item)
        }
    }
}
```

## SecureState

`SecureState` 将敏感数据安全地存储在钥匙串中。

### 示例

```swift
import AppState
import SwiftUI

struct SecureView: View {
    @SecureState(\.userToken) var userToken: String?

    var body: some View {
        VStack {
            if let token = userToken {
                Text("用户令牌: \(token)")
            } else {
                Text("未找到令牌。")
            }
            Button("设置令牌") {
                userToken = "secure_token_value"
            }
        }
    }
}
```

## Constant

`Constant` 提供对应用程序状态中值的不可变、只读访问，确保在访问不应修改的值时的安全性。

### 示例

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.user, \.name) var name: String

    var body: some View {
        Text("用户名: \(name)")
    }
}
```

## Slicing State

`Slice` 和 `OptionalSlice` 允许您访问应用程序状态的特定部分。

### 示例

```swift
import AppState
import SwiftUI

struct SlicingView: View {
    @Slice(\.user, \.name) var name: String

    var body: some View {
        VStack {
            Text("用户名: \(name)")
            Button("更新用户名") {
                name = "NewUsername"
            }
        }
    }
}
```

## 最佳实践

- **在 SwiftUI 视图中使用 `AppState`**：`@AppState`、`@StoredState`、`@FileState`、`@SecureState` 等属性包装器设计用于 SwiftUI 视图的范围内。
- **在 Application 扩展中定义状态**：通过扩展 `Application` 来定义应用程序的状态和依赖项，从而集中管理状态。
- **反应式更新**：当状态更改时，SwiftUI 会自动更新视图，因此您无需手动刷新 UI。
- **[最佳实践指南](best-practices.md)**：有关使用 AppState 时的最佳实践的详细分类。

## 后续步骤

熟悉基本用法后，您可以探索更高级的主题：

- 在[FileState 用法指南](usage-filestate.md)中探索使用 **FileState** 将大量数据持久化到文件中。
- 在[常量用法指南](usage-constant.md)中了解 **常量** 以及如何在应用程序状态中使用它们来表示不可变值。
- 在[状态依赖用法指南](usage-state-dependency.md)中研究 **Dependency** 如何在 AppState 中用于处理共享服务，并查看示例。
- 在[ObservedDependency 用法指南](usage-observeddependency.md)中更深入地研究 **高级 SwiftUI** 技术，例如使用 `ObservedDependency` 在视图中管理可观察的依赖项。
- 有关更高级的用法技术，例如即时创建和预加载依赖项，请参阅[高级用法指南](advanced-usage.md)。

---
这是使用 Jules 生成的，可能会出现错误。如果您是母语人士，请提出包含任何应有修复的拉取请求。
