# AppState

[![macOS Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/macOS.yml?label=macOS&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/macOS.yml)
[![Ubuntu Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/ubuntu.yml?label=Ubuntu&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/ubuntu.yml)
[![Windows Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/windows.yml?label=Windows&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/windows.yml)
[![License](https://img.shields.io/github/license/0xLeif/AppState)](https://github.com/0xLeif/AppState/blob/main/LICENSE)
[![Version](https://img.shields.io/github/v/release/0xLeif/AppState)](https://github.com/0xLeif/AppState/releases)

Читайте это на других языках: [French](README.fr.md) | [German](README.de.md) | [Hindi](README.hi.md) | [Portuguese](README.pt.md) | [Russian](README.ru.md) | [Simplified Chinese](README.zh-CN.md) | [Spanish](README.es.md)

**AppState** — это библиотека Swift 6 для управления состоянием приложения в поточно-безопасном, типобезопасном и дружественном к SwiftUI виде. Централизуйте и синхронизируйте состояние в вашем приложении; внедряйте зависимости где угодно.

## Требования

- **iOS**: 17.0+
- **watchOS**: 10.0+
- **macOS**: 14.0+
- **tvOS**: 17.0+
- **visionOS**: 1.0+
- **Swift**: 6.0+
- **Xcode**: 16.0+

**Поддержка платформ, не относящихся к Apple**: Linux и Windows

> 🍎 Функции, отмеченные этим символом, специфичны для платформ Apple, так как они зависят от технологий Apple, таких как iCloud и Keychain.

## Ключевые особенности

**AppState** включает в себя несколько мощных функций для управления состоянием и зависимостями:

- **State**: Централизованное управление состоянием, которое позволяет инкапсулировать и транслировать изменения по всему приложению.
- **StoredState**: Постоянное состояние с использованием `UserDefaults`, идеально подходящее для сохранения небольших объемов данных между запусками приложения.
- **FileState**: Постоянное состояние, хранящееся с использованием `FileManager`, полезное для безопасного хранения больших объемов данных на диске.
- 🍎 **SwiftData (ModelState)**: Управляйте объектами SwiftData `@Model` через AppState, внедряя общий `ModelContainer` и читая/записывая модели с помощью `ModelState`.
- 🍎 **SyncState**: Синхронизация состояния между несколькими устройствами с использованием iCloud, обеспечивающая согласованность пользовательских предпочтений и настроек.
- 🍎 **SecureState**: Безопасное хранение конфиденциальных данных с использованием Keychain, защита информации пользователя, такой как токены или пароли.
- **Управление зависимостями**: Внедряйте зависимости, такие как сетевые службы или клиенты баз данных, по всему вашему приложению для лучшей модульности и тестирования.
- **Slicing**: Доступ к определенным частям состояния или зависимости для гранулярного контроля без необходимости управлять всем состоянием приложения.
- **Constants**: Доступ к срезам вашего состояния только для чтения, когда вам нужны неизменяемые значения.
- **Observed Dependencies**: Наблюдайте за зависимостями `ObservableObject`, чтобы ваши представления обновлялись при их изменении.

## Начало работы

Добавьте **AppState** через Swift Package Manager — см. [Руководство по установке](ru/installation.md). Затем ознакомьтесь с [Обзором использования](ru/usage-overview.md) для быстрого введения.

## Краткий пример

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

## Документация

Вот подробная разбивка документации **AppState**:

- [Руководство по установке](ru/installation.md): Как добавить **AppState** в ваш проект с помощью Swift Package Manager.
- [Обзор использования](ru/usage-overview.md): Обзор ключевых функций с примерами реализации.

### Подробные руководства по использованию:

- [Управление состоянием и зависимостями](ru/usage-state-dependency.md): Централизуйте состояние и внедряйте зависимости по всему вашему приложению.
- [Нарезка состояния](ru/usage-slice.md): Доступ и изменение определенных частей состояния.
- [Руководство по использованию StoredState](ru/usage-storedstate.md): Как сохранять легковесные данные с помощью `StoredState`.
- [Руководство по использованию FileState](ru/usage-filestate.md): Узнайте, как безопасно хранить большие объемы данных на диске.
- 🍎 [Руководство по использованию ModelState](ru/usage-modelstate.md): Управляйте объектами SwiftData `@Model` через общий `ModelContainer`.
- [Использование SecureState с Keychain](ru/usage-securestate.md): Безопасное хранение конфиденциальных данных с использованием Keychain.
- [Синхронизация с iCloud с помощью SyncState](ru/usage-syncstate.md): Поддерживайте синхронизацию состояния на всех устройствах с помощью iCloud.
- [Обновление до AppState 3.0](ru/upgrade-to-v3.md): Критические изменения и способы миграции с линейки выпусков 2.x.
- [Часто задаваемые вопросы](ru/faq.md): Ответы на часто задаваемые вопросы при использовании **AppState**.
- [Руководство по использованию констант](ru/usage-constant.md): Доступ к значениям только для чтения из вашего состояния.
- [Руководство по использованию ObservedDependency](ru/usage-observeddependency.md): Работа с зависимостями `ObservableObject` в ваших представлениях.
- [Расширенное использование](ru/advanced-usage.md): Такие методы, как создание «точно в срок» и предварительная загрузка зависимостей.
- [Лучшие практики](ru/best-practices.md): Советы по эффективной структуре состояния вашего приложения.
- [Рекомендации по миграции](ru/migration-considerations.md): Руководство при обновлении сохраненных моделей.

## Вклад

Мы приветствуем вклад! Пожалуйста, ознакомьтесь с нашим [Руководством по участию](ru/contributing.md), чтобы узнать, как принять участие.

## Следующие шаги

Начните с [Обзора использования](ru/usage-overview.md). Для создания «точно в срок» и предварительной загрузки зависимостей см. [Руководство по расширенному использованию](ru/advanced-usage.md). Руководства [Constant](ru/usage-constant.md) и [ObservedDependency](ru/usage-observeddependency.md) описывают дополнительные возможности.

---
Это было сгенерировано с использованием [Jules](https://jules.google), могут возникнуть ошибки. Пожалуйста, сделайте Pull Request с любыми исправлениями, которые должны произойти, если вы носитель языка.
