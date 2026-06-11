# ModelState 用法

🍎 `ModelState` 让你通过 AppState 的依赖注入模型来管理 SwiftData 的 `@Model` 对象。只需注册一次共享的 `ModelContainer`；即可在任何地方 —— 视图模型、服务或其他非视图代码 —— 读写模型，而无需将 `ModelContext` 沿调用栈层层传递。

> 🍎 `ModelState` 需要支持 SwiftData 的苹果平台（iOS 17+、macOS 14+、tvOS 17+、watchOS 10+、visionOS 1+）。这些 API 在 Linux 和 Windows 上会被编译排除。

## 端到端示例

```swift
import AppState
import SwiftData
import SwiftUI

// 1. Define the model.
@Model
final class TodoItem {
    var title: String
    var isComplete: Bool

    init(title: String, isComplete: Bool = false) {
        self.title = title
        self.isComplete = isComplete
    }
}

// 2. Register the shared container and a ModelState on Application.
private func makeModelContainer() -> ModelContainer {
    do {
        return try ModelContainer(for: TodoItem.self)
    } catch {
        fatalError("Failed to create ModelContainer: \(error)")
    }
}

extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }

    var todoItems: ModelState<TodoItem> {
        modelState(
            container: \.modelContainer,
            fetchDescriptor: FetchDescriptor<TodoItem>(
                sortBy: [SortDescriptor(\.title)]
            ),
            id: "todoItems"
        )
    }
}

// 3. Use @ModelState from a view model.
@MainActor
final class TodoListViewModel: ObservableObject {
    @ModelState(\.todoItems) var todoItems: [TodoItem]

    func add(title: String) {
        $todoItems.insert(TodoItem(title: title))
    }

    func toggle(_ item: TodoItem) {
        item.isComplete.toggle()
        $todoItems.save()
    }

    func remove(_ item: TodoItem) {
        $todoItems.delete(item)
    }

    func clearAll() {
        $todoItems.deleteAll()
    }
}
```

## 注册 ModelContainer

`modelContainer(_:)` 使用自动生成的标识符注册容器，并且只对 autoclosure 求值一次。请在辅助函数中构建容器，而不是内联构建 —— 这能让失败更明确：

```swift
extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }
}
```

## 定义 ModelState

不提供 `FetchDescriptor` 时，该状态会匹配给定类型的所有模型：

```swift
extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

提供 `FetchDescriptor` 以进行筛选或排序：

```swift
extension Application {
    var items: ModelState<Item> {
        modelState(
            container: \.modelContainer,
            fetchDescriptor: FetchDescriptor<Item>(
                sortBy: [SortDescriptor(\.title)]
            ),
            id: "items"
        )
    }
}
```

## 读取与修改

**通过 `@ModelState`** —— 读取被包装的值，通过 `$items` 进行修改：

```swift
@ModelState(\.items) var items: [Item]

func add(_ item: Item) { $items.insert(item) }
func remove(_ item: Item) { $items.delete(item) }
func persist() { $items.save() }
```

**通过 `Application.modelState`** —— 在服务和非视图代码中很有用：

```swift
@MainActor
func syncItems() {
    let state = Application.modelState(\.items)
    let current = state.models
    state.insert(Item(title: "New"))
    state.delete(current.first!)
    state.save()
}
```

> `models` 在每次读取时都会执行一次实时的 SwiftData 抓取。如果需要多次使用，请将结果捕获到局部变量中。

### 投影值 API

| 方法 | 行为 |
| --- | --- |
| `$items.insert(_:)` | 插入一个模型并保存 |
| `$items.delete(_:)` | 删除一个模型并保存 |
| `$items.save()` | 持久化待处理的更改 |
| `$items.deleteAll()` | 删除所有匹配 `FetchDescriptor` 的模型并保存 |

## 访问 ModelContext

```swift
let context = Application.modelContext(\.modelContainer)
```

返回已解析的 `ModelContainer` 的 `mainContext` —— 即所有读写操作所使用的同一个上下文。

## ModelState 与 SwiftData @Query 的对比

`ModelState` 的修改**不会**自动广播到 SwiftUI 视图。这是有意为之的设计。

- **响应式视图** —— 使用 `@Query`。它直接观察 `ModelContext`，并在数据变化时刷新视图。请将 AppState 提供的容器与 SwiftUI 环境共享，使视图和非视图代码使用同一个存储：

  ```swift
  @main
  struct MyApp: App {
      var body: some Scene {
          WindowGroup {
              ItemsView()
          }
          .modelContainer(Application.dependency(\.modelContainer))
      }
  }

  struct ItemsView: View {
      @Query(sort: \Item.title) private var items: [Item]

      var body: some View {
          List(items) { Text($0.title) }
      }
  }
  ```

- **视图模型与服务** —— 使用 `@ModelState` / `Application.modelState`。当 `@Environment` 和 `@Query` 不可用，或需要在视图代码之外执行模型操作时，这是理想之选。

## 注意事项

- 所有读写都经由容器的 `mainContext` —— 请将使用保持在主 actor 上。
- `ModelState` 不会在 AppState 自身的缓存中缓存结果。SwiftData 的 `ModelContext` 才是事实来源。
- 注册单个 `ModelContainer` 依赖，并从所有 model state 和 SwiftUI 环境中引用它。

---
该译文由机器自动生成，可能存在错误。如果您是母语使用者，我们期待您通过 Pull Request 提出修改建议。
