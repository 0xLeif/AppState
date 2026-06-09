# Использование ModelState

🍎 `ModelState` — это компонент библиотеки **AppState**, который позволяет управлять объектами SwiftData `@Model` через область видимости приложения. Он внедряет общий контейнер SwiftData `ModelContainer` в качестве зависимости, а также читает и записывает данные через `ModelContext` этого контейнера, предоставляя модели представлений, службам и другому коду, не относящемуся к представлениям, общий доступ к вашим моделям с внедрением зависимостей.

> 🍎 `ModelState` и зависимость SwiftData `ModelContainer` специфичны для платформ Apple, так как они зависят от фреймворка SwiftData от Apple.

## Ключевые особенности

- **Модели с внедрением зависимостей**: зарегистрируйте общий `ModelContainer` один раз и получайте доступ к его моделям в любом месте вашего приложения.
- **`ModelContext` на главном акторе**: получайте `mainContext` контейнера из любого кода, включая модели представлений и службы, не имеющие доступа к `@Environment` SwiftUI.
- **Удобство CRUD**: читайте, вставляйте, удаляйте, сохраняйте и сбрасывайте модели SwiftData через небольшой, узконаправленный API.
- **SwiftData как источник истины**: `ModelState` не кэширует результаты в кэше AppState — `ModelContext` SwiftData остается единственным источником истины.

## Требования и доступность

Функции SwiftData требуют более новых версий платформ, чем базовые требования AppState. Все API `ModelState` и `ModelContainer` ограничены условием `#if canImport(SwiftData)` и следующей доступностью:

- **iOS**: 17.0+
- **macOS**: 14.0+
- **tvOS**: 17.0+
- **watchOS**: 10.0+
- **visionOS**: 1.0+

На платформах или версиях ОС, где SwiftData недоступна, эти API не компилируются.

## Регистрация зависимости ModelContainer

`ModelContainer` из SwiftData соответствует `Sendable`, поэтому его можно хранить как обычную `Dependency` AppState. Определите его в расширении `Application` с помощью удобного метода `modelContainer(_:)`, который регистрирует контейнер с автоматически сгенерированным идентификатором и вычисляет автозамыкание только один раз:

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

## Доступ к ModelContext

После того как зависимость `ModelContainer` определена, вы можете получить доступ к общему, связанному с главным актором `ModelContext` в любом месте вашего приложения:

```swift
let context = Application.modelContext(\.modelContainer)
```

Это возвращает `mainContext` разрешенного `ModelContainer`, поэтому один и тот же контекст используется во всем вашем приложении.

## Определение ModelState

Определите `ModelState`, расширив объект `Application` и указав ему зависимость `ModelContainer`, которая его поддерживает. Без `FetchDescriptor` состояние соответствует всем моделям заданного типа:

```swift
import AppState
import SwiftData

extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

Вы также можете предоставить собственный `FetchDescriptor` (для фильтрации или сортировки) и явный `id`:

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

## Обертка свойства @ModelState

Обертка свойства `@ModelState` предоставляет коллекцию моделей из области видимости `Application`:

```swift
import AppState
import SwiftData

