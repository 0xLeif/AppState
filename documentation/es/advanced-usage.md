# Uso Avanzado de AppState

Esta guía cubre temas avanzados para el uso de **AppState**, incluyendo la creación Just-In-Time, la precarga de dependencias, la gestión eficaz de estados y dependencias, y la comparación de **AppState** con el **Entorno de SwiftUI**.

## 1. Creación Just-In-Time

Los valores de AppState, como `State`, `Dependency`, `StoredState` y `SyncState`, se crean justo a tiempo. Esto significa que se instancian solo cuando se accede a ellos por primera vez, mejorando la eficiencia y el rendimiento de su aplicación.

### Ejemplo

```swift
extension Application {
    var defaultState: State<Int> {
        state(initial: 0) // El valor no se crea hasta que se accede a él
    }
}
```

En este ejemplo, `defaultState` no se crea hasta que se accede por primera vez, optimizando el uso de recursos.

## 2. Precarga de Dependencias

En algunos casos, es posible que desee precargar ciertas dependencias para asegurarse de que estén disponibles cuando se inicie su aplicación. AppState proporciona una función `load` que precarga las dependencias.

### Ejemplo

```swift
extension Application {
    var databaseClient: Dependency<DatabaseClient> {
        dependency(DatabaseClient())
    }
}

// Precargar en la inicialización de la aplicación
Application.load(dependency: \.databaseClient)
```

En este ejemplo, `databaseClient` se precarga durante la inicialización de la aplicación, asegurando que esté disponible cuando se necesite en sus vistas.

## 3. Gestión de Estado y Dependencias

### 3.1 Estado y Dependencias Compartidos en Toda la Aplicación

Puede definir un estado o dependencias compartidas en una parte de su aplicación y acceder a ellos en otra parte utilizando ID únicos.

### Ejemplo

```swift
private extension Application {
    var stateValue: State<Int> {
        state(initial: 0, id: "stateValue")
    }

    var dependencyValue: Dependency<SomeType> {
        dependency(SomeType(), id: "dependencyValue")
    }
}
```

Esto le permite acceder al mismo `State` o `Dependency` en otro lugar utilizando el mismo ID.

```swift
private extension Application {
    var theSameStateValue: State<Int> {
        state(initial: 0, id: "stateValue")
    }

    var theSameDependencyValue: Dependency<SomeType> {
        dependency(SomeType(), id: "dependencyValue")
    }
}
```

Aunque este enfoque es válido para compartir estados y dependencias en toda la aplicación reutilizando el mismo `id` de cadena, generalmente se desaconseja. Se basa en la gestión manual de estos ID de cadena, lo que puede llevar a:
- Colisiones accidentales de ID si el mismo ID se utiliza para diferentes estados/dependencias previstos.
- Dificultad para rastrear dónde se define un estado/dependencia frente a dónde se accede.
- Reducción de la claridad y mantenibilidad del código.
El valor `initial` proporcionado en definiciones posteriores con el mismo ID se ignorará si el estado/dependencia ya ha sido inicializado por su primer acceso. Este comportamiento es más un efecto secundario de cómo funciona el almacenamiento en caché basado en ID en AppState, en lugar de un patrón principal recomendado para definir datos compartidos. Prefiera definir estados y dependencias como propiedades computadas únicas en extensiones de `Application` (que generan automáticamente ID internos únicos si no se proporciona un `id` explícito al método de fábrica).

### 3.2 Acceso Restringido a Estado y Dependencias

Para restringir el acceso, utilice un ID único como un UUID para asegurarse de que solo las partes correctas de la aplicación puedan acceder a estados o dependencias específicos.

### Ejemplo

```swift
private extension Application {
    var restrictedState: State<Int?> {
        state(initial: nil, id: UUID().uuidString)
    }

    var restrictedDependency: Dependency<SomeType> {
        dependency(SomeType(), id: UUID().uuidString)
    }
}
```

### 3.3 ID Únicos para Estados y Dependencias

Cuando no se proporciona un ID, AppState genera un ID predeterminado basado en la ubicación en el código fuente. Esto asegura que cada `State` o `Dependency` sea único y esté protegido contra accesos no deseados.

