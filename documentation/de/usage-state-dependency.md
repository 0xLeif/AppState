# Verwendung von Zustand und Abhängigkeiten

**AppState** bietet leistungsstarke Werkzeuge zur Verwaltung des anwendungsweiten Zustands und zur Injektion von Abhängigkeiten in SwiftUI-Ansichten. Durch die Zentralisierung Ihres Zustands und Ihrer Abhängigkeiten können Sie sicherstellen, dass Ihre Anwendung konsistent und wartbar bleibt.

## Übersicht

- **Zustand**: Stellt einen Wert dar, der in der gesamten App gemeinsam genutzt werden kann. Zustandswerte können in Ihren SwiftUI-Ansichten geändert und beobachtet werden.
- **Abhängigkeit**: Stellt eine gemeinsam genutzte Ressource oder einen Dienst dar, der in SwiftUI-Ansichten injiziert und auf den zugegriffen werden kann.

### Hauptmerkmale

- **Zentralisierter Zustand**: Definieren und verwalten Sie den anwendungsweiten Zustand an einem Ort.
- **Abhängigkeitsinjektion**: Injizieren und greifen Sie auf gemeinsam genutzte Dienste und Ressourcen in verschiedenen Komponenten Ihrer Anwendung zu.

## Anwendungsbeispiel

### Definieren des Anwendungszustands

Um den anwendungsweiten Zustand zu definieren, erweitern Sie das `Application`-Objekt und deklarieren Sie die Zustandseigenschaften.

```swift
import AppState

struct User {
    var name: String
    var isLoggedIn: Bool
}

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }
}
```

### Zugreifen auf und Ändern von Zustand in einer Ansicht

Sie können mit dem `@AppState`-Property-Wrapper direkt in einer SwiftUI-Ansicht auf Zustandswerte zugreifen und diese ändern.

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("Hallo, \(user.name)!")
            Button("Anmelden") {
                user.name = "John Doe"
                user.isLoggedIn = true
            }
        }
    }
}
```

### Definieren von Abhängigkeiten

Sie können gemeinsam genutzte Ressourcen wie einen Netzwerkdienst als Abhängigkeiten im `Application`-Objekt definieren. Diese Abhängigkeiten können in SwiftUI-Ansichten injiziert werden.

```swift
import AppState

protocol NetworkServiceType {
    func fetchData() -> String
}

class NetworkService: NetworkServiceType {
    func fetchData() -> String {
        return "Data from network"
    }
}

extension Application {
    var networkService: Dependency<NetworkServiceType> {
        dependency(NetworkService())
    }
}
```

### Zugreifen auf Abhängigkeiten in einer Ansicht

Greifen Sie mit dem `@AppDependency`-Property-Wrapper in einer SwiftUI-Ansicht auf Abhängigkeiten zu. Dies ermöglicht es Ihnen, Dienste wie einen Netzwerkdienst in Ihre Ansicht zu injizieren.

```swift
import AppState
import SwiftUI

struct NetworkView: View {
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("Daten: \(networkService.fetchData())")
        }
    }
}
```

### Kombinieren von Zustand und Abhängigkeiten in einer Ansicht

Zustand und Abhängigkeiten können zusammenarbeiten, um eine komplexere Anwendungslogik zu erstellen. Sie können beispielsweise Daten von einem Dienst abrufen und den Zustand aktualisieren:

```swift
import AppState
import SwiftUI

struct CombinedView: View {
    @AppState(\.user) var user: User
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("Benutzer: \(user.name)")
            Button("Daten abrufen") {
                user.name = networkService.fetchData()
                user.isLoggedIn = true
            }
        }
    }
}
```

### Bewährte Praktiken

- **Zentralisieren Sie den Zustand**: Halten Sie Ihren anwendungsweiten Zustand an einem Ort, um Duplizierung zu vermeiden und Konsistenz zu gewährleisten.
- **Verwenden Sie Abhängigkeiten für gemeinsam genutzte Dienste**: Injizieren Sie Abhängigkeiten wie Netzwerkdienste, Datenbanken oder andere gemeinsam genutzte Ressourcen, um eine enge Kopplung zwischen den Komponenten zu vermeiden.

## Fazit

Mit **AppState** können Sie den anwendungsweiten Zustand verwalten und gemeinsam genutzte Abhängigkeiten direkt in Ihre SwiftUI-Ansichten injizieren. Dieses Muster hilft, Ihre App modular und wartbar zu halten. Entdecken Sie weitere Funktionen der **AppState**-Bibliothek wie [SecureState](usage-securestate.md) und [SyncState](usage-syncstate.md), um die Zustandsverwaltung Ihrer App weiter zu verbessern.
