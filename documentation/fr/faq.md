# Foire Aux Questions

Cette courte FAQ répond aux questions courantes que les développeurs могут se poser lors de l'utilisation de **AppState**.

## Comment réinitialiser une valeur d'état ?

Pour les états persistants comme `StoredState`, `FileState` et `SyncState`, vous pouvez les réinitialiser à leurs valeurs initiales en utilisant les fonctions statiques `reset` sur le type `Application`.

Par exemple, pour réinitialiser un `StoredState<Bool>` :
```swift
extension Application {
    var hasCompletedOnboarding: StoredState<Bool> { storedState(initial: false, id: "onboarding_complete") }
}

// Quelque part dans votre code
Application.reset(storedState: \.hasCompletedOnboarding)
```
Cela réinitialisera la valeur dans `UserDefaults` à `false`. Des fonctions `reset` similares existent pour `FileState`, `SyncState` et `SecureState`.

Pour un `State` non persistant, vous pouvez le réinitialiser de la même manière que les états persistants :
```swift
extension Application {
    var counter: State<Int> { state(initial: 0) }
}

// Quelque part dans votre code
Application.reset(\.counter)
```

## Puis-je utiliser AppState avec des tâches asynchrones ?

Oui. Les valeurs de `State` et de dépendance sont thread-safe et fonctionnent de manière transparente avec Swift Concurrency. Vous pouvez y accéder et les modifier à l'intérieur des fonctions `async` sans verrouillage supplémentaire.

## Où dois-je définir les états et les dépendances ?

Conservez tous vos états et dépendances dans des extensions de `Application`. Cela garantit une source unique de vérité et facilite la découverte de toutes les valeurs disponibles.

## AppState est-il compatible avec Combine ?

Vous pouvez utiliser AppState avec Combine en pontant les changements de `State` vers des publicateurs. Observez une valeur `State` et envoyez des mises à jour via un `PassthroughSubject` ou un autre publicateur Combine si nécessaire.
