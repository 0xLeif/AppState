# Uso de ModelState

🍎 `ModelState` es un componente de la biblioteca **AppState** que le permite gestionar objetos `@Model` de SwiftData a través del alcance de la aplicación. Inyecta un `ModelContainer` compartido de SwiftData como una dependencia y lee y escribe en el `ModelContext` de ese contenedor, brindando a los view models, servicios y otro código que no es de vista un acceso compartido e inyectado por dependencias a sus modelos.

> 🍎 `ModelState` y la dependencia `ModelContainer` de SwiftData son específicos de las plataformas de Apple, ya que dependen del framework SwiftData de Apple.

## Características Clave

- **Modelos Inyectados por Dependencias**: Registre un `ModelContainer` compartido una vez y acceda a sus modelos en cualquier parte de su aplicación.
- **`ModelContext` en el Actor Principal**: Recupere el `mainContext` del contenedor desde cualquier código, incluidos los view models y servicios que no tienen acceso al `@Environment` de SwiftUI.
- **Conveniencia CRUD**: Lea, inserte, elimine, guarde y restablezca modelos de SwiftData a través de una API pequeña y enfocada.
- **SwiftData como Fuente de Verdad**: `ModelState` no almacena en caché los resultados en la caché de AppState — el `ModelContext` de SwiftData sigue siendo la única fuente de verdad.

## Requisitos y Disponibilidad

Las características de SwiftData requieren versiones de plataforma más nuevas que los requisitos base de AppState. Todas las API de `ModelState` y `ModelContainer` están protegidas detrás de `#if canImport(SwiftData)` y la siguiente disponibilidad:

- **iOS**: 17.0+
- **macOS**: 14.0+
- **tvOS**: 17.0+
- **watchOS**: 10.0+
- **visionOS**: 1.0+

En plataformas o versiones de SO donde SwiftData no está disponible, estas API no se compilan.

## Registro de la Dependencia ModelContainer

El `ModelContainer` de SwiftData es `Sendable`, por lo que puede almacenarse como una `Dependency` normal de AppState. Defina uno en una extensión de `Application` usando la conveniencia `modelContainer(_:)`, que registra el contenedor con un identificador generado automáticamente y evalúa el autoclosure solo una vez:

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

## Acceso al ModelContext

Una vez que se define una dependencia `ModelContainer`, puede acceder al `ModelContext` compartido y vinculado al actor principal en cualquier parte de su aplicación:

```swift
let context = Application.modelContext(\.modelContainer)
```

Esto devuelve el `mainContext` del `ModelContainer` resuelto, por lo que el mismo contexto se comparte en toda su aplicación.

## Definición de un ModelState

Defina un `ModelState` extendiendo el objeto `Application` y apuntándolo a la dependencia `ModelContainer` que lo respalda. Sin un `FetchDescriptor`, el estado coincide con todos los modelos del tipo dado:

```swift
import AppState
import SwiftData

extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

También puede proporcionar un `FetchDescriptor` personalizado (para filtrar u ordenar) y un `id` explícito:

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

## El Property Wrapper @ModelState

El property wrapper `@ModelState` expone una colección de modelos desde el alcance de `Application`:

```swift
import AppState
import SwiftData

