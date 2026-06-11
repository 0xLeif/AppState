# Uso de ModelState

🍎 `ModelState` le permite gestionar objetos `@Model` de SwiftData a través del modelo de inyección de dependencias de AppState. Registre un `ModelContainer` compartido una vez; lea y escriba modelos desde cualquier lugar — view models, servicios u otro código que no es de vista — sin tener que pasar el `ModelContext` a través de su pila de llamadas.

> 🍎 `ModelState` requiere plataformas de Apple con soporte para SwiftData (iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS 1+). Estas API se excluyen de la compilación en Linux y Windows.

## Ejemplo de Extremo a Extremo

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

## Registro del ModelContainer

`modelContainer(_:)` registra el contenedor con un identificador generado automáticamente y evalúa el autoclosure solo una vez. Construya el contenedor en una función auxiliar en lugar de hacerlo en línea — así los fallos quedan explícitos:

```swift
extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }
}
```

## Definición de un ModelState

Sin un `FetchDescriptor`, el estado coincide con todos los modelos del tipo dado:

```swift
extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

Proporcione un `FetchDescriptor` para filtrar u ordenar:

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

## Lectura y Mutación

**A través de `@ModelState`** — lea el valor envuelto, mute a través de `$items`:

```swift
@ModelState(\.items) var items: [Item]

func add(_ item: Item) { $items.insert(item) }
func remove(_ item: Item) { $items.delete(item) }
func persist() { $items.save() }
```

**A través de `Application.modelState`** — útil en servicios y código que no es de vista:

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

> `models` realiza una búsqueda en vivo de SwiftData en cada lectura. Capture el resultado en una variable local cuando lo necesite más de una vez.

### API del Valor Proyectado

| Método | Comportamiento |
| --- | --- |
| `$items.insert(_:)` | Inserta un modelo y guarda |
| `$items.delete(_:)` | Elimina un modelo y guarda |
| `$items.save()` | Persiste los cambios pendientes |
| `$items.deleteAll()` | Elimina todos los modelos que coinciden con el `FetchDescriptor` y guarda |

Estos mutadores registran y descartan cualquier error subyacente de SwiftData para que los sitios de llamada se mantengan concisos. Cuando necesite exponer o recuperarse de una escritura fallida, recurra a las contrapartes que lanzan errores en `strict`:

```swift
do {
    try $items.strict.insert(item)
    try $items.strict.save()
} catch {
    // presentar el error, revertir, reintentar…
}
```

`strict` expone versiones que lanzan errores de los cuatro mutadores (`insert`, `delete`, `save`, `deleteAll`) respaldadas por el mismo contexto — elija la API tolerante cuando un fallo registrado sea aceptable, y `strict` cuando quien llama deba gestionarlo.

## Acceso al ModelContext

```swift
let context = Application.modelContext(\.modelContainer)
```

Devuelve el `mainContext` del `ModelContainer` resuelto — el mismo contexto usado por todas las lecturas y escrituras.

## ModelState vs el @Query de SwiftData

Las mutaciones de `ModelState` **no** se transmiten automáticamente a las vistas de SwiftUI. Esto es intencional.

- **Vistas reactivas** — use `@Query`. Observa el `ModelContext` directamente y actualiza la vista cuando cambian los datos. Comparta el contenedor proporcionado por AppState con el entorno de SwiftUI para que las vistas y el código que no es de vista usen el mismo almacén:

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

- **View models y servicios** — use `@ModelState` / `Application.modelState`. Ideal cuando `@Environment` y `@Query` no están disponibles, o cuando necesita operaciones de modelo fuera del código de vista.

## Notas

- Todas las lecturas y escrituras pasan por el `mainContext` del contenedor — mantenga los usos en el actor principal.
- `ModelState` no almacena en caché los resultados en la propia caché de AppState. El `ModelContext` de SwiftData es la fuente de verdad.
- Registre una sola dependencia `ModelContainer` y refiéralo desde todos los estados de modelo y el entorno de SwiftUI.

---
Esta traducción fue generada automáticamente y puede contener errores. Si eres un hablante nativo, te agradecemos que contribuyas con correcciones a través de un Pull Request.
