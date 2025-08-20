# 迁移注意事项

在更新您的数据模型时，特别是对于持久化或同步的数据，您需要处理向后兼容性，以避免在加载旧数据时出现潜在问题。以下是一些需要牢记的重要事项：

## 1. 添加非可选字段
如果您向模型中添加新的非可选字段，解码旧数据（其中不包含这些字段）可能会失败。为避免这种情况：
- 考虑为新字段提供默认值。
- 将新字段设为可选，以确保与旧版应用程序的兼容性。

### 示例：
```swift
struct Settings: Codable {
    var text: String
    var isDarkMode: Bool
    var newField: String? // 新字段是可选的
}
```

## 2. 数据格式更改
如果您修改了模型的结构（例如，将类型从 `Int` 更改为 `String`），在读取旧数据时解码过程可能会失败。通过以下方式规划平滑迁移：
- 创建迁移逻辑以将旧数据格式转换为新结构。
- 使用 `Decodable` 的自定义初始化程序来处理旧数据并将其映射到您的新模型。

### 示例：
```swift
struct Settings: Codable {
    var text: String
    var isDarkMode: Bool
    var version: Int

    // 针对旧版本的自定义解码逻辑
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text)
        self.isDarkMode = try container.decode(Bool.self, forKey: .isDarkMode)
        self.version = (try? container.decode(Int.self, forKey: .version)) ?? 1 // 旧数据的默认值
    }
}
```

## 3. 处理已删除或已弃用的字段
如果您从模型中删除一个字段，请确保旧版本的应用程序仍然可以在不崩溃的情况下解码新数据。您可以：
- 在解码时忽略多余的字段。
- 使用自定义解码器来处理旧数据并正确管理已弃用的字段。

## 4. 版本化您的模型

版本化您的模型允许您随时间处理数据结构中的更改。通过在模型中保留版本号，您可以轻松地实现迁移逻辑，将旧数据格式转换为新数据格式。这种方法可确保您的应用程序可以处理旧数据结构，同时平滑地过渡到新版本。

- **为什么版本化很重要**：当用户更新其应用程序时，他们的设备上可能仍保留有旧数据。版本化可帮助您的应用程序识别数据格式并应用正确的迁移逻辑。
- **如何使用**：向您的模型添加一个 `version` 字段，并在解码过程中检查它，以确定是否需要迁移。

### 示例：
```swift
struct Settings: Codable {
    var version: Int
    var text: String
    var isDarkMode: Bool

    // 处理特定于版本的解码逻辑
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(Int.self, forKey: .version)
        self.text = try container.decode(String.self, forKey: .text)
        self.isDarkMode = try container.decode(Bool.self, forKey: .isDarkMode)

        // 如果从旧版本迁移，请在此处应用必要的转换
        if version < 2 {
            // 将旧数据迁移到新格式
        }
    }
}
```

- **最佳实践**：从一开始就使用 `version` 字段。每次更新模型结构时，增加版本并处理必要的迁移逻辑。

## 5. 测试迁移
始终通过使用新版本的模型模拟加载旧数据来彻底测试您的迁移，以确保您的应用程序按预期运行。

---
该译文由机器自动生成，可能存在错误。如果您是母语使用者，我们期待您通过 Pull Request 提出修改建议。
