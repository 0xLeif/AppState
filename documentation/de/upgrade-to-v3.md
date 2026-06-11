# Upgrade auf AppState 3.0

AppState 3.0 ist rund um Swift 6 und Apples Observation-Framework aufgebaut. Im Folgenden finden Sie die Breaking Changes und wie Sie sich anpassen.

## Breaking Changes auf einen Blick

- **Plattform-Mindestversionen angehoben** — iOS 17, macOS 14, tvOS 17, watchOS 10
- **Strikte Swift-6-Nebenläufigkeit** — `ExistentialAny` aktiviert; explizites `any` bei Protokoll-Existentialen erforderlich
- **`ObservableObject` entfernt** — `Application` verwendet `@Observable`; `objectWillChange` ist weg, ersetzt durch `notifyChange()`
- **Neu (additiv): SwiftData-Unterstützung** — `ModelState` / `@ModelState` für `@Model`-Objekte

---

## 1. Erhöhte Plattformanforderungen

| Plattform | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux und Windows werden für den Funktionsumfang ohne Apple-Bezug weiterhin unterstützt.

Bleiben Sie bei der 2.x-Release-Linie, wenn Sie ältere Betriebssystemversionen unterstützen müssen.

## 2. Striktes Swift 6

Das Paket fixiert den Swift-6-Sprachmodus (`swiftLanguageModes: [.v6]`) und aktiviert das anstehende Feature `ExistentialAny`. CI-Builds behandeln Warnungen als Fehler.

Für die meisten Apps sind keine Änderungen erforderlich. Wenn Sie eines der öffentlichen Protokolle von AppState implementiert haben — `FileManaging`, `UserDefaultsManaging` oder `UbiquitousKeyValueStoreManaging` —, müssen Sie möglicherweise existenzielle Typen mit einem expliziten `any` schreiben:

```swift
// Before (2.x)
var fileManager: FileManaging

// After (3.0)
var fileManager: any FileManaging
```

## 3. Observation ersetzt ObservableObject

`Application` verwendet jetzt [`@Observable`](https://developer.apple.com/documentation/observation) anstelle von `ObservableObject`.

**Die Property-Wrapper sind unverändert.** `@AppState`, `@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`, `@OptionalSlice`, `@DependencySlice` und `@ModelState` funktionieren allesamt weiterhin in SwiftUI-Ansichten. View-Modelle, die `ObservableObject` entsprechen und diese Wrapper hosten, werden weiterhin unterstützt.

Was sich geändert hat:

- `Application.shared.objectWillChange` existiert nicht mehr.
- `Application.notifyChange()` ersetzt es. Die eigenen Setter von AppState rufen es automatisch auf.
- Das direkte Lesen von `Application.state(_:).value` nimmt jetzt an der Observation teil — nicht nur der `@AppState`-Wrapper. Das bedeutet, dass beliebiger Code (nicht nur SwiftUI-Ansichten) Zustandsänderungen beobachten kann:

  ```swift
  withObservationTracking {
      _ = Application.state(\.counter).value
  } onChange: {
      // runs when the value changes — no SwiftUI required
  }
  ```

Wenn Sie `Application` abgeleitet und `objectWillChange.send()` manuell aufgerufen haben (z. B. aus einem `didChangeExternally`-Override), ersetzen Sie es durch `notifyChange()`:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            self.notifyChange()
        }
    }
}
```

> `@ObservedDependency` ist unverändert — es beobachtet weiterhin Abhängigkeitswerte, die `ObservableObject` entsprechen.

## 4. Neu: SwiftData-Unterstützung

3.0 fügt SwiftData-Integration hinzu. Injizieren Sie einen gemeinsam genutzten `ModelContainer` als Abhängigkeit und lesen/schreiben Sie `@Model`-Objekte über `ModelState`. Dies ist additiv und optional — siehe den [ModelState-Verwendungsleitfaden](usage-modelstate.md).

---
Diese Übersetzung wurde automatisch generiert und kann Fehler enthalten. Wenn Sie Muttersprachler sind, freuen wir uns über Ihre Korrekturvorschläge per Pull Request.
