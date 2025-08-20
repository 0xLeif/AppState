# Preguntas Frecuentes

Esta breve sección de preguntas frecuentes aborda las preguntas comunes que los desarrolladores pueden tener al usar **AppState**.

## ¿Cómo reinicio un valor de estado?

Para los estados persistentes como `StoredState`, `FileState` y `SyncState`, puede reiniciarlos a sus valores iniciales utilizando las funciones estáticas `reset` en el tipo `Application`.

Por ejemplo, para reiniciar un `StoredState<Bool>`:
```swift
extension Application {
    var hasCompletedOnboarding: StoredState<Bool> { storedState(initial: false, id: "onboarding_complete") }
}

// En algún lugar de su código
Application.reset(storedState: \.hasCompletedOnboarding)
```
Esto restablecerá el valor en `UserDefaults` a `false`. Existen funciones `reset` similares para `FileState`, `SyncState` y `SecureState`.

Para un `State` no persistente, puede reiniciarlo de la misma manera que los estados persistentes:
```swift
extension Application {
    var counter: State<Int> { state(initial: 0) }
}

// En algún lugar de su código
Application.reset(\.counter)
```

## ¿Puedo usar AppState con tareas asíncronas?

Sí. Los valores de `State` y de dependencia son seguros para hilos y funcionan sin problemas con Swift Concurrency. Puede acceder a ellos y modificarlos dentro de funciones `async` sin necesidad de bloqueos adicionales.

## ¿Dónde debo definir los estados y las dependencias?

Mantenga todos sus estados y dependencias en extensiones de `Application`. Esto asegura una única fuente de verdad y facilita el descubrimiento de todos los valores disponibles.

## ¿Es AppState compatible con Combine?

Puede usar AppState junto con Combine puenteando los cambios de `State` a publicadores. Observe un valor de `State` y envíe actualizaciones a través de un `PassthroughSubject` u otro publicador de Combine si es necesario.

---
Esto fue generado usando Jules, pueden ocurrir errores. Por favor, haga un Pull Request con cualquier corrección que deba realizarse si es un hablante nativo.
