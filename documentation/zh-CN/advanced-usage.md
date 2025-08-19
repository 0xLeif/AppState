# AppState 的高级用法

本指南涵盖了使用 **AppState** 的高级主题，包括即时创建、预加载依赖项、有效管理状态和依赖项，以及将 **AppState** 与 **SwiftUI 的 Environment** 进行比较。

## 1. 即时创建

AppState 的值，例如 `State`、`Dependency`、`StoredState` 和 `SyncState`，是即时创建的。这意味着它们仅在首次访问时才被实例化，从而提高了应用程序的效率和性能。

### 示例

```swift
extension Application {
    var defaultState: State<Int> {
        state(initial: 0) // 该值直到被访问时才被创建
    }
}
```

在此示例中，`defaultState` 直到首次访问时才被创建，从而优化了资源使用。

## 2. 预加载依赖项

在某些情况下，您可能希望预加载某些依赖项，以确保它们在应用程序启动时可用。AppState 提供了一个 `load` 函数来预加载依赖项。

### 示例

```swift
extension Application {
    var databaseClient: Dependency<DatabaseClient> {
        dependency(DatabaseClient())
    }
}

// 在应用程序初始化时预加载
Application.load(dependency: \.databaseClient)
```

在此示例中，`databaseClient` 在应用程序初始化期间被预加载，确保在视图中需要时可用。

## 3. 状态和依赖项管理

### 3.1 在整个应用程序中共享状态和依赖项

您可以在应用程序的一部分中定义共享状态或依赖项，并使用唯一 ID 在另一部分中访问它们。

### 示例

```swift
private extension Application {
    var stateValue: State<Int> {
        state(initial: 0, id: "stateValue")
    }

    var dependencyValue: Dependency<SomeType> {
        dependency(SomeType(), id: "dependencyValue")
    }
}
```

这使您可以通过使用相同的 ID 在其他地方访问相同的 `State` 或 `Dependency`。

```swift
private extension Application {
    var theSameStateValue: State<Int> {
        state(initial: 0, id: "stateValue")
    }

    var theSameDependencyValue: Dependency<SomeType> {
        dependency(SomeType(), id: "dependencyValue")
    }
}
```

虽然这种通过重用相同的字符串 `id` 在整个应用程序中共享状态和依赖项的方法是有效的，但通常不鼓励这样做。它依赖于手动管理这些字符串 ID，这可能导致：
- 如果相同的 ID 用于不同的预期状态/依赖项，则会发生意外的 ID 冲突。
- 难以跟踪状态/依赖项的定义位置与访问位置。
- 降低了代码的清晰度和可维护性。
如果状态/依赖项已通过其首次访问进行了初始化，则在后续使用相同 ID 的定义中提供的 `initial` 值将被忽略。此行为更多是 AppState 中基于 ID 的缓存工作方式的副作用，而不是定义共享数据的推荐主要模式。首选在 `Application` 扩展中将状态和依赖项定义为唯一的计算属性（如果在工厂方法中未提供显式 `id`，则会自动生成唯一的内部 ID）。

### 3.2 受限的状态和依赖项访问

要限制访问，请使用像 UUID 这样的唯一 ID，以确保只有应用程序的正确部分才能访问特定的状态或依赖项。

### 示例

```swift
private extension Application {
    var restrictedState: State<Int?> {
        state(initial: nil, id: UUID().uuidString)
    }

    var restrictedDependency: Dependency<SomeType> {
        dependency(SomeType(), id: UUID().uuidString)
    }
}
```

### 3.3 状态和依赖项的唯一 ID

当未提供 ID 时，AppState 会根据源代码中的位置生成默认 ID。这确保了每个 `State` 或 `Dependency` 都是唯一的，并受到保护，防止意外访问。

### 示例

```swift
extension Application {
    var defaultState: State<Int> {
        state(initial: 0) // AppState 生成一个唯一的 ID
    }

    var defaultDependency: Dependency<SomeType> {
        dependency(SomeType()) // AppState 生成一个唯一的 ID
    }
}
```

### 3.4 文件私有状态和依赖项访问

为了在同一个 Swift 文件中实现更严格的访问限制，请使用 `fileprivate` 访问级别来保护状态和依赖项不被外部访问。

### 示例

```swift
fileprivate extension Application {
    var fileprivateState: State<Int> {
        state(initial: 0)
    }

    var fileprivateDependency: Dependency<SomeType> {
        dependency(SomeType())
    }
}
```

### 3.5 理解 AppState 的存储机制

AppState 使用统一的缓存来存储 `State`、`Dependency`、`StoredState` 和 `SyncState`。这确保了这些数据类型在您的应用程序中得到有效管理。

默认情况下，AppState 将名称值指定为“App”，这确保了与模块关联的所有值都与该名称绑定。这使得从其他模块访问这些状态和依赖项变得更加困难。

## 4. AppState 与 SwiftUI 的 Environment

AppState 和 SwiftUI 的 Environment 都提供了在应用程序中管理共享状态和依赖项的方法，但它们在范围、功能和用例上有所不同。

### 4.1 SwiftUI 的 Environment

SwiftUI 的 Environment 是一种内置机制，允许您通过视图层次结构向下传递共享数据。它非常适合传递许多视图需要访问的数据，但在更复杂的状态管理方面存在局限性。

**优点：**
- 使用简单，与 SwiftUI 集成良好。
- 非常适合需要在层次结构中的多个视图之间共享的轻量级数据。

**局限性：**
- 数据仅在特定的视图层次结构中可用。在没有额外工作的情况下，无法跨不同的视图层次结构访问相同的数据。
- 与 AppState 相比，对线程安全和持久性的控制较少。
- 缺乏内置的持久性或同步机制。

### 4.2 AppState

AppState 为在整个应用程序中管理状态提供了一个更强大、更灵活的系统，具有线程安全、持久性和依赖项注入功能。

**优点：**
- 集中式状态管理，可在整个应用程序中访问，而不仅仅是在特定的视图层次结构中。
- 内置的持久性机制（`StoredState`、`FileState` 和 `SyncState`）。
- 类型安全和线程安全保证，确保状态被正确访问和修改。
- 可以处理更复杂的状态和依赖项管理。

**局限性：**
- 与 SwiftUI 的 Environment 相比，需要更多的设置和配置。
- 与 Environment 相比，与 SwiftUI 的集成程度稍差，但在 SwiftUI 应用程序中仍然运行良好。

### 4.3 何时使用

- 当您有需要在视图层次结构中共享的简单数据（例如用户设置或主题首选项）时，请使用 **SwiftUI 的 Environment**。
- 当您需要集中式状态管理、持久性或需要在整个应用程序中访问的更复杂的状态时，请使用 **AppState**。

## 结论

通过使用这些高级技术，例如即时创建、预加载、状态和依赖项管理，以及理解 AppState 和 SwiftUI 的 Environment 之间的差异，您可以使用 **AppState** 构建高效且资源节约的应用程序。
