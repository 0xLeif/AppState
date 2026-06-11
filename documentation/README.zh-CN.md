# AppState

[![macOS 构建](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/macOS.yml?label=macOS&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/macOS.yml)
[![Ubuntu 构建](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/ubuntu.yml?label=Ubuntu&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/ubuntu.yml)
[![Windows 构建](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/windows.yml?label=Windows&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/windows.yml)
[![许可证](https://img.shields.io/github/license/0xLeif/AppState)](https://github.com/0xLeif/AppState/blob/main/LICENSE)
[![版本](https://img.shields.io/github/v/release/0xLeif/AppState)](https://github.com/0xLeif/AppState/releases)

阅读其他语言版本：[French](README.fr.md) | [German](README.de.md) | [Hindi](README.hi.md) | [Portuguese](README.pt.md) | [Russian](README.ru.md) | [Simplified Chinese](README.zh-CN.md) | [Spanish](README.es.md)

**AppState** 是一个 Swift 6 库，以线程安全、类型安全和 SwiftUI 友好的方式管理应用程序状态。集中并同步整个应用的状态；在任何地方注入依赖。

## 要求

- **iOS**: 17.0+
- **watchOS**: 10.0+
- **macOS**: 14.0+
- **tvOS**: 17.0+
- **visionOS**: 1.0+
- **Swift**: 6.0+
- **Xcode**: 16.0+

**非苹果平台支持**：Linux 和 Windows

> 🍎 标有此符号的功能是苹果平台特有的，因为它们依赖于 iCloud 和钥匙串等苹果技术。

## 主要功能

**AppState** 包括：

- **State**：集中式状态管理，允许你封装并广播整个应用的更改。
- **StoredState**：使用 `UserDefaults` 的持久状态，非常适合在应用启动之间保存少量数据。
- **FileState**：使用 `FileManager` 存储的持久状态，用于在磁盘上安全地存储大量数据。
- 🍎 **SwiftData (ModelState)**：通过注入共享的 `ModelContainer` 并使用 `ModelState` 读取/写入模型，借助 AppState 管理 SwiftData 的 `@Model` 对象。
- 🍎 **SyncState**：使用 iCloud 在多个设备之间同步状态，确保用户偏好和设置的一致性。
- 🍎 **SecureState**：使用钥匙串安全地存储敏感数据，保护用户信息（如令牌或密码）。
- **依赖管理**：在整个应用中注入网络服务或数据库客户端等依赖，以实现更好的模块化和测试。
- **Slicing**：访问状态或依赖的特定部分以进行精细控制，而无需管理整个应用状态。
- **Constants**：当你需要不可变值时，可以访问状态的只读切片。
- **Observed Dependencies**：观察 `ObservableObject` 依赖，以便在它们更改时更新你的视图。

## 入门

通过 Swift 包管理器添加 **AppState** —— 参见[安装指南](en/installation.md)。然后查看[用法概述](en/usage-overview.md)，快速了解入门方法。

## 快速示例

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
            Text("Count: \(counter)")
            Button("Increment") { counter += 1 }
        }
    }
}
```

## 文档

以下是 **AppState** 文档的详细分类：

- [安装指南](en/installation.md)：如何使用 Swift 包管理器将 **AppState** 添加到你的项目中。
- [用法概述](en/usage-overview.md)：主要功能的概述及示例实现。

### 详细用法指南：

- [状态和依赖管理](en/usage-state-dependency.md)：集中管理状态并在整个应用中注入依赖。
- [状态切片](en/usage-slice.md)：访问和修改状态的特定部分。
- [StoredState 用法指南](en/usage-storedstate.md)：如何使用 `StoredState` 持久化轻量级数据。
- [FileState 用法指南](en/usage-filestate.md)：了解如何安全地在磁盘上持久化大量数据。
- 🍎 [ModelState 用法指南](en/usage-modelstate.md)：通过共享的 `ModelContainer` 管理 SwiftData 的 `@Model` 对象。
- [钥匙串 SecureState 用法](en/usage-securestate.md)：使用钥匙串安全地存储敏感数据。
- [使用 SyncState 进行 iCloud 同步](en/usage-syncstate.md)：使用 iCloud 在设备之间保持状态同步。
- [升级到 AppState 3.0](en/upgrade-to-v3.md)：重大变更以及如何从 2.x 发布线迁移。
- [常见问题解答](en/faq.md)：使用 **AppState** 时常见问题的解答。
- [常量用法指南](en/usage-constant.md)：从你的状态中访问只读值。
- [ObservedDependency 用法指南](en/usage-observeddependency.md)：在你的视图中使用 `ObservableObject` 依赖。
- [高级用法](en/advanced-usage.md)：诸如即时创建和预加载依赖等技术。
- [最佳实践](en/best-practices.md)：有效构建应用状态的技巧。
- [迁移注意事项](en/migration-considerations.md)：更新持久化模型时的指导。

## 贡献

我们欢迎贡献！请查看我们的[贡献指南](en/contributing.md)以了解如何参与。

## 后续步骤

从[用法概述](en/usage-overview.md)开始。有关即时创建和预加载，请参阅[高级用法指南](en/advanced-usage.md)。[常量](en/usage-constant.md)和 [ObservedDependency](en/usage-observeddependency.md) 指南涵盖了其他功能。

---
这是使用 [Jules](https://jules.google) 生成的，可能会出现错误。如果您是母语人士，请提出包含任何应有修复的拉取请求。
