# Guide d'Installation

Ce guide vous expliquera comment installer **AppState** dans votre projet Swift à l'aide du Swift Package Manager.

## Swift Package Manager

**AppState** peut être facilement intégré à votre projet à l'aide du Swift Package Manager. Suivez les étapes ci-dessous pour ajouter **AppState** en tant que dépendance.

### Étape 1 : Mettez à jour votre fichier `Package.swift`

Ajoutez **AppState** à la section `dependencies` de votre fichier `Package.swift` :

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/AppState.git", from: "2.2.0")
]
```

### Étape 2 : Ajoutez AppState à votre cible

Incluez AppState dans les dépendances de votre cible :

```swift
.target(
    name: "YourTarget",
    dependencies: ["AppState"]
)
```

### Étape 3 : Compilez votre projet

Une fois que vous avez ajouté AppState à votre fichier `Package.swift`, compilez votre projet pour récupérer la dépendance et l'intégrer à votre base de code.

```
swift build
```

### Étape 4 : Importez AppState dans votre code

Maintenant, vous pouvez commencer à utiliser AppState dans votre projet en l'important en haut de vos fichiers Swift :

```swift
import AppState
```

## Xcode

Si vous préférez ajouter **AppState** directement via Xcode, suivez ces étapes :

### Étape 1 : Ouvrez votre projet Xcode

Ouvrez votre projet ou espace de travail Xcode.

### Étape 2 : Ajoutez une dépendance de package Swift

1. Accédez au navigateur de projet et sélectionnez votre fichier de projet.
2. Dans l'éditeur de projet, sélectionnez votre cible, puis allez à l'onglet "Swift Packages".
3. Cliquez sur le bouton "+" pour ajouter une dépendance de package.

### Étape 3 : Entrez l'URL du dépôt

Dans la boîte de dialogue "Choose Package Repository", entrez l'URL suivante : `https://github.com/0xLeif/AppState.git`

Puis cliquez sur "Next".

### Étape 4 : Spécifiez la version

Choisissez la version que vous souhaitez utiliser. Il est recommandé de sélectionner l'option "Up to Next Major Version" et de spécifier `2.0.0` comme limite inférieure. Puis cliquez sur "Next".

### Étape 5 : Ajoutez le package

Xcode récupérera le package et vous présentera des options pour ajouter **AppState** à votre cible. Assurez-vous de sélectionner la bonne cible et cliquez sur "Finish".

### Étape 6 : Importez `AppState` dans votre code

Vous pouvez maintenant importer **AppState** en haut de vos fichiers Swift :

```swift
import AppState
```

## Prochaines Étapes

Une fois AppState installé, vous pouvez passer à l'[Aperçu de l'utilisation](usage-overview.md) pour voir comment implémenter les fonctionnalités clés dans votre projet.
