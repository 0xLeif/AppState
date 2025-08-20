# Uso de ObservedDependency

`ObservedDependency` es un componente de la biblioteca **AppState** que le permite usar dependencias que se ajustan a `ObservableObject`. Esto es útil cuando desea que la dependencia notifique a sus vistas de SwiftUI sobre los cambios, haciendo que sus vistas sean reactivas y dinámicas.

## Características Clave

- **Dependencias Observables**: Use dependencias que se ajusten a `ObservableObject`, permitiendo que la dependencia actualice automáticamente sus vistas cuando su estado cambie.
- **Actualizaciones de IU Reactivas**: Las vistas de SwiftUI se actualizan automáticamente cuando la dependencia observada publica cambios.
- **Seguro para Hilos**: Al igual que otros componentes de AppState, `ObservedDependency` garantiza un acceso seguro a la dependencia observada para hilos.

## Ejemplo de Uso

### Definir una Dependencia Observable

A continuación, se muestra cómo definir un servicio observable como una dependencia en la extensión de `Application`:

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

### Usar la Dependencia Observada en una Vista de SwiftUI

En su vista de SwiftUI, puede acceder a la dependencia observable usando el property wrapper `@ObservedDependency`. El objeto observado actualiza automáticamente la vista cada vez que su estado cambia.

```swift
import AppState
import SwiftUI

struct ObservedDependencyExampleView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        VStack {
            Text("Conteo: \(service.count)")
            Button("Incrementar Conteo") {
                service.count += 1
            }
        }
    }
}
```

### Caso de Prueba

El siguiente caso de prueba demuestra la interacción con `ObservedDependency`:

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

### Actualizaciones de IU Reactivas

Dado que la dependencia se ajusta a `ObservableObject`, cualquier cambio en su estado activará una actualización de la IU en la vista de SwiftUI. Puede vincular el estado directamente a elementos de la IU como un `Picker`:

```swift
import AppState
import SwiftUI

struct ReactiveView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        Picker("Seleccionar Conteo", selection: $service.count) {
            ForEach(0..<10) { count in
                Text("\(count)").tag(count)
            }
        }
    }
}
```

## Mejores Prácticas

- **Usar para Servicios Observables**: `ObservedDependency` es ideal cuando su dependencia necesita notificar a las vistas sobre los cambios, especialmente para los servicios que proporcionan actualizaciones de datos o de estado.
- **Aprovechar las Propiedades Publicadas**: Asegúrese de que su dependencia use propiedades `@Published` para activar actualizaciones en sus vistas de SwiftUI.
- **Seguro para Hilos**: Al igual que otros componentes de AppState, `ObservedDependency` garantiza un acceso y modificaciones seguros para hilos al servicio observable.

## Conclusión

`ObservedDependency` es una herramienta poderosa para gestionar dependencias observables dentro de su aplicación. Al aprovechar el protocolo `ObservableObject` de Swift, garantiza que sus vistas de SwiftUI permanezcan reactivas y actualizadas con los cambios en el servicio o recurso.

---
Esta traducción fue generada automáticamente y puede contener errores. Si eres un hablante nativo, te agradecemos que contribuyas con correcciones a través de un Pull Request.
