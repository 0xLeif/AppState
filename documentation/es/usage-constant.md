# Uso de Constantes

`Constant` en la biblioteca **AppState** proporciona acceso de solo lectura a los valores dentro del estado de su aplicación. Funciona de manera similar a `Slice`, pero asegura que los valores a los que se accede sean inmutables. Esto hace que `Constant` sea ideal para acceder a valores que de otro modo podrían ser mutables pero que deben permanecer de solo lectura en ciertos contextos.

## Características Clave

- **Acceso de Solo Lectura**: Las constantes proporcionan acceso al estado mutable, pero los valores no se pueden modificar.
- **Ámbito de Aplicación**: Al igual que `Slice`, `Constant` se define dentro de la extensión de `Application` y tiene como ámbito el acceso a partes específicas del estado.
- **Seguro para Hilos**: `Constant` garantiza un acceso seguro al estado en entornos concurrentes.

## Ejemplo de Uso

### Definir una Constante en la Aplicación

Así es como se define una `Constant` en la extensión de `Application` para acceder a un valor de solo lectura:

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

### Acceder a la Constante en una Vista de SwiftUI

En una vista de SwiftUI, puede usar el property wrapper `@Constant` para acceder al estado constante de solo lectura:

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

### Acceso de Solo Lectura al Estado Mutable

Incluso si el valor es mutable en otro lugar, cuando se accede a través de `@Constant`, el valor se vuelve inmutable:

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.exampleValue, \.mutableValue) var constantMutableValue: String

    var body: some View {
        Text("Valor Mutable de Solo Lectura: \(constantMutableValue)")
    }
}
```

## Mejores Prácticas

- **Usar para Acceso de Solo Lectura**: Use `Constant` para acceder a partes del estado que no deben modificarse en ciertos contextos, incluso si son mutables en otro lugar.
- **Seguro para Hilos**: Al igual que otros componentes de AppState, `Constant` garantiza un acceso seguro al estado para hilos.
- **Usar `OptionalConstant` para Valores Opcionales**: Si la parte del estado a la que está accediendo puede ser `nil`, use `OptionalConstant` para manejar de forma segura la ausencia de un valor.

## Conclusión

`Constant` y `OptionalConstant` proporcionan una forma eficiente de acceder a partes específicas del estado de su aplicación de solo lectura. Aseguran que los valores que de otro modo podrían ser mutables se traten como inmutables cuando se accede a ellos dentro de una vista, garantizando la seguridad y la claridad en su código.

---
Esta traducción fue generada automáticamente y puede contener errores. Si eres un hablante nativo, te agradecemos que contribuyas con correcciones a través de un Pull Request.
