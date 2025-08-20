# Utilisation de l'État et des Dépendances

**AppState** fournit des outils puissants pour gérer l'état à l'échelle de l'application et injecter des dépendances dans les vues SwiftUI. En centralisant votre état et vos dépendances, vous pouvez vous assurer que votre application reste cohérente et maintenable.

## Vue d'ensemble

- **État** : Représente une valeur qui peut être partagée dans toute l'application. Les valeurs d'état peuvent être modifiées et observées dans vos vues SwiftUI.
- **Dépendance** : Représente une ressource ou un service partagé qui peut être injecté et accédé dans les vues SwiftUI.

### Fonctionnalités Clés

- **État Centralisé** : Définissez et gérez l'état à l'échelle de l'application en un seul endroit.
- **Injection de Dépendances** : Injectez et accédez à des services et des ressources partagés dans différents composants de votre application.

## Exemple d'Utilisation

### Définir l'État de l'Application

Pour définir l'état à l'échelle de l'application, étendez l'objet `Application` et déclarez les propriétés d'état.

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

### Accéder et Modifier l'État dans une Vue

Vous pouvez accéder et modifier les valeurs d'état directement dans une vue SwiftUI à l'aide du property wrapper `@AppState`.

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("Bonjour, \(user.name)!")
            Button("Se connecter") {
                user.name = "John Doe"
                user.isLoggedIn = true
            }
        }
    }
}
```

### Définir des Dépendances

Vous pouvez définir des ressources partagées, comme un service réseau, en tant que dépendances dans l'objet `Application`. Ces dépendances peuvent être injectées dans les vues SwiftUI.

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

### Accéder aux Dépendances dans une Vue

Accédez aux dépendances dans une vue SwiftUI à l'aide du property wrapper `@AppDependency`. Cela vous permet d'injecter des services comme un service réseau dans votre vue.

```swift
import AppState
import SwiftUI

struct NetworkView: View {
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("Données : \(networkService.fetchData())")
        }
    }
}
```

### Combiner État et Dépendances dans une Vue

L'état et les dépendances peuvent fonctionner ensemble pour créer une logique d'application plus complexe. Par exemple, vous pouvez récupérer des données d'un service et mettre à jour l'état :

```swift
import AppState
import SwiftUI

struct CombinedView: View {
    @AppState(\.user) var user: User
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("Utilisateur : \(user.name)")
            Button("Récupérer les données") {
                user.name = networkService.fetchData()
                user.isLoggedIn = true
            }
        }
    }
}
```

### Meilleures Pratiques

- **Centraliser l'État** : Gardez l'état de votre application en un seul endroit pour éviter la duplication et garantir la cohérence.
- **Utiliser les Dépendances pour les Services Partagés** : Injectez des dépendances comme des services réseau, des bases de données ou d'autres ressources partagées pour éviter un couplage étroit entre les composants.

## Conclusion

Avec **AppState**, vous pouvez gérer l'état à l'échelle de l'application et injecter des dépendances partagées directement dans vos vues SwiftUI. Ce modèle permet de garder votre application modulaire et maintenable. Explorez d'autres fonctionnalités de la bibliothèque **AppState**, telles que [SecureState](usage-securestate.md) et [SyncState](usage-syncstate.md), pour améliorer encore la gestion de l'état de votre application.

---
Ceci a été généré à l'aide de [Jules](https://jules.google), des erreurs peuvent survenir. Veuillez faire une Pull Request avec les corrections qui devraient être apportées si vous êtes un locuteur natif.
