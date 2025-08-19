# Uso de Estado y Dependencia

**AppState** proporciona herramientas poderosas para administrar el estado de toda la aplicación e inyectar dependencias en las vistas de SwiftUI. Al centralizar su estado y dependencias, puede asegurarse de que su aplicación se mantenga consistente y mantenible.

## Descripción General

- **Estado**: Representa un valor que se puede compartir en toda la aplicación. Los valores de estado se pueden modificar y observar dentro de sus vistas de SwiftUI.
- **Dependencia**: Representa un recurso o servicio compartido que se puede inyectar y acceder dentro de las vistas de SwiftUI.

### Características Clave

- **Estado Centralizado**: Defina y administre el estado de toda la aplicación en un solo lugar.
- **Inyección de Dependencias**: Inyecte y acceda a servicios y recursos compartidos en diferentes componentes de su aplicación.

## Ejemplo de Uso

### Definir el Estado de la Aplicación

Para definir el estado de toda la aplicación, extienda el objeto `Application` y declare las propiedades de estado.

```swift
import AppState

struct User {
    var name: String
    var isLoggedIn: Bool
}

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }
}
```

### Acceder y Modificar el Estado en una Vista

Puede acceder y modificar los valores de estado directamente dentro de una vista de SwiftUI usando el property wrapper `@AppState`.

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("¡Hola, \(user.name)!")
            Button("Iniciar sesión") {
                user.name = "John Doe"
                user.isLoggedIn = true
            }
        }
    }
}
```

### Definir Dependencias

Puede definir recursos compartidos, como un servicio de red, como dependencias en el objeto `Application`. Estas dependencias se pueden inyectar en las vistas de SwiftUI.

```swift
import AppState

protocol NetworkServiceType {
    func fetchData() -> String
}

class NetworkService: NetworkServiceType {
    func fetchData() -> String {
        return "Data from network"
    }
}

extension Application {
    var networkService: Dependency<NetworkServiceType> {
        dependency(NetworkService())
    }
}
```

### Acceder a las Dependencias en una Vista

Acceda a las dependencias dentro de una vista de SwiftUI usando el property wrapper `@AppDependency`. Esto le permite inyectar servicios como un servicio de red en su vista.

```swift
import AppState
import SwiftUI

struct NetworkView: View {
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("Datos: \(networkService.fetchData())")
        }
    }
}
```

### Combinar Estado y Dependencias en una Vista

El estado y las dependencias pueden trabajar juntos para construir una lógica de aplicación más compleja. Por ejemplo, puede obtener datos de un servicio y actualizar el estado:

```swift
import AppState
import SwiftUI

struct CombinedView: View {
    @AppState(\.user) var user: User
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("Usuario: \(user.name)")
            Button("Obtener Datos") {
                user.name = networkService.fetchData()
                user.isLoggedIn = true
            }
        }
    }
}
```

### Mejores Prácticas

- **Centralizar el Estado**: Mantenga el estado de toda su aplicación en un solo lugar para evitar la duplicación y garantizar la consistencia.
- **Usar Dependencias para Servicios Compartidos**: Inyecte dependencias como servicios de red, bases de datos u otros recursos compartidos para evitar un acoplamiento estrecho entre los componentes.

## Conclusión

Con **AppState**, puede administrar el estado de toda la aplicación e inyectar dependencias compartidas directamente en sus vistas de SwiftUI. Este patrón ayuda a mantener su aplicación modular y mantenible. Explore otras características de la biblioteca **AppState**, como [SecureState](usage-securestate.md) y [SyncState](usage-syncstate.md), para mejorar aún más la gestión del estado de su aplicación.
