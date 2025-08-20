# Обзор использования

Этот обзор представляет собой краткое введение в использование ключевых компонентов библиотеки **AppState** в SwiftUI `View`. Каждый раздел содержит простые примеры, которые вписываются в рамки структуры представления SwiftUI.

## Определение значений в расширении приложения

Для определения состояния или зависимостей в масштабах всего приложения необходимо расширить объект `Application`. Это позволяет централизовать все состояние вашего приложения в одном месте. Вот пример того, как расширить `Application` для создания различных состояний и зависимостей:

```swift
import AppState

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }

    var userPreferences: StoredState<String> {
        storedState(initial: "Default Preferences", id: "userPreferences")
    }

    var darkModeEnabled: SyncState<Bool> {
        syncState(initial: false, id: "darkModeEnabled")
    }

    var userToken: SecureState {
        secureState(id: "userToken")
    }

    @MainActor
    var largeDataset: FileState<[String]> {
        fileState(initial: [], filename: "largeDataset")
    }
}
```

## State

`State` позволяет определить состояние в масштабах всего приложения, к которому можно получить доступ и изменить его в любом месте вашего приложения.

### Пример

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("Привет, \(user.name)!")
            Button("Войти") {
                user.isLoggedIn.toggle()
            }
        }
    }
}
```

## StoredState

`StoredState` сохраняет состояние с помощью `UserDefaults`, чтобы гарантировать, что значения сохраняются между запусками приложения.

### Пример

```swift
import AppState
import SwiftUI

struct PreferencesView: View {
    @StoredState(\.userPreferences) var userPreferences: String

    var body: some View {
        VStack {
            Text("Настройки: \(userPreferences)")
            Button("Обновить настройки") {
                userPreferences = "Updated Preferences"
            }
        }
    }
}
```

## SyncState

`SyncState` синхронизирует состояние приложения на нескольких устройствах с помощью iCloud.

### Пример

```swift
import AppState
import SwiftUI

struct SyncSettingsView: View {
    @SyncState(\.darkModeEnabled) var isDarkModeEnabled: Bool

    var body: some View {
        VStack {
            Toggle("Темный режим", isOn: $isDarkModeEnabled)
        }
    }
}
```

## FileState

`FileState` используется для постоянного хранения больших или более сложных данных с помощью файловой системы, что делает его идеальным для кэширования или сохранения данных, которые не вписываются в ограничения `UserDefaults`.

### Пример

```swift
import AppState
import SwiftUI

struct LargeDataView: View {
    @FileState(\.largeDataset) var largeDataset: [String]

    var body: some View {
        List(largeDataset, id: \.self) { item in
            Text(item)
        }
    }
}
```

## SecureState

`SecureState` надежно хранит конфиденциальные данные в связке ключей.

### Пример

```swift
import AppState
import SwiftUI

struct SecureView: View {
    @SecureState(\.userToken) var userToken: String?

    var body: some View {
        VStack {
            if let token = userToken {
                Text("Токен пользователя: \(token)")
            } else {
                Text("Токен не найден.")
            }
            Button("Установить токен") {
                userToken = "secure_token_value"
            }
        }
    }
}
```

## Constant

`Constant` предоставляет неизменяемый доступ только для чтения к значениям в состоянии вашего приложения, обеспечивая безопасность при доступе к значениям, которые не должны изменяться.

### Пример

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.user, \.name) var name: String

    var body: some View {
        Text("Имя пользователя: \(name)")
    }
}
```

## Slicing State

`Slice` и `OptionalSlice` позволяют получить доступ к определенным частям состояния вашего приложения.

### Пример

```swift
import AppState
import SwiftUI

struct SlicingView: View {
    @Slice(\.user, \.name) var name: String

    var body: some View {
        VStack {
            Text("Имя пользователя: \(name)")
            Button("Обновить имя пользователя") {
                name = "NewUsername"
            }
        }
    }
}
```

## Лучшие практики

- **Используйте `AppState` в представлениях SwiftUI**: обертки свойств, такие как `@AppState`, `@StoredState`, `@FileState`, `@SecureState` и другие, предназначены для использования в области представлений SwiftUI.
- **Определяйте состояние в расширении приложения**: централизуйте управление состоянием, расширяя `Application` для определения состояния и зависимостей вашего приложения.
- **Реактивные обновления**: SwiftUI автоматически обновляет представления при изменении состояния, поэтому вам не нужно вручную обновлять пользовательский интерфейс.
- **[Руководство по лучшим практикам](best-practices.md)**: для подробного описания лучших практик при использовании AppState.

## Следующие шаги

После ознакомления с основами использования вы можете изучить более сложные темы:

- Изучите использование **FileState** для сохранения больших объемов данных в файлы в [Руководстве по использованию FileState](usage-filestate.md).
- Узнайте о **константах** и о том, как их использовать для неизменяемых значений в состоянии вашего приложения, в [Руководстве по использованию констант](usage-constant.md).
- Узнайте, как **Dependency** используется в AppState для обработки общих служб, и посмотрите примеры в [Руководстве по использованию зависимостей состояния](usage-state-dependency.md).
- Углубитесь в более сложные методы **SwiftUI**, такие как использование `ObservedDependency` для управления наблюдаемыми зависимостями в представлениях, в [Руководстве по использованию ObservedDependency](usage-observeddependency.md).
- Для более сложных методов использования, таких как создание «точно в срок» и предварительная загрузка зависимостей, см. [Руководство по расширенному использованию](advanced-usage.md).

---
Это было сгенерировано с использованием Jules, могут возникнуть ошибки. Пожалуйста, сделайте Pull Request с любыми исправлениями, которые должны произойти, если вы носитель языка.
