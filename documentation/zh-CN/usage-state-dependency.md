# 状态和依赖用法

**AppState** 提供了强大的工具，用于管理应用程序范围的状态并将依赖项注入到 SwiftUI 视图中。通过集中管理您的状态和依赖项，您可以确保您的应用程序保持一致和可维护。

## 概述

- **状态**：表示可在整个应用程序中共享的值。可以在您的 SwiftUI 视图中修改和观察状态值。
- **依赖项**：表示可在 SwiftUI 视图中注入和访问的共享资源或服务。

### 主要功能

- **集中式状态**：在一个地方定义和管理应用程序范围的状态。
- **依赖注入**：在应用程序的不同组件之间注入和访问共享服务和资源。

## 用法示例

### 定义应用程序状态

要定义应用程序范围的状态，请扩展 `Application` 对象并声明状态属性。

```swift
import AppState

struct User {
    var name: String
    var isLoggedIn: Bool
}

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }
}
```

### 在视图中访问和修改状态

您可以使用 `@AppState` 属性包装器直接在 SwiftUI 视图中访问和修改状态值。

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("你好, \(user.name)!")
            Button("登录") {
                user.name = "John Doe"
                user.isLoggedIn = true
            }
        }
    }
}
```

### 定义依赖项

您可以将共享资源（例如网络服务）定义为 `Application` 对象中的依赖项。这些依赖项可以注入到 SwiftUI 视图中。

```swift
import AppState

protocol NetworkServiceType {
    func fetchData() -> String
}

class NetworkService: NetworkServiceType {
    func fetchData() -> String {
        return "Data from network"
    }
}

extension Application {
    var networkService: Dependency<NetworkServiceType> {
        dependency(NetworkService())
    }
}
```

### 在视图中访问依赖项

使用 `@AppDependency` 属性包装器在 SwiftUI 视图中访问依赖项。这允许您将网络服务等服务注入到您的视图中。

```swift
import AppState
import SwiftUI

struct NetworkView: View {
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("数据: \(networkService.fetchData())")
        }
    }
}
```

### 在视图中结合状态和依赖项

状态和依赖项可以协同工作，构建更复杂的应用程序逻辑。例如，您可以从服务中获取数据并更新状态：

```swift
import AppState
import SwiftUI

struct CombinedView: View {
    @AppState(\.user) var user: User
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("用户: \(user.name)")
            Button("获取数据") {
                user.name = networkService.fetchData()
                user.isLoggedIn = true
            }
        }
    }
}
```

### 最佳实践

- **集中管理状态**：将您的应用程序范围的状态放在一个地方，以避免重复并确保一致性。
- **对共享服务使用依赖项**：注入网络服务、数据库或其他共享资源等依赖项，以避免组件之间的紧密耦合。

## 结论

使用 **AppState**，您可以管理应用程序范围的状态，并将共享依赖项直接注入到您的 SwiftUI 视图中。这种模式有助于保持您的应用程序模块化和可维护性。探索 **AppState** 库的其他功能，例如 [SecureState](usage-securestate.md) 和 [SyncState](usage-syncstate.md)，以进一步增强您的应用程序的状态管理。

---
该译文由机器自动生成，可能存在错误。如果您是母语使用者，我们期待您通过 Pull Request 提出修改建议。
