# Atualizando para o AppState 3.0

O AppState 3.0 moderniza a biblioteca em torno do Swift 6 e do framework
Observation da Apple. Este guia cobre as alterações que quebram a compatibilidade e como se adaptar.

## 1. Requisitos de plataforma elevados

Os alvos de implantação mínimos foram elevados para aproveitar as APIs modernas do
Swift e do SwiftData/Observation:

| Plataforma | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux e Windows continuam a ser suportados para o conjunto de recursos não-Apple.

Se você precisar continuar a oferecer suporte a versões de SO mais antigas, permaneça na linha de lançamento 2.x.

## 2. Swift 6 estrito

O pacote agora fixa o modo de linguagem do Swift 6 (`swiftLanguageModes: [.v6]`) e o
recurso futuro `ExistentialAny`, e a CI compila com avisos tratados como erros.
Para a maioria dos aplicativos, isso não requer alterações. Se você implementou algum dos
protocolos públicos do AppState (por exemplo, um `FileManaging`, `UserDefaultsManaging` ou
`UbiquitousKeyValueStoreManaging` personalizado), pode ser necessário escrever tipos existenciais com um
`any` explícito (por exemplo, `any FileManaging`).

## 3. Observation substitui ObservableObject

`Application` agora usa o macro [`@Observable`](https://developer.apple.com/documentation/observation)
em vez de se conformar a `ObservableObject`.

**Nenhuma alteração é necessária para o uso típico.** Os property wrappers — `@AppState`,
`@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`,
`@OptionalSlice`, `@DependencySlice` e `@ModelState` — continuam a funcionar dentro
de visualizações SwiftUI e as visualizações são atualizadas como antes. View models que se conformam a
`ObservableObject` e hospedam esses wrappers ainda são suportados.

O que mudou:

- `Application` não se conforma mais a `ObservableObject`, então
  `Application.shared.objectWillChange` não está mais disponível.
- Um novo método, `Application.notifyChange()`, solicita que os observadores (visualizações SwiftUI)
  sejam atualizados. Os próprios setters do AppState o chamam por você.

Se você criou uma subclasse de `Application` e acionou atualizações manualmente — por exemplo, a partir de uma
sobrescrita de `didChangeExternally(notification:)` que reage a alterações recebidas do iCloud —
substitua `objectWillChange.send()` por `notifyChange()`:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            // Antes (2.x):
            // self.objectWillChange.send()

            // Depois (3.0):
            self.notifyChange()
        }
    }
}
```

> Nota: `@ObservedDependency` permanece inalterado. Ele ainda observa valores de dependência
> que se conformam a `ObservableObject`.

## 4. Novo: Suporte ao SwiftData

O 3.0 adiciona integração de primeira classe com o SwiftData: injete um `ModelContainer` compartilhado como uma
dependência e leia/grave objetos `@Model` através do `ModelState`. Consulte o
[Guia de Uso do ModelState](usage-modelstate.md). Isso é aditivo e opcional.

---
Esta tradução foi gerada automaticamente e pode conter erros. Se você é um falante nativo, agradecemos suas contribuições com correções por meio de um Pull Request.
