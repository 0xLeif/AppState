# Uso do ModelState

🍎 `ModelState` permite que você gerencie objetos `@Model` do SwiftData através do modelo de injeção de dependência do AppState. Registre um `ModelContainer` compartilhado uma vez; leia e grave modelos de qualquer lugar — view models, serviços ou outro código fora de visualizações — sem ter que passar o `ModelContext` por toda a sua pilha de chamadas.

> 🍎 `ModelState` requer plataformas Apple com suporte ao SwiftData (iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS 1+). Essas APIs não são compiladas no Linux e no Windows.

## Exemplo de Ponta a Ponta

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

## Registrando o ModelContainer

`modelContainer(_:)` registra o contêiner com um identificador gerado automaticamente e avalia a autoclosure apenas uma vez. Construa o contêiner em uma função auxiliar em vez de inline — isso torna as falhas explícitas:

```swift
extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }
}
```

## Definindo um ModelState

Sem um `FetchDescriptor`, o estado corresponde a todos os modelos do tipo fornecido:

```swift
extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

Forneça um `FetchDescriptor` para filtragem ou ordenação:

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

## Lendo e Modificando

**Via `@ModelState`** — leia o valor encapsulado, mute através de `$items`:

```swift
@ModelState(\.items) var items: [Item]

func add(_ item: Item) { $items.insert(item) }
func remove(_ item: Item) { $items.delete(item) }
func persist() { $items.save() }
```

**Via `Application.modelState`** — útil em serviços e código fora de visualizações:

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

> `models` executa uma busca ativa no SwiftData a cada leitura. Capture o resultado em uma variável local quando precisar dele mais de uma vez.

### API de Valor Projetado

| Método | Comportamento |
| --- | --- |
| `$items.insert(_:)` | Insere um modelo e salva |
| `$items.delete(_:)` | Exclui um modelo e salva |
| `$items.save()` | Persiste as alterações pendentes |
| `$items.deleteAll()` | Exclui todos os modelos que correspondem ao `FetchDescriptor` e salva |

Esses mutadores registram e engolem qualquer erro subjacente do SwiftData para que os pontos de chamada permaneçam concisos. Quando você precisar expor ou se recuperar de uma gravação malsucedida, recorra às contrapartes que lançam erros em `strict`:

```swift
do {
    try $items.strict.insert(item)
    try $items.strict.save()
} catch {
    // apresente o erro, reverta, tente novamente…
}
```

`strict` expõe versões que lançam erros de todos os quatro mutadores (`insert`, `delete`, `save`, `deleteAll`) apoiadas pelo mesmo contexto — escolha a API tolerante quando uma falha registrada for aceitável, e `strict` quando o chamador precisar tratá-la.

## Acessando o ModelContext

```swift
let context = Application.modelContext(\.modelContainer)
```

Retorna o `mainContext` do `ModelContainer` resolvido — o mesmo contexto usado por todas as leituras e gravações.

## ModelState vs @Query do SwiftData

As mutações do `ModelState` **não** são transmitidas automaticamente para as visualizações SwiftUI. Isso é intencional.

- **Visualizações reativas** — use `@Query`. Ele observa o `ModelContext` diretamente e atualiza a visualização quando os dados mudam. Compartilhe o contêiner fornecido pelo AppState com o ambiente do SwiftUI para que as visualizações e o código fora de visualizações usem o mesmo armazenamento:

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

- **View models e serviços** — use `@ModelState` / `Application.modelState`. Ideal quando `@Environment` e `@Query` não estão disponíveis, ou quando você precisa de operações de modelo fora do código de visualização.

## Notas

- Todas as leituras e gravações passam pelo `mainContext` do contêiner — mantenha os usos no main actor.
- `ModelState` não armazena resultados em cache no próprio cache do AppState. O `ModelContext` do SwiftData é a fonte da verdade.
- Registre uma única dependência `ModelContainer` e referencie-a a partir de todos os estados de modelo e do ambiente do SwiftUI.

---
Esta tradução foi gerada automaticamente e pode conter erros. Se você é um falante nativo, agradecemos suas contribuições com correções por meio de um Pull Request.
