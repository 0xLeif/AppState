# Verwendung von StoredState

`StoredState` ist eine Komponente der **AppState**-Bibliothek, mit der Sie kleine Datenmengen mithilfe von `UserDefaults` speichern und beibehalten können. Es ist ideal zum Speichern von leichtgewichtigen, nicht sensiblen Daten, die über App-Starts hinweg erhalten bleiben sollen.

## Übersicht

- **StoredState** basiert auf `UserDefaults`, was bedeutet, dass es schnell und effizient zum Speichern kleiner Datenmengen (wie Benutzereinstellungen oder App-Einstellungen) ist.
- In **StoredState** gespeicherte Daten bleiben über App-Sitzungen hinweg erhalten, sodass Sie den Anwendungszustand beim Start wiederherstellen können.

### Hauptmerkmale

- **Permanenter Speicher**: In `StoredState` gespeicherte Daten bleiben zwischen den App-Starts verfügbar.
- **Umgang mit kleinen Daten**: Am besten für leichtgewichtige Daten wie Einstellungen, Schalter oder kleine Konfigurationen geeignet.
- **Threadsicher**: `StoredState` stellt sicher, dass der Datenzugriff in nebenläufigen Umgebungen sicher bleibt.

## Anwendungsbeispiel

### Definieren eines StoredState

Sie können einen **StoredState** definieren, indem Sie das `Application`-Objekt erweitern und die Zustandseigenschaft deklarieren:

```swift
import AppState

extension Application {
    var userPreferences: StoredState<String> {
        storedState(initial: "Default Preferences", id: "userPreferences")
    }
}
```

### Zugreifen auf und Ändern von StoredState in einer Ansicht

Sie können mit dem `@StoredState`-Property-Wrapper in SwiftUI-Ansichten auf **StoredState**-Werte zugreifen und diese ändern:

```swift
import AppState
import SwiftUI

struct PreferencesView: View {
    @StoredState(\.userPreferences) var userPreferences: String

    var body: some View {
        VStack {
            Text("Einstellungen: \(userPreferences)")
            Button("Einstellungen aktualisieren") {
                userPreferences = "Updated Preferences"
            }
        }
    }
}
```

## Umgang mit Datenmigration

Wenn sich Ihre App weiterentwickelt, können Sie die Modelle aktualisieren, die über **StoredState** beibehalten werden. Stellen Sie beim Aktualisieren Ihres Datenmodells die Abwärtskompatibilität sicher. Sie können beispielsweise neue Felder hinzufügen oder Ihr Modell versionieren, um die Migration zu handhaben.

Weitere Informationen finden Sie im [Leitfaden zu Migrationsüberlegungen](migration-considerations.md).

### Überlegungen zur Migration

- **Hinzufügen neuer nicht optionaler Felder**: Stellen Sie sicher, dass neue Felder entweder optional sind oder Standardwerte haben, um die Abwärtskompatibilität zu gewährleisten.
- **Versionierung von Modellen**: Wenn sich Ihr Datenmodell im Laufe der Zeit ändert, fügen Sie ein `version`-Feld hinzu, um verschiedene Versionen Ihrer beibehaltenen Daten zu verwalten.

## Bewährte Praktiken

- **Verwendung für kleine Daten**: Speichern Sie leichtgewichtige, не sensible Daten, die über App-Starts hinweg erhalten bleiben müssen, wie z. B. Benutzereinstellungen.
- **Berücksichtigen Sie Alternativen für größere Daten**: Wenn Sie große Datenmengen speichern müssen, sollten Sie stattdessen **FileState** verwenden.

## Fazit

**StoredState** ist eine einfache und effiziente Möglichkeit, kleine Datenmengen mit `UserDefaults` beizubehalten. Es ist ideal zum Speichern von Einstellungen und anderen kleinen Konfigurationen über App-Starts hinweg und bietet gleichzeitig einen sicheren Zugriff und eine einfache Integration mit SwiftUI. Für komplexere Persistenzanforderungen erkunden Sie andere **AppState**-Funktionen wie [FileState](usage-filestate.md) oder [SyncState](usage-syncstate.md).
