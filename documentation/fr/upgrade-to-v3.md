# Mise à Niveau vers AppState 3.0

AppState 3.0 est construit autour de Swift 6 et du framework Observation d'Apple. Vous trouverez ci-dessous les changements incompatibles et la manière de s'y adapter.

## Aperçu des changements incompatibles

- **Versions minimales des plates-formes relevées** — iOS 17, macOS 14, tvOS 17, watchOS 10
- **Concurrence stricte de Swift 6** — `ExistentialAny` activé ; `any` explicite requis sur les existentiels de protocole
- **`ObservableObject` supprimé** — `Application` utilise `@Observable` ; `objectWillChange` a disparu, à remplacer par `notifyChange()`
- **Nouveau (additif) : prise en charge de SwiftData** — `ModelState` / `@ModelState` pour les objets `@Model`

---

## 1. Versions minimales des plates-formes relevées

| Plate-forme | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux et Windows continuent d'être pris en charge pour l'ensemble des fonctionnalités non-Apple.

Restez sur la ligne de version 2.x si vous devez prendre en charge des versions d'OS plus anciennes.

## 2. Swift 6 strict

Le package fixe le mode de langage Swift 6 (`swiftLanguageModes: [.v6]`) et active la fonctionnalité à venir `ExistentialAny`. La CI compile en traitant les avertissements comme des erreurs.

La plupart des applications ne nécessitent aucune modification. Si vous avez implémenté l'un des protocoles publics d'AppState — `FileManaging`, `UserDefaultsManaging` ou `UbiquitousKeyValueStoreManaging` — vous devrez peut-être écrire les types existentiels avec un `any` explicite :

```swift
// Before (2.x)
var fileManager: FileManaging

// After (3.0)
var fileManager: any FileManaging
```

## 3. Observation remplace ObservableObject

`Application` utilise désormais [`@Observable`](https://developer.apple.com/documentation/observation) au lieu de `ObservableObject`.

**Les property wrappers sont inchangés.** `@AppState`, `@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`, `@OptionalSlice`, `@DependencySlice` et `@ModelState` continuent tous de fonctionner à l'intérieur des vues SwiftUI. Les modèles de vue qui se conforment à `ObservableObject` et hébergent ces wrappers sont toujours pris en charge.

Ce qui a changé :

- `Application.shared.objectWillChange` n'existe plus.
- `Application.notifyChange()` le remplace. Les propres setters d'AppState l'appellent automatiquement.
- Lire directement `Application.state(_:).value` participe désormais à l'Observation — pas seulement le wrapper `@AppState`. Cela signifie que n'importe quel code (pas seulement les vues SwiftUI) peut observer les changements d'état :

  ```swift
  withObservationTracking {
      _ = Application.state(\.counter).value
  } onChange: {
      // runs when the value changes — no SwiftUI required
  }
  ```

Si vous avez sous-classé `Application` et appelé `objectWillChange.send()` manuellement (par exemple, depuis une surcharge de `didChangeExternally`), remplacez-le par `notifyChange()` :

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

> `@ObservedDependency` est inchangé — il observe toujours les valeurs de dépendance qui se conforment à `ObservableObject`.

## 4. Nouveau : prise en charge de SwiftData

La version 3.0 ajoute l'intégration de SwiftData. Injectez un `ModelContainer` partagé en tant que dépendance et lisez/écrivez les objets `@Model` via `ModelState`. Cet ajout est additif et optionnel — consultez le [Guide d'Utilisation de ModelState](usage-modelstate.md).

---
Cette traduction a été générée automatiquement et peut contenir des erreurs. Si vous êtes un locuteur natif, nous vous serions reconnaissants de contribuer avec des corrections via une Pull Request.
