# Utilisation de Constant

`Constant` dans la bibliothèque **AppState** fournit un accès en lecture seule aux valeurs de l'état de votre application. Il fonctionne de manière similaire à `Slice`, mais garantit que les valeurs consultées sont immuables. Cela rend `Constant` idéal pour accéder à des valeurs qui pourraient autrement être mutables mais qui doivent rester en lecture seule dans certains contextes.

## Fonctionnalités Clés

- **Accès en Lecture Seule**: Les constantes permettent d'accéder à un état mutable, mais les valeurs ne peuvent pas être modifiées.
- **Portée Limitée à l'Application**: Comme `Slice`, `Constant` est défini dans l'extension `Application` et sa portée est limitée à l'accès à des parties spécifiques de l'état.
- **Thread-Safe**: `Constant` garantit un accès sécurisé à l'état dans les environnements concurrents.

## Exemple d'Utilisation

### Définir une Constante dans l'Application

Voici comment définir une `Constant` dans l'extension `Application` pour accéder à une valeur en lecture seule :

```swift
import AppState
import SwiftUI

struct ExampleValue {
    var username: String?
    var isLoading: Bool
    let value: String
    var mutableValue: String
}

extension Application {
    var exampleValue: State<ExampleValue> {
        state(
            initial: ExampleValue(
                username: "Leif",
                isLoading: false,
                value: "value",
                mutableValue: ""
            )
        )
    }
}
```

### Accéder à la Constante dans une Vue SwiftUI

Dans une vue SwiftUI, vous pouvez utiliser le property wrapper `@Constant` pour accéder à l'état constant en lecture seule :

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.exampleValue, \.value) var constantValue: String

    var body: some View {
        Text("Valeur Constante : \(constantValue)")
    }
}
```

### Accès en Lecture Seule à un État Mutable

Même si la valeur est mutable ailleurs, lorsqu'elle est consultée via `@Constant`, la valeur devient immuable :

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.exampleValue, \.mutableValue) var constantMutableValue: String

    var body: some View {
        Text("Valeur Mutable en Lecture Seule : \(constantMutableValue)")
    }
}
```

## Meilleures Pratiques

- **Utiliser pour un Accès en Lecture Seule**: Utilisez `Constant` pour accéder aux parties de l'état qui ne doivent pas être modifiées dans certains contextes, même si elles sont mutables ailleurs.
- **Thread-Safe**: Comme les autres composants d'AppState, `Constant` garantit un accès thread-safe à l'état.
- **Utiliser `OptionalConstant` pour les Valeurs Optionnelles**: Si la partie de l'état que vous consultez peut être `nil`, utilisez `OptionalConstant` pour gérer en toute sécurité l'absence de valeur.

## Conclusion

`Constant` et `OptionalConstant` offrent un moyen efficace d'accéder à des parties spécifiques de l'état de votre application en lecture seule. Ils garantissent que les valeurs qui pourraient autrement être mutables sont traitées comme immuables lorsqu'elles sont consultées dans une vue, assurant ainsi la sécurité et la clarté de votre code.

---
Ceci a été généré à l'aide de [Jules](https://jules.google), des erreurs peuvent survenir. Veuillez faire une Pull Request avec les corrections qui devraient être apportées si vous êtes un locuteur natif.
