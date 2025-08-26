# AppState 中的 SyncState 实现

本指南介绍了如何在您的应用程序中设置和配置 SyncState，包括设置 iCloud 功能和了解潜在的限制。

## 1. 设置 iCloud 功能

要在您的应用程序中使用 SyncState，您首先需要在您的项目中启用 iCloud 并配置键值存储。

### 启用 iCloud 和键值存储的步骤：

1. 打开您的 Xcode 项目并导航到您的项目设置。
2. 在“Signing & Capabilities”选项卡下，选择您的目标（iOS 或 macOS）。
3. 单击“+ Capability”按钮，然后从列表中选择“iCloud”。
4. 在 iCloud 设置下启用“Key-Value storage”选项。这允许您的应用程序使用 iCloud 存储和同步少量数据。

### Entitlements 文件配置：

1. 在您的 Xcode 项目中，找到或创建您应用程序的 **entitlements 文件**。
2. 确保在 entitlements 文件中正确设置了 iCloud 键值存储，并使用了正确的 iCloud 容器。

entitlements 文件中的示例：

```xml
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)com.yourdomain.app</string>
```

确保字符串值与您的项目关联的 iCloud 容器匹配。

## 2. 在您的应用程序中使用 SyncState

启用 iCloud 后，您可以在您的应用程序中使用 `SyncState` 来跨设备同步数据。

### SyncState 使用示例：

```swift
import AppState
import SwiftUI

extension Application {
    var syncValue: SyncState<Int?> {
        syncState(id: "syncValue")
    }
}

struct ContentView: View {
    @SyncState(\.syncValue) private var syncValue: Int?

    var body: some View {
        VStack {
            if let syncValue = syncValue {
                Text("SyncValue: \(syncValue)")
            } else {
                Text("No SyncValue")
            }

            Button("Update SyncValue") {
                syncValue = Int.random(in: 0..<100)
            }
        }
    }
}
```

在此示例中，同步状态将保存到 iCloud 并在登录到同一 iCloud 帐户的设备之间同步。

## 3. 限制和最佳实践

SyncState 使用 `NSUbiquitousKeyValueStore`，它有一些限制：

- **存储限制**：SyncState 专为少量数据而设计。总存储限制为 1 MB，每个键值对限制在 1 MB 左右。
- **同步**：对 SyncState 所做的更改不会立即在设备之间同步。同步可能会有轻微的延迟，并且 iCloud 同步有时可能会受到网络条件的影响。

### 最佳实践：

- **将 SyncState 用于小数据**：确保仅使用 SyncState 同步用户偏好或设置等小数据。
- **优雅地处理 SyncState 失败**：使用默认值或错误处理机制来解决潜在的同步延迟或失败。

## 4. 结论

通过正确配置 iCloud 并了解 SyncState 的限制，您可以利用其功能来跨设备同步数据。确保您仅将 SyncState 用于小的、关键的数据片段，以避免 iCloud 存储限制的潜在问题。

---
该译文由机器自动生成，可能存在错误。如果您是母语使用者，我们期待您通过 Pull Request 提出修改建议。
