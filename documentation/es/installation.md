# Guía de Instalación

Esta guía lo guiará a través del proceso de instalación de **AppState** en su proyecto de Swift utilizando Swift Package Manager.

## Swift Package Manager

**AppState** se puede integrar fácilmente en su proyecto utilizando Swift Package Manager. Siga los pasos a continuación para agregar **AppState** como una dependencia.

### Paso 1: Actualice su Archivo `Package.swift`

Agregue **AppState** a la sección de `dependencies` de su archivo `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/AppState.git", from: "2.2.0")
]
```

### Paso 2: Agregue AppState a su Objetivo

Incluya AppState en las dependencias de su objetivo:

```swift
.target(
    name: "YourTarget",
    dependencies: ["AppState"]
)
```

### Paso 3: Compile su Proyecto

Una vez que haya agregado AppState a su archivo `Package.swift`, compile su proyecto para obtener la dependencia e integrarla en su base de código.

```
swift build
```

### Paso 4: Importe AppState en su Código

Ahora, puede comenzar a usar AppState en su proyecto importándolo en la parte superior de sus archivos de Swift:

```swift
import AppState
```

## Xcode

Si prefiere agregar **AppState** directamente a través de Xcode, siga estos pasos:

### Paso 1: Abra su Proyecto de Xcode

Abra su proyecto o espacio de trabajo de Xcode.

### Paso 2: Agregue una Dependencia de Paquete de Swift

1. Navegue hasta el navegador de proyectos y seleccione el archivo de su proyecto.
2. En el editor de proyectos, seleccione su objetivo y luego vaya a la pestaña "Swift Packages".
3. Haga clic en el botón "+" para agregar una dependencia de paquete.

### Paso 3: Ingrese la URL del Repositorio

En el cuadro de diálogo "Choose Package Repository", ingrese la siguiente URL: `https://github.com/0xLeif/AppState.git`

Luego haga clic en "Next".

### Paso 4: Especifique la Versión

Elija la versión que desea utilizar. Se recomienda seleccionar la opción "Up to Next Major Version" y especificar `2.0.0` como el límite inferior. Luego haga clic en "Next".

### Paso 5: Agregue el Paquete

Xcode obtendrá el paquete y le presentará opciones para agregar **AppState** a su objetivo. Asegúrese de seleccionar el objetivo correcto y haga clic en "Finish".

### Paso 6: Importe `AppState` en su Código

Ahora puede importar **AppState** en la parte superior de sus archivos de Swift:

```swift
import AppState
```

## Próximos Pasos

Con AppState instalado, puede pasar a la [Descripción General del Uso](usage-overview.md) para ver cómo implementar las características clave en su proyecto.

---
Esto fue generado usando [Jules](https://jules.google), pueden ocurrir errores. Por favor, haga un Pull Request con cualquier corrección que deba realizarse si es un hablante nativo.
