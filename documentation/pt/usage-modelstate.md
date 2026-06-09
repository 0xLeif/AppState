# Uso do ModelState

🍎 `ModelState` é um componente da biblioteca **AppState** que permite gerenciar objetos `@Model` do SwiftData através do escopo da aplicação. Ele injeta um `ModelContainer` compartilhado do SwiftData como uma dependência e lê e grava no `ModelContext` desse contêiner, dando a view models, serviços e outro código fora de visualizações acesso compartilhado e injetado por dependência aos seus modelos.

> 🍎 `ModelState` e a dependência `ModelContainer` do SwiftData são específicos para plataformas Apple, pois dependem do framework SwiftData da Apple.

## Principais Características

- **Modelos Injetados por Dependência**: Registre um `ModelContainer` compartilhado uma vez e acesse seus modelos em qualquer lugar da sua aplicação.
- **`ModelContext` no Main-Actor**: Recupere o `mainContext` do contêiner a partir de qualquer código, incluindo view models e serviços que não têm acesso ao `@Environment` do SwiftUI.
- **Conveniência de CRUD**: Leia, insira, exclua, salve e exclua tudo de uma vez nos modelos do SwiftData através de uma API pequena e focada.
- **SwiftData como Fonte da Verdade**: `ModelState` não armazena resultados em cache no cache do AppState — o `ModelContext` do SwiftData permanece a única fonte da verdade.

## Requisitos e Disponibilidade

Os recursos do SwiftData exigem versões de plataforma mais recentes do que os requisitos básicos do AppState. Todas as APIs `ModelState` e `ModelContainer` são protegidas por `#if canImport(SwiftData)` e pela seguinte disponibilidade:

- **iOS**: 17.0+
- **macOS**: 14.0+
- **tvOS**: 17.0+
- **watchOS**: 10.0+
- **visionOS**: 1.0+

Em plataformas ou versões de SO onde o SwiftData não está disponível, essas APIs não são compiladas.

## Registrando a Dependência ModelContainer

O `ModelContainer` do SwiftData é `Sendable`, então ele pode ser armazenado como uma `Dependency` regular do AppState. Defina um em uma extensão de `Application` usando a conveniência `modelContainer(_:)`, que registra o contêiner com um identificador gerado automaticamente e avalia a autoclosure apenas uma vez:

```swift
import AppState
import SwiftData

private func makeModelContainer() -> ModelContainer {
    do {
        return try ModelContainer(for: Item.self)
    } catch {
        fatalError("Failed to create the ModelContainer: \(error)")
    }
}

extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }
}
```

## Acessando o ModelContext

Uma vez que a dependência `ModelContainer` é definida, você pode acessar o `ModelContext` compartilhado e vinculado ao main-actor em qualquer lugar da sua aplicação:

```swift
let context = Application.modelContext(\.modelContainer)
```

Isso retorna o `mainContext` do `ModelContainer` resolvido, de modo que o mesmo contexto é compartilhado por toda a sua aplicação.

## Definindo um ModelState

Defina um `ModelState` estendendo o objeto `Application` e apontando-o para a dependência `ModelContainer` que o sustenta. Sem um `FetchDescriptor`, o estado corresponde a todos os modelos do tipo fornecido:

```swift
import AppState
import SwiftData

extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

Você também pode fornecer um `FetchDescriptor` personalizado (para filtragem ou ordenação) e um `id` explícito:

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

## O Property Wrapper @ModelState

O property wrapper `@ModelState` expõe uma coleção de modelos a partir do escopo da `Application`:

```swift
import AppState
import SwiftData