@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func addItem(title: String) {
        // Присваивание вставляет новые (еще не сохраненные) модели и сохраняет их.
        items = items + [Item(title: title)]
    }
}
```

- **Чтение** обернутого значения выполняет выборку с использованием `FetchDescriptor` состояния.
- **Присваивание** обернутому значению вставляет все модели из нового значения, которые еще не сохранены, и сохраняет поддерживающий контекст. Существующие модели, отсутствующие в новом значении, **не** удаляются — для удаления используйте `delete(_:)` или `reset()`.

### CRUD через проецируемое значение

Проецируемое значение (`$items`) предоставляет базовый `Application.ModelState<Item>`, давая вам явный контроль над вставками, удалениями и сохранениями:

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

## Чтение и изменение через Application.modelState

Вы также можете работать с `ModelState` напрямую через тип `Application`, без обертки свойства. Это удобно в службах и другом коде, не относящемся к представлениям:

```swift
@MainActor
func loadAndAppend() {
    let state = Application.modelState(\.items)

    // Чтение текущих моделей (выполняет выборку).
    let current = state.value

    // При необходимости получите прямой доступ к поддерживающему ModelContext.
    let context = state.context

    // Вставка, удаление и сохранение.
    state.insert(Item(title: "New item"))
    state.delete(current.first!)
    state.save()
}
```

Возвращаемый `ModelState` предоставляет:

- `value`: модели, в данный момент соответствующие `FetchDescriptor` состояния (чтение выполняет выборку; запись вставляет новые модели и сохраняет).
- `context`: поддерживающий `ModelContext` на главном акторе.
- `insert(_:)`: вставляет модель и сохраняет.
- `delete(_:)`: удаляет модель и сохраняет.
- `save()`: сохраняет все ожидающие изменения в контексте.

## Сброс

Чтобы удалить каждую модель, управляемую `ModelState`, используйте `Application.reset(modelState:)`:

```swift
Application.reset(modelState: \.items)
```

Это выбирает каждую модель, соответствующую `FetchDescriptor` состояния, удаляет ее и сохраняет контекст.

## Когда использовать ModelState, а когда SwiftData @Query

Изменения, сделанные через `ModelState` и `@ModelState`, **не** транслируются автоматически в SwiftUI. Это намеренное проектное решение:

- **Используйте собственный `@Query` SwiftData для реактивных представлений.** `@Query` наблюдает за `ModelContext` и автоматически обновляет ваше представление при изменении базовых данных. Сочетайте его с предоставляемым AppState `ModelContainer`, чтобы ваши представления и код, не относящийся к представлениям, использовали один и тот же контейнер:

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

  // Внедрите общий контейнер в окружение SwiftUI.
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

- **Используйте `ModelState` / `@ModelState` для моделей представлений, служб и другого кода, не относящегося к представлениям**, которому нужен общий доступ к вашим моделям с внедрением зависимостей. Это идеально подходит там, где `@Environment` и `@Query` SwiftUI недоступны, или где вы хотите выполнять операции над моделями вне кода представлений.

Также обратите внимание, что сеттер `value` вставляет только еще не сохраненные модели — он не удаляет модели, отсутствующие в новом значении. Для удаления моделей используйте `delete(_:)` или `reset(modelState:)`.

## Сквозной пример

Следующий пример показывает полный поток: `@Model`, расширения `Application`, регистрирующие контейнер и состояние модели, и модель представления, использующая `@ModelState`.

```swift
import AppState
import SwiftData
import SwiftUI

// 1. Определите модель SwiftData.
@Model
final class TodoItem {
    var title: String
    var isComplete: Bool

    init(title: String, isComplete: Bool = false) {
        self.title = title
        self.isComplete = isComplete
    }
}

// 2. Зарегистрируйте общий ModelContainer и ModelState в Application.
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

// 3. Используйте @ModelState из модели представления.
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

Для реактивного списка, привязанного к тем же данным, управляйте представлением с помощью `@Query` SwiftData, оставляя изменения в модели представления, как показано в разделе [Когда использовать ModelState, а когда SwiftData @Query](#когда-использовать-modelstate-а-когда-swiftdata-query) выше.

## Лучшие практики

- **Реактивные представления используют `@Query`**: зарезервируйте `@Query` SwiftData для представлений, которым необходимо обновляться автоматически, и используйте с ними общий `ModelContainer`, предоставляемый AppState.
- **Код, не относящийся к представлениям, использует `ModelState`**: используйте `@ModelState` и `Application.modelState` в моделях представлений, службах и фоновой логике, которым нужен общий доступ к моделям.
- **Явные удаления**: помните, что присваивание `value` только вставляет; для удаления моделей используйте `delete(_:)` или `reset(modelState:)`.
- **Один общий контейнер**: зарегистрируйте единственную зависимость `ModelContainer` и ссылайтесь на нее из ваших состояний модели и окружения SwiftUI, чтобы все читали и записывали в одно и то же хранилище.

## Заключение

`ModelState` привносит SwiftData в модель внедрения зависимостей **AppState**, позволяя вам совместно использовать единственный `ModelContainer` во всем вашем приложении и работать с объектами `@Model` из моделей представлений и служб. Для реактивного UI сочетайте его с `@Query` SwiftData и тем же общим контейнером.

---
Этот перевод был сгенерирован автоматически и может содержать ошибки. Если вы носитель языка, мы будем признательны за ваши исправления через Pull Request.
