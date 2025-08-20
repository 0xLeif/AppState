# Verwendung von SyncState

`SyncState` ist eine Komponente der **AppState**-Bibliothek, mit der Sie den App-Zustand über mehrere Geräte hinweg mithilfe von iCloud synchronisieren können. Dies ist besonders nützlich, um Benutzereinstellungen, Einstellungen oder andere wichtige Daten über Geräte hinweg konsistent zu halten.

## Übersicht

`SyncState` nutzt den `NSUbiquitousKeyValueStore` von iCloud, um kleine Datenmengen über Geräte hinweg synchron zu halten. Dies macht es ideal für die Synchronisierung von leichtgewichtigen Anwendungszuständen wie Einstellungen oder Benutzereinstellungen.

### Hauptmerkmale

- **iCloud-Synchronisierung**: Synchronisieren Sie den Zustand automatisch über alle Geräte, die mit demselben iCloud-Konto angemeldet sind.
- **Permanenter Speicher**: Daten werden dauerhaft in iCloud gespeichert, was bedeutet, dass sie auch dann erhalten bleiben, wenn die App beendet oder neu gestartet wird.
- **Nahezu Echtzeit-Synchronisierung**: Zustandsänderungen werden fast sofort auf andere Geräte übertragen.

> **Hinweis**: `SyncState` wird auf watchOS 9.0 und höher unterstützt.

## Anwendungsbeispiel

### Datenmodell

Angenommen, wir haben eine Struktur namens `Settings`, die `Codable` entspricht:

```swift
struct Settings: Codable {
    var text: String
    var isShowingSheet: Bool
    var isDarkMode: Bool
}
```

### Definieren eines SyncState

Sie können einen `SyncState` definieren, indem Sie das `Application`-Objekt erweitern und die Zustandseigenschaften deklarieren, die synchronisiert werden sollen:

```swift
extension Application {
    var settings: SyncState<Settings> {
        syncState(
            initial: Settings(
                text: "Hello, World!",
                isShowingSheet: false,
                isDarkMode: false
            ),
            id: "settings"
        )
    }
}
```

### Umgang mit externen Änderungen

Um sicherzustellen, dass die App auf externe Änderungen von iCloud reagiert, überschreiben Sie die Funktion `didChangeExternally`, indem Sie eine benutzerdefinierte `Application`-Unterklasse erstellen:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
```

### Erstellen von Ansichten zum Ändern und Synchronisieren des Zustands

Im folgenden Beispiel haben wir zwei Ansichten: `ContentView` und `ContentViewInnerView`. Diese Ansichten teilen und synchronisieren den `Settings`-Zustand zwischen sich. `ContentView` ermöglicht es dem Benutzer, den `text` zu ändern und `isDarkMode` umzuschalten, während `ContentViewInnerView` denselben Text anzeigt und ihn bei Berührung aktualisiert.

```swift
struct ContentView: View {
    @SyncState(\.settings) private var settings: Settings

    var body: some View {
        VStack {
            TextField("", text: $settings.text)

            Button(settings.isDarkMode ? "Light" : "Dark") {
                settings.isDarkMode.toggle()
            }

            Button("Show") { settings.isShowingSheet = true }
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        .sheet(isPresented: $settings.isShowingSheet, content: ContentViewInnerView.init)
    }
}

struct ContentViewInnerView: View {
    @Slice(\.settings, \.text) private var text: String

