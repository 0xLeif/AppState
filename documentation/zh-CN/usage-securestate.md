# SecureState 用法

`SecureState` 是 **AppState** 库的一个组件，允许您将敏感数据安全地存储在钥匙串中。它最适合存储需要安全加密的小块数据，例如令牌或密码。

## 主要功能

- **安全存储**：使用 `SecureState` 存储的数据经过加密并安全地保存在钥匙串中。
- **持久性**：数据在应用程序启动之间保持持久，允许安全地检索敏感值。

## 钥匙串限制

虽然 `SecureState` 非常安全，但它有一定的限制：

- **有限的存储大小**：钥匙串专为小块数据而设计。它不适合存储大文件或数据集。
- **性能**：访问钥匙串比访问 `UserDefaults` 慢，因此仅在需要安全存储敏感数据时才使用它。

## 用法示例

### 存储安全令牌

```swift
import AppState
import SwiftUI

extension Application {
    var userToken: SecureState {
        secureState(id: "userToken")
    }
}

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

### 处理安全数据缺失的情况

首次访问钥匙串时，或者如果没有存储任何值，`SecureState` 将返回 `nil`。确保您正确处理这种情况：

```swift
if let token = userToken {
    print("令牌: \(token)")
} else {
    print("没有可用的令牌。")
}
```

## 最佳实践

- **用于小数据**：钥匙串应用于存储小块敏感信息，如令牌、密码和密钥。
- **避免大数据集**：如果您需要安全地存储大数据集，请考虑使用基于文件的加密或其他方法，因为钥匙串不是为大数据存储而设计的。
- **处理 nil**：始终处理钥匙串在没有值时返回 `nil` 的情况。

---
该译文由机器自动生成，可能存在错误。如果您是母语使用者，我们期待您通过 Pull Request 提出修改建议。
