# Uso de StoredState

`StoredState` es un componente de la biblioteca **AppState** que le permite almacenar y persistir pequeñas cantidades de datos utilizando `UserDefaults`. Es ideal para almacenar datos ligeros y no confidenciales que deben persistir entre los lanzamientos de la aplicación.

## Descripción General

- **StoredState** se basa en `UserDefaults`, lo que significa que es rápido y eficiente para almacenar pequeñas cantidades de datos (como las preferencias del usuario o la configuración de la aplicación).
- Los datos guardados en **StoredState** persisten entre las sesiones de la aplicación, lo que le permite restaurar el estado de la aplicación al iniciarla.

### Características Clave

- **Almacenamiento Persistente**: Los datos guardados en `StoredState` permanecen disponibles entre los lanzamientos de la aplicación.
- **Manejo de Datos Pequeños**: Se utiliza mejor para datos ligeros como preferencias, interruptores o configuraciones pequeñas.
- **Seguro para Hilos**: `StoredState` garantiza que el acceso a los datos permanezca seguro en entornos concurrentes.

## Ejemplo de Uso

### Definir un StoredState

Puede definir un **StoredState** extendiendo el objeto `Application` y declarando la propiedad de estado:

```swift
import AppState

extension Application {
    var userPreferences: StoredState<String> {
        storedState(initial: "Default Preferences", id: "userPreferences")
    }
}
```

### Acceder y Modificar StoredState en una Vista

Puede acceder y modificar los valores de **StoredState** dentro de las vistas de SwiftUI utilizando el property wrapper `@StoredState`:

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

## Manejo de la Migración de Datos

A medida que su aplicación evoluciona, es posible que actualice los modelos que se persisten a través de **StoredState**. Al actualizar su modelo de datos, asegúrese de la compatibilidad con versiones anteriores. Por ejemplo, puede agregar nuevos campos o versionar su modelo para manejar la migración.

Para obtener más información, consulte la [Guía de Consideraciones sobre la Migración](migration-considerations.md).

### Consideraciones sobre la Migración

- **Agregar Nuevos Campos no Opcionales**: Asegúrese de que los nuevos campos sean opcionales o tengan valores predeterminados para mantener la compatibilidad con versiones anteriores.
- **Versionado de Modelos**: Si su modelo de datos cambia con el tiempo, incluya un campo de `version` para administrar diferentes versiones de sus datos persistentes.

## Mejores Prácticas

- **Usar para Datos Pequeños**: Almacene datos ligeros y no confidenciales que necesiten persistir entre los lanzamientos de la aplicación, como las preferencias del usuario.
- **Considere Alternativas para Datos más Grandes**: Si necesita almacenar grandes cantidades de datos, considere usar **FileState** en su lugar.

## Conclusión

**StoredState** es una forma simple y eficiente de persistir pequeñas piezas de datos utilizando `UserDefaults`. Es ideal para guardar preferencias y otras configuraciones pequeñas entre los lanzamientos de la aplicación, al tiempo que proporciona un acceso seguro y una fácil integración con SwiftUI. Para necesidades de persistencia más complejas, explore otras características de **AppState** como [FileState](usage-filestate.md) o [SyncState](usage-syncstate.md).

---
Esta traducción fue generada automáticamente y puede contener errores. Si eres un hablante nativo, te agradecemos que contribuyas con correcciones a través de un Pull Request.
