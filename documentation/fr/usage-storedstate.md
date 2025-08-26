# Utilisation de StoredState

`StoredState` est un composant de la bibliothèque **AppState** qui vous permet de stocker et de persister de petites quantités de données à l'aide de `UserDefaults`. Il est idéal pour stocker des données légères et non sensibles qui doivent persister entre les lancements de l'application.

## Vue d'ensemble

- **StoredState** est construit sur `UserDefaults`, ce qui signifie qu'il est rapide et efficace pour stocker de petites quantités de données (telles que les préférences de l'utilisateur ou les paramètres de l'application).
- Les données enregistrées dans **StoredState** persistent entre les sessions de l'application, ce qui vous permet de restaurer l'état de l'application au lancement.

### Fonctionnalités Clés

- **Stockage Persistant** : Les données enregistrées dans `StoredState` restent disponibles entre les lancements de l'application.
- **Gestion des Petites Données** : Idéal pour les données légères comme les préférences, les bascules ou les petites configurations.
- **Thread-Safe** : `StoredState` garantit que l'accès aux données reste sécurisé dans les environnements concurrents.

## Exemple d'Utilisation

### Définir un StoredState

Vous pouvez définir un **StoredState** en étendant l'objet `Application` et en déclarant la propriété d'état :

```swift
import AppState

extension Application {
    var userPreferences: StoredState<String> {
        storedState(initial: "Default Preferences", id: "userPreferences")
    }
}
```

### Accéder et Modifier StoredState dans une Vue

Vous pouvez accéder et modifier les valeurs de **StoredState** dans les vues SwiftUI à l'aide du property wrapper `@StoredState` :

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

## Gérer la Migration des Données

À mesure que votre application évolue, vous pouvez mettre à jour les modèles qui sont persistants via **StoredState**. Lors de la mise à jour de votre modèle de données, assurez-vous de la compatibilité ascendante. Par exemple, vous pouvez ajouter de nouveaux champs ou versionner votre modèle pour gérer la migration.

Pour plus d'informations, consultez le [Guide des Considérations sur la Migration](migration-considerations.md).

### Considérations sur la Migration

- **Ajout de Nouveaux Champs Non Optionnels** : Assurez-vous que les nouveaux champs sont soit optionnels, soit qu'ils ont des valeurs par défaut pour maintenir la compatibilité ascendante.
- **Versionnement des Modèles** : Si votre modèle de données change au fil du temps, incluez un champ `version` pour gérer les différentes versions de vos données persistantes.

## Meilleures Pratiques

- **Utiliser pour de Petites Données** : Stockez des données légères et non sensibles qui doivent persister entre les lancements de l'application, comme les préférences de l'utilisateur.
- **Envisager des Alternatives pour les Données plus Volumineuses** : Si vous devez stocker de grandes quantités de données, envisagez d'utiliser **FileState** à la place.

## Conclusion

**StoredState** est un moyen simple et efficace de persister de petites quantités de données à l'aide de `UserDefaults`. Il est idéal pour enregistrer les préférences et autres petits paramètres entre les lancements de l'application tout en offrant un accès sécurisé et une intégration facile avec SwiftUI. Pour des besoins de persistance plus complexes, explorez d'autres fonctionnalités de **AppState** comme [FileState](usage-filestate.md) ou [SyncState](usage-syncstate.md).

---
Cette traduction a été générée automatiquement et peut contenir des erreurs. Si vous êtes un locuteur natif, nous vous serions reconnaissants de contribuer avec des corrections via une Pull Request.
