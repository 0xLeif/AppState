# Actualización a AppState 3.0

AppState 3.0 está construido en torno a Swift 6 y el framework Observation de Apple. A continuación se detallan los cambios importantes y cómo adaptarse.

## Cambios importantes de un vistazo

- **Versiones mínimas de plataforma elevadas** — iOS 17, macOS 14, tvOS 17, watchOS 10
- **Concurrencia estricta de Swift 6** — `ExistentialAny` habilitado; se requiere `any` explícito en los existenciales de protocolo
- **`ObservableObject` eliminado** — `Application` usa `@Observable`; `objectWillChange` desaparece, reemplácelo con `notifyChange()`
- **Nuevo (aditivo): soporte para SwiftData** — `ModelState` / `@ModelState` para objetos `@Model`

---

## 1. Requisitos de plataforma elevados

| Plataforma | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux y Windows siguen siendo compatibles para el conjunto de características que no son de Apple.

Permanezca en la línea de versiones 2.x si necesita admitir versiones de SO más antiguas.

## 2. Swift 6 estricto

El paquete fija el modo de lenguaje Swift 6 (`swiftLanguageModes: [.v6]`) y habilita la característica próxima `ExistentialAny`. CI compila con las advertencias tratadas como errores.

La mayoría de las aplicaciones no requieren cambios. Si implementó alguno de los protocolos públicos de AppState — `FileManaging`, `UserDefaultsManaging` o `UbiquitousKeyValueStoreManaging` — es posible que necesite escribir los tipos existenciales con un `any` explícito:

```swift
// Before (2.x)
var fileManager: FileManaging

// After (3.0)
var fileManager: any FileManaging
```

## 3. Observation reemplaza a ObservableObject

`Application` ahora usa [`@Observable`](https://developer.apple.com/documentation/observation) en lugar de `ObservableObject`.

**Los property wrappers no cambian.** `@AppState`, `@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`, `@OptionalSlice`, `@DependencySlice` y `@ModelState` siguen funcionando dentro de las vistas de SwiftUI. Los view models que se ajustan a `ObservableObject` y alojan estos wrappers todavía son compatibles.

Lo que cambió:

- `Application.shared.objectWillChange` ya no existe.
- `Application.notifyChange()` lo reemplaza. Los propios setters de AppState lo llaman automáticamente.
- Leer `Application.state(_:).value` directamente ahora participa en Observation — no solo el wrapper `@AppState`. Esto significa que cualquier código (no solo las vistas de SwiftUI) puede observar los cambios de estado:

  ```swift
  withObservationTracking {
      _ = Application.state(\.counter).value
  } onChange: {
      // runs when the value changes — no SwiftUI required
  }
  ```

Si creó una subclase de `Application` y llamó a `objectWillChange.send()` manualmente (por ejemplo, desde una anulación de `didChangeExternally`), reemplácelo con `notifyChange()`:

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

> `@ObservedDependency` no ha cambiado — todavía observa los valores de dependencia que se ajustan a `ObservableObject`.

## 4. Nuevo: Soporte para SwiftData

3.0 añade integración con SwiftData. Inyecte un `ModelContainer` compartido como una dependencia y lea/escriba objetos `@Model` a través de `ModelState`. Esto es aditivo y opcional — consulte la [Guía de Uso de ModelState](usage-modelstate.md).

---
Esta traducción fue generada automáticamente y puede contener errores. Si eres un hablante nativo, te agradecemos que contribuyas con correcciones a través de un Pull Request.
