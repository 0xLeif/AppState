# ModelState 用法

🍎 `ModelState` 是 **AppState** 库的一个组件，允许您通过应用程序范围管理 SwiftData 的 `@Model` 对象。它将共享的 SwiftData `ModelContainer` 作为依赖项注入，并从该容器的 `ModelContext` 中读取和写入，从而为视图模型、服务以及其他非视图代码提供共享的、依赖注入式的模型访问。

> 🍎 `ModelState` 和 SwiftData 的 `ModelContainer` 依赖项是苹果平台特有的，因为它们依赖于苹果的 SwiftData 框架。

## 主要功能

- **依赖注入式模型**：注册一次共享的 `ModelContainer`，即可在应用程序中的任何位置访问其模型。
- **主 Actor 的 `ModelContext`**：从任何代码中获取容器的 `mainContext`，包括无法访问 SwiftUI `@Environment` 的视图模型和服务。
- **便捷的 CRUD**：通过一个小巧、专注的 API 读取、插入、删除、保存和重置 SwiftData 模型。
- **以 SwiftData 作为唯一数据源**：`ModelState` 不会将结果缓存在 AppState 的缓存中——SwiftData 的 `ModelContext` 仍然是唯一的数据源。

## 要求与可用性

SwiftData 功能要求的平台版本高于 AppState 的基础要求。所有 `ModelState` 和 `ModelContainer` API 都受 `#if canImport(SwiftData)` 以及以下可用性的限制：

- **iOS**：17.0+
- **macOS**：14.0+
- **tvOS**：17.0+
- **watchOS**：10.0+
- **visionOS**：1.0+

在 SwiftData 不可用的平台或操作系统版本上，这些 API 不会被编译进来。

## 注册 ModelContainer 依赖项

SwiftData 的 `ModelContainer` 是 `Sendable` 的，因此可以作为常规的 AppState `Dependency` 存储。使用 `modelContainer(_:)` 便捷方法在 `Application` 扩展上定义一个容器，该方法会使用自动生成的标识符注册容器，并且只对 autoclosure 求值一次：

```swift
import AppState
import SwiftData

extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(
            try! ModelContainer(for: Item.self)
        )
    }
}
```

## 访问 ModelContext

定义了 `ModelContainer` 依赖项后，您可以在应用程序中的任何位置访问共享的、绑定到主 Actor 的 `ModelContext`：

```swift
let context = Application.modelContext(\.modelContainer)
```

这会返回已解析的 `ModelContainer` 的 `mainContext`，因此整个应用程序共享同一个上下文。

## 定义 ModelState

通过扩展 `Application` 对象并将其指向支撑它的 `ModelContainer` 依赖项来定义 `ModelState`。在没有 `FetchDescriptor` 的情况下，该状态会匹配给定类型的所有模型：

```swift
import AppState
import SwiftData

extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

您还可以提供自定义的 `FetchDescriptor`（用于过滤或排序）和一个显式的 `id`：

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

## @ModelState 属性包装器

`@ModelState` 属性包装器从 `Application` 的范围中公开一组模型：

```swift
import AppState
import SwiftData

