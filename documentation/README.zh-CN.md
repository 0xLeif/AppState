# AppState

[![macOS 构建](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/macOS.yml?label=macOS&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/macOS.yml)
[![Ubuntu 构建](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/ubuntu.yml?label=Ubuntu&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/ubuntu.yml)
[![Windows 构建](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/windows.yml?label=Windows&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/windows.yml)
[![许可证](https://img.shields.io/github/license/0xLeif/AppState)](https://github.com/0xLeif/AppState/blob/main/LICENSE)
[![版本](https://img.shields.io/github/v/release/0xLeif/AppState)](https://github.com/0xLeif/AppState/releases)

**AppState** 是一个 Swift 6 库，旨在以线程安全、类型安全和 SwiftUI 友好的方式简化应用程序状态的管理。它提供了一套工具来集中和同步整个应用程序的状态，并将依赖项注入到应用程序的各个部分。

## 要求

- **iOS**: 15.0+
- **watchOS**: 8.0+
- **macOS**: 11.0+
- **tvOS**: 15.0+
- **visionOS**: 1.0+
- **Swift**: 6.0+
- **Xcode**: 16.0+

**非苹果平台支持**：Linux 和 Windows

> 🍎 标有此符号的功能是苹果平台特有的，因为它们依赖于 iCloud 和钥匙串等苹果技术。

## 主要功能

**AppState** 包括几个强大的功能来帮助管理状态和依赖项：

- **State**：集中式状态管理，允许您封装和广播整个应用程序的更改。
- **StoredState**：使用 `UserDefaults` 的持久状态，非常适合在应用程序启动之间保存少量数据。
- **FileState**：使用 `FileManager` 存储的持久状态，用于在磁盘上安全地存储大量数据。
- 🍎 **SyncState**：使用 iCloud 在多个设备之间同步状态，确保用户偏好和设置的一致性。
- 🍎 **SecureState**：使用钥匙串安全地存储敏感数据，保护用户信息（如令牌或密码）。
- **依赖管理**：在整个应用程序中注入网络服务或数据库客户端等依赖项，以实现更好的模块化和测试。
- **Slicing**：访问状态或依赖项的特定部分以进行精细控制，而无需管理整个应用程序状态。
- **Constants**：当您需要不可变值时，可以访问状态的只读切片。
- **Observed Dependencies**：观察 `ObservableObject` 依赖项，以便在它们更改时更新您的视图。

## 入门

要将 **AppState** 集成到您的 Swift 项目中，您需要使用 Swift 包管理器。有关设置 **AppState** 的详细说明，请遵循[安装指南](documentation/zh-CN/installation.md)。

安装后，请参阅[用法概述](documentation/zh-CN/usage-overview.md)，快速了解如何管理状态和将依赖项注入到您的项目中。

## 快速示例

以下是一个最小示例，展示了如何定义一个状态片段并从 SwiftUI 视图中访问它：

```swift
import AppState
import SwiftUI

private extension Application {
    var counter: State<Int> {
        state(initial: 0)
    }
}

struct ContentView: View {
    @AppState(\.counter) var counter: Int

    var body: some View {
        VStack {
            Text("计数: \(counter)")
            Button("递增") { counter += 1 }
        }
    }
}
```

此代码片段演示了如何在 `Application` 扩展中定义状态值，并使用 `@AppState` 属性包装器将其绑定到视图中。

## 文档

以下是 **AppState** 文档的详细分类：

- [安装指南](documentation/zh-CN/installation.md)：如何使用 Swift 包管理器将 **AppState** 添加到您的项目中。
- [用法概述](documentation/zh-CN/usage-overview.md)：主要功能的概述及示例实现。

### 详细用法指南：

- [状态和依赖管理](documentation/zh-CN/usage-state-dependency.md)：集中管理状态并在整个应用程序中注入依赖项。
- [状态切片](documentation/zh-CN/usage-slice.md)：访问和修改状态的特定部分。
- [StoredState 用法指南](documentation/zh-CN/usage-storedstate.md)：如何使用 `StoredState` 持久化轻量级数据。
- [FileState 用法指南](documentation/zh-CN/usage-filestate.md)：了解如何安全地在磁盘上持久化大量数据。
- [钥匙串 SecureState 用法](documentation/zh-CN/usage-securestate.md)：使用钥匙串安全地存储敏感数据。
- [使用 SyncState 进行 iCloud 同步](documentation/zh-CN/usage-syncstate.md)：使用 iCloud 在设备之间保持状态同步。
- [常见问题解答](documentation/zh-CN/faq.md)：使用 **AppState** 时常见问题的解答。
- [常量用法指南](documentation/zh-CN/usage-constant.md)：从您的状态中访问只读值。
- [ObservedDependency 用法指南](documentation/zh-CN/usage-observeddependency.md)：在您的视图中使用 `ObservableObject` 依赖项。
- [高级用法](documentation/zh-CN/advanced-usage.md)：诸如即时创建和预加载依赖项等技术。
- [最佳实践](documentation/zh-CN/best-practices.md)：有效构建应用程序状态的技巧。
- [迁移注意事项](documentation/zh-CN/migration-considerations.md)：更新持久化模型时的指导。

## 贡献

我们欢迎贡献！请查看我们的[贡献指南](documentation/zh-CN/contributing.md)以了解如何参与。

## 后续步骤

安装 **AppState** 后，您可以通过查看[用法概述](documentation/zh-CN/usage-overview.md)和更详细的指南来开始探索其主要功能。开始在您的 Swift 项目中有效地管理状态和依赖项！有关更高级的用法技术，如即时创建和预加载依赖项，请参阅[高级用法指南](documentation/zh-CN/advanced-usage.md)。您还可以查看[常量](documentation/zh-CN/usage-constant.md)和[ObservedDependency](documentation/zh-CN/usage-observeddependency.md)指南以了解其他功能。
