# Aperçu de l'Utilisation

Cet aperçu fournit une introduction rapide à l'utilisation des composants clés de la bibliothèque **AppState** dans une `View` SwiftUI. Chaque section comprend des exemples simples qui s'inscrivent dans le cadre d'une structure de vue SwiftUI.

## Définition des Valeurs dans l'Extension Application

Pour définir un état ou des dépendances à l'échelle de l'application, vous devez étendre l'objet `Application`. Cela vous permet de centraliser tout l'état de votre application en un seul endroit. Voici un exemple de la manière d'étendre `Application` pour créer divers états et dépendances :

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

`State` vous permet de définir un état à l'échelle de l'application qui peut être accédé et modifié n'importe où dans votre application.

### Exemple

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("Bonjour, \(user.name)!")
            Button("Se connecter") {
                user.isLoggedIn.toggle()
            }
        }
    }
}
```

## StoredState

`StoredState` persiste l'état en utilisant `UserDefaults` pour garantir que les valeurs sont sauvegardées entre les lancements de l'application.

### Exemple

```swift
import AppState
import SwiftUI

struct PreferencesView: View {
    @StoredState(\.userPreferences) var userPreferences: String

    var body: some View {
        VStack {
            Text("Préférences : \(userPreferences)")
            Button("Mettre à jour les préférences") {
                userPreferences = "Updated Preferences"
            }
        }
    }
}
```

## SyncState

`SyncState` synchronise l'état de l'application sur plusieurs appareils à l'aide d'iCloud.

### Exemple

```swift
import AppState
import SwiftUI

struct SyncSettingsView: View {
    @SyncState(\.darkModeEnabled) var isDarkModeEnabled: Bool

    var body: some View {
        VStack {
            Toggle("Mode Sombre", isOn: $isDarkModeEnabled)
        }
    }
}
```

## FileState

`FileState` est utilisé pour stocker des données plus volumineuses ou plus complexes de manière persistante à l'aide du système de fichiers, ce qui le rend idéal pour la mise en cache ou la sauvegarde de données qui ne rentrent pas dans les limites de `UserDefaults`.

### Exemple

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

`SecureState` stocke les données sensibles de manière sécurisée dans le Trousseau.

### Exemple

```swift
import AppState
import SwiftUI

struct SecureView: View {
    @SecureState(\.userToken) var userToken: String?

    var body: some View {
        VStack {
            if let token = userToken {
                Text("Jeton utilisateur : \(token)")
            } else {
                Text("Aucun jeton trouvé.")
            }
            Button("Définir le jeton") {
                userToken = "secure_token_value"
            }
        }
    }
}
```

## Constant

`Constant` fournit un accès immuable et en lecture seule aux valeurs de l'état de votre application, garantissant la sécurité lors de l'accès à des valeurs qui ne doivent pas être modifiées.

### Exemple

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.user, \.name) var name: String

    var body: some View {
        Text("Nom d'utilisateur : \(name)")
    }
}
```

## Slicing State

`Slice` et `OptionalSlice` vous permettent d'accéder à des parties spécifiques de l'état de votre application.

### Exemple

```swift
import AppState
import SwiftUI

struct SlicingView: View {
    @Slice(\.user, \.name) var name: String

    var body: some View {
        VStack {
            Text("Nom d'utilisateur : \(name)")
            Button("Mettre à jour le nom d'utilisateur") {
                name = "NewUsername"
            }
        }
    }
}
```

## Meilleures Pratiques

- **Utilisez `AppState` dans les Vues SwiftUI** : Les property wrappers comme `@AppState`, `@StoredState`, `@FileState`, `@SecureState`, et d'autres sont conçus pour être utilisés dans le cadre des vues SwiftUI.
- **Définissez l'État dans l'Extension Application** : Centralisez la gestion de l'état en étendant `Application` pour définir l'état et les dépendances de votre application.
- **Mises à Jour Réactives** : SwiftUI met automatiquement à jour les vues lorsque l'état change, vous n'avez donc pas besoin de rafraîchir manuellement l'interface utilisateur.
- **[Guide des Meilleures Pratiques](./best-practices.md)** : Pour une description détaillée des meilleures pratiques lors de l'utilisation d'AppState.

## Prochaines Étapes

Après vous être familiarisé avec l'utilisation de base, vous pouvez explorer des sujets plus avancés :

- Explorez l'utilisation de **FileState** pour persister de grandes quantités de données dans des fichiers dans le [Guide d'Utilisation de FileState](./usage-filestate.md).
- Apprenez-en davantage sur les **Constantes** et comment les utiliser pour des valeurs immuables dans l'état de votre application dans le [Guide d'Utilisation des Constantes](./usage-constant.md).
- Examinez comment **Dependency** est utilisé dans AppState pour gérer les services partagés, et consultez des exemples dans le [Guide d'Utilisation de la Dépendance d'État](./usage-state-dependency.md).
- Approfondissez les techniques avancées de **SwiftUI** comme l'utilisation de `ObservedDependency` pour gérer les dépendances observables dans les vues dans le [Guide d'Utilisation de ObservedDependency](./usage-observeddependency.md).
- Pour des techniques d'utilisation plus avancées, comme la création Juste-à-Temps et le préchargement des dépendances, consultez le [Guide d'Utilisation Avancée](./advanced-usage.md).
