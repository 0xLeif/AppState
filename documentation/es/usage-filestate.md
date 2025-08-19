# Uso de FileState

`FileState` es un componente de la biblioteca **AppState** que le permite almacenar y recuperar datos persistentes utilizando el sistema de archivos. Es útil para almacenar datos grandes u objetos complejos que necesitan guardarse entre lanzamientos de la aplicación y restaurarse cuando sea necesario.

## Características Clave

- **Almacenamiento Persistente**: Los datos almacenados con `FileState` persisten entre lanzamientos de la aplicación.
- **Manejo de Datos Grandes**: A diferencia de `StoredState`, `FileState` es ideal para manejar datos más grandes o complejos.
- **Seguro para Hilos**: Al igual que otros componentes de AppState, `FileState` garantiza un acceso seguro a los datos en entornos concurrentes.

## Ejemplo de Uso

### Almacenar y Recuperar Datos con FileState

A continuación, se muestra cómo definir un `FileState` en la extensión de `Application` para almacenar y recuperar un objeto grande:

```swift
import AppState
import SwiftUI

struct UserProfile: Codable {
    var name: String
    var age: Int
}

extension Application {
    @MainActor
    var userProfile: FileState<UserProfile> {
        fileState(initial: UserProfile(name: "Guest", age: 25), filename: "userProfile")
    }
}

struct FileStateExampleView: View {
    @FileState(\.userProfile) var userProfile: UserProfile

    var body: some View {
        VStack {
            Text("Nombre: \(userProfile.name), Edad: \(userProfile.age)")
            Button("Actualizar Perfil") {
                userProfile = UserProfile(name: "UpdatedName", age: 30)
            }
        }
    }
}
```

### Manejo de Datos Grandes con FileState

Cuando necesite manejar conjuntos de datos u objetos más grandes, `FileState` garantiza que los datos se almacenen de manera eficiente en el sistema de archivos de la aplicación. Esto es útil para escenarios como el almacenamiento en caché o el almacenamiento sin conexión.

```swift
import AppState
import SwiftUI

extension Application {
    @MainActor
    var largeDataset: FileState<[String]> {
        fileState(initial: [], filename: "largeDataset")
    }
}

struct LargeDataView: View {
    @FileState(\.largeDataset) var largeDataset: [String]

    var body: some View {
        List(largeDataset, id: \.self) { item in
            Text(item)
        }
    }
}
```

### Consideraciones sobre la Migración

Al actualizar su modelo de datos, es importante tener en cuenta los posibles desafíos de migración, especialmente cuando se trabaja con datos persistentes utilizando **StoredState**, **FileState** o **SyncState**. Sin un manejo adecuado de la migración, cambios como agregar nuevos campos o modificar formatos de datos pueden causar problemas al cargar datos antiguos.

Aquí hay algunos puntos clave a tener en cuenta:
- **Agregar Nuevos Campos no Opcionales**: Asegúrese de que los nuevos campos sean opcionales o tengan valores predeterminados para mantener la compatibilidad con versiones anteriores.
- **Manejo de Cambios en el Formato de Datos**: Si la estructura de su modelo cambia, implemente una lógica de decodificación personalizada para admitir formatos antiguos.
- **Versionado de sus Modelos**: Use un campo `version` en sus modelos para ayudar con las migraciones y aplicar la lógica según la versión de los datos.

Para obtener más información sobre cómo administrar las migraciones y evitar posibles problemas, consulte la [Guía de Consideraciones sobre la Migración](migration-considerations.md).


## Mejores Prácticas

- **Usar para Datos Grandes o Complejos**: Si está almacenando datos grandes u objetos complejos, `FileState` es ideal sobre `StoredState`.
- **Acceso Seguro para Hilos**: Al igual que otros componentes de **AppState**, `FileState` garantiza que se acceda a los datos de forma segura incluso cuando varias tareas interactúan con los datos almacenados.
- **Combinar con Codable**: Cuando trabaje con tipos de datos personalizados, asegúrese de que se ajusten a `Codable` para simplificar la codificación y decodificación hacia y desde el sistema de archivos.

## Conclusión

`FileState` es una herramienta poderosa para manejar datos persistentes en su aplicación, permitiéndole almacenar y recuperar objetos más grandes o complejos de una manera segura para hilos y persistente. Funciona sin problemas con el protocolo `Codable` de Swift, asegurando que sus datos puedan ser serializados y deserializados fácilmente para un almacenamiento a largo plazo.
