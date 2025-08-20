# SyncState 用法

`SyncState` 是 **AppState** 库的一个组件，允许您使用 iCloud 在多个设备之间同步应用程序状态。这对于在设备之间保持用户偏好、设置或其他重要数据的一致性特别有用。

## 概述

`SyncState` 利用 iCloud 的 `NSUbiquitousKeyValueStore` 在设备之间保持少量数据的同步。这使其非常适合同步轻量级应用程序状态，例如偏好或用户设置。

### 主要功能

- **iCloud 同步**：在登录到同一 iCloud 帐户的所有设备之间自动同步状态。
- **持久性存储**：数据持久地存储在 iCloud 中，这意味着即使应用程序终止或重新启动，它也会持久存在。
- **近乎实时的同步**：对状态的更改几乎可以立即传播到其他设备。

> **注意**：`SyncState` 在 watchOS 9.0 及更高版本上受支持。

## 用法示例

### 数据模型

假设我们有一个名为 `Settings` 的结构体，它符合 `Codable`：

```swift
struct Settings: Codable {
    var text: String
    var isShowingSheet: Bool
    var isDarkMode: Bool
}
```

### 定义 SyncState

您可以通过扩展 `Application` 对象并声明应同步的状态属性来定义 `SyncState`：

```swift
extension Application {
    var settings: SyncState<Settings> {
        syncState(
            initial: Settings(
                text: "Hello, World!",
                isShowingSheet: false,
                isDarkMode: false
            ),
            id: "settings"
        )
    }
}
```

### 处理外部更改

为确保应用程序响应来自 iCloud 的外部更改，请通过创建自定义 `Application` 子类来覆盖 `didChangeExternally` 函数：

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
```

### 创建视图以修改和同步状态

在以下示例中，我们有两个视图：`ContentView` 和 `ContentViewInnerView`。这些视图在它们之间共享和同步 `Settings` 状态。`ContentView` 允许用户修改 `text` 和切换 `isDarkMode`，而 `ContentViewInnerView` 显示相同的文本并在点击时更新它。

```swift
struct ContentView: View {
    @SyncState(\.settings) private var settings: Settings

    var body: some View {
        VStack {
            TextField("", text: $settings.text)

            Button(settings.isDarkMode ? "Light" : "Dark") {
                settings.isDarkMode.toggle()
            }

            Button("Show") { settings.isShowingSheet = true }
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        .sheet(isPresented: $settings.isShowingSheet, content: ContentViewInnerView.init)
    }
}

struct ContentViewInnerView: View {
    @Slice(\.settings, \.text) private var text: String

    var body: some View {
        Text("\(text)")
            .onTapGesture {
                text = Date().formatted()
            }
    }
}
```

### 设置应用程序

最后，在 `@main` 结构体中设置应用程序。在初始化中，提升自定义应用程序，启用日志记录，并加载用于同步的 iCloud 存储依赖项：

```swift
@main
struct SyncStateExampleApp: App {
    init() {
        Application
            .promote(to: CustomApplication.self)
            .logging(isEnabled: true)
            .load(dependency: \.icloudStore)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 启用 iCloud 键值存储

要启用 iCloud 同步，请确保您按照本指南启用 iCloud 键值存储功能：[开始使用 SyncState](https://github.com/0xLeif/AppState/wiki/Starting-to-use-SyncState)。

### SyncState：关于 iCloud 存储的说明

虽然 `SyncState` 可以轻松同步，但请务必记住 `NSUbiquitousKeyValueStore` 的限制：

- **存储限制**：您可以使用 `NSUbiquitousKeyValueStore` 在 iCloud 中存储最多 1 MB 的数据，每个键值对的大小限制为 1 MB。

### 迁移注意事项

在更新数据模型时，考虑潜在的迁移挑战非常重要，尤其是在使用 **StoredState**、**FileState** 或 **SyncState** 处理持久化数据时。如果没有适当的迁移处理，添加新字段或修改数据格式等更改可能会在加载旧数据时导致问题。

以下是一些需要牢记的关键点：
- **添加新的非可选字段**：确保新字段是可选的或具有默认值，以保持向后兼容性。
- **处理数据格式更改**：如果模型的结构发生变化，请实现自定义解码逻辑以支持旧格式。
- **版本化您的模型**：在您的模型中使用 `version` 字段以帮助进行迁移，并根据数据版本应用逻辑。

要了解有关如何管理迁移和避免潜在问题的更多信息，请参阅[迁移注意事项指南](migration-considerations.md)。

## SyncState 实现指南

有关如何配置 iCloud 并在您的项目中设置 SyncState 的详细说明，请参阅[SyncState 实现指南](syncstate-implementation.md)。

## 最佳实践

- **用于小的、关键的数据**：`SyncState` 非常适合同步小的、重要的状态片段，例如用户偏好、设置或功能标志。
- **监控 iCloud 存储**：确保您对 `SyncState` 的使用保持在 iCloud 存储限制内，以防止数据同步问题。
- **处理外部更新**：如果您的应用程序需要响应在另一台设备上发起的状态更改，请覆盖 `didChangeExternally` 函数以实时更新应用程序的状态。

## 结论

`SyncState` 提供了一种通过 iCloud 在设备之间同步少量应用程序状态的强大方法。它非常适合确保用户偏好和其他关键数据在登录到同一 iCloud 帐户的所有设备上保持一致。对于更高级的用例，请探索 **AppState** 的其他功能，例如 [SecureState](usage-securestate.md) 和 [FileState](usage-filestate.md)。

---
这是使用 Jules 生成的，可能会出现错误。如果您是母语人士，请提出包含任何应有修复的拉取请求。
