# Uso de ObservedDependency

`ObservedDependency` é um componente da biblioteca **AppState** que permite que você use dependências que se conformam com `ObservableObject`. Isso é útil quando você quer que a dependência notifique suas visualizações SwiftUI sobre mudanças, tornando suas visualizações reativas e dinâmicas.

## Principais Características

- **Dependências Observáveis**: Use dependências que se conformam com `ObservableObject`, permitindo que a dependência atualize automaticamente suas visualizações quando seu estado muda.
- **Atualizações de IU Reativas**: As visualizações SwiftUI são atualizadas automaticamente quando as alterações são publicadas pela dependência observada.
- **Seguro para Threads**: Como outros componentes do AppState, `ObservedDependency` garante acesso seguro à dependência observada em threads.

## Exemplo de Uso

### Definindo uma Dependência Observável

Veja como definir um serviço observável como uma dependência na extensão `Application`:

```swift
import AppState
import SwiftUI

@MainActor
class ObservableService: ObservableObject {
    @Published var count: Int = 0
}

extension Application {
    @MainActor
    var observableService: Dependency<ObservableService> {
        dependency(ObservableService())
    }
}
```

### Usando a Dependência Observada em uma Visualização SwiftUI

Em sua visualização SwiftUI, você pode acessar a dependência observável usando o property wrapper `@ObservedDependency`. O objeto observado atualiza automaticamente a visualização sempre que seu estado muda.

```swift
import AppState
import SwiftUI

struct ObservedDependencyExampleView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        VStack {
            Text("Contagem: \(service.count)")
            Button("Incrementar Contagem") {
                service.count += 1
            }
        }
    }
}
```

### Caso de Teste

O seguinte caso de teste demonstra a interação com `ObservedDependency`:

```swift
import XCTest
@testable import AppState

@MainActor
fileprivate class ObservableService: ObservableObject {
    @Published var count: Int

    init() {
        count = 0
    }
}

fileprivate extension Application {
    @MainActor
    var observableService: Dependency<ObservableService> {
        dependency(ObservableService())
    }
}

@MainActor
fileprivate struct ExampleDependencyWrapper {
    @ObservedDependency(\.observableService) var service

    func test() {
        service.count += 1
    }
}

final class ObservedDependencyTests: XCTestCase {
    @MainActor
    func testDependency() async {
        let example = ExampleDependencyWrapper()

        XCTAssertEqual(example.service.count, 0)

        example.test()

        XCTAssertEqual(example.service.count, 1)
    }
}
```

### Atualizações de IU Reativas

Como a dependência se conforma com `ObservableObject`, qualquer alteração em seu estado acionará uma atualização da IU na visualização SwiftUI. Você pode vincular o estado diretamente a elementos da IU como um `Picker`:

```swift
import AppState
import SwiftUI

struct ReactiveView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        Picker("Selecionar Contagem", selection: $service.count) {
            ForEach(0..<10) { count in
                Text("\(count)").tag(count)
            }
        }
    }
}
```

## Melhores Práticas

- **Use para Serviços Observáveis**: `ObservedDependency` é ideal quando sua dependência precisa notificar as visualizações sobre mudanças, especialmente para serviços que fornecem atualizações de dados ou de estado.
- **Aproveite as Propriedades Publicadas**: Certifique-se de que sua dependência use propriedades `@Published` para acionar atualizações em suas visualizações SwiftUI.
- **Seguro para Threads**: Como outros componentes do AppState, `ObservedDependency` garante acesso e modificações seguros para threads ao serviço observável.

## Conclusão

`ObservedDependency` é uma ferramenta poderosa para gerenciar dependências observáveis dentro de seu aplicativo. Ao aproveitar o protocolo `ObservableObject` do Swift, ele garante que suas visualizações SwiftUI permaneçam reativas e atualizadas com as mudanças no serviço ou recurso.

---
Isso foi gerado usando Jules, erros podem acontecer. Por favor, faça um Pull Request com quaisquer correções que devam acontecer se você for um falante nativo.