@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func addItem(title: String) {
        // O valor encapsulado é somente leitura — mute através do valor projetado.
        $items.insert(Item(title: title))
    }
}
```

- O valor encapsulado é uma coleção `[Model]` **somente leitura**; não há atribuição. **Ler** o valor encapsulado executa uma busca ativa usando o `FetchDescriptor` do estado a CADA leitura.
- Para mutar, use o valor projetado: `$items.insert(...)`, `$items.delete(...)`, `$items.save()` e `$items.deleteAll()`.

### CRUD via Valor Projetado

O valor projetado (`$items`) expõe a `Application.ModelState<Item>` subjacente, dando a você controle explícito sobre inserções, exclusões e salvamentos:

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

## Lendo e Modificando via Application.modelState

Você também pode trabalhar com o `ModelState` diretamente através do tipo `Application`, sem um property wrapper. Isso é conveniente em serviços e outro código fora de visualizações:

```swift
@MainActor
func loadAndAppend() {
    let state = Application.modelState(\.items)

    // Lê os modelos atuais (executa uma busca ativa a cada leitura).
    let current = state.models

    // Acessa o ModelContext subjacente diretamente, se necessário.
    let context = state.context

    // Insere, exclui e salva.
    state.insert(Item(title: "New item"))
    state.delete(current.first!)
    state.save()
}
```

> ⚠️ A propriedade `models` é **somente leitura** e não possui setter. Cada leitura de `models` executa uma busca ativa no `ModelContext` usando o `FetchDescriptor` do estado, portanto evite lê-la repetidamente em laços apertados — capture o resultado em uma variável local quando precisar usá-lo várias vezes.

O `Application.ModelState` **não** conforma mais a `MutableApplicationState`. O `ModelState` retornado expõe:

- `models`: os modelos que atualmente correspondem ao `FetchDescriptor` do estado, **somente leitura** (cada leitura executa uma busca ativa; sem setter).
- `context`: o `ModelContext` subjacente vinculado ao main-actor.
- `insert(_:)`: insere um modelo e salva.
- `delete(_:)`: exclui um modelo e salva.
- `save()`: persiste quaisquer alterações pendentes no contexto.
- `deleteAll()`: exclui todos os modelos que correspondem ao `FetchDescriptor` do estado e salva o contexto.

## Excluindo Tudo

Para excluir todos os modelos gerenciados por um `ModelState`, use `deleteAll()` (que substitui o antigo `reset()` e o removido `Application.reset(modelState:)`):

```swift
Application.modelState(\.items).deleteAll()
```

Isso busca todos os modelos que correspondem ao `FetchDescriptor` do estado, exclui-os e salva o contexto.

## Quando Usar ModelState vs @Query do SwiftData

As mutações feitas através de `ModelState` e `@ModelState` **não** são transmitidas automaticamente para o SwiftUI. Esta é uma escolha de design intencional:

- **Use o próprio `@Query` do SwiftData para visualizações reativas.** O `@Query` observa o `ModelContext` e atualiza automaticamente sua visualização quando os dados subjacentes mudam. Combine-o com o `ModelContainer` fornecido pelo AppState para que suas visualizações e seu código fora de visualizações compartilhem o mesmo contêiner:

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

  // Injeta o contêiner compartilhado no ambiente do SwiftUI.
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

- **Use `ModelState` / `@ModelState` para view models, serviços e outro código fora de visualizações** que precise de acesso compartilhado e injetado por dependência aos seus modelos. É ideal onde o `@Environment` e o `@Query` do SwiftUI não estão disponíveis, ou onde você deseja realizar operações de modelo fora do código de visualização.

Observe também que os modelos são expostos apenas para leitura — para mutar, use `insert(_:)`, `delete(_:)`, `save()` e `deleteAll()` (ou os equivalentes do valor projetado: `$items.insert(...)`, `$items.delete(...)`, `$items.save()`, `$items.deleteAll()`).

## Exemplo de Ponta a Ponta

O exemplo a seguir mostra um fluxo completo: um `@Model`, as extensões de `Application` registrando o contêiner e o estado do modelo, e um view model que usa `@ModelState`.

```swift
import AppState
import SwiftData
import SwiftUI

// 1. Define o modelo do SwiftData.
@Model
final class TodoItem {
    var title: String
    var isComplete: Bool

    init(title: String, isComplete: Bool = false) {
        self.title = title
        self.isComplete = isComplete
    }
}

// 2. Registra o ModelContainer compartilhado e um ModelState na Application.
private func makeModelContainer() -> ModelContainer {
    do {
        return try ModelContainer(for: TodoItem.self)
    } catch {
        fatalError("Failed to create the ModelContainer: \(error)")
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

// 3. Usa @ModelState a partir de um view model.
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

Para uma lista reativa vinculada aos mesmos dados, conduza a visualização com o `@Query` do SwiftData enquanto mantém as mutações no view model, como mostrado na seção [Quando Usar ModelState vs @Query do SwiftData](#quando-usar-modelstate-vs-query-do-swiftdata) acima.

## Melhores Práticas

- **Visualizações Reativas Usam `@Query`**: Reserve o `@Query` do SwiftData para visualizações que precisam ser atualizadas automaticamente e compartilhe o `ModelContainer` fornecido pelo AppState com elas.
- **Código Fora de Visualizações Usa `ModelState`**: Use `@ModelState` e `Application.modelState` em view models, serviços e lógica de segundo plano que precisem de acesso compartilhado aos modelos.
- **Mutações Explícitas**: Os modelos são somente leitura; use `insert(_:)`, `delete(_:)`, `save()` e `deleteAll()` (ou os equivalentes do valor projetado) para modificar e remover modelos.
- **Um Contêiner Compartilhado**: Registre uma única dependência `ModelContainer` e referencie-a a partir dos seus estados de modelo e do ambiente do SwiftUI para que tudo leia e grave no mesmo armazenamento.

## Conclusão

`ModelState` traz o SwiftData para o modelo de injeção de dependência do **AppState**, permitindo que você compartilhe um único `ModelContainer` em toda a sua aplicação e trabalhe com objetos `@Model` a partir de view models e serviços. Para uma interface reativa, combine-o com o `@Query` do SwiftData e o mesmo contêiner compartilhado.

---
Esta tradução foi gerada automaticamente e pode conter erros. Se você é um falante nativo, agradecemos suas contribuições com correções por meio de um Pull Request.