@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func addItem(title: String) {
        // 赋值会插入新的（尚未持久化的）模型并保存。
        items = items + [Item(title: title)]
    }
}
```

- **读取**被包装的值会使用该状态的 `FetchDescriptor` 执行一次提取。
- **赋值**给被包装的值会插入新值中尚未持久化的所有模型，并保存支撑上下文。新值中不存在的现有模型**不会**被删除——请使用 `delete(_:)` 或 `reset()` 来移除。

### 通过投影值进行 CRUD

投影值（`$items`）公开了底层的 `Application.ModelState<Item>`，让您可以显式控制插入、删除和保存：

```swift
@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func add(_ item: Item) {
        $items.insert(item)
    }

    func remove(_ item: Item) {
        $items.delete(item)
    }

    func persistPendingChanges() {
        $items.save()
    }
}
```

## 通过 Application.modelState 读取和修改

您也可以直接通过 `Application` 类型使用 `ModelState`，而无需属性包装器。这在服务和其他非视图代码中非常方便：

```swift
@MainActor
func loadAndAppend() {
    let state = Application.modelState(\.items)

    // 读取当前模型（执行一次提取）。
    let current = state.value

    // 如果需要，可直接访问支撑的 ModelContext。
    let context = state.context

    // 插入、删除和保存。
    state.insert(Item(title: "New item"))
    state.delete(current.first!)
    state.save()
}
```

返回的 `ModelState` 公开了：

- `value`：当前匹配该状态 `FetchDescriptor` 的模型（读取时会提取；设置时会插入新模型并保存）。
- `context`：支撑的主 Actor `ModelContext`。
- `insert(_:)`：插入一个模型并保存。
- `delete(_:)`：删除一个模型并保存。
- `save()`：持久化上下文中任何待处理的更改。

## 重置

要删除由某个 `ModelState` 管理的所有模型，请使用 `Application.reset(modelState:)`：

```swift
Application.reset(modelState: \.items)
```

这会提取所有匹配该状态 `FetchDescriptor` 的模型，将其删除，并保存上下文。

## 何时使用 ModelState 与 SwiftData @Query

通过 `ModelState` 和 `@ModelState` 进行的修改**不会**自动广播到 SwiftUI。这是一个有意为之的设计选择：

- **对响应式视图使用 SwiftData 自己的 `@Query`。** `@Query` 会观察 `ModelContext`，并在底层数据更改时自动刷新您的视图。将其与 AppState 提供的 `ModelContainer` 结合使用，以便您的视图和非视图代码共享同一个容器：

  ```swift
  import SwiftData
  import SwiftUI

  struct ItemsView: View {
      @Query(sort: \Item.title) private var items: [Item]

      var body: some View {
          List(items) { item in
              Text(item.title)
          }
      }
  }

  // 将共享容器注入 SwiftUI 环境。
  @main
  struct MyApp: App {
      var body: some Scene {
          WindowGroup {
              ItemsView()
          }
          .modelContainer(Application.dependency(\.modelContainer))
      }
  }
  ```

- **对视图模型、服务以及其他非视图代码使用 `ModelState` / `@ModelState`**，这些代码需要共享的、依赖注入式的模型访问。它非常适合 SwiftUI 的 `@Environment` 和 `@Query` 不可用的场景，或者您希望在视图代码之外执行模型操作的场景。

另请注意，`value` 设置器只会插入尚未持久化的模型——它不会删除新值中不存在的模型。请使用 `delete(_:)` 或 `reset(modelState:)` 来移除模型。

## 端到端示例

以下示例展示了一个完整的流程：一个 `@Model`、用于注册容器和模型状态的 `Application` 扩展，以及一个使用 `@ModelState` 的视图模型。

```swift
import AppState
import SwiftData
import SwiftUI

// 1. 定义 SwiftData 模型。
@Model
final class TodoItem {
    var title: String
    var isComplete: Bool

    init(title: String, isComplete: Bool = false) {
        self.title = title
        self.isComplete = isComplete
    }
}

// 2. 在 Application 上注册共享的 ModelContainer 和一个 ModelState。
extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(
            try! ModelContainer(for: TodoItem.self)
        )
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

// 3. 在视图模型中使用 @ModelState。
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
        Application.reset(modelState: \.todoItems)
    }
}
```

要将响应式列表绑定到相同的数据，请使用 SwiftData 的 `@Query` 驱动视图，同时将修改保留在视图模型中，如上文[何时使用 ModelState 与 SwiftData @Query](#何时使用-modelstate-与-swiftdata-query) 部分所示。

## 最佳实践

- **响应式视图使用 `@Query`**：将 SwiftData 的 `@Query` 保留给需要自动更新的视图，并与它们共享 AppState 提供的 `ModelContainer`。
- **非视图代码使用 `ModelState`**：在需要共享模型访问的视图模型、服务和后台逻辑中使用 `@ModelState` 和 `Application.modelState`。
- **显式删除**：请记住，赋值给 `value` 只会插入；请使用 `delete(_:)` 或 `reset(modelState:)` 来移除模型。
- **一个共享容器**：注册单个 `ModelContainer` 依赖项，并从您的模型状态和 SwiftUI 环境中引用它，以便所有内容读取和写入同一个存储。

## 结论

`ModelState` 将 SwiftData 引入了 **AppState** 的依赖注入模型，让您可以在整个应用程序中共享单个 `ModelContainer`，并从视图模型和服务中操作 `@Model` 对象。对于响应式 UI，请将其与 SwiftData 的 `@Query` 和相同的共享容器配对使用。

---
该译文由机器自动生成，可能存在错误。如果您是母语使用者，我们期待您通过 Pull Request 提出修改建议。
