# 用法概述

本概述快速介绍如何在 SwiftUI `View` 中使用 **AppState** 库的关键组件。每个小节都包含适配于 SwiftUI 视图结构范围内的简单示例。

## 在 Application 扩展中定义值

要定义应用范围内的状态或依赖，你应当扩展 `Application` 对象。这能让你把应用的所有状态集中在一处。以下示例展示如何扩展 `Application` 来创建各种状态和依赖：

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

`State` 让你定义可在应用任何位置访问和修改的应用范围状态。

### 示例

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("Hello, \(user.name)!")
            Button("Log in") {
                user.isLoggedIn.toggle()
            }
        }
    }
}
```

## StoredState

`StoredState` 使用 `UserDefaults` 持久化状态，确保值在应用启动之间被保存。

### 示例

```swift
import AppState
import SwiftUI

struct PreferencesView: View {
    @StoredState(\.userPreferences) var userPreferences: String

    var body: some View {
        VStack {
            Text("Preferences: \(userPreferences)")
            Button("Update Preferences") {
                userPreferences = "Updated Preferences"
            }
        }
    }
}
```

## SyncState

`SyncState` 使用 iCloud 在多个设备之间同步应用状态。

### 示例

```swift
import AppState
import SwiftUI

struct SyncSettingsView: View {
    @SyncState(\.darkModeEnabled) var isDarkModeEnabled: Bool

    var body: some View {
        VStack {
            Toggle("Dark Mode", isOn: $isDarkModeEnabled)
        }
    }
}
```

## FileState

`FileState` 用于使用文件系统持久化存储更大或更复杂的数据，非常适合缓存或保存那些超出 `UserDefaults` 限制的数据。

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

## ModelState

🍎 `ModelState` 通过注入共享的 `ModelContainer`，借助 AppState 管理 SwiftData 的 `@Model` 对象。它适用于视图模型、服务以及其他非视图代码；对于响应式视图，请将 SwiftData 的 `@Query` 与 AppState 提供的 `ModelContainer` 配合使用。SwiftData 功能需要 iOS 17+ / macOS 14+。

### 示例

```swift
import AppState
import SwiftData

private func makeItemContainer() -> ModelContainer {
    do {
        return try ModelContainer(for: Item.self)
    } catch {
        fatalError("Failed to create ModelContainer: \(error)")
    }
}

extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeItemContainer())
    }

    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}

@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func add(_ item: Item) {
        $items.insert(item)
    }
}
```

更多细节请参阅 [ModelState 用法指南](usage-modelstate.md)。

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
                Text("User token: \(token)")
            } else {
                Text("No token found.")
            }
            Button("Set Token") {
                userToken = "secure_token_value"
            }
        }
    }
}
```

## Constant

`Constant` 提供对应用状态中各值的不可变、只读访问，确保在访问那些不应被修改的值时的安全性。

### 示例

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.user, \.name) var name: String

    var body: some View {
        Text("Username: \(name)")
    }
}
```

## 切片状态

`Slice` 和 `OptionalSlice` 让你访问应用状态的特定部分。

### 示例

```swift
import AppState
import SwiftUI

struct SlicingView: View {
    @Slice(\.user, \.name) var name: String

    var body: some View {
        VStack {
            Text("Username: \(name)")
            Button("Update Username") {
                name = "NewUsername"
            }
        }
    }
}
```

## 最佳实践

- **在 SwiftUI 视图中使用 `AppState`**：诸如 `@AppState`、`@StoredState`、`@FileState`、`@SecureState` 等属性包装器，是为在 SwiftUI 视图范围内使用而设计的。
- **在 Application 扩展中定义状态**：通过扩展 `Application` 来定义应用的状态和依赖，从而集中管理状态。
- **响应式更新**：当状态变化时，SwiftUI 会自动更新视图，因此你无需手动刷新 UI。
- **[最佳实践指南](best-practices.md)**：使用 AppState 时最佳实践的详细分类。

## 后续步骤

熟悉基本用法后，你可以探索更多进阶主题：

- 在 [FileState 用法指南](usage-filestate.md) 中探索如何使用 **FileState** 将大量数据持久化到文件。
- 🍎 在 [ModelState 用法指南](usage-modelstate.md) 中了解如何借助 AppState 管理 **SwiftData** 模型。
- 在 [常量用法指南](usage-constant.md) 中了解 **Constants** 以及如何用它们表示应用状态中的不可变值。
- 研究 **Dependency** 在 AppState 中如何用于处理共享服务，并在 [状态依赖用法指南](usage-state-dependency.md) 中查看示例。
- 在 [ObservedDependency 用法指南](usage-observeddependency.md) 中深入探讨 **进阶 SwiftUI** 技术，例如使用 `ObservedDependency` 在视图中管理可观察的依赖。
- 有关更进阶的用法技术，如即时创建和预加载依赖，请参阅 [高级用法指南](advanced-usage.md)。

---
该译文由机器自动生成，可能存在错误。如果您是母语使用者，我们期待您通过 Pull Request 提出修改建议。
