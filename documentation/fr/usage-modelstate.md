# Utilisation de ModelState

🍎 `ModelState` est un composant de la bibliothèque **AppState** qui vous permet de gérer les objets SwiftData `@Model` à travers la portée de l'application. Il injecte un `ModelContainer` SwiftData partagé en tant que dépendance et lit et écrit dans le `ModelContext` de ce conteneur, offrant aux modèles de vue, aux services et à tout autre code hors-vue un accès partagé et injecté par dépendance à vos modèles.

> 🍎 `ModelState` et la dépendance `ModelContainer` de SwiftData sont spécifiques aux plates-formes Apple, car ils reposent sur le framework SwiftData d'Apple.

## Fonctionnalités Clés

- **Modèles Injectés par Dépendance** : Enregistrez un `ModelContainer` partagé une seule fois et accédez à ses modèles partout dans votre application.
- **`ModelContext` sur le Main-Actor** : Récupérez le `mainContext` du conteneur depuis n'importe quel code, y compris les modèles de vue et les services qui n'ont pas accès à l'`@Environment` de SwiftUI.
- **Commodité CRUD** : Lisez, insérez, supprimez, sauvegardez et supprimez tout (delete-all) les modèles SwiftData via une API petite et ciblée.
- **SwiftData comme Source de Vérité** : `ModelState` ne met pas les résultats en cache dans le cache d'AppState — le `ModelContext` de SwiftData reste l'unique source de vérité.

## Exigences et Disponibilité

Les fonctionnalités de SwiftData nécessitent des versions de plate-forme plus récentes que les exigences de base d'AppState. Toutes les API `ModelState` et `ModelContainer` sont protégées par `#if canImport(SwiftData)` et la disponibilité suivante :

- **iOS** : 17.0+
- **macOS** : 14.0+
- **tvOS** : 17.0+
- **watchOS** : 10.0+
- **visionOS** : 1.0+

Sur les plates-formes ou les versions d'OS où SwiftData n'est pas disponible, ces API ne sont pas compilées.

## Enregistrement de la Dépendance ModelContainer

Le `ModelContainer` de SwiftData est `Sendable`, il peut donc être stocké comme une `Dependency` AppState ordinaire. Définissez-en un sur une extension `Application` à l'aide de la commodité `modelContainer(_:)`, qui enregistre le conteneur avec un identifiant généré automatiquement et n'évalue l'autoclosure qu'une seule fois. Construisez le conteneur via une fonction d'aide qui gère les erreurs de manière explicite plutôt que d'utiliser un `try!` forcé :

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

## Accès au ModelContext

Une fois qu'une dépendance `ModelContainer` est définie, vous pouvez accéder au `ModelContext` partagé et lié au main-actor partout dans votre application :

```swift
let context = Application.modelContext(\.modelContainer)
```

Ceci renvoie le `mainContext` du `ModelContainer` résolu, de sorte que le même contexte est partagé dans toute votre application.

## Définition d'un ModelState

Définissez un `ModelState` en étendant l'objet `Application` et en le pointant vers la dépendance `ModelContainer` qui le sous-tend. Sans `FetchDescriptor`, l'état correspond à tous les modèles du type donné :

```swift
import AppState
import SwiftData

extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

Vous pouvez également fournir un `FetchDescriptor` personnalisé (pour le filtrage ou le tri) et un `id` explicite :

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

## Le Property Wrapper @ModelState

Le property wrapper `@ModelState` expose une collection de modèles en lecture seule depuis la portée de l'`Application`. Mutez via la valeur projetée (`$items`) :

```swift
import AppState
import SwiftData

