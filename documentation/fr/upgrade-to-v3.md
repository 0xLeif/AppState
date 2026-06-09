# Mise à Niveau vers AppState 3.0

AppState 3.0 modernise la bibliothèque autour de Swift 6 et du framework
Observation d'Apple. Ce guide couvre les changements incompatibles et la manière
de s'y adapter.

## 1. Exigences de plate-forme relevées

Les cibles de déploiement minimales ont été relevées pour tirer parti des API
modernes de Swift et de SwiftData/Observation :

| Plate-forme | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux et Windows continuent d'être pris en charge pour l'ensemble des
fonctionnalités non-Apple.

Si vous devez continuer à prendre en charge des versions d'OS plus anciennes,
restez sur la ligne de version 2.x.

## 2. Swift 6 strict

Le package fixe désormais le mode de langage Swift 6 (`swiftLanguageModes: [.v6]`) et
la fonctionnalité à venir `ExistentialAny`, et la CI compile en traitant les
avertissements comme des erreurs. Pour la plupart des applications, cela ne nécessite
aucun changement. Si vous avez implémenté l'un des protocoles publics d'AppState
(par exemple un `FileManaging`, `UserDefaultsManaging` ou
`UbiquitousKeyValueStoreManaging` personnalisé), vous devrez peut-être écrire les
types existentiels avec un `any` explicite (par exemple `any FileManaging`).

## 3. Observation remplace ObservableObject

`Application` utilise désormais la macro [`@Observable`](https://developer.apple.com/documentation/observation)
au lieu de se conformer à `ObservableObject`.

**Aucun changement n'est requis pour une utilisation typique.** Les property wrappers — `@AppState`,
`@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`,
`@OptionalSlice`, `@DependencySlice` et `@ModelState` — continuent de fonctionner à l'intérieur
des vues SwiftUI et les vues se mettent à jour comme auparavant. Les modèles de vue qui se conforment à
`ObservableObject` et hébergent ces wrappers sont toujours pris en charge.

Ce qui a changé :

- `Application` ne se conforme plus à `ObservableObject`, de sorte que
  `Application.shared.objectWillChange` n'est plus disponible.
- Une nouvelle méthode, `Application.notifyChange()`, demande aux observateurs (les vues SwiftUI) de
  se mettre à jour. Les propres setters d'AppState l'appellent pour vous.

Si vous avez sous-classé `Application` et déclenché les mises à jour manuellement — par exemple depuis une
surcharge de `didChangeExternally(notification:)` qui réagit aux changements iCloud entrants —
remplacez `objectWillChange.send()` par `notifyChange()` :

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            // Avant (2.x) :
            // self.objectWillChange.send()

            // Après (3.0) :
            self.notifyChange()
        }
    }
}
```

> Remarque : `@ObservedDependency` est inchangé. Il observe toujours les valeurs de dépendance
> qui se conforment à `ObservableObject`.

## 4. Nouveau : prise en charge de SwiftData

La version 3.0 ajoute une intégration SwiftData de première classe : injectez un `ModelContainer` partagé en tant que
dépendance et lisez/écrivez les objets `@Model` via `ModelState`. Consultez le
[Guide d'Utilisation de ModelState](usage-modelstate.md). Cet ajout est additif et optionnel.

---
Cette traduction a été générée automatiquement et peut contenir des erreurs. Si vous êtes un locuteur natif, nous vous serions reconnaissants de contribuer avec des corrections via une Pull Request.
