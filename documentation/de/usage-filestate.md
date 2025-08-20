# Verwendung von FileState

`FileState` ist eine Komponente der **AppState**-Bibliothek, mit der Sie persistente Daten mithilfe des Dateisystems speichern und abrufen können. Es ist nützlich zum Speichern großer Datenmengen oder komplexer Objekte, die zwischen App-Starts gespeichert und bei Bedarf wiederhergestellt werden müssen.

## Hauptmerkmale

- **Persistenter Speicher**: Mit `FileState` gespeicherte Daten bleiben über App-Starts hinweg erhalten.
- **Umgang mit großen Datenmengen**: Im Gegensatz zu `StoredState` ist `FileState` ideal für den Umgang mit größeren oder komplexeren Daten.
- **Threadsicher**: Wie andere AppState-Komponenten gewährleistet `FileState` einen sicheren Zugriff auf die Daten in nebenläufigen Umgebungen.

## Anwendungsbeispiel

### Speichern und Abrufen von Daten mit FileState

So definieren Sie einen `FileState` in der `Application`-Erweiterung, um ein großes Objekt zu speichern und abzurufen:

```swift
import AppState
import SwiftUI

struct UserProfile: Codable {
    var name: String
    var age: Int
}

extension Application {
    @MainActor
    var userProfile: FileState<UserProfile> {
        fileState(initial: UserProfile(name: "Guest", age: 25), filename: "userProfile")
    }
}

struct FileStateExampleView: View {
    @FileState(\.userProfile) var userProfile: UserProfile

    var body: some View {
        VStack {
            Text("Name: \(userProfile.name), Alter: \(userProfile.age)")
            Button("Profil aktualisieren") {
                userProfile = UserProfile(name: "UpdatedName", age: 30)
            }
        }
    }
}
```

### Umgang mit großen Datenmengen mit FileState

Wenn Sie mit größeren Datensätzen oder Objekten arbeiten müssen, stellt `FileState` sicher, dass die Daten effizient im Dateisystem der App gespeichert werden. Dies ist nützlich für Szenarien wie Caching oder Offline-Speicherung.

```swift
import AppState
import SwiftUI

extension Application {
    @MainActor
    var largeDataset: FileState<[String]> {
        fileState(initial: [], filename: "largeDataset")
    }
}

struct LargeDataView: View {
    @FileState(\.largeDataset) var largeDataset: [String]

    var body: some View {
        List(largeDataset, id: \.self) { item in
            Text(item)
        }
    }
}
```

### Überlegungen zur Migration

Bei der Aktualisierung Ihres Datenmodells ist es wichtig, potenzielle Migrationsherausforderungen zu berücksichtigen, insbesondere bei der Arbeit mit persistenten Daten mit **StoredState**, **FileState** oder **SyncState**. Ohne eine ordnungsgemäße Migrationsbehandlung können Änderungen wie das Hinzufügen neuer Felder oder das Ändern von Datenformaten Probleme beim Laden älterer Daten verursachen.

Hier sind einige wichtige Punkte, die Sie beachten sollten:
- **Hinzufügen neuer nicht optionaler Felder**: Stellen Sie sicher, dass neue Felder entweder optional sind oder Standardwerte haben, um die Abwärtskompatibilität zu gewährleisten.
- **Umgang mit Änderungen des Datenformats**: Wenn sich die Struktur Ihres Modells ändert, implementieren Sie eine benutzerdefinierte Dekodierungslogik, um alte Formate zu unterstützen.
- **Versionierung Ihrer Modelle**: Verwenden Sie ein `version`-Feld in Ihren Modellen, um bei Migrationen zu helfen und Logik basierend auf der Datenversion anzuwenden.

Weitere Informationen zur Verwaltung von Migrationen und zur Vermeidung potenzieller Probleme finden Sie im [Leitfaden zu Migrationsüberlegungen](migration-considerations.md).


## Bewährte Praktiken

- **Verwendung für große oder komplexe Daten**: Wenn Sie große Datenmengen oder komplexe Objekte speichern, ist `FileState` `StoredState` vorzuziehen.
- **Threadsicherer Zugriff**: Wie andere Komponenten von **AppState** stellt `FileState` sicher, dass auf Daten sicher zugegriffen wird, auch wenn mehrere Aufgaben mit den gespeicherten Daten interagieren.
- **Kombinieren mit Codable**: Stellen Sie bei der Arbeit mit benutzerdefinierten Datentypen sicher, dass diese `Codable` entsprechen, um die Kodierung und Dekodierung in und aus dem Dateisystem zu vereinfachen.

## Fazit

`FileState` ist ein leistungsstarkes Werkzeug für den Umgang mit persistenten Daten in Ihrer App, mit dem Sie größere oder komplexere Objekte auf threadsichere und persistente Weise speichern und abrufen können. Es arbeitet nahtlos mit dem `Codable`-Protokoll von Swift zusammen und stellt sicher, dass Ihre Daten für die langfristige Speicherung einfach serialisiert und deserialisiert werden können.

---
Dies wurde mit Jules erstellt, es können Fehler auftreten. Bitte erstellen Sie einen Pull Request mit allen Korrekturen, die vorgenommen werden sollten, wenn Sie Muttersprachler sind.
