# Verwendungsübersicht

Diese Übersicht bietet eine schnelle Einführung in die Verwendung der Schlüsselkomponenten der **AppState**-Bibliothek in einer SwiftUI-`View`. Jeder Abschnitt enthält einfache Beispiele, die in den Rahmen einer SwiftUI-Ansichtsstruktur passen.

## Definieren von Werten in der Anwendungserweiterung

Um anwendungsweite Zustände oder Abhängigkeiten zu definieren, sollten Sie das `Application`-Objekt erweitern. Dies ermöglicht es Ihnen, den gesamten Zustand Ihrer App an einem Ort zu zentralisieren. Hier ist ein Beispiel, wie Sie `Application` erweitern können, um verschiedene Zustände und Abhängigkeiten zu erstellen:

```swift
import AppState

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }

    var userPreferences: StoredState<String> {
        storedState(initial: "Default Preferences", id: "userPreferences")
    }

    var darkModeEnabled: SyncState<Bool> {
        syncState(initial: false, id: "darkModeEnabled")
    }

    var userToken: SecureState {
        secureState(id: "userToken")
    }

    @MainActor
    var largeDataset: FileState<[String]> {
        fileState(initial: [], filename: "largeDataset")
    }
}
```

## State

`State` ermöglicht es Ihnen, einen anwendungsweiten Zustand zu definieren, auf den überall in Ihrer App zugegriffen und der geändert werden kann.

### Beispiel

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("Hallo, \(user.name)!")
            Button("Anmelden") {
                user.isLoggedIn.toggle()
            }
        }
    }
}
```

## StoredState

`StoredState` speichert den Zustand mit `UserDefaults`, um sicherzustellen, dass die Werte über App-Starts hinweg gespeichert werden.

### Beispiel

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

## SyncState

`SyncState` synchronisiert den App-Zustand über mehrere Geräte hinweg mit iCloud.

### Beispiel

```swift
import AppState
import SwiftUI

struct SyncSettingsView: View {
    @SyncState(\.darkModeEnabled) var isDarkModeEnabled: Bool

    var body: some View {
        VStack {
            Toggle("Dunkelmodus", isOn: $isDarkModeEnabled)
        }
    }
}
```

## FileState

`FileState` wird verwendet, um größere oder komplexere Daten dauerhaft im Dateisystem zu speichern, was es ideal für das Caching oder das Speichern von Daten macht, die nicht in die Grenzen von `UserDefaults` passen.

### Beispiel

```swift
import AppState
import SwiftUI

struct LargeDataView: View {
    @FileState(\.largeDataset) var largeDataset: [String]

    var body: some View {
        List(largeDataset, id: \.self) { item in
            Text(item)
        }
    }
}
```

## SecureState

`SecureState` speichert vertrauliche Daten sicher im Schlüsselbund.

### Beispiel

```swift
import AppState
import SwiftUI

struct SecureView: View {
    @SecureState(\.userToken) var userToken: String?

    var body: some View {
        VStack {
            if let token = userToken {
                Text("Benutzertoken: \(token)")
            } else {
                Text("Kein Token gefunden.")
            }
            Button("Token festlegen") {
                userToken = "secure_token_value"
            }
        }
    }
}
```

## Constant

`Constant` bietet unveränderlichen, schreibgeschützten Zugriff auf Werte im Zustand Ihrer Anwendung und gewährleistet so die Sicherheit beim Zugriff auf Werte, die nicht geändert werden sollen.

### Beispiel

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.user, \.name) var name: String

    var body: some View {
        Text("Benutzername: \(name)")
    }
}
```

## Slicing State

`Slice` und `OptionalSlice` ermöglichen den Zugriff auf bestimmte Teile des Zustands Ihrer Anwendung.

### Beispiel

```swift
import AppState
import SwiftUI

struct SlicingView: View {
    @Slice(\.user, \.name) var name: String

    var body: some View {
        VStack {
            Text("Benutzername: \(name)")
            Button("Benutzernamen aktualisieren") {
                name = "NewUsername"
            }
        }
    }
}
```

## Bewährte Praktiken

- **Verwenden Sie `AppState` in SwiftUI-Ansichten**: Eigenschafts-Wrapper wie `@AppState`, `@StoredState`, `@FileState`, `@SecureState` und andere sind für die Verwendung im Geltungsbereich von SwiftUI-Ansichten konzipiert.
- **Definieren Sie den Zustand in der Anwendungserweiterung**: Zentralisieren Sie die Zustandsverwaltung, indem Sie `Application` erweitern, um den Zustand und die Abhängigkeiten Ihrer App zu definieren.
- **Reaktive Aktualisierungen**: SwiftUI aktualisiert Ansichten automatisch, wenn sich der Zustand ändert, sodass Sie die Benutzeroberfläche nicht manuell aktualisieren müssen.
- **[Leitfaden zu bewährten Praktiken](./best-practices.md)**: Für eine detaillierte Aufschlüsselung der bewährten Praktiken bei der Verwendung von AppState.

## Nächste Schritte

Nachdem Sie sich mit der grundlegenden Verwendung vertraut gemacht haben, können Sie sich mit fortgeschritteneren Themen befassen:

- Erkunden Sie die Verwendung von **FileState** zum dauerhaften Speichern großer Datenmengen in Dateien im [FileState-Verwendungsleitfaden](./usage-filestate.md).
- Erfahren Sie mehr über **Konstanten** und wie Sie sie für unveränderliche Werte im Zustand Ihrer App verwenden können, im [Konstanten-Verwendungsleitfaden](./usage-constant.md).
- Untersuchen Sie, wie **Dependency** in AppState verwendet wird, um gemeinsam genutzte Dienste zu verarbeiten, und sehen Sie sich Beispiele im [Zustandsabhängigkeits-Verwendungsleitfaden](./usage-state-dependency.md) an.
- Tauchen Sie tiefer in fortgeschrittene **SwiftUI**-Techniken wie die Verwendung von `ObservedDependency` zur Verwaltung beobachtbarer Abhängigkeiten in Ansichten im [ObservedDependency-Verwendungsleitfaden](./usage-observeddependency.md) ein.
- Informationen zu fortgeschritteneren Verwendungstechniken wie der Just-in-Time-Erstellung und dem Vorabladen von Abhängigkeiten finden Sie im [Leitfaden zur erweiterten Verwendung](./advanced-usage.md).