    var body: some View {
        Text("\(text)")
            .onTapGesture {
                text = Date().formatted()
            }
    }
}
```

### Einrichten der App

Richten Sie schließlich die Anwendung in der `@main`-Struktur ein. In der Initialisierung bewerben Sie die benutzerdefinierte Anwendung, aktivieren die Protokollierung und laden die iCloud-Speicherabhängigkeit für die Synchronisierung:

```swift
@main
struct SyncStateExampleApp: App {
    init() {
        Application
            .promote(to: CustomApplication.self)
            .logging(isEnabled: true)
            .load(dependency: \.icloudStore)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Aktivieren des iCloud-Schlüssel-Wert-Speichers

Um die iCloud-Synchronisierung zu aktivieren, stellen Sie sicher, dass Sie dieser Anleitung folgen, um die Funktion des iCloud-Schlüssel-Wert-Speichers zu aktivieren: [Erste Schritte mit SyncState](starting-to-use-syncstate.md).

### SyncState: Hinweise zum iCloud-Speicher

Obwohl `SyncState` eine einfache Synchronisierung ermöglicht, ist es wichtig, die Einschränkungen von `NSUbiquitousKeyValueStore` zu beachten:

- **Speicherlimit**: Sie können mit `NSUbiquitousKeyValueStore` bis zu 1 MB Daten in iCloud speichern, mit einem Größenlimit von 1 MB pro Schlüssel-Wert-Paar.

### Überlegungen zur Migration

Bei der Aktualisierung Ihres Datenmodells ist es wichtig, potenzielle Migrationsherausforderungen zu berücksichtigen, insbesondere bei der Arbeit mit persistenten Daten mit **StoredState**, **FileState** oder **SyncState**. Ohne eine ordnungsgemäße Migrationsbehandlung können Änderungen wie das Hinzufügen neuer Felder oder das Ändern von Datenformaten Probleme beim Laden älterer Daten verursachen.

Hier sind einige wichtige Punkte, die Sie beachten sollten:
- **Hinzufügen neuer nicht optionaler Felder**: Stellen Sie sicher, dass neue Felder entweder optional sind oder Standardwerte haben, um die Abwärtskompatibilität zu gewährleisten.
- **Umgang mit Änderungen des Datenformats**: Wenn sich die Struktur Ihres Modells ändert, implementieren Sie eine benutzerdefinierte Dekodierungslogik, um alte Formate zu unterstützen.
- **Versionierung Ihrer Modelle**: Verwenden Sie ein `version`-Feld in Ihren Modellen, um bei Migrationen zu helfen und Logik basierend auf der Datenversion anzuwenden.

Weitere Informationen zur Verwaltung von Migrationen und zur Vermeidung potenzieller Probleme finden Sie im [Leitfaden zu Migrationsüberlegungen](migration-considerations.md).

## SyncState-Implementierungsleitfaden

Detaillierte Anweisungen zur Konfiguration von iCloud und zur Einrichtung von SyncState in Ihrem Projekt finden Sie im [SyncState-Implementierungsleitfaden](syncstate-implementation.md).

## Bewährte Praktiken

- **Verwendung für kleine, kritische Daten**: `SyncState` ist ideal für die Synchronisierung kleiner, wichtiger Zustandsteile wie Benutzereinstellungen, Einstellungen oder Funktionskennzeichen.
- **Überwachen Sie den iCloud-Speicher**: Stellen Sie sicher, dass Ihre Verwendung von `SyncState` innerhalb der iCloud-Speichergrenzen bleibt, um Probleme bei der Datensynchronisierung zu vermeiden.
- **Behandeln Sie externe Aktualisierungen**: Wenn Ihre App auf Zustandsänderungen reagieren muss, die auf einem anderen Gerät initiiert wurden, überschreiben Sie die Funktion `didChangeExternally`, um den Zustand der App in Echtzeit zu aktualisieren.

## Fazit

`SyncState` bietet eine leistungsstarke Möglichkeit, kleine Mengen von Anwendungszuständen über Geräte hinweg über iCloud zu synchronisieren. Es ist ideal, um sicherzustellen, dass Benutzereinstellungen und andere wichtige Daten auf allen Geräten, die mit demselben iCloud-Konto angemeldet sind, konsistent bleiben. Für fortgeschrittenere Anwendungsfälle erkunden Sie andere Funktionen von **AppState**, wie [SecureState](usage-securestate.md) und [FileState](usage-filestate.md).

---
Dies wurde mit [Jules](https://jules.google) erstellt, es können Fehler auftreten. Bitte erstellen Sie einen Pull Request mit allen Korrekturen, die vorgenommen werden sollten, wenn Sie Muttersprachler sind.
