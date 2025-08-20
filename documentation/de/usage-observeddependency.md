# Verwendung von ObservedDependency

`ObservedDependency` ist eine Komponente der **AppState**-Bibliothek, mit der Sie Abhängigkeiten verwenden können, die dem `ObservableObject`-Protokoll entsprechen. Dies ist nützlich, wenn Sie möchten, dass die Abhängigkeit Ihre SwiftUI-Ansichten über Änderungen benachrichtigt, wodurch Ihre Ansichten reaktiv und dynamisch werden.

## Hauptmerkmale

- **Beobachtbare Abhängigkeiten**: Verwenden Sie Abhängigkeiten, die dem `ObservableObject`-Protokoll entsprechen, sodass die Abhängigkeit Ihre Ansichten automatisch aktualisiert, wenn sich ihr Zustand ändert.
- **Reaktive UI-Aktualisierungen**: SwiftUI-Ansichten werden automatisch aktualisiert, wenn Änderungen von der beobachteten Abhängigkeit veröffentlicht werden.
- **Threadsicher**: Wie andere AppState-Komponenten gewährleistet `ObservedDependency` einen threadsicheren Zugriff auf die beobachtete Abhängigkeit.

## Anwendungsbeispiel

### Definieren einer beobachtbaren Abhängigkeit

So definieren Sie einen beobachtbaren Dienst als Abhängigkeit in der `Application`-Erweiterung:

```swift
import AppState
import SwiftUI

@MainActor
class ObservableService: ObservableObject {
    @Published var count: Int = 0
}

extension Application {
    @MainActor
    var observableService: Dependency<ObservableService> {
        dependency(ObservableService())
    }
}
```

### Verwendung der beobachteten Abhängigkeit in einer SwiftUI-Ansicht

In Ihrer SwiftUI-Ansicht können Sie mit dem `@ObservedDependency`-Property-Wrapper auf die beobachtbare Abhängigkeit zugreifen. Das beobachtete Objekt aktualisiert die Ansicht automatisch, wenn sich sein Zustand ändert.

```swift
import AppState
import SwiftUI

struct ObservedDependencyExampleView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        VStack {
            Text("Zähler: \(service.count)")
            Button("Zähler erhöhen") {
                service.count += 1
            }
        }
    }
}
```

### Testfall

Der folgende Testfall zeigt die Interaktion mit `ObservedDependency`:

```swift
import XCTest
@testable import AppState

@MainActor
fileprivate class ObservableService: ObservableObject {
    @Published var count: Int

    init() {
        count = 0
    }
}

fileprivate extension Application {
    @MainActor
    var observableService: Dependency<ObservableService> {
        dependency(ObservableService())
    }
}

@MainActor
fileprivate struct ExampleDependencyWrapper {
    @ObservedDependency(\.observableService) var service

    func test() {
        service.count += 1
    }
}

final class ObservedDependencyTests: XCTestCase {
    @MainActor
    func testDependency() async {
        let example = ExampleDependencyWrapper()

        XCTAssertEqual(example.service.count, 0)

        example.test()

        XCTAssertEqual(example.service.count, 1)
    }
}
```

### Reaktive UI-Aktualisierungen

Da die Abhängigkeit dem `ObservableObject`-Protokoll entspricht, löst jede Änderung ihres Zustands eine UI-Aktualisierung in der SwiftUI-Ansicht aus. Sie können den Zustand direkt an UI-Elemente wie einen `Picker` binden:

```swift
import AppState
import SwiftUI

struct ReactiveView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        Picker("Zähler auswählen", selection: $service.count) {
            ForEach(0..<10) { count in
                Text("\(count)").tag(count)
            }
        }
    }
}
```

## Bewährte Praktiken

- **Verwendung für beobachtbare Dienste**: `ObservedDependency` ist ideal, wenn Ihre Abhängigkeit Ansichten über Änderungen benachrichtigen muss, insbesondere für Dienste, die Daten- oder Zustandsaktualisierungen bereitstellen.
- **Veröffentlichte Eigenschaften nutzen**: Stellen Sie sicher, dass Ihre Abhängigkeit `@Published`-Eigenschaften verwendet, um Aktualisierungen in Ihren SwiftUI-Ansichten auszulösen.
- **Threadsicher**: Wie andere AppState-Komponenten gewährleistet `ObservedDependency` einen threadsicheren Zugriff und Änderungen am beobachtbaren Dienst.

## Fazit

`ObservedDependency` ist ein leistungsstarkes Werkzeug zur Verwaltung beobachtbarer Abhängigkeiten in Ihrer App. Durch die Nutzung des `ObservableObject`-Protokolls von Swift wird sichergestellt, dass Ihre SwiftUI-Ansichten reaktiv und auf dem neuesten Stand der Änderungen im Dienst oder in der Ressource bleiben.

---
Dies wurde mit Jules erstellt, es können Fehler auftreten. Bitte erstellen Sie einen Pull Request mit allen Korrekturen, die vorgenommen werden sollten, wenn Sie Muttersprachler sind.
