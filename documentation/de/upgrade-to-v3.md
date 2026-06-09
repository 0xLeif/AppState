# Upgrade auf AppState 3.0

AppState 3.0 modernisiert die Bibliothek rund um Swift 6 und Apples Observation-Framework. Diese Anleitung behandelt die Breaking Changes und wie Sie sich anpassen.

## 1. Erhöhte Plattformanforderungen

Die minimalen Bereitstellungsziele wurden erhöht, um moderne Swift- und SwiftData/Observation-APIs zu nutzen:

| Plattform | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux und Windows werden für den Funktionsumfang ohne Apple-Bezug weiterhin unterstützt.

Wenn Sie ältere Betriebssystemversionen weiterhin unterstützen müssen, bleiben Sie bei der 2.x-Release-Linie.

## 2. Striktes Swift 6

Das Paket fixiert nun den Swift-6-Sprachmodus (`swiftLanguageModes: [.v6]`) und das anstehende Feature `ExistentialAny`, und CI-Builds behandeln Warnungen als Fehler. Für die meisten Apps sind hierfür keine Änderungen erforderlich. Wenn Sie eines der öffentlichen Protokolle von AppState implementiert haben (zum Beispiel ein benutzerdefiniertes `FileManaging`, `UserDefaultsManaging` oder `UbiquitousKeyValueStoreManaging`), müssen Sie möglicherweise existenzielle Typen mit einem expliziten `any` schreiben (z. B. `any FileManaging`).

## 3. Observation ersetzt ObservableObject

`Application` verwendet jetzt das [`@Observable`](https://developer.apple.com/documentation/observation)-Makro, anstatt `ObservableObject` zu entsprechen.

**Für die typische Verwendung ist keine Änderung erforderlich.** Die Property-Wrapper – `@AppState`, `@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`, `@OptionalSlice`, `@DependencySlice` und `@ModelState` – funktionieren weiterhin in SwiftUI-Ansichten, und Ansichten werden wie zuvor aktualisiert. View-Modelle, die `ObservableObject` entsprechen und diese Wrapper hosten, werden weiterhin unterstützt.

Was sich geändert hat:

- `Application` entspricht nicht mehr `ObservableObject`, sodass `Application.shared.objectWillChange` nicht mehr verfügbar ist.
- Eine neue Methode, `Application.notifyChange()`, fordert Beobachter (SwiftUI-Ansichten) zur Aktualisierung auf. Die eigenen Setter von AppState rufen sie für Sie auf.

Wenn Sie `Application` abgeleitet und Aktualisierungen manuell ausgelöst haben – zum Beispiel aus einem `didChangeExternally(notification:)`-Override, das auf eingehende iCloud-Änderungen reagiert –, ersetzen Sie `objectWillChange.send()` durch `notifyChange()`:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            // Vorher (2.x):
            // self.objectWillChange.send()

            // Nachher (3.0):
            self.notifyChange()
        }
    }
}
```

> Hinweis: `@ObservedDependency` ist unverändert. Es beobachtet weiterhin Abhängigkeitswerte, die `ObservableObject` entsprechen.

## 4. Neu: SwiftData-Unterstützung

3.0 fügt erstklassige SwiftData-Integration hinzu: Injizieren Sie einen gemeinsam genutzten `ModelContainer` als Abhängigkeit und lesen/schreiben Sie `@Model`-Objekte über `ModelState`. Siehe den [ModelState-Verwendungsleitfaden](usage-modelstate.md). Dies ist additiv und optional.

---
Diese Übersetzung wurde automatisch generiert und kann Fehler enthalten. Wenn Sie Muttersprachler sind, freuen wir uns über Ihre Korrekturvorschläge per Pull Request.
