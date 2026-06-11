# AppState

[![macOS Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/macOS.yml?label=macOS&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/macOS.yml)
[![Ubuntu Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/ubuntu.yml?label=Ubuntu&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/ubuntu.yml)
[![Windows Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/windows.yml?label=Windows&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/windows.yml)
[![License](https://img.shields.io/github/license/0xLeif/AppState)](https://github.com/0xLeif/AppState/blob/main/LICENSE)
[![Version](https://img.shields.io/github/v/release/0xLeif/AppState)](https://github.com/0xLeif/AppState/releases)

Lea esto en otros idiomas: [Francés](README.fr.md) | [Alemán](README.de.md) | [Hindi](README.hi.md) | [Portugués](README.pt.md) | [Ruso](README.ru.md) | [Chino Simplificado](README.zh-CN.md) | [Español](README.es.md)

**AppState** es una biblioteca de Swift 6 para gestionar el estado de la aplicación de una manera segura para hilos, segura para tipos y compatible con SwiftUI. Centralice y sincronice el estado en toda su aplicación; inyecte dependencias en cualquier lugar.

## Requisitos

- **iOS**: 17.0+
- **watchOS**: 10.0+
- **macOS**: 14.0+
- **tvOS**: 17.0+
- **visionOS**: 1.0+
- **Swift**: 6.0+
- **Xcode**: 16.0+

**Soporte para plataformas no Apple**: Linux y Windows

> 🍎 Las características marcadas con este símbolo son específicas de las plataformas de Apple, ya que dependen de tecnologías de Apple como iCloud y el Llavero.

## Características Clave

**AppState** incluye:

- **State**: Gestión centralizada del estado que le permite encapsular y transmitir cambios en toda la aplicación.
- **StoredState**: Estado persistente utilizando `UserDefaults`, ideal para guardar pequeñas cantidades de datos entre lanzamientos de la aplicación.
- **FileState**: Estado persistente almacenado usando `FileManager`, útil para almacenar grandes cantidades de datos de forma segura en el disco.
- 🍎 **SwiftData (ModelState)**: Gestione objetos `@Model` de SwiftData a través de AppState inyectando un `ModelContainer` compartido y leyendo/escribiendo modelos con `ModelState`.
- 🍎 **SyncState**: Sincronice el estado en múltiples dispositivos usando iCloud, asegurando la coherencia en las preferencias y configuraciones del usuario.
- 🍎 **SecureState**: Almacene datos sensibles de forma segura usando el Llavero, protegiendo información del usuario como tokens o contraseñas.
- **Gestión de Dependencias**: Inyecte dependencias como servicios de red o clientes de bases de datos en toda su aplicación para una mejor modularidad y pruebas.
- **Slicing**: Acceda a partes específicas de un estado o dependencia para un control granular sin necesidad de gestionar todo el estado de la aplicación.
- **Constants**: Acceda a porciones de solo lectura de su estado cuando necesite valores inmutables.
- **Observed Dependencies**: Observe las dependencias de `ObservableObject` para que sus vistas se actualicen cuando cambien.

## Empezando

Agregue **AppState** mediante Swift Package Manager — consulte la [Guía de Instalación](es/installation.md). Luego revise la [Descripción General del Uso](es/usage-overview.md) para una introducción rápida.

## Ejemplo Rápido

```swift
import AppState
import SwiftUI

private extension Application {
    var counter: State<Int> {
        state(initial: 0)
    }
}

struct ContentView: View {
    @AppState(\.counter) var counter: Int

    var body: some View {
        VStack {
            Text("Count: \(counter)")
            Button("Increment") { counter += 1 }
        }
    }
}
```

## Documentación

Aquí hay un desglose detallado de la documentación de **AppState**:

- [Guía de Instalación](es/installation.md): Cómo agregar **AppState** a su proyecto usando Swift Package Manager.
- [Descripción General del Uso](es/usage-overview.md): Una descripción general de las características clave con implementaciones de ejemplo.

### Guías de Uso Detalladas:

- [Gestión de Estado y Dependencias](es/usage-state-dependency.md): Centralice el estado e inyecte dependencias en toda su aplicación.
- [Slicing de Estado](es/usage-slice.md): Acceda y modifique partes específicas del estado.
- [Guía de Uso de StoredState](es/usage-storedstate.md): Cómo persistir datos ligeros usando `StoredState`.
- [Guía de Uso de FileState](es/usage-filestate.md): Aprenda a persistir grandes cantidades de datos de forma segura en el disco.
- 🍎 [Guía de Uso de ModelState](es/usage-modelstate.md): Gestione objetos `@Model` de SwiftData a través de un `ModelContainer` compartido.
- [Uso de SecureState con Llavero](es/usage-securestate.md): Almacene datos sensibles de forma segura usando el Llavero.
- [Sincronización con iCloud usando SyncState](es/usage-syncstate.md): Mantenga el estado sincronizado en todos los dispositivos usando iCloud.
- [Actualización a AppState 3.0](es/upgrade-to-v3.md): Cambios importantes y cómo migrar desde la línea de versiones 2.x.
- [Preguntas Frecuentes](es/faq.md): Respuestas a preguntas comunes al usar **AppState**.
- [Guía de Uso de Constantes](es/usage-constant.md): Acceda a valores de solo lectura de su estado.
- [Guía de Uso de ObservedDependency](es/usage-observeddependency.md): Trabaje con dependencias de `ObservableObject` en sus vistas.
- [Uso Avanzado](es/advanced-usage.md): Técnicas como la creación justo a tiempo y la precarga de dependencias.
- [Mejores Prácticas](es/best-practices.md): Consejos para estructurar el estado de su aplicación de manera efectiva.
- [Consideraciones sobre la Migración](es/migration-considerations.md): Orientación al actualizar modelos persistentes.

## Contribuciones

¡Aceptamos contribuciones! Consulte nuestra [Guía de Contribuciones](es/contributing.md) para saber cómo participar.

## Próximos Pasos

Comience con la [Descripción General del Uso](es/usage-overview.md). Para la creación Justo a Tiempo y la precarga, consulte la [Guía de Uso Avanzado](es/advanced-usage.md). Las guías de [Constantes](es/usage-constant.md) y [ObservedDependency](es/usage-observeddependency.md) cubren características adicionales.

---
Esta traducción fue generada automáticamente y puede contener errores. Si eres un hablante nativo, te agradecemos que contribuyas con correcciones a través de un Pull Request.
