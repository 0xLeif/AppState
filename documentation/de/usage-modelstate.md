# Verwendung von ModelState

🍎 `ModelState` ist eine Komponente der **AppState**-Bibliothek, mit der Sie SwiftData-`@Model`-Objekte über den Geltungsbereich der Anwendung verwalten können. Es injiziert einen gemeinsam genutzten SwiftData-`ModelContainer` als Abhängigkeit und liest aus dem `ModelContext` dieses Containers bzw. schreibt in ihn, wodurch View-Modelle, Dienste und anderer Nicht-View-Code gemeinsamen, per Dependency Injection bereitgestellten Zugriff auf Ihre Modelle erhalten.

> 🍎 `ModelState` und die SwiftData-`ModelContainer`-Abhängigkeit sind spezifisch für Apple-Plattformen, da sie auf Apples SwiftData-Framework basieren.

## Hauptmerkmale

- **Per Dependency Injection bereitgestellte Modelle**: Registrieren Sie einen gemeinsam genutzten `ModelContainer` einmal und greifen Sie überall in Ihrer App auf seine Modelle zu.
- **Main-Actor-`ModelContext`**: Rufen Sie den `mainContext` des Containers aus beliebigem Code ab, einschließlich View-Modellen und Diensten, die keinen Zugriff auf SwiftUIs `@Environment` haben.
- **CRUD-Komfort**: Lesen, einfügen, löschen, speichern und zurücksetzen Sie SwiftData-Modelle über eine kleine, fokussierte API.
- **SwiftData als Quelle der Wahrheit**: `ModelState` speichert Ergebnisse nicht im Cache von AppState zwischen – der `ModelContext` von SwiftData bleibt die einzige Quelle der Wahrheit.

## Anforderungen & Verfügbarkeit

SwiftData-Funktionen erfordern neuere Plattformversionen als die Basisanforderungen von AppState. Alle `ModelState`- und `ModelContainer`-APIs sind hinter `#if canImport(SwiftData)` und der folgenden Verfügbarkeit geschützt:

- **iOS**: 17.0+
- **macOS**: 14.0+
- **tvOS**: 17.0+
- **watchOS**: 10.0+
- **visionOS**: 1.0+

Auf Plattformen oder Betriebssystemversionen, auf denen SwiftData nicht verfügbar ist, werden diese APIs nicht einkompiliert.

## Registrieren der ModelContainer-Abhängigkeit

Der `ModelContainer` von SwiftData ist `Sendable` und kann daher als reguläre AppState-`Dependency` gespeichert werden. Definieren Sie eine in einer `Application`-Erweiterung mithilfe des Komforts `modelContainer(_:)`, der den Container mit einer automatisch generierten Kennung registriert und die Autoclosure nur einmal auswertet:

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

## Zugriff auf den ModelContext

Sobald eine `ModelContainer`-Abhängigkeit definiert ist, können Sie überall in Ihrer App auf den gemeinsam genutzten, an den Main-Actor gebundenen `ModelContext` zugreifen:

```swift
let context = Application.modelContext(\.modelContainer)
```

Dies gibt den `mainContext` des aufgelösten `ModelContainer` zurück, sodass derselbe Kontext in Ihrer gesamten App geteilt wird.

## Definieren eines ModelState

Definieren Sie einen `ModelState`, indem Sie das `Application`-Objekt erweitern und es auf die `ModelContainer`-Abhängigkeit verweisen, die es untermauert. Ohne `FetchDescriptor` entspricht der Zustand allen Modellen des angegebenen Typs:

```swift
import AppState
import SwiftData

extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

Sie können auch einen benutzerdefinierten `FetchDescriptor` (zum Filtern oder Sortieren) und eine explizite `id` angeben:

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

## Der @ModelState-Property-Wrapper

Der `@ModelState`-Property-Wrapper stellt eine Sammlung von Modellen aus dem Geltungsbereich der `Application` bereit:

```swift
import AppState
import SwiftData

