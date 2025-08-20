# Descripción General del Uso

Esta descripción general proporciona una introducción rápida al uso de los componentes clave de la biblioteca **AppState** dentro de una `View` de SwiftUI. Cada sección incluye ejemplos simples que se ajustan al alcance de una estructura de vista de SwiftUI.

## Definición de Valores en la Extensión de Application

Para definir el estado o las dependencias de toda la aplicación, debe extender el objeto `Application`. Esto le permite centralizar todo el estado de su aplicación en un solo lugar. A continuación, se muestra un ejemplo de cómo extender `Application` para crear varios estados y dependencias:

```swift
import AppState

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }

    var userPreferences: StoredState<String> {
        storedState(initial: "Default Preferences", id: "userPreferences")
    }

    var darkModeEnabled: SyncState<Bool> {
        syncState(initial: false, id: "darkModeEnabled")
    }

    var userToken: SecureState {
        secureState(id: "userToken")
    }

    @MainActor
    var largeDataset: FileState<[String]> {
        fileState(initial: [], filename: "largeDataset")
    }
}
```

## State

`State` le permite definir un estado de toda la aplicación al que se puede acceder y modificar en cualquier parte de su aplicación.

### Ejemplo

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("¡Hola, \(user.name)!")
            Button("Iniciar sesión") {
                user.isLoggedIn.toggle()
            }
        }
    }
}
```

## StoredState

`StoredState` persiste el estado usando `UserDefaults` para garantizar que los valores se guarden entre lanzamientos de la aplicación.

### Ejemplo

```swift
import AppState
import SwiftUI

struct PreferencesView: View {
    @StoredState(\.userPreferences) var userPreferences: String

    var body: some View {
        VStack {
            Text("Preferencias: \(userPreferences)")
            Button("Actualizar Preferencias") {
                userPreferences = "Updated Preferences"
            }
        }
    }
}
```

## SyncState

`SyncState` sincroniza el estado de la aplicación en múltiples dispositivos usando iCloud.

### Ejemplo

```swift
import AppState
import SwiftUI

struct SyncSettingsView: View {
    @SyncState(\.darkModeEnabled) var isDarkModeEnabled: Bool

    var body: some View {
        VStack {
            Toggle("Modo Oscuro", isOn: $isDarkModeEnabled)
        }
    }
}
```

## FileState

`FileState` se utiliza para almacenar datos más grandes o complejos de forma persistente utilizando el sistema de archivos, lo que lo hace ideal para almacenar en caché o guardar datos que no se ajustan a las limitaciones de `UserDefaults`.

### Ejemplo

```swift
import AppState
import SwiftUI

struct LargeDataView: View {
    @FileState(\.largeDataset) var largeDataset: [String]

    var body: some View {
        List(largeDataset, id: \.self) { item in
            Text(item)
        }
    }
}
```

## SecureState

`SecureState` almacena datos confidenciales de forma segura en el Llavero.

### Ejemplo

```swift
import AppState
import SwiftUI

struct SecureView: View {
    @SecureState(\.userToken) var userToken: String?

    var body: some View {
        VStack {
            if let token = userToken {
                Text("Token de usuario: \(token)")
            } else {
                Text("No se encontró ningún token.")
            }
            Button("Establecer Token") {
                userToken = "secure_token_value"
            }
        }
    }
}
```

## Constant

`Constant` proporciona acceso inmutable y de solo lectura a los valores dentro del estado de su aplicación, garantizando la seguridad al acceder a valores que no deben modificarse.

### Ejemplo

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.user, \.name) var name: String

    var body: some View {
        Text("Nombre de usuario: \(name)")
    }
}
```

## Slicing State

`Slice` y `OptionalSlice` le permiten acceder a partes específicas del estado de su aplicación.

### Ejemplo

```swift
import AppState
import SwiftUI

struct SlicingView: View {
    @Slice(\.user, \.name) var name: String

    var body: some View {
        VStack {
            Text("Nombre de usuario: \(name)")
            Button("Actualizar Nombre de Usuario") {
                name = "NewUsername"
            }
        }
    }
}
```

## Mejores Prácticas

- **Use `AppState` en Vistas de SwiftUI**: Los property wrappers como `@AppState`, `@StoredState`, `@FileState`, `@SecureState`, y otros están diseñados para ser utilizados dentro del alcance de las vistas de SwiftUI.
- **Defina el Estado en la Extensión de Application**: Centralice la gestión del estado extendiendo `Application` para definir el estado y las dependencias de su aplicación.
- **Actualizaciones Reactivas**: SwiftUI actualiza automáticamente las vistas cuando cambia el estado, por lo que no necesita actualizar manualmente la interfaz de usuario.
- **[Guía de Mejores Prácticas](best-practices.md)**: Para un desglose detallado de las mejores prácticas al usar AppState.

## Próximos Pasos

Después de familiarizarse con el uso básico, puede explorar temas más avanzados:

- Explore el uso de **FileState** para persistir grandes cantidades de datos en archivos en la [Guía de Uso de FileState](usage-filestate.md).
- Aprenda sobre **Constantes** y cómo usarlas para valores inmutables en el estado de su aplicación en la [Guía de Uso de Constantes](usage-constant.md).
- Investigue cómo se usa **Dependency** en AppState para manejar servicios compartidos y vea ejemplos en la [Guía de Uso de Dependencia de Estado](usage-state-dependency.md).
- Profundice en técnicas avanzadas de **SwiftUI** como el uso de `ObservedDependency` para gestionar dependencias observables en las vistas en la [Guía de Uso de ObservedDependency](usage-observeddependency.md).
- Para técnicas de uso más avanzadas, como la creación Just-In-Time y la precarga de dependencias, consulte la [Guía de Uso Avanzado](advanced-usage.md).
