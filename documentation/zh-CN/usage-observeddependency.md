# ObservedDependency 用法

`ObservedDependency` 是 **AppState** 库的一个组件，允许您使用符合 `ObservableObject` 的依赖项。当您希望依赖项通知您的 SwiftUI 视图有关更改时，这非常有用，使您的视图具有反应性和动态性。

## 主要功能

- **可观察的依赖项**：使用符合 `ObservableObject` 的依赖项，允许依赖项在其状态更改时自动更新您的视图。
- **反应式 UI 更新**：当观察到的依赖项发布更改时，SwiftUI 视图会自动更新。
- **线程安全**：与其他 AppState 组件一样，`ObservedDependency` 确保对观察到的依赖项进行线程安全的访问。

## 用法示例

### 定义可观察的依赖项

以下是如何在 `Application` 扩展中将可观察的服务定义为依赖项：

```swift
import AppState
import SwiftUI

@MainActor
class ObservableService: ObservableObject {
    @Published var count: Int = 0
}

extension Application {
    @MainActor
    var observableService: Dependency<ObservableService> {
        dependency(ObservableService())
    }
}
```

### 在 SwiftUI 视图中使用观察到的依赖项

在您的 SwiftUI 视图中，您可以使用 `@ObservedDependency` 属性包装器访问可观察的依赖项。观察到的对象在其状态更改时会自动更新视图。

```swift
import AppState
import SwiftUI

struct ObservedDependencyExampleView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        VStack {
            Text("计数: \(service.count)")
            Button("增加计数") {
                service.count += 1
            }
        }
    }
}
```

### 测试用例

以下测试用例演示了与 `ObservedDependency` 的交互：

```swift
import XCTest
@testable import AppState

@MainActor
fileprivate class ObservableService: ObservableObject {
    @Published var count: Int

    init() {
        count = 0
    }
}

fileprivate extension Application {
    @MainActor
    var observableService: Dependency<ObservableService> {
        dependency(ObservableService())
    }
}

@MainActor
fileprivate struct ExampleDependencyWrapper {
    @ObservedDependency(\.observableService) var service

    func test() {
        service.count += 1
    }
}

final class ObservedDependencyTests: XCTestCase {
    @MainActor
    func testDependency() async {
        let example = ExampleDependencyWrapper()

        XCTAssertEqual(example.service.count, 0)

        example.test()

        XCTAssertEqual(example.service.count, 1)
    }
}
```

### 反应式 UI 更新

由于依赖项符合 `ObservableObject`，因此对其状态的任何更改都将触发 SwiftUI 视图中的 UI 更新。您可以将状态直接绑定到 UI 元素，例如 `Picker`：

```swift
import AppState
import SwiftUI

struct ReactiveView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        Picker("选择计数", selection: $service.count) {
            ForEach(0..<10) { count in
                Text("\(count)").tag(count)
            }
        }
    }
}
```

## 最佳实践

- **用于可观察的服务**：当您的依赖项需要通知视图有关更改时，`ObservedDependency` 是理想的选择，特别是对于提供数据或状态更新的服务。
- **利用已发布的属性**：确保您的依赖项使用 `@Published` 属性来触发 SwiftUI 视图中的更新。
- **线程安全**：与其他 AppState 组件一样，`ObservedDependency` 确保对可观察服务的线程安全访问和修改。

## 结论

`ObservedDependency` 是在您的应用程序中管理可观察依赖项的强大工具。通过利用 Swift 的 `ObservableObject` 协议，它确保您的 SwiftUI 视图保持反应性并与服务或资源中的更改保持同步。

---
这是使用 Jules 生成的，可能会出现错误。如果您是母语人士，请提出包含任何应有修复的拉取请求。
