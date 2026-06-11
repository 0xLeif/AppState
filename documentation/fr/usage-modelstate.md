# Utilisation de ModelState

🍎 `ModelState` vous permet de gérer les objets SwiftData `@Model` via le modèle d'injection de dépendances d'AppState. Enregistrez un `ModelContainer` partagé une seule fois ; lisez et écrivez les modèles depuis n'importe où — modèles de vue, services ou autre code hors-vue — sans avoir à faire transiter un `ModelContext` à travers votre pile d'appels.

> 🍎 `ModelState` nécessite des plates-formes Apple prenant en charge SwiftData (iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS 1+). Ces API ne sont pas compilées sur Linux et Windows.

## Exemple de Bout en Bout

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

## Enregistrement du ModelContainer

`modelContainer(_:)` enregistre le conteneur avec un identifiant généré automatiquement et n'évalue l'autoclosure qu'une seule fois. Construisez le conteneur dans une fonction d'aide plutôt qu'en ligne — cela rend les échecs explicites :

```swift
extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }
}
```

## Définition d'un ModelState

Sans `FetchDescriptor`, l'état correspond à tous les modèles du type donné :

```swift
extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

Fournissez un `FetchDescriptor` pour le filtrage ou le tri :

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

## Lecture et Mutation

**Via `@ModelState`** — lisez la valeur encapsulée, mutez via `$items` :

```swift
@ModelState(\.items) var items: [Item]

func add(_ item: Item) { $items.insert(item) }
func remove(_ item: Item) { $items.delete(item) }
func persist() { $items.save() }
```

**Via `Application.modelState`** — utile dans les services et le code hors-vue :

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

> `models` effectue une récupération SwiftData en direct à chaque lecture. Capturez le résultat dans une variable locale lorsque vous en avez besoin plusieurs fois.

### API de la valeur projetée

| Méthode | Comportement |
| --- | --- |
| `$items.insert(_:)` | Insère un modèle et sauvegarde |
| `$items.delete(_:)` | Supprime un modèle et sauvegarde |
| `$items.save()` | Persiste les changements en attente |
| `$items.deleteAll()` | Supprime tous les modèles correspondant au `FetchDescriptor` et sauvegarde |

Ces mutateurs journalisent et absorbent toute erreur SwiftData sous-jacente afin que les sites d'appel restent concis. Lorsque vous avez besoin de faire remonter ou de récupérer une écriture échouée, tournez-vous vers les variantes pouvant lever des erreurs disponibles sur `strict` :

```swift
do {
    try $items.strict.insert(item)
    try $items.strict.save()
} catch {
    // présenter l'erreur, annuler, réessayer…
}
```

`strict` expose des versions pouvant lever des erreurs des quatre mutateurs (`insert`, `delete`, `save`, `deleteAll`) adossées au même contexte — choisissez l'API indulgente lorsqu'un échec journalisé est acceptable, et `strict` lorsque l'appelant doit le gérer.

## Accès au ModelContext

```swift
let context = Application.modelContext(\.modelContainer)
```

Renvoie le `mainContext` du `ModelContainer` résolu — le même contexte utilisé par toutes les lectures et écritures.

## ModelState vs @Query de SwiftData

Les mutations de `ModelState` ne sont **pas** automatiquement diffusées aux vues SwiftUI. C'est intentionnel.

- **Vues réactives** — utilisez `@Query`. Il observe directement le `ModelContext` et rafraîchit la vue lorsque les données changent. Partagez le conteneur fourni par AppState avec l'environnement SwiftUI afin que les vues et le code hors-vue utilisent le même magasin :

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

- **Modèles de vue et services** — utilisez `@ModelState` / `Application.modelState`. Idéal lorsque `@Environment` et `@Query` ne sont pas disponibles, ou lorsque vous avez besoin d'opérations sur les modèles en dehors du code de vue.

## Remarques

- Toutes les lectures et écritures passent par le `mainContext` du conteneur — gardez les usages sur le main actor.
- `ModelState` ne met pas les résultats en cache dans le cache propre d'AppState. Le `ModelContext` de SwiftData est la source de vérité.
- Enregistrez une seule dépendance `ModelContainer` et référencez-la depuis tous les états de modèle et l'environnement SwiftUI.

---
Cette traduction a été générée automatiquement et peut contenir des erreurs. Si vous êtes un locuteur natif, nous vous serions reconnaissants de contribuer avec des corrections via une Pull Request.
