# Verwendung von ModelState

🍎 `ModelState` ermöglicht es Ihnen, SwiftData-`@Model`-Objekte über das Dependency-Injection-Modell von AppState zu verwalten. Registrieren Sie einen gemeinsam genutzten `ModelContainer` einmal; lesen und schreiben Sie Modelle von überall — View-Modelle, Dienste oder anderer Nicht-View-Code — ohne den `ModelContext` durch Ihren Aufrufstapel zu fädeln.

> 🍎 `ModelState` erfordert Apple-Plattformen mit SwiftData-Unterstützung (iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS 1+). Diese APIs werden auf Linux und Windows nicht einkompiliert.

## End-to-End-Beispiel

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

## Registrieren des ModelContainer

`modelContainer(_:)` registriert den Container mit einer automatisch generierten Kennung und wertet die Autoclosure nur einmal aus. Bauen Sie den Container in einer Hilfsfunktion statt inline — das macht Fehler explizit:

```swift
extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }
}
```

## Definieren eines ModelState

Ohne `FetchDescriptor` entspricht der Zustand allen Modellen des angegebenen Typs:

```swift
extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

Geben Sie einen `FetchDescriptor` zum Filtern oder Sortieren an:

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

## Lesen und Ändern

**Über `@ModelState`** — lesen Sie den umschlossenen Wert, ändern Sie über `$items`:

```swift
@ModelState(\.items) var items: [Item]

func add(_ item: Item) { $items.insert(item) }
func remove(_ item: Item) { $items.delete(item) }
func persist() { $items.save() }
```

**Über `Application.modelState`** — nützlich in Diensten und Nicht-View-Code:

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

> `models` führt bei jedem Lesezugriff einen Live-Abruf aus SwiftData durch. Speichern Sie das Ergebnis in einer lokalen Variablen, wenn Sie es mehr als einmal benötigen.

### Projected-Value-API

| Methode | Verhalten |
| --- | --- |
| `$items.insert(_:)` | Fügt ein Modell ein und speichert |
| `$items.delete(_:)` | Löscht ein Modell und speichert |
| `$items.save()` | Persistiert ausstehende Änderungen |
| `$items.deleteAll()` | Löscht alle Modelle, die dem `FetchDescriptor` entsprechen, und speichert |

Diese Mutatoren protokollieren jeden zugrunde liegenden SwiftData-Fehler und unterdrücken ihn, damit die Aufrufstellen knapp bleiben. Wenn Sie einen fehlgeschlagenen Schreibvorgang offenlegen oder davon wiederherstellen müssen, greifen Sie auf die werfenden Gegenstücke von `strict` zurück:

```swift
do {
    try $items.strict.insert(item)
    try $items.strict.save()
} catch {
    // Fehler anzeigen, zurückrollen, erneut versuchen…
}
```

`strict` stellt werfende Versionen aller vier Mutatoren (`insert`, `delete`, `save`, `deleteAll`) bereit, die durch denselben Kontext gestützt werden — wählen Sie die nachsichtige API, wenn ein protokollierter Fehler akzeptabel ist, und `strict`, wenn der Aufrufer ihn behandeln muss.

## Zugriff auf den ModelContext

```swift
let context = Application.modelContext(\.modelContainer)
```

Gibt den `mainContext` des aufgelösten `ModelContainer` zurück — denselben Kontext, der von allen Lese- und Schreibvorgängen verwendet wird.

## ModelState vs. SwiftData @Query

Über `ModelState` vorgenommene Änderungen werden **nicht** automatisch an SwiftUI-Ansichten weitergegeben. Das ist beabsichtigt.

- **Reaktive Ansichten** — verwenden Sie `@Query`. Es beobachtet den `ModelContext` direkt und aktualisiert die Ansicht, wenn sich die Daten ändern. Teilen Sie den von AppState bereitgestellten Container mit der SwiftUI-Umgebung, damit Ansichten und Nicht-View-Code denselben Speicher verwenden:

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

- **View-Modelle und Dienste** — verwenden Sie `@ModelState` / `Application.modelState`. Ideal, wenn `@Environment` und `@Query` nicht verfügbar sind oder wenn Sie Modelloperationen außerhalb von View-Code benötigen.

## Hinweise

- Alle Lese- und Schreibvorgänge laufen über den `mainContext` des Containers — halten Sie die Verwendung auf dem Main-Actor.
- `ModelState` speichert Ergebnisse nicht im eigenen Cache von AppState zwischen. Der `ModelContext` von SwiftData ist die Quelle der Wahrheit.
- Registrieren Sie eine einzelne `ModelContainer`-Abhängigkeit und referenzieren Sie sie aus allen Modellzuständen und der SwiftUI-Umgebung.

---
Diese Übersetzung wurde automatisch generiert und kann Fehler enthalten. Wenn Sie Muttersprachler sind, freuen wir uns über Ihre Korrekturvorschläge per Pull Request.