@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func addItem(title: String) {
        $items.insert(Item(title: title))
    }
}
```

- **La lecture** de la valeur encapsulée effectue une récupération à l'aide du `FetchDescriptor` de l'état. La valeur encapsulée est un `[Model]` en lecture seule — vous ne pouvez pas lui affecter de valeur.
- **La mutation** se fait via la valeur projetée : `$items.insert(...)`, `$items.delete(...)`, `$items.save()` et `$items.deleteAll()`.

> ⚠️ La lecture de la valeur encapsulée effectue une récupération SwiftData en direct à **chaque** lecture. Évitez de la lire de manière répétée dans les chemins critiques (hot paths) — capturez plutôt le résultat dans une variable locale.

### CRUD via la Valeur Projetée

La valeur projetée (`$items`) expose l'`Application.ModelState<Item>` sous-jacent, vous donnant un contrôle explicite sur les insertions, les suppressions et les sauvegardes :

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

## Lecture et Mutation via Application.modelState

Vous pouvez également travailler avec le `ModelState` directement via le type `Application`, sans property wrapper. Ceci est pratique dans les services et autre code hors-vue :

```swift
@MainActor
func loadAndAppend() {
    let state = Application.modelState(\.items)

    // Lit les modèles actuels (effectue une récupération).
    let current = state.models

    // Accède directement au ModelContext sous-jacent si nécessaire.
    let context = state.context

    // Insère, supprime et sauvegarde.
    state.insert(Item(title: "New item"))
    state.delete(current.first!)
    state.save()
}
```

Le `ModelState` renvoyé expose :

- `models` : les modèles correspondant actuellement au `FetchDescriptor` de l'état (lecture seule ; chaque lecture effectue une nouvelle récupération en direct, sans setter).
- `context` : le `ModelContext` sous-jacent lié au main-actor.
- `insert(_:)` : insère un modèle et sauvegarde.
- `delete(_:)` : supprime un modèle et sauvegarde.
- `save()` : persiste tous les changements en attente dans le contexte.
- `deleteAll()` : supprime tous les modèles correspondant au `FetchDescriptor` de l'état et sauvegarde.

> ⚠️ `models` est récupéré en direct depuis SwiftData à **chaque** lecture. Évitez de le lire de manière répétée dans les chemins critiques (hot paths) — capturez plutôt le résultat dans une variable locale.

## Suppression de Tous les Modèles

Pour supprimer tous les modèles gérés par un `ModelState`, utilisez `deleteAll()` (qui remplace l'ancien `reset()`) :

```swift
Application.modelState(\.items).deleteAll()
```

Ceci récupère tous les modèles correspondant au `FetchDescriptor` de l'état, les supprime et sauvegarde le contexte.

## Quand Utiliser ModelState plutôt que @Query de SwiftData

Les mutations effectuées via `ModelState` et `@ModelState` ne sont **pas** automatiquement diffusées à SwiftUI. Il s'agit d'un choix de conception intentionnel :

- **Utilisez le `@Query` de SwiftData pour les vues réactives.** `@Query` observe le `ModelContext` et rafraîchit automatiquement votre vue lorsque les données sous-jacentes changent. Combinez-le avec le `ModelContainer` fourni par AppState afin que vos vues et votre code hors-vue partagent le même conteneur :

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

  // Injecte le conteneur partagé dans l'environnement SwiftUI.
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

- **Utilisez `ModelState` / `@ModelState` pour les modèles de vue, les services et autre code hors-vue** qui ont besoin d'un accès partagé et injecté par dépendance à vos modèles. C'est idéal là où l'`@Environment` et le `@Query` de SwiftUI ne sont pas disponibles, ou là où vous souhaitez effectuer des opérations sur les modèles en dehors du code de vue.

Notez également que la valeur encapsulée `@ModelState` et la propriété `models` sont en lecture seule — il n'y a pas d'affectation. Mutez toujours via la valeur projetée (`$items.insert(...)`, `$items.delete(...)`, `$items.save()`, `$items.deleteAll()`) ou via les méthodes de `ModelState`.

## Exemple de Bout en Bout

L'exemple suivant montre un flux complet : un `@Model`, les extensions `Application` enregistrant le conteneur et l'état du modèle, et un modèle de vue qui utilise `@ModelState`.

```swift
import AppState
import SwiftData
import SwiftUI

// 1. Définit le modèle SwiftData.
@Model
final class TodoItem {
    var title: String
    var isComplete: Bool

    init(title: String, isComplete: Bool = false) {
        self.title = title
        self.isComplete = isComplete
    }
}

// 2. Enregistre le ModelContainer partagé et un ModelState sur Application.
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

// 3. Utilise @ModelState depuis un modèle de vue.
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

Pour une liste réactive liée aux mêmes données, pilotez la vue avec le `@Query` de SwiftData tout en conservant les mutations dans le modèle de vue, comme indiqué dans la section [Quand Utiliser ModelState plutôt que @Query de SwiftData](#quand-utiliser-modelstate-plutôt-que-query-de-swiftdata) ci-dessus.

## Meilleures Pratiques

- **Les Vues Réactives Utilisent `@Query`** : Réservez le `@Query` de SwiftData aux vues qui doivent se mettre à jour automatiquement, et partagez avec elles le `ModelContainer` fourni par AppState.
- **Le Code Hors-Vue Utilise `ModelState`** : Utilisez `@ModelState` et `Application.modelState` dans les modèles de vue, les services et la logique d'arrière-plan qui ont besoin d'un accès partagé aux modèles.
- **Suppressions Explicites** : La valeur encapsulée et `models` étant en lecture seule, mutez via la valeur projetée ; utilisez `$items.delete(_:)` pour supprimer un modèle ou `$items.deleteAll()` pour tout supprimer.
- **Un Seul Conteneur Partagé** : Enregistrez une seule dépendance `ModelContainer` et référencez-la depuis vos états de modèle et l'environnement SwiftUI afin que tout lise et écrive dans le même magasin.

## Conclusion

`ModelState` intègre SwiftData au modèle d'injection de dépendances d'**AppState**, vous permettant de partager un seul `ModelContainer` dans toute votre application et de travailler avec les objets `@Model` depuis les modèles de vue et les services. Pour une interface utilisateur réactive, associez-le au `@Query` de SwiftData et au même conteneur partagé.

---
Cette traduction a été générée automatiquement et peut contenir des erreurs. Si vous êtes un locuteur natif, nous vous serions reconnaissants de contribuer avec des corrections via une Pull Request.
