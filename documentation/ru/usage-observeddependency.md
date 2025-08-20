# Использование ObservedDependency

`ObservedDependency` — это компонент библиотеки **AppState**, который позволяет использовать зависимости, соответствующие протоколу `ObservableObject`. Это полезно, когда вы хотите, чтобы зависимость уведомляла ваши представления SwiftUI об изменениях, делая их реактивными и динамичными.

## Ключевые особенности

- **Наблюдаемые зависимости**: используйте зависимости, соответствующие протоколу `ObservableObject`, что позволяет зависимости автоматически обновлять ваши представления при изменении ее состояния.
- **Реактивные обновления пользовательского интерфейса**: представления SwiftUI автоматически обновляются при публикации изменений наблюдаемой зависимостью.
- **Потокобезопасность**: как и другие компоненты AppState, `ObservedDependency` обеспечивает потокобезопасный доступ к наблюдаемой зависимости.

## Пример использования

### Определение наблюдаемой зависимости

Вот как определить наблюдаемую службу как зависимость в расширении `Application`:

```swift
import AppState
import SwiftUI

@MainActor
class ObservableService: ObservableObject {
    @Published var count: Int = 0
}

extension Application {
    @MainActor
    var observableService: Dependency<ObservableService> {
        dependency(ObservableService())
    }
}
```

### Использование наблюдаемой зависимости в представлении SwiftUI

В вашем представлении SwiftUI вы можете получить доступ к наблюдаемой зависимости с помощью обертки свойства `@ObservedDependency`. Наблюдаемый объект автоматически обновляет представление при каждом изменении его состояния.

```swift
import AppState
import SwiftUI

struct ObservedDependencyExampleView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        VStack {
            Text("Счетчик: \(service.count)")
            Button("Увеличить счетчик") {
                service.count += 1
            }
        }
    }
}
```

### Тестовый случай

Следующий тестовый случай демонстрирует взаимодействие с `ObservedDependency`:

```swift
import XCTest
@testable import AppState

@MainActor
fileprivate class ObservableService: ObservableObject {
    @Published var count: Int

    init() {
        count = 0
    }
}

fileprivate extension Application {
    @MainActor
    var observableService: Dependency<ObservableService> {
        dependency(ObservableService())
    }
}

@MainActor
fileprivate struct ExampleDependencyWrapper {
    @ObservedDependency(\.observableService) var service

    func test() {
        service.count += 1
    }
}

final class ObservedDependencyTests: XCTestCase {
    @MainActor
    func testDependency() async {
        let example = ExampleDependencyWrapper()

        XCTAssertEqual(example.service.count, 0)

        example.test()

        XCTAssertEqual(example.service.count, 1)
    }
}
```

### Реактивные обновления пользовательского интерфейса

Поскольку зависимость соответствует протоколу `ObservableObject`, любое изменение ее состояния вызовет обновление пользовательского интерфейса в представлении SwiftUI. Вы можете напрямую привязать состояние к элементам пользовательского интерфейса, таким как `Picker`:

```swift
import AppState
import SwiftUI

struct ReactiveView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        Picker("Выберите счетчик", selection: $service.count) {
            ForEach(0..<10) { count in
                Text("\(count)").tag(count)
            }
        }
    }
}
```

## Лучшие практики

- **Используйте для наблюдаемых служб**: `ObservedDependency` идеально подходит, когда вашей зависимости необходимо уведомлять представления об изменениях, особенно для служб, которые предоставляют обновления данных или состояния.
- **Используйте опубликованные свойства**: убедитесь, что ваша зависимость использует свойства `@Published` для запуска обновлений в ваших представлениях SwiftUI.
- **Потокобезопасность**: как и другие компоненты AppState, `ObservedDependency` обеспечивает потокобезопасный доступ и изменения наблюдаемой службы.

## Заключение

`ObservedDependency` — это мощный инструмент для управления наблюдаемыми зависимостями в вашем приложении. Используя протокол `ObservableObject` Swift, он гарантирует, что ваши представления SwiftUI остаются реактивными и актуальными с изменениями в службе или ресурсе.

---
Это было сгенерировано с использованием Jules, могут возникнуть ошибки. Пожалуйста, сделайте Pull Request с любыми исправлениями, которые должны произойти, если вы носитель языка.
