# Обновление до AppState 3.0

AppState 3.0 модернизирует библиотеку вокруг Swift 6 и фреймворка Observation от
Apple. Это руководство охватывает критические изменения и способы адаптации к ним.

## 1. Повышенные требования к платформам

Минимальные цели развертывания были повышены, чтобы использовать преимущества
современного Swift и API SwiftData/Observation:

| Платформа | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux и Windows по-прежнему поддерживаются для набора функций, не относящихся к Apple.

Если вам необходимо продолжать поддерживать более старые версии ОС, оставайтесь на линейке выпусков 2.x.

## 2. Строгий Swift 6

Теперь пакет фиксирует языковой режим Swift 6 (`swiftLanguageModes: [.v6]`) и
предстоящую функцию `ExistentialAny`, а CI собирает проект с предупреждениями,
рассматриваемыми как ошибки. Для большинства приложений это не требует изменений.
Если вы реализовали какие-либо из публичных протоколов AppState (например, собственный
`FileManaging`, `UserDefaultsManaging` или `UbiquitousKeyValueStoreManaging`), вам,
возможно, потребуется записывать экзистенциальные типы с явным `any` (например,
`any FileManaging`).

## 3. Observation заменяет ObservableObject

`Application` теперь использует макрос [`@Observable`](https://developer.apple.com/documentation/observation)
вместо соответствия `ObservableObject`.

**Для типичного использования никаких изменений не требуется.** Обертки свойств — `@AppState`,
`@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`,
`@OptionalSlice`, `@DependencySlice` и `@ModelState` — продолжают работать внутри
представлений SwiftUI, и представления обновляются как прежде. Модели представлений,
соответствующие `ObservableObject` и содержащие эти обертки, по-прежнему поддерживаются.

Что изменилось:

- `Application` больше не соответствует `ObservableObject`, поэтому
  `Application.shared.objectWillChange` больше недоступен.
- Новый метод, `Application.notifyChange()`, просит наблюдателей (представления SwiftUI)
  обновиться. Собственные сеттеры AppState вызывают его за вас.

Если вы создали подкласс `Application` и запускали обновления вручную — например, из
переопределения `didChangeExternally(notification:)`, реагирующего на входящие изменения
iCloud, — замените `objectWillChange.send()` на `notifyChange()`:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            // Раньше (2.x):
            // self.objectWillChange.send()

            // Теперь (3.0):
            self.notifyChange()
        }
    }
}
```

> Примечание: `@ObservedDependency` не изменился. Он по-прежнему наблюдает за значениями
> зависимостей, которые соответствуют `ObservableObject`.

## 4. Новое: поддержка SwiftData

3.0 добавляет первоклассную интеграцию SwiftData: внедряйте общий `ModelContainer` в
качестве зависимости и читайте/записывайте объекты `@Model` через `ModelState`. См.
[Руководство по использованию ModelState](usage-modelstate.md). Это дополнительно и необязательно.

---
Этот перевод был сгенерирован автоматически и может содержать ошибки. Если вы носитель языка, мы будем признательны за ваши исправления через Pull Request.
