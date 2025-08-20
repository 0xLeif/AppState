# Erweiterte Nutzung von AppState

Dieser Leitfaden behandelt fortgeschrittene Themen zur Verwendung von **AppState**, einschließlich Just-in-Time-Erstellung, Vorladen von Abhängigkeiten, effektive Verwaltung von Zustand und Abhängigkeiten und ein Vergleich von **AppState** mit der **SwiftUI-Umgebung**.

## 1. Just-in-Time-Erstellung

AppState-Werte wie `State`, `Dependency`, `StoredState` und `SyncState` werden just-in-time erstellt. Das bedeutet, dass sie erst instanziiert werden, wenn zum ersten Mal auf sie zugegriffen wird, was die Effizienz und Leistung Ihrer Anwendung verbessert.

### Beispiel

```swift
extension Application {
    var defaultState: State<Int> {
        state(initial: 0) // Der Wert wird erst erstellt, wenn darauf zugegriffen wird
    }
}
```

In diesem Beispiel wird `defaultState` erst erstellt, wenn zum ersten Mal darauf zugegriffen wird, was die Ressourcennutzung optimiert.

## 2. Vorladen von Abhängigkeiten

In einigen Fällen möchten Sie möglicherweise bestimmte Abhängigkeiten vorladen, um sicherzustellen, dass sie beim Start Ihrer Anwendung verfügbar sind. AppState bietet eine `load`-Funktion, die Abhängigkeiten vorlädt.

### Beispiel

```swift
extension Application {
    var databaseClient: Dependency<DatabaseClient> {
        dependency(DatabaseClient())
    }
}

// Beim Initialisieren der App vorladen
Application.load(dependency: \.databaseClient)
```

In diesem Beispiel wird `databaseClient` während der Initialisierung der App vorgeladen, um sicherzustellen, dass er bei Bedarf in Ihren Ansichten verfügbar ist.

## 3. Zustands- und Abhängigkeitsverwaltung

### 3.1 Gemeinsamer Zustand und Abhängigkeiten in der gesamten Anwendung

Sie können einen gemeinsamen Zustand oder Abhängigkeiten in einem Teil Ihrer App definieren und in einem anderen Teil über eindeutige IDs darauf zugreifen.

### Beispiel

```swift
private extension Application {
    var stateValue: State<Int> {
        state(initial: 0, id: "stateValue")
    }

    var dependencyValue: Dependency<SomeType> {
        dependency(SomeType(), id: "dependencyValue")
    }
}
```

Dies ermöglicht es Ihnen, auf denselben `State` oder dieselbe `Dependency` an anderer Stelle zuzugreifen, indem Sie dieselbe ID verwenden.

```swift
private extension Application {
    var theSameStateValue: State<Int> {
        state(initial: 0, id: "stateValue")
    }

    var theSameDependencyValue: Dependency<SomeType> {
        dependency(SomeType(), id: "dependencyValue")
    }
}
```

Obwohl dieser Ansatz gültig ist, um Zustand und Abhängigkeiten in der gesamten Anwendung durch Wiederverwendung derselben Zeichenfolgen-`id` zu teilen, wird er im Allgemeinen nicht empfohlen. Er beruht auf der manuellen Verwaltung dieser Zeichenfolgen-IDs, was zu Folgendem führen kann:
- Versehentliche ID-Kollisionen, wenn dieselbe ID für verschiedene beabsichtigte Zustände/Abhängigkeiten verwendet wird.
- Schwierigkeiten bei der Nachverfolgung, wo ein Zustand/eine Abhängigkeit definiert und wo darauf zugegriffen wird.
- Reduzierte Code-Klarheit und Wartbarkeit.
Der in nachfolgenden Definitionen mit derselben ID angegebene `initial`-Wert wird ignoriert, wenn der Zustand/die Abhängigkeit bereits durch den ersten Zugriff initialisiert wurde. Dieses Verhalten ist eher ein Nebeneffekt der ID-basierten Zwischenspeicherung in AppState als ein empfohlenes primäres Muster für die Definition gemeinsamer Daten. Bevorzugen Sie die Definition von Zuständen und Abhängigkeiten als eindeutige berechnete Eigenschaften in `Application`-Erweiterungen (die automatisch eindeutige interne IDs generieren, wenn der Factory-Methode keine explizite `id` übergeben wird).

### 3.2 Eingeschränkter Zustands- und Abhängigkeitszugriff

Um den Zugriff einzuschränken, verwenden Sie eine eindeutige ID wie eine UUID, um sicherzustellen, dass nur die richtigen Teile der App auf bestimmte Zustände oder Abhängigkeiten zugreifen können.

### Beispiel

```swift
private extension Application {
    var restrictedState: State<Int?> {
        state(initial: nil, id: UUID().uuidString)
    }

    var restrictedDependency: Dependency<SomeType> {
        dependency(SomeType(), id: UUID().uuidString)
    }
}
```

### 3.3 Eindeutige IDs für Zustände und Abhängigkeiten

