# Utilisation de SyncState

`SyncState` est un composant de la bibliothèque **AppState** qui vous permet de synchroniser l'état de l'application sur plusieurs appareils à l'aide d'iCloud. Ceci est particulièrement utile pour maintenir la cohérence des préférences utilisateur, des paramètres ou d'autres données importantes sur tous les appareils.

## Vue d'ensemble

`SyncState` s'appuie sur le `NSUbiquitousKeyValueStore` d'iCloud pour synchroniser de petites quantités de données sur tous les appareils. Cela le rend idéal pour synchroniser un état d'application léger tel que les préférences ou les paramètres utilisateur.

### Fonctionnalités Clés

- **Synchronisation iCloud** : Synchronise automatiquement l'état sur tous les appareils connectés au même compte iCloud.
- **Stockage Persistant** : Les données sont stockées de manière persistante dans iCloud, ce qui signifie qu'elles persisteront même si l'application est terminée ou redémarrée.
- **Synchronisation Quasi en Temps Réel** : Les modifications de l'état sont propagées aux autres appareils presque instantanément.

> **Remarque** : `SyncState` est pris en charge sur watchOS 9.0 et versions ultérieures.

## Exemple d'Utilisation

### Modèle de Données

Supposons que nous ayons une structure nommée `Settings` qui se conforme à `Codable` :

```swift
struct Settings: Codable {
    var text: String
    var isShowingSheet: Bool
    var isDarkMode: Bool
}
```

### Définir un SyncState

Vous pouvez définir un `SyncState` en étendant l'objet `Application` et en déclarant les propriétés d'état qui doivent être synchronisées :

```swift
extension Application {
    var settings: SyncState<Settings> {
        syncState(
            initial: Settings(
                text: "Hello, World!",
                isShowingSheet: false,
                isDarkMode: false
            ),
            id: "settings"
        )
    }
}
```

### Gérer les Changements Externes

Pour s'assurer que l'application répond aux changements externes d'iCloud, surchargez la fonction `didChangeExternally` en créant une sous-classe personnalisée de `Application` :

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
```

### Créer des Vues pour Modifier et Synchroniser l'État

Dans l'exemple suivant, nous avons deux vues : `ContentView` et `ContentViewInnerView`. Ces vues partagent et synchronisent l'état `Settings` entre elles. `ContentView` permet à l'utilisateur de modifier le `text` et de basculer `isDarkMode`, tandis que `ContentViewInnerView` affiche le même texte et le met à jour lorsqu'il est touché.

```swift
struct ContentView: View {
    @SyncState(\.settings) private var settings: Settings

    var body: some View {
        VStack {
            TextField("", text: $settings.text)

            Button(settings.isDarkMode ? "Light" : "Dark") {
                settings.isDarkMode.toggle()
            }

            Button("Show") { settings.isShowingSheet = true }
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        .sheet(isPresented: $settings.isShowingSheet, content: ContentViewInnerView.init)
    }
}

struct ContentViewInnerView: View {
    @Slice(\.settings, \.text) private var text: String

    var body: some View {
        Text("\(text)")
            .onTapGesture {
                text = Date().formatted()
            }
    }
}
```

### Configurer l'Application

Enfin, configurez l'application dans la structure `@main`. Dans l'initialisation, promouvez l'application personnalisée, activez la journalisation et chargez la dépendance du magasin iCloud pour la synchronisation :

```swift
@main
struct SyncStateExampleApp: App {
    init() {
        Application
            .promote(to: CustomApplication.self)
            .logging(isEnabled: true)
            .load(dependency: \.icloudStore)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Activer le Magasin Clé-Valeur iCloud

Pour activer la synchronisation iCloud, assurez-vous de suivre ce guide pour activer la fonctionnalité de stockage clé-valeur iCloud : [Démarrer avec SyncState](starting-to-use-syncstate.md).

### SyncState : Notes sur le Stockage iCloud

Bien que `SyncState` permette une synchronisation facile, il est important de se souvenir des limitations de `NSUbiquitousKeyValueStore` :

- **Limite de Stockage** : Vous pouvez stocker jusqu'à 1 Mo de données dans iCloud en utilisant `NSUbiquitousKeyValueStore`, avec une limite de taille de valeur par clé de 1 Mo.

### Considérations sur la Migration

Lors de la mise à jour de votre modèle de données, il est important de tenir compte des défis potentiels de la migration, en particulier lorsque vous travaillez avec des données persistantes à l'aide de **StoredState**, **FileState** ou **SyncState**. Sans une gestion appropriée de la migration, des changements tels que l'ajout de nouveaux champs ou la modification des formats de données peuvent entraîner des problèmes lors du chargement des anciennes données.

Voici quelques points clés à garder à l'esprit :
- **Ajout de Nouveaux Champs Non Optionnels** : Assurez-vous que les nouveaux champs sont soit optionnels, soit qu'ils ont des valeurs par défaut pour maintenir la compatibilité ascendante.
- **Gestion des Changements de Format de Données** : Si la structure de votre modèle change, implémentez une logique de décodage personnalisée pour prendre en charge les anciens formats.
- **Versionnement de Vos Modèles** : Utilisez un champ `version` dans vos modèles pour aider aux migrations et appliquer une logique en fonction de la version des données.

Pour en savoir plus sur la gestion des migrations et éviter les problèmes potentiels, consultez le [Guide des Considérations sur la Migration](migration-considerations.md).

## Guide d'Implémentation de SyncState

Pour des instructions détaillées sur la configuration d'iCloud et la configuration de SyncState dans votre projet, consultez le [Guide d'Implémentation de SyncState](syncstate-implementation.md).

## Meilleures Pratiques

- **Utiliser pour les Données Petites et Critiques** : `SyncState` est idéal pour synchroniser de petites et importantes pièces d'état telles que les préférences utilisateur, les paramètres ou les indicateurs de fonctionnalités.
- **Surveiller le Stockage iCloud** : Assurez-vous que votre utilisation de `SyncState` reste dans les limites de stockage d'iCloud pour éviter les problèmes de synchronisation des données.
- **Gérer les Mises à Jour Externes** : Si votre application doit répondre aux changements d'état initiés sur un autre appareil, surchargez la fonction `didChangeExternally` pour mettre à jour l'état de l'application en temps réel.

## Conclusion

`SyncState` offre un moyen puissant de synchroniser de petites quantités d'état d'application sur tous les appareils via iCloud. Il est idéal pour garantir que les préférences de l'utilisateur et d'autres données clés restent cohérentes sur tous les appareils connectés au même compte iCloud. Pour des cas d'utilisation plus avancés, explorez d'autres fonctionnalités de **AppState**, telles que [SecureState](usage-securestate.md) et [FileState](usage-filestate.md).

---
Cette traduction a été générée automatiquement et peut contenir des erreurs. Si vous êtes un locuteur natif, nous vous serions reconnaissants de contribuer avec des corrections via une Pull Request.
