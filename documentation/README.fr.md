# AppState

[![macOS Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/macOS.yml?label=macOS&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/macOS.yml)
[![Ubuntu Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/ubuntu.yml?label=Ubuntu&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/ubuntu.yml)
[![Windows Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/windows.yml?label=Windows&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/windows.yml)
[![License](https://img.shields.io/github/license/0xLeif/AppState)](https://github.com/0xLeif/AppState/blob/main/LICENSE)
[![Version](https://img.shields.io/github/v/release/0xLeif/AppState)](https://github.com/0xLeif/AppState/releases)

**AppState** est une bibliothèque Swift 6 conçue pour simplifier la gestion de l'état de l'application de manière thread-safe, type-safe et compatible avec SwiftUI. Elle fournit un ensemble d'outils pour centraliser et synchroniser l'état à travers votre application, ainsi que pour injecter des dépendances dans diverses parties de votre application.

## Exigences

- **iOS**: 15.0+
- **watchOS**: 8.0+
- **macOS**: 11.0+
- **tvOS**: 15.0+
- **visionOS**: 1.0+
- **Swift**: 6.0+
- **Xcode**: 16.0+

**Prise en charge des plates-formes non-Apple**: Linux et Windows

> 🍎 Les fonctionnalités marquées de ce symbole sont spécifiques aux plates-formes Apple, car elles reposent sur des technologies Apple telles qu'iCloud et le Trousseau.

## Fonctionnalités Clés

**AppState** inclut plusieurs fonctionnalités puissantes pour aider à gérer l'état et les dépendances :

- **State**: Gestion centralisée de l'état qui vous permet d'encapsuler et de diffuser les changements à travers l'application.
- **StoredState**: État persistant utilisant `UserDefaults`, idéal pour sauvegarder de petites quantités de données entre les lancements de l'application.
- **FileState**: État persistant stocké à l'aide de `FileManager`, utile pour stocker de plus grandes quantités de données en toute sécurité sur le disque.
- 🍎 **SyncState**: Synchronisez l'état sur plusieurs appareils à l'aide d'iCloud, garantissant la cohérence des préférences et des paramètres de l'utilisateur.
- 🍎 **SecureState**: Stockez les données sensibles en toute sécurité à l'aide du Trousseau, protégeant les informations de l'utilisateur telles que les jetons ou les mots de passe.
- **Gestion des Dépendances**: Injectez des dépendances comme des services réseau ou des clients de base de données à travers votre application pour une meilleure modularité et des tests facilités.
- **Slicing**: Accédez à des parties spécifiques d'un état ou d'une dépendance pour un contrôle granulaire sans avoir à gérer l'état complet de l'application.
- **Constants**: Accédez à des tranches en lecture seule de votre état lorsque vous avez besoin de valeurs immuables.
- **Observed Dependencies**: Observez les dépendances `ObservableObject` pour que vos vues se mettent à jour lorsqu'elles changent.

## Pour Commencer

Pour intégrer **AppState** dans votre projet Swift, vous devrez utiliser le Swift Package Manager. Suivez le [Guide d'Installation](fr/installation.md) pour des instructions détaillées sur la configuration de **AppState**.

Après l'installation, consultez l'[Aperçu de l'Utilisation](fr/usage-overview.md) pour une introduction rapide sur la manière de gérer l'état et d'injecter des dépendances dans votre projet.

## Exemple Rapide

Voici un exemple minimal montrant comment définir une tranche d'état et y accéder depuis une vue SwiftUI :

```swift
import AppState
import SwiftUI

private extension Application {
    var counter: State<Int> {
        state(initial: 0)
    }
}

struct ContentView: View {
    @AppState(\.counter) var counter: Int

    var body: some View {
        VStack {
            Text("Compteur: \(counter)")
            Button("Incrémenter") { counter += 1 }
        }
    }
}
```

Cet extrait montre comment définir une valeur d'état dans une extension `Application` et utiliser le property wrapper `@AppState` pour la lier à l'intérieur d'une vue.

## Documentation

Voici une ventilation détaillée de la documentation de **AppState** :

- [Guide d'Installation](fr/installation.md) : Comment ajouter **AppState** à votre projet à l'aide du Swift Package Manager.
- [Aperçu de l'Utilisation](fr/usage-overview.md) : Un aperçu des fonctionnalités clés avec des exemples d'implémentation.

### Guides d'Utilisation Détaillés :

- [Gestion de l'État et des Dépendances](fr/usage-state-dependency.md) : Centralisez l'état et injectez des dépendances dans toute votre application.
- [Découpage de l'État (Slicing)](fr/usage-slice.md) : Accédez et modifiez des parties spécifiques de l'état.
- [Guide d'Utilisation de StoredState](fr/usage-storedstate.md) : Comment persister des données légères à l'aide de `StoredState`.
- [Guide d'Utilisation de FileState](fr/usage-filestate.md) : Apprenez à persister de plus grandes quantités de données en toute sécurité sur le disque.
- [Utilisation de SecureState avec le Trousseau](fr/usage-securestate.md) : Stockez les données sensibles en toute sécurité à l'aide du Trousseau.
- [Synchronisation iCloud avec SyncState](fr/usage-syncstate.md) : Maintenez l'état synchronisé sur tous les appareils à l'aide d'iCloud.
- [FAQ](fr/faq.md) : Réponses aux questions courantes lors de l'utilisation de **AppState**.
- [Guide d'Utilisation des Constantes](fr/usage-constant.md) : Accédez à des valeurs en lecture seule de votre état.
- [Guide d'Utilisation de ObservedDependency](fr/usage-observeddependency.md) : Travaillez avec des dépendances `ObservableObject` dans vos vues.
- [Utilisation Avancée](fr/advanced-usage.md) : Techniques telles que la création juste à temps et le préchargement des dépendances.
- [Meilleures Pratiques](fr/best-practices.md) : Conseils pour structurer efficacement l'état de votre application.
- [Considérations sur la Migration](fr/migration-considerations.md) : Guide pour la mise à jour des modèles persistants.

## Contributions

Nous accueillons les contributions ! Veuillez consulter notre [Guide de Contribution](fr/contributing.md) pour savoir comment vous impliquer.

## Prochaines Étapes

Une fois **AppState** installé, vous pouvez commencer à explorer ses fonctionnalités clés en consultant l'[Aperçu de l'Utilisation](fr/usage-overview.md) et des guides plus détaillés. Commencez à gérer efficacement l'état et les dépendances dans vos projets Swift ! Pour des techniques d'utilisation plus avancées, comme la création Juste-à-Temps et le préchargement des dépendances, consultez le [Guide d'Utilisation Avancée](fr/advanced-usage.md). Vous pouvez également consulter les guides [Constant](fr/usage-constant.md) et [ObservedDependency](fr/usage-observeddependency.md) pour des fonctionnalités supplémentaires.

---
Cette traduction a été générée automatiquement et peut contenir des erreurs. Si vous êtes un locuteur natif, nous vous serions reconnaissants de contribuer avec des corrections via une Pull Request.