Wenn keine ID angegeben wird, generiert AppState eine Standard-ID basierend auf dem Speicherort im Quellcode. Dadurch wird sichergestellt, dass jeder `State` oder jede `Dependency` eindeutig ist und vor unbeabsichtigtem Zugriff geschützt ist.

### Beispiel

```swift
extension Application {
    var defaultState: State<Int> {
        state(initial: 0) // AppState generiert eine eindeutige ID
    }

    var defaultDependency: Dependency<SomeType> {
        dependency(SomeType()) // AppState generiert eine eindeutige ID
    }
}
```

### 3.4 Dateiprivater Zustands- und Abhängigkeitszugriff

Für einen noch stärker eingeschränkten Zugriff innerhalb derselben Swift-Datei verwenden Sie die Zugriffsebene `fileprivate`, um Zustände und Abhängigkeiten vor externem Zugriff zu schützen.

### Beispiel

```swift
fileprivate extension Application {
    var fileprivateState: State<Int> {
        state(initial: 0)
    }

    var fileprivateDependency: Dependency<SomeType> {
        dependency(SomeType())
    }
}
```

### 3.5 Verständnis des Speichermechanismus von AppState

AppState verwendet einen einheitlichen Cache zum Speichern von `State`, `Dependency`, `StoredState` und `SyncState`. Dadurch wird sichergestellt, dass diese Datentypen in Ihrer gesamten App effizient verwaltet werden.

Standardmäßig weist AppState einen Namenswert als "App" zu, wodurch sichergestellt wird, dass alle mit einem Modul verbundenen Werte an diesen Namen gebunden sind. Dies erschwert den Zugriff auf diese Zustände und Abhängigkeiten von anderen Modulen.

## 4. AppState vs. SwiftUI-Umgebung

Sowohl AppState als auch die SwiftUI-Umgebung bieten Möglichkeiten zur Verwaltung von gemeinsamem Zustand und Abhängigkeiten in Ihrer Anwendung, unterscheiden sich jedoch in Umfang, Funktionalität und Anwendungsfällen.

### 4.1 SwiftUI-Umgebung

Die SwiftUI-Umgebung ist ein integrierter Mechanismus, mit dem Sie gemeinsame Daten über eine Ansichtshierarchie weitergeben können. Sie ist ideal für die Weitergabe von Daten, auf die viele Ansichten zugreifen müssen, hat aber Einschränkungen bei der Verwaltung komplexerer Zustände.

**Stärken:**
- Einfach zu bedienen und gut in SwiftUI integriert.
- Ideal für leichtgewichtige Daten, die über mehrere Ansichten in einer Hierarchie geteilt werden müssen.

**Einschränkungen:**
- Daten sind nur innerhalb der spezifischen Ansichtshierarchie verfügbar. Der Zugriff auf dieselben Daten über verschiedene Ansichtshierarchien hinweg ist ohne zusätzliche Arbeit nicht möglich.
- Weniger Kontrolle über Threadsicherheit und Persistenz im Vergleich zu AppState.
- Fehlende integrierte Persistenz- oder Synchronisierungsmechanismen.

### 4.2 AppState

AppState bietet ein leistungsfähigeres und flexibleres System zur Verwaltung von Zustand in der gesamten Anwendung mit Threadsicherheit, Persistenz und Abhängigkeitsinjektionsfunktionen.

**Stärken:**
- Zentralisierte Zustandsverwaltung, die in der gesamten App zugänglich ist, nicht nur in bestimmten Ansichtshierarchien.
- Integrierte Persistenzmechanismen (`StoredState`, `FileState` und `SyncState`).
- Typ- und Threadsicherheitsgarantien, die sicherstellen, dass der Zustand korrekt abgerufen und geändert wird.
- Kann komplexere Zustands- und Abhängigkeitsverwaltung handhaben.

**Einschränkungen:**
- Erfordert mehr Einrichtung und Konfiguration im Vergleich zur SwiftUI-Umgebung.
- Etwas weniger integriert mit SwiftUI im Vergleich zur Umgebung, funktioniert aber dennoch gut in SwiftUI-Apps.

### 4.3 Wann man was verwenden sollte

- Verwenden Sie die **SwiftUI-Umgebung**, wenn Sie einfache Daten haben, die über eine Ansichtshierarchie geteilt werden müssen, z. B. Benutzereinstellungen oder Designpräferenzen.
- Verwenden Sie **AppState**, wenn Sie eine zentralisierte Zustandsverwaltung, Persistenz oder einen komplexeren Zustand benötigen, auf den in der gesamten App zugegriffen werden muss.

## Fazit

Durch die Verwendung dieser fortschrittlichen Techniken wie Just-in-Time-Erstellung, Vorladen, Zustands- und Abhängigkeitsverwaltung und das Verständnis der Unterschiede zwischen AppState und der SwiftUI-Umgebung können Sie mit **AppState** effiziente und ressourcenbewusste Anwendungen erstellen.

---
Dies wurde mit [Jules](https://jules.google) erstellt, es können Fehler auftreten. Bitte erstellen Sie einen Pull Request mit allen Korrekturen, die vorgenommen werden sollten, wenn Sie Muttersprachler sind.
