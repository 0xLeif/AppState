# Использование ModelState

🍎 `ModelState` позволяет управлять объектами SwiftData `@Model` через модель внедрения зависимостей AppState. Зарегистрируйте общий `ModelContainer` один раз; читайте и записывайте модели откуда угодно — из моделей представлений, служб или другого кода, не относящегося к представлениям — без необходимости пробрасывать `ModelContext` через стек вызовов.

> 🍎 `ModelState` требует платформ Apple с поддержкой SwiftData (iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS 1+). На Linux и Windows эти API не компилируются.

## Сквозной пример

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

## Регистрация ModelContainer

`modelContainer(_:)` регистрирует контейнер с автоматически сгенерированным идентификатором и вычисляет автозамыкание только один раз. Создавайте контейнер во вспомогательной функции, а не встраивайте его — это делает ошибки явными:

```swift
extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }
}
```

## Определение ModelState

Без `FetchDescriptor` состояние соответствует всем моделям заданного типа:

```swift
extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

Передайте `FetchDescriptor` для фильтрации или сортировки:

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

## Чтение и изменение

**Через `@ModelState`** — читайте обернутое значение, изменяйте через `$items`:

```swift
@ModelState(\.items) var items: [Item]

func add(_ item: Item) { $items.insert(item) }
func remove(_ item: Item) { $items.delete(item) }
func persist() { $items.save() }
```

**Через `Application.modelState`** — удобно в службах и коде, не относящемся к представлениям:

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

> `models` выполняет «живую» выборку SwiftData при каждом чтении. Сохраняйте результат в локальной переменной, когда он нужен более одного раза.

### API проецируемого значения

| Метод | Поведение |
| --- | --- |
| `$items.insert(_:)` | Вставляет модель и сохраняет |
| `$items.delete(_:)` | Удаляет модель и сохраняет |
| `$items.save()` | Сохраняет ожидающие изменения |
| `$items.deleteAll()` | Удаляет все модели, соответствующие `FetchDescriptor`, и сохраняет |

Эти методы изменения логируют и поглощают любую внутреннюю ошибку SwiftData, чтобы места вызова оставались лаконичными. Когда вам нужно показать сбой записи или восстановиться после него, используйте бросающие исключения аналоги в `strict`:

```swift
do {
    try $items.strict.insert(item)
    try $items.strict.save()
} catch {
    // показать ошибку, откатить, повторить…
}
```

`strict` предоставляет бросающие исключения версии всех четырёх методов изменения (`insert`, `delete`, `save`, `deleteAll`), опирающиеся на тот же контекст — выбирайте мягкий API, когда залогированный сбой допустим, и `strict`, когда вызывающая сторона обязана его обработать.

## Доступ к ModelContext

```swift
let context = Application.modelContext(\.modelContainer)
```

Возвращает `mainContext` разрешённого `ModelContainer` — тот же контекст, который используется для всех чтений и записей.

## ModelState против SwiftData @Query

Изменения `ModelState` **не** транслируются автоматически в представления SwiftUI. Это сделано намеренно.

- **Реактивные представления** — используйте `@Query`. Он наблюдает за `ModelContext` напрямую и обновляет представление при изменении данных. Передайте предоставляемый AppState контейнер в окружение SwiftUI, чтобы представления и код, не относящийся к представлениям, использовали одно и то же хранилище:

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

- **Модели представлений и службы** — используйте `@ModelState` / `Application.modelState`. Идеально подходит там, где `@Environment` и `@Query` недоступны, или когда операции над моделями нужны вне кода представлений.

## Примечания

- Все чтения и записи проходят через `mainContext` контейнера — держите использование на главном акторе.
- `ModelState` не кэширует результаты в собственном кэше AppState. `ModelContext` SwiftData является источником истины.
- Регистрируйте единственную зависимость `ModelContainer` и ссылайтесь на неё из всех состояний модели и окружения SwiftUI.
