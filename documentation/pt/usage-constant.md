# Uso de Constantes

`Constant` na biblioteca **AppState** fornece acesso somente leitura a valores dentro do estado da sua aplicação. Funciona de forma semelhante a `Slice`, mas garante que os valores acessados sejam imutáveis. Isso torna `Constant` ideal para acessar valores que, de outra forma, poderiam ser mutáveis, mas que devem permanecer somente leitura em certos contextos.

## Principais Características

- **Acesso Somente Leitura**: As constantes fornecem acesso ao estado mutável, mas os valores não podem ser modificados.
- **Escopo para a Aplicação**: Assim como `Slice`, `Constant` é definido dentro da extensão `Application` e tem como escopo o acesso a partes específicas do estado.
- **Seguro para Threads**: `Constant` garante o acesso seguro ao estado em ambientes concorrentes.

## Exemplo de Uso

### Definindo uma Constante na Aplicação

Veja como definir uma `Constant` na extensão `Application` para acessar um valor somente leitura:

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

### Acessando a Constante em uma Visualização SwiftUI

Em uma visualização SwiftUI, você pode usar o property wrapper `@Constant` para acessar o estado constante de forma somente leitura:

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.exampleValue, \.value) var constantValue: String

    var body: some View {
        Text("Valor Constante: \(constantValue)")
    }
}
```

### Acesso Somente Leitura a um Estado Mutável

Mesmo que o valor seja mutável em outro lugar, quando acessado através de `@Constant`, o valor se torna imutável:

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.exampleValue, \.mutableValue) var constantMutableValue: String

    var body: some View {
        Text("Valor Mutável Somente Leitura: \(constantMutableValue)")
    }
}
```

## Melhores Práticas

- **Use para Acesso Somente Leitura**: Use `Constant` para acessar partes do estado que não devem ser modificadas em certos contextos, mesmo que sejam mutáveis em outro lugar.
- **Seguro para Threads**: Assim como outros componentes do AppState, `Constant` garante o acesso seguro ao estado por threads.
- **Use `OptionalConstant` para Valores Opcionais**: Se a parte do estado que você está acessando puder ser `nil`, use `OptionalConstant` para lidar com segurança com a ausência de um valor.

## Conclusão

`Constant` e `OptionalConstant` fornecem uma maneira eficiente de acessar partes específicas do estado da sua aplicação de forma somente leitura. Eles garantem que valores que, de outra forma, poderiam ser mutáveis, sejam tratados como imutáveis quando acessados dentro de uma visualização, garantindo segurança e clareza no seu código.
