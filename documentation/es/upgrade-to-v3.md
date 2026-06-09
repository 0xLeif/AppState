# Actualización a AppState 3.0

AppState 3.0 moderniza la biblioteca en torno a Swift 6 y el framework Observation
de Apple. Esta guía cubre los cambios importantes y cómo adaptarse a ellos.

## 1. Requisitos de plataforma elevados

Los objetivos de implementación mínimos se elevaron para aprovechar las API modernas de
Swift y SwiftData/Observation:

| Plataforma | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux y Windows siguen siendo compatibles para el conjunto de características que no son de Apple.

Si debe seguir admitiendo versiones de SO más antiguas, permanezca en la línea de versiones 2.x.

## 2. Swift 6 estricto

El paquete ahora fija el modo de lenguaje Swift 6 (`swiftLanguageModes: [.v6]`) y la
característica próxima `ExistentialAny`, y CI compila con las advertencias tratadas como errores.
Para la mayoría de las aplicaciones esto no requiere cambios. Si implementó alguno de los
protocolos públicos de AppState (por ejemplo, un `FileManaging`, `UserDefaultsManaging` o
`UbiquitousKeyValueStoreManaging` personalizado), es posible que necesite escribir tipos existenciales con un
`any` explícito (por ejemplo, `any FileManaging`).

## 3. Observation reemplaza a ObservableObject

`Application` ahora usa la macro [`@Observable`](https://developer.apple.com/documentation/observation)
en lugar de ajustarse a `ObservableObject`.

**No se requiere ningún cambio para el uso típico.** Los property wrappers — `@AppState`,
`@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`,
`@OptionalSlice`, `@DependencySlice` y `@ModelState` — siguen funcionando dentro de
las vistas de SwiftUI y las vistas se actualizan como antes. Los view models que se ajustan a
`ObservableObject` y alojan estos wrappers todavía son compatibles.

Lo que cambió:

- `Application` ya no se ajusta a `ObservableObject`, por lo que
  `Application.shared.objectWillChange` ya no está disponible.
- Un nuevo método, `Application.notifyChange()`, solicita a los observadores (vistas de SwiftUI) que
  se actualicen. Los propios setters de AppState lo llaman por usted.

Si creó una subclase de `Application` y desencadenó actualizaciones manualmente — por ejemplo desde una
anulación de `didChangeExternally(notification:)` que reacciona a los cambios entrantes de iCloud —
reemplace `objectWillChange.send()` con `notifyChange()`:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            // Antes (2.x):
            // self.objectWillChange.send()

            // Después (3.0):
            self.notifyChange()
        }
    }
}
```

> Nota: `@ObservedDependency` no ha cambiado. Todavía observa los valores de dependencia
> que se ajustan a `ObservableObject`.

## 4. Nuevo: Soporte para SwiftData

3.0 añade una integración de SwiftData de primera clase: inyecte un `ModelContainer` compartido como
una dependencia y lea/escriba objetos `@Model` a través de `ModelState`. Consulte la
[Guía de Uso de ModelState](usage-modelstate.md). Esto es aditivo y opcional.

---
Esta traducción fue generada automáticamente y puede contener errores. Si eres un hablante nativo, te agradecemos que contribuyas con correcciones a través de un Pull Request.
