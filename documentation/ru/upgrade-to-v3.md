# Обновление до AppState 3.0

AppState 3.0 построен вокруг Swift 6 и фреймворка Observation от Apple. Ниже перечислены критические изменения и способы адаптации к ним.

## Критические изменения вкратце

- **Повышены минимальные требования к платформам** — iOS 17, macOS 14, tvOS 17, watchOS 10
- **Строгая конкурентность Swift 6** — включён `ExistentialAny`; для протокольных экзистенциалов требуется явный `any`
- **`ObservableObject` удалён** — `Application` использует `@Observable`; `objectWillChange` больше нет, замените его на `notifyChange()`
- **Новое (дополнительно): поддержка SwiftData** — `ModelState` / `@ModelState` для объектов `@Model`

---

## 1. Повышенные требования к платформам

| Платформа | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux и Windows по-прежнему поддерживаются для набора функций, не относящихся к Apple.

Если вам нужно поддерживать более старые версии ОС, оставайтесь на линейке выпусков 2.x.

## 2. Строгий Swift 6

Пакет фиксирует языковой режим Swift 6 (`swiftLanguageModes: [.v6]`) и включает предстоящую функцию `ExistentialAny`. CI собирает проект с предупреждениями, рассматриваемыми как ошибки.

Большинству приложений изменения не требуются. Если вы реализовали какие-либо из публичных протоколов AppState — `FileManaging`, `UserDefaultsManaging` или `UbiquitousKeyValueStoreManaging` — вам, возможно, потребуется записывать экзистенциальные типы с явным `any`:

```swift
// Before (2.x)
var fileManager: FileManaging

// After (3.0)
var fileManager: any FileManaging
```

## 3. Observation заменяет ObservableObject

`Application` теперь использует [`@Observable`](https://developer.apple.com/documentation/observation) вместо `ObservableObject`.

**Обертки свойств не изменились.** `@AppState`, `@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`, `@OptionalSlice`, `@DependencySlice` и `@ModelState` по-прежнему работают внутри представлений SwiftUI. Модели представлений, соответствующие `ObservableObject` и содержащие эти обертки, по-прежнему поддерживаются.

Что изменилось:

- `Application.shared.objectWillChange` больше не существует.
- На замену пришёл `Application.notifyChange()`. Собственные сеттеры AppState вызывают его автоматически.
- Прямое чтение `Application.state(_:).value` теперь участвует в Observation — а не только обертка `@AppState`. Это значит, что любой код (не только представления SwiftUI) может наблюдать за изменениями состояния:

  ```swift
  withObservationTracking {
      _ = Application.state(\.counter).value
  } onChange: {
      // runs when the value changes — no SwiftUI required
  }
  ```

Если вы создали подкласс `Application` и вызывали `objectWillChange.send()` вручную (например, из переопределения `didChangeExternally`), замените его на `notifyChange()`:

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

> `@ObservedDependency` не изменился — он по-прежнему наблюдает за значениями зависимостей, соответствующих `ObservableObject`.

## 4. Новое: поддержка SwiftData

3.0 добавляет интеграцию SwiftData. Внедряйте общий `ModelContainer` в качестве зависимости и читайте/записывайте объекты `@Model` через `ModelState`. Это дополнительная и необязательная возможность — см. [Руководство по использованию ModelState](usage-modelstate.md).
