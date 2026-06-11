# Atualizando para o AppState 3.0

O AppState 3.0 é construído em torno do Swift 6 e do framework Observation da Apple. Abaixo estão as alterações que quebram a compatibilidade e como se adaptar.

## Visão geral das alterações que quebram a compatibilidade

- **Versões mínimas de plataforma elevadas** — iOS 17, macOS 14, tvOS 17, watchOS 10
- **Concorrência estrita do Swift 6** — `ExistentialAny` ativado; `any` explícito necessário em existenciais de protocolo
- **`ObservableObject` removido** — `Application` usa `@Observable`; `objectWillChange` foi removido, substitua por `notifyChange()`
- **Novo (aditivo): suporte a SwiftData** — `ModelState` / `@ModelState` para objetos `@Model`

---

## 1. Requisitos de plataforma elevados

| Plataforma | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux e Windows continuam a ser suportados para o conjunto de recursos não-Apple.

Permaneça na linha de lançamento 2.x se você precisar dar suporte a versões mais antigas do sistema operacional.

## 2. Swift 6 estrito

O pacote fixa o modo de linguagem do Swift 6 (`swiftLanguageModes: [.v6]`) e ativa o recurso futuro `ExistentialAny`. A CI compila com avisos tratados como erros.

A maioria dos aplicativos não requer alterações. Se você implementou algum dos protocolos públicos do AppState — `FileManaging`, `UserDefaultsManaging` ou `UbiquitousKeyValueStoreManaging` — talvez precise escrever tipos existenciais com um `any` explícito:

```swift
// Before (2.x)
var fileManager: FileManaging

// After (3.0)
var fileManager: any FileManaging
```

## 3. Observation substitui ObservableObject

`Application` agora usa [`@Observable`](https://developer.apple.com/documentation/observation) em vez de `ObservableObject`.

**Os property wrappers permanecem inalterados.** `@AppState`, `@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`, `@OptionalSlice`, `@DependencySlice` e `@ModelState` continuam todos a funcionar dentro de visualizações SwiftUI. Os view models que se conformam a `ObservableObject` e hospedam esses wrappers ainda são suportados.

O que mudou:

- `Application.shared.objectWillChange` não existe mais.
- `Application.notifyChange()` o substitui. Os próprios setters do AppState o chamam automaticamente.
- Ler `Application.state(_:).value` diretamente agora participa do Observation — não apenas o wrapper `@AppState`. Isso significa que qualquer código (não apenas visualizações SwiftUI) pode observar alterações de estado:

  ```swift
  withObservationTracking {
      _ = Application.state(\.counter).value
  } onChange: {
      // runs when the value changes — no SwiftUI required
  }
  ```

Se você criou uma subclasse de `Application` e chamou `objectWillChange.send()` manualmente (por exemplo, a partir de uma sobrescrita de `didChangeExternally`), substitua-a por `notifyChange()`:

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

> `@ObservedDependency` permanece inalterado — ele ainda observa valores de dependência que se conformam a `ObservableObject`.

## 4. Novo: suporte a SwiftData

O 3.0 adiciona integração com SwiftData. Injete um `ModelContainer` compartilhado como uma dependência e leia/grave objetos `@Model` através do `ModelState`. Isso é aditivo e opcional — consulte o [Guia de Uso do ModelState](usage-modelstate.md).

---
Esta tradução foi gerada automaticamente e pode conter erros. Se você é um falante nativo, agradecemos suas contribuições com correções por meio de um Pull Request.
