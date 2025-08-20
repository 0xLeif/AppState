# Utilisation de ObservedDependency

`ObservedDependency` est un composant de la bibliothèque **AppState** qui vous permet d'utiliser des dépendances conformes à `ObservableObject`. Ceci est utile lorsque vous souhaitez que la dépendance notifie vos vues SwiftUI des changements, rendant vos vues réactives et dynamiques.

## Fonctionnalités Clés

- **Dépendances Observables** : Utilisez des dépendances conformes à `ObservableObject`, permettant à la dépendance de mettre à jour automatiquement vos vues lorsque son état change.
- **Mises à Jour d'IU Réactives** : Les vues SwiftUI se mettent à jour automatiquement lorsque des changements sont publiés par la dépendance observée.
- **Thread-Safe** : Comme les autres composants d'AppState, `ObservedDependency` garantit un accès thread-safe à la dépendance observée.

## Exemple d'Utilisation

### Définir une Dépendance Observable

Voici comment définir un service observable en tant que dépendance dans l'extension `Application` :

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

### Utiliser la Dépendance Observée dans une Vue SwiftUI

Dans votre vue SwiftUI, vous pouvez accéder à la dépendance observable à l'aide du property wrapper `@ObservedDependency`. L'objet observé met automatiquement à jour la vue chaque fois que son état change.

```swift
import AppState
import SwiftUI

struct ObservedDependencyExampleView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        VStack {
            Text("Compte : \(service.count)")
            Button("Incrémenter le Compte") {
                service.count += 1
            }
        }
    }
}
```

### Cas de Test

Le cas de test suivant démontre l'interaction avec `ObservedDependency` :

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

### Mises à Jour d'IU Réactives

Étant donné que la dépendance est conforme à `ObservableObject`, toute modification de son état déclenchera une mise à jour de l'IU dans la vue SwiftUI. Vous pouvez lier directement l'état à des éléments d'IU comme un `Picker` :

```swift
import AppState
import SwiftUI

struct ReactiveView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        Picker("Sélectionner le Compte", selection: $service.count) {
            ForEach(0..<10) { count in
                Text("\(count)").tag(count)
            }
        }
    }
}
```

## Meilleures Pratiques

- **Utiliser pour les Services Observables** : `ObservedDependency` est idéal lorsque votre dépendance doit notifier les vues des changements, en particulier pour les services qui fournissent des mises à jour de données ou d'état.
- **Tirer Parti des Propriétés Publiées** : Assurez-vous que votre dépendance utilise des propriétés `@Published` pour déclencher des mises à jour dans vos vues SwiftUI.
- **Thread-Safe** : Comme les autres composants d'AppState, `ObservedDependency` garantit un accès et des modifications thread-safe au service observable.

## Conclusion

`ObservedDependency` est un outil puissant pour gérer les dépendances observables au sein de votre application. En tirant parti du protocole `ObservableObject` de Swift, il garantit que vos vues SwiftUI restent réactives et à jour avec les changements dans le service ou la ressource.

---
Ceci a été généré à l'aide de [Jules](https://jules.google), des erreurs peuvent survenir. Veuillez faire une Pull Request avec les corrections qui devraient être apportées si vous êtes un locuteur natif.