@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func addItem(title: String) {
        // Asignar inserta modelos nuevos (aún no persistidos) y guarda.
        items = items + [Item(title: title)]
    }
}
```

- **Leer** el valor envuelto realiza una búsqueda usando el `FetchDescriptor` del estado.
- **Asignar** al valor envuelto inserta cualquier modelo en el nuevo valor que aún no esté persistido y guarda el contexto de respaldo. Los modelos existentes que están ausentes del nuevo valor **no** se eliminan — use `delete(_:)` o `reset()` para eliminarlos.

### CRUD a través del Valor Proyectado

El valor proyectado (`$items`) expone el `Application.ModelState<Item>` subyacente, brindándole control explícito sobre las inserciones, eliminaciones y guardados:

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

## Lectura y Mutación a través de Application.modelState

También puede trabajar con el `ModelState` directamente a través del tipo `Application`, sin un property wrapper. Esto es conveniente en servicios y otro código que no es de vista:

```swift
@MainActor
func loadAndAppend() {
    let state = Application.modelState(\.items)

    // Lee los modelos actuales (realiza una búsqueda).
    let current = state.value

    // Accede directamente al ModelContext de respaldo si es necesario.
    let context = state.context

    // Inserta, elimina y guarda.
    state.insert(Item(title: "New item"))
    state.delete(current.first!)
    state.save()
}
```

El `ModelState` devuelto expone:

- `value`: los modelos que actualmente coinciden con el `FetchDescriptor` del estado (al obtenerlo realiza una búsqueda; al asignarlo inserta nuevos modelos y guarda).
- `context`: el `ModelContext` de respaldo vinculado al actor principal.
- `insert(_:)`: inserta un modelo y guarda.
- `delete(_:)`: elimina un modelo y guarda.
- `save()`: persiste cualquier cambio pendiente en el contexto.

## Restablecimiento

Para eliminar todos los modelos gestionados por un `ModelState`, use `Application.reset(modelState:)`:

```swift
Application.reset(modelState: \.items)
```

Esto obtiene todos los modelos que coinciden con el `FetchDescriptor` del estado, los elimina y guarda el contexto.

## Cuándo Usar ModelState vs el @Query de SwiftData

Las mutaciones realizadas a través de `ModelState` y `@ModelState` **no** se transmiten automáticamente a SwiftUI. Esta es una decisión de diseño intencional:

- **Use el propio `@Query` de SwiftData para vistas reactivas.** `@Query` observa el `ModelContext` y actualiza automáticamente su vista cuando cambian los datos subyacentes. Combínelo con el `ModelContainer` proporcionado por AppState para que sus vistas y su código que no es de vista compartan el mismo contenedor:

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

  // Inyecta el contenedor compartido en el entorno de SwiftUI.
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

- **Use `ModelState` / `@ModelState` para view models, servicios y otro código que no es de vista** que necesite un acceso compartido e inyectado por dependencias a sus modelos. Es ideal donde el `@Environment` y `@Query` de SwiftUI no están disponibles, o donde desea realizar operaciones de modelo fuera del código de vista.

Tenga en cuenta también que el setter de `value` solo inserta modelos aún no persistidos — no elimina los modelos que están ausentes del nuevo valor. Use `delete(_:)` o `reset(modelState:)` para eliminar modelos.

## Ejemplo de Extremo a Extremo

El siguiente ejemplo muestra un flujo completo: un `@Model`, las extensiones de `Application` que registran el contenedor y el estado del modelo, y un view model que usa `@ModelState`.

```swift
import AppState
import SwiftData
import SwiftUI

// 1. Define el modelo de SwiftData.
@Model
final class TodoItem {
    var title: String
    var isComplete: Bool

    init(title: String, isComplete: Bool = false) {
        self.title = title
        self.isComplete = isComplete
    }
}

// 2. Registra el ModelContainer compartido y un ModelState en Application.
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

// 3. Usa @ModelState desde un view model.
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

Para una lista reactiva vinculada a los mismos datos, controle la vista con el `@Query` de SwiftData mientras mantiene las mutaciones en el view model, como se muestra en la sección [Cuándo Usar ModelState vs el @Query de SwiftData](#cuándo-usar-modelstate-vs-el-query-de-swiftdata) anterior.

## Mejores Prácticas

- **Las Vistas Reactivas Usan `@Query`**: Reserve el `@Query` de SwiftData para las vistas que necesitan actualizarse automáticamente, y comparta con ellas el `ModelContainer` proporcionado por AppState.
- **El Código que No es de Vista Usa `ModelState`**: Use `@ModelState` y `Application.modelState` en view models, servicios y lógica en segundo plano que necesiten acceso compartido a los modelos.
- **Eliminaciones Explícitas**: Recuerde que asignar a `value` solo inserta; use `delete(_:)` o `reset(modelState:)` para eliminar modelos.
- **Un Único Contenedor Compartido**: Registre una sola dependencia `ModelContainer` y refiéralo desde sus estados de modelo y el entorno de SwiftUI para que todo lea y escriba en el mismo almacén.

## Conclusión

`ModelState` lleva SwiftData al modelo de inyección de dependencias de **AppState**, permitiéndole compartir un único `ModelContainer` en toda su aplicación y trabajar con objetos `@Model` desde view models y servicios. Para una interfaz de usuario reactiva, combínelo con el `@Query` de SwiftData y el mismo contenedor compartido.

---
Esta traducción fue generada automáticamente y puede contener errores. Si eres un hablante nativo, te agradecemos que contribuyas con correcciones a través de un Pull Request.
