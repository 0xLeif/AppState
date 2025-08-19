# Использование состояния и зависимостей

**AppState** предоставляет мощные инструменты для управления состоянием в масштабах всего приложения и внедрения зависимостей в представления SwiftUI. Централизуя свое состояние и зависимости, вы можете обеспечить согласованность и удобство сопровождения вашего приложения.

## Обзор

- **Состояние**: представляет значение, которое можно совместно использовать в приложении. Значения состояния можно изменять и наблюдать в представлениях SwiftUI.
- **Зависимость**: представляет собой общий ресурс или службу, которую можно внедрять и получать доступ в представлениях SwiftUI.

### Ключевые особенности

- **Централизованное состояние**: определяйте и управляйте состоянием в масштабах всего приложения в одном месте.
- **Внедрение зависимостей**: внедряйте и получайте доступ к общим службам и ресурсам в различных компонентах вашего приложения.

## Пример использования

### Определение состояния приложения

Чтобы определить состояние в масштабах всего приложения, расширьте объект `Application` и объявите свойства состояния.

```swift
import AppState

struct User {
    var name: String
    var isLoggedIn: Bool
}

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }
}
```

### Доступ и изменение состояния в представлении

Вы можете получать доступ и изменять значения состояния непосредственно в представлении SwiftUI с помощью обертки свойства `@AppState`.

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("Привет, \(user.name)!")
            Button("Войти") {
                user.name = "John Doe"
                user.isLoggedIn = true
            }
        }
    }
}
```

### Определение зависимостей

Вы можете определить общие ресурсы, такие как сетевая служба, как зависимости в объекте `Application`. Эти зависимости можно внедрять в представления SwiftUI.

```swift
import AppState

protocol NetworkServiceType {
    func fetchData() -> String
}

class NetworkService: NetworkServiceType {
    func fetchData() -> String {
        return "Data from network"
    }
}

extension Application {
    var networkService: Dependency<NetworkServiceType> {
        dependency(NetworkService())
    }
}
```

### Доступ к зависимостям в представлении

Получайте доступ к зависимостям в представлении SwiftUI с помощью обертки свойства `@AppDependency`. Это позволяет внедрять службы, такие как сетевая служба, в ваше представление.

```swift
import AppState
import SwiftUI

struct NetworkView: View {
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("Данные: \(networkService.fetchData())")
        }
    }
}
```

### Объединение состояния и зависимостей в представлении

Состояние и зависимости могут работать вместе для создания более сложной логики приложения. Например, вы можете получать данные из службы и обновлять состояние:

```swift
import AppState
import SwiftUI

struct CombinedView: View {
    @AppState(\.user) var user: User
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("Пользователь: \(user.name)")
            Button("Получить данные") {
                user.name = networkService.fetchData()
                user.isLoggedIn = true
            }
        }
    }
}
```

### Лучшие практики

- **Централизуйте состояние**: храните состояние вашего приложения в одном месте, чтобы избежать дублирования и обеспечить согласованность.
- **Используйте зависимости для общих служб**: внедряйте зависимости, такие как сетевые службы, базы данных или другие общие ресурсы, чтобы избежать тесной связи между компонентами.

## Заключение

С помощью **AppState** вы можете управлять состоянием в масштабах всего приложения и внедрять общие зависимости непосредственно в ваши представления SwiftUI. Этот шаблон помогает сохранить модульность и удобство сопровождения вашего приложения. Изучите другие функции библиотеки **AppState**, такие как [SecureState](usage-securestate.md) и [SyncState](usage-syncstate.md), чтобы еще больше улучшить управление состоянием вашего приложения.