### Ejemplo

```swift
extension Application {
    var defaultState: State<Int> {
        state(initial: 0) // AppState genera un ID único
    }

    var defaultDependency: Dependency<SomeType> {
        dependency(SomeType()) // AppState genera un ID único
    }
}
```

### 3.4 Acceso a Estado y Dependencias Privado a Nivel de Archivo

Para un acceso aún más restringido dentro del mismo archivo Swift, utilice el nivel de acceso `fileprivate` para proteger los estados y las dependencias de ser accedidos externamente.

### Ejemplo

```swift
fileprivate extension Application {
    var fileprivateState: State<Int> {
        state(initial: 0)
    }

    var fileprivateDependency: Dependency<SomeType> {
        dependency(SomeType())
    }
}
```

### 3.5 Comprensión del Mecanismo de Almacenamiento de AppState

AppState utiliza una caché unificada para almacenar `State`, `Dependency`, `StoredState` y `SyncState`. Esto asegura que estos tipos de datos se gestionen de manera eficiente en toda su aplicación.

Por defecto, AppState asigna un valor de nombre como "App", lo que asegura que todos los valores asociados con un módulo estén vinculados a ese nombre. Esto dificulta el acceso a estos estados y dependencias desde otros módulos.

## 4. AppState vs Entorno de SwiftUI

AppState y el Entorno de SwiftUI ofrecen formas de gestionar el estado compartido y las dependencias en su aplicación, pero difieren en alcance, funcionalidad y casos de uso.

### 4.1 Entorno de SwiftUI

El Entorno de SwiftUI es un mecanismo incorporado que le permite pasar datos compartidos a través de una jerarquía de vistas. Es ideal para pasar datos a los que muchas vistas necesitan acceso, pero tiene limitaciones cuando se trata de una gestión de estado más compleja.

**Fortalezas:**
- Fácil de usar y bien integrado con SwiftUI.
- Ideal para datos ligeros que necesitan ser compartidos entre múltiples vistas en una jerarquía.

**Limitaciones:**
- Los datos solo están disponibles dentro de la jerarquía de vistas específica. Acceder a los mismos datos a través de diferentes jerarquías de vistas no es posible sin trabajo adicional.
- Menos control sobre la seguridad de hilos y la persistencia en comparación con AppState.
- Falta de mecanismos de persistencia o sincronización incorporados.

### 4.2 AppState

AppState proporciona un sistema más potente y flexible para gestionar el estado en toda la aplicación, con capacidades de seguridad de hilos, persistencia e inyección de dependencias.

**Fortalezas:**
- Gestión de estado centralizada, accesible en toda la aplicación, no solo en jerarquías de vistas específicas.
- Mecanismos de persistencia incorporados (`StoredState`, `FileState` y `SyncState`).
- Garantías de seguridad de tipos y de hilos, asegurando que el estado se acceda y modifique correctamente.
- Puede manejar una gestión de estado y dependencias más compleja.

**Limitaciones:**
- Requiere más configuración en comparación con el Entorno de SwiftUI.
- Algo menos integrado con SwiftUI en comparación con Environment, aunque sigue funcionando bien en aplicaciones de SwiftUI.

### 4.3 Cuándo Usar Cada Uno

- Use el **Entorno de SwiftUI** cuando tenga datos simples que necesiten ser compartidos a través de una jerarquía de vistas, como la configuración del usuario o las preferencias de temas.
- Use **AppState** cuando necesite una gestión de estado centralizada, persistencia o un estado más complejo que deba ser accedido en toda la aplicación.

## Conclusión

Al utilizar estas técnicas avanzadas, como la creación justo a tiempo, la precarga, la gestión de estados y dependencias, y la comprensión de las diferencias entre AppState y el Entorno de SwiftUI, puede crear aplicaciones eficientes y conscientes de los recursos con **AppState**.

---
Esta traducción fue generada automáticamente y puede contener errores. Si eres un hablante nativo, te agradecemos que contribuyas con correcciones a través de un Pull Request.
