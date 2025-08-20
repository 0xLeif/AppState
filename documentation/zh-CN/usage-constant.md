# 常量用法

**AppState** 库中的 `Constant` 提供了对应用程序状态中值的只读访问。它的工作方式类似于 `Slice`，但确保所访问的值是不可变的。这使得 `Constant` 非常适合访问在某些上下文中应保持只读但在其他地方可能是可变的值。

## 主要功能

- **只读访问**：常量提供对可变状态的访问，但值不能被修改。
- **作用域限定于应用程序**：与 `Slice` 一样，`Constant` 在 `Application` 扩展中定义，并作用域限定于访问状态的特定部分。
- **线程安全**：`Constant` 确保在并发环境中安全地访问状态。

## 用法示例

### 在应用程序中定义常量

以下是如何在 `Application` 扩展中定义 `Constant` 以访问只读值：

```swift
import AppState
import SwiftUI

struct ExampleValue {
    var username: String?
    var isLoading: Bool
    let value: String
    var mutableValue: String
}

extension Application {
    var exampleValue: State<ExampleValue> {
        state(
            initial: ExampleValue(
                username: "Leif",
                isLoading: false,
                value: "value",
                mutableValue: ""
            )
        )
    }
}
```

### 在 SwiftUI 视图中访问常量

在 SwiftUI 视图中，您可以使用 `@Constant` 属性包装器以只读方式访问常量状态：

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.exampleValue, \.value) var constantValue: String

    var body: some View {
        Text("常量值: \(constantValue)")
    }
}
```

### 对可变状态的只读访问

即使该值在其他地方是可变的，当通过 `@Constant` 访问时，该值也变为不可变的：

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.exampleValue, \.mutableValue) var constantMutableValue: String

    var body: some View {
        Text("只读可变值: \(constantMutableValue)")
    }
}
```

## 最佳实践

- **用于只读访问**：使用 `Constant` 访问在某些上下文中不应修改的状态部分，即使它们在其他地方是可变的。
- **线程安全**：与其他 AppState 组件一样，`Constant` 确保对状态的线程安全访问。
- **对可选值使用 `OptionalConstant`**：如果您正在访问的状态部分可能为 `nil`，请使用 `OptionalConstant` 来安全地处理值的缺失。

## 结论

`Constant` 和 `OptionalConstant` 提供了一种以只读方式访问应用程序状态特定部分的有效方法。它们确保在视图中访问时，可能在其他地方是可变的值被视为不可变的，从而确保代码的安全性和清晰性。

---
这是使用 Jules 生成的，可能会出现错误。如果您是母语人士，请提出包含任何应有修复的拉取请求。