@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func addItem(title: String) {
        // Die Zuweisung fügt neue (noch nicht persistierte) Modelle ein und speichert.
        items = items + [Item(title: title)]
    }
}
```

- **Das Lesen** des umschlossenen Werts führt einen Abruf mit dem `FetchDescriptor` des Zustands durch.
- **Das Zuweisen** zum umschlossenen Wert fügt alle Modelle im neuen Wert ein, die noch nicht persistiert sind, und speichert den zugrunde liegenden Kontext. Vorhandene Modelle, die im neuen Wert fehlen, werden **nicht** gelöscht – verwenden Sie `delete(_:)` oder `reset()` zum Entfernen.

### CRUD über den projizierten Wert

Der projizierte Wert (`$items`) stellt das zugrunde liegende `Application.ModelState<Item>` bereit und gibt Ihnen explizite Kontrolle über Einfügungen, Löschungen und Speichervorgänge:

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

## Lesen und Ändern über Application.modelState

Sie können auch direkt über den `Application`-Typ mit dem `ModelState` arbeiten, ohne einen Property-Wrapper. Dies ist praktisch in Diensten und anderem Nicht-View-Code:

```swift
@MainActor
func loadAndAppend() {
    let state = Application.modelState(\.items)

    // Aktuelle Modelle lesen (führt einen Abruf durch).
    let current = state.value

    // Bei Bedarf direkt auf den zugrunde liegenden ModelContext zugreifen.
    let context = state.context

    // Einfügen, löschen und speichern.
    state.insert(Item(title: "New item"))
    state.delete(current.first!)
    state.save()
}
```

Der zurückgegebene `ModelState` stellt Folgendes bereit:

- `value`: die Modelle, die derzeit dem `FetchDescriptor` des Zustands entsprechen (beim Abrufen wird abgerufen; beim Festlegen werden neue Modelle eingefügt und gespeichert).
- `context`: der zugrunde liegende Main-Actor-`ModelContext`.
- `insert(_:)`: fügt ein Modell ein und speichert.
- `delete(_:)`: löscht ein Modell und speichert.
- `save()`: persistiert alle ausstehenden Änderungen im Kontext.

## Zurücksetzen

Um jedes von einem `ModelState` verwaltete Modell zu löschen, verwenden Sie `Application.reset(modelState:)`:

```swift
Application.reset(modelState: \.items)
```

Dies ruft jedes Modell ab, das dem `FetchDescriptor` des Zustands entspricht, löscht es und speichert den Kontext.

## Wann ModelState vs. SwiftData @Query verwenden

Über `ModelState` und `@ModelState` vorgenommene Änderungen werden **nicht** automatisch an SwiftUI weitergegeben. Dies ist eine bewusste Designentscheidung:

- **Verwenden Sie SwiftDatas eigenes `@Query` für reaktive Ansichten.** `@Query` beobachtet den `ModelContext` und aktualisiert Ihre Ansicht automatisch, wenn sich die zugrunde liegenden Daten ändern. Kombinieren Sie es mit dem von AppState bereitgestellten `ModelContainer`, damit Ihre Ansichten und Ihr Nicht-View-Code denselben Container teilen:

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

  // Den gemeinsam genutzten Container in die SwiftUI-Umgebung injizieren.
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

- **Verwenden Sie `ModelState` / `@ModelState` für View-Modelle, Dienste und anderen Nicht-View-Code**, der gemeinsamen, per Dependency Injection bereitgestellten Zugriff auf Ihre Modelle benötigt. Es ist ideal dort, wo SwiftUIs `@Environment` und `@Query` nicht verfügbar sind oder wo Sie Modelloperationen außerhalb von View-Code durchführen möchten.

Beachten Sie außerdem, dass der `value`-Setter nur noch nicht persistierte Modelle einfügt – er löscht keine Modelle, die im neuen Wert fehlen. Verwenden Sie `delete(_:)` oder `reset(modelState:)`, um Modelle zu entfernen.

## End-to-End-Beispiel

Das folgende Beispiel zeigt einen vollständigen Ablauf: ein `@Model`, die `Application`-Erweiterungen, die den Container und den Modellzustand registrieren, und ein View-Modell, das `@ModelState` verwendet.

```swift
import AppState
import SwiftData
import SwiftUI

// 1. Das SwiftData-Modell definieren.
@Model
final class TodoItem {
    var title: String
    var isComplete: Bool

    init(title: String, isComplete: Bool = false) {
        self.title = title
        self.isComplete = isComplete
    }
}

// 2. Den gemeinsam genutzten ModelContainer und einen ModelState auf Application registrieren.
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

// 3. @ModelState aus einem View-Modell verwenden.
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

Für eine reaktive Liste, die an dieselben Daten gebunden ist, steuern Sie die Ansicht mit SwiftDatas `@Query`, während Sie die Änderungen im View-Modell belassen, wie im Abschnitt [Wann ModelState vs. SwiftData @Query verwenden](#wann-modelstate-vs-swiftdata-query-verwenden) oben gezeigt.

## Bewährte Praktiken

- **Reaktive Ansichten verwenden `@Query`**: Reservieren Sie SwiftDatas `@Query` für Ansichten, die sich automatisch aktualisieren müssen, und teilen Sie den von AppState bereitgestellten `ModelContainer` mit ihnen.
- **Nicht-View-Code verwendet `ModelState`**: Verwenden Sie `@ModelState` und `Application.modelState` in View-Modellen, Diensten und Hintergrundlogik, die gemeinsamen Modellzugriff benötigen.
- **Explizite Löschungen**: Denken Sie daran, dass die Zuweisung zu `value` nur einfügt; verwenden Sie `delete(_:)` oder `reset(modelState:)`, um Modelle zu entfernen.
- **Ein gemeinsam genutzter Container**: Registrieren Sie eine einzelne `ModelContainer`-Abhängigkeit und referenzieren Sie sie aus Ihren Modellzuständen und der SwiftUI-Umgebung, damit alles aus demselben Speicher liest und in ihn schreibt.

## Fazit

`ModelState` bringt SwiftData in das Dependency-Injection-Modell von **AppState** ein, sodass Sie einen einzelnen `ModelContainer` in Ihrer gesamten App teilen und mit `@Model`-Objekten aus View-Modellen und Diensten arbeiten können. Für eine reaktive Benutzeroberfläche kombinieren Sie es mit SwiftDatas `@Query` und demselben gemeinsam genutzten Container.

---
Diese Übersetzung wurde automatisch generiert und kann Fehler enthalten. Wenn Sie Muttersprachler sind, freuen wir uns über Ihre Korrekturvorschläge per Pull Request.
