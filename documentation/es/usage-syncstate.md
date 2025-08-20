# Uso de SyncState

`SyncState` es un componente de la biblioteca **AppState** que le permite sincronizar el estado de la aplicación en múltiples dispositivos usando iCloud. Esto es especialmente útil para mantener consistentes las preferencias del usuario, la configuración u otros datos importantes en todos los dispositivos.

## Descripción General

`SyncState` aprovecha el `NSUbiquitousKeyValueStore` de iCloud para mantener pequeñas cantidades de datos sincronizadas en todos los dispositivos. Esto lo hace ideal para sincronizar el estado de la aplicación ligero, como las preferencias o la configuración del usuario.

### Características Clave

- **Sincronización con iCloud**: Sincroniza automáticamente el estado en todos los dispositivos que hayan iniciado sesión en la misma cuenta de iCloud.
- **Almacenamiento Persistente**: Los datos se almacenan de forma persistente en iCloud, lo que significa que persistirán incluso si la aplicación se cierra o se reinicia.
- **Sincronización Casi en Tiempo Real**: Los cambios en el estado se propagan a otros dispositivos casi instantáneamente.

> **Nota**: `SyncState` es compatible con watchOS 9.0 y versiones posteriores.

## Ejemplo de Uso

### Modelo de Datos

Supongamos que tenemos una estructura llamada `Settings` que se ajusta a `Codable`:

```swift
struct Settings: Codable {
    var text: String
    var isShowingSheet: Bool
    var isDarkMode: Bool
}
```

### Definir un SyncState

Puede definir un `SyncState` extendiendo el objeto `Application` y declarando las propiedades de estado que deben sincronizarse:

```swift
extension Application {
    var settings: SyncState<Settings> {
        syncState(
            initial: Settings(
                text: "Hello, World!",
                isShowingSheet: false,
                isDarkMode: false
            ),
            id: "settings"
        )
    }
}
```

### Manejo de Cambios Externos

Para asegurarse de que la aplicación responda a los cambios externos de iCloud, anule la función `didChangeExternally` creando una subclase personalizada de `Application`:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
```

### Creación de Vistas para Modificar y Sincronizar el Estado

En el siguiente ejemplo, tenemos dos vistas: `ContentView` y `ContentViewInnerView`. Estas vistas comparten y sincronizan el estado de `Settings` entre ellas. `ContentView` permite al usuario modificar el `text` y alternar `isDarkMode`, mientras que `ContentViewInnerView` muestra el mismo texto y lo actualiza cuando se toca.

```swift
struct ContentView: View {
    @SyncState(\.settings) private var settings: Settings

    var body: some View {
        VStack {
            TextField("", text: $settings.text)

            Button(settings.isDarkMode ? "Light" : "Dark") {
                settings.isDarkMode.toggle()
            }

            Button("Show") { settings.isShowingSheet = true }
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        .sheet(isPresented: $settings.isShowingSheet, content: ContentViewInnerView.init)
    }
}

struct ContentViewInnerView: View {
    @Slice(\.settings, \.text) private var text: String

    var body: some View {
        Text("\(text)")
            .onTapGesture {
                text = Date().formatted()
            }
    }
}
```

### Configuración de la Aplicación

Finalmente, configure la aplicación en la estructura `@main`. En la inicialización, promueva la aplicación personalizada, habilite el registro y cargue la dependencia de la tienda de iCloud para la sincronización:

```swift
@main
struct SyncStateExampleApp: App {
    init() {
        Application
            .promote(to: CustomApplication.self)
            .logging(isEnabled: true)
            .load(dependency: \.icloudStore)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Habilitar el Almacenamiento de Clave-Valor de iCloud

Para habilitar la sincronización de iCloud, asegúrese de seguir esta guía para habilitar la capacidad de Almacenamiento de Clave-Valor de iCloud: [Comenzando a usar SyncState](https://github.com/0xLeif/AppState/wiki/Starting-to-use-SyncState).

### SyncState: Notas sobre el Almacenamiento de iCloud

Aunque `SyncState` permite una sincronización fácil, es importante recordar las limitaciones de `NSUbiquitousKeyValueStore`:

- **Límite de Almacenamiento**: Puede almacenar hasta 1 MB de datos en iCloud usando `NSUbiquitousKeyValueStore`, con un límite de tamaño de valor por clave de 1 MB.

### Consideraciones sobre la Migración

Al actualizar su modelo de datos, es importante tener en cuenta los posibles desafíos de migración, especialmente cuando se trabaja con datos persistentes utilizando **StoredState**, **FileState** o **SyncState**. Sin un manejo adecuado de la migración, cambios como agregar nuevos campos o modificar formatos de datos pueden causar problemas al cargar datos antiguos.

Aquí hay algunos puntos clave a tener en cuenta:
- **Agregar Nuevos Campos no Opcionales**: Asegúrese de que los nuevos campos sean opcionales o tengan valores predeterminados para mantener la compatibilidad con versiones anteriores.
- **Manejo de Cambios en el Formato de Datos**: Si la estructura de su modelo cambia, implemente una lógica de decodificación personalizada para admitir formatos antiguos.
- **Versionado de sus Modelos**: Use un campo `version` en sus modelos para ayudar con las migraciones y aplicar la lógica según la versión de los datos.

Para obtener más información sobre cómo administrar las migraciones y evitar posibles problemas, consulte la [Guía de Consideraciones sobre la Migración](migration-considerations.md).

## Guía de Implementación de SyncState

Para obtener instrucciones detalladas sobre cómo configurar iCloud y configurar SyncState en su proyecto, consulte la [Guía de Implementación de SyncState](syncstate-implementation.md).

## Mejores Prácticas

- **Use para Datos Pequeños y Críticos**: `SyncState` es ideal para sincronizar pequeñas e importantes piezas de estado, como las preferencias del usuario, la configuración o los indicadores de funciones.
- **Monitoree el Almacenamiento de iCloud**: Asegúrese de que su uso de `SyncState` se mantenga dentro de los límites de almacenamiento de iCloud para evitar problemas de sincronización de datos.
- **Maneje las Actualizaciones Externas**: Si su aplicación necesita responder a los cambios de estado iniciados en otro dispositivo, anule la función `didChangeExternally` para actualizar el estado de la aplicación en tiempo real.

## Conclusión

`SyncState` proporciona una forma poderosa de sincronizar pequeñas cantidades de estado de la aplicación en todos los dispositivos a través de iCloud. Es ideal para garantizar que las preferencias del usuario y otros datos clave permanezcan consistentes en todos los dispositivos que hayan iniciado sesión en la misma cuenta de iCloud. Para casos de uso más avanzados, explore otras características de **AppState**, como [SecureState](usage-securestate.md) y [FileState](usage-filestate.md).

---
Esto fue generado usando Jules, pueden ocurrir errores. Por favor, haga un Pull Request con cualquier corrección que deba realizarse si es un hablante nativo.
