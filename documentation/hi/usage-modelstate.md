# ModelState का उपयोग

🍎 `ModelState` आपको AppState के निर्भरता-इंजेक्शन मॉडल के माध्यम से SwiftData `@Model` ऑब्जेक्ट्स का प्रबंधन करने देता है। एक साझा `ModelContainer` को एक बार पंजीकृत करें; अपने कॉल स्टैक के माध्यम से `ModelContext` को पास किए बिना — व्यू मॉडल, सेवाओं, या अन्य गैर-व्यू कोड से — कहीं भी मॉडलों को पढ़ें और लिखें।

> 🍎 `ModelState` के लिए SwiftData समर्थन वाले Apple प्लेटफ़ॉर्म आवश्यक हैं (iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS 1+)। ये API Linux और Windows पर संकलित नहीं होते।

## एंड-टू-एंड उदाहरण

```swift
import AppState
import SwiftData
import SwiftUI

// 1. Define the model.
@Model
final class TodoItem {
    var title: String
    var isComplete: Bool

    init(title: String, isComplete: Bool = false) {
        self.title = title
        self.isComplete = isComplete
    }
}

// 2. Register the shared container and a ModelState on Application.
private func makeModelContainer() -> ModelContainer {
    do {
        return try ModelContainer(for: TodoItem.self)
    } catch {
        fatalError("Failed to create ModelContainer: \(error)")
    }
}

extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }

    var todoItems: ModelState<TodoItem> {
        modelState(
            container: \.modelContainer,
            fetchDescriptor: FetchDescriptor<TodoItem>(
                sortBy: [SortDescriptor(\.title)]
            ),
            id: "todoItems"
        )
    }
}

// 3. Use @ModelState from a view model.
@MainActor
final class TodoListViewModel: ObservableObject {
    @ModelState(\.todoItems) var todoItems: [TodoItem]

    func add(title: String) {
        $todoItems.insert(TodoItem(title: title))
    }

    func toggle(_ item: TodoItem) {
        item.isComplete.toggle()
        $todoItems.save()
    }

    func remove(_ item: TodoItem) {
        $todoItems.delete(item)
    }

    func clearAll() {
        $todoItems.deleteAll()
    }
}
```

## ModelContainer पंजीकृत करना

`modelContainer(_:)` कंटेनर को एक स्वतः-उत्पन्न पहचानकर्ता के साथ पंजीकृत करता है और ऑटोक्लोज़र का मूल्यांकन केवल एक बार करता है। कंटेनर को इनलाइन के बजाय एक हेल्पर में बनाएं — इससे विफलताएँ स्पष्ट होती हैं:

```swift
extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }
}
```

## ModelState परिभाषित करना

बिना किसी `FetchDescriptor` के, स्थिति दिए गए प्रकार के सभी मॉडलों से मेल खाती है:

```swift
extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

फ़िल्टरिंग या सॉर्टिंग के लिए एक `FetchDescriptor` प्रदान करें:

```swift
extension Application {
    var items: ModelState<Item> {
        modelState(
            container: \.modelContainer,
            fetchDescriptor: FetchDescriptor<Item>(
                sortBy: [SortDescriptor(\.title)]
            ),
            id: "items"
        )
    }
}
```

## पढ़ना और बदलना

**`@ModelState` के माध्यम से** — रैप किए गए मान को पढ़ें, `$items` के माध्यम से बदलें:

```swift
@ModelState(\.items) var items: [Item]

func add(_ item: Item) { $items.insert(item) }
func remove(_ item: Item) { $items.delete(item) }
func persist() { $items.save() }
```

**`Application.modelState` के माध्यम से** — सेवाओं और गैर-व्यू कोड में उपयोगी:

```swift
@MainActor
func syncItems() {
    let state = Application.modelState(\.items)
    let current = state.models
    state.insert(Item(title: "New"))
    state.delete(current.first!)
    state.save()
}
```

> `models` प्रत्येक पठन पर एक लाइव SwiftData फ़ेच करता है। जब आपको इसकी एक से अधिक बार आवश्यकता हो तो परिणाम को एक लोकल में कैप्चर करें।

### प्रोजेक्टेड-वैल्यू API

| विधि | व्यवहार |
| --- | --- |
| `$items.insert(_:)` | एक मॉडल सम्मिलित करता है और सहेजता है |
| `$items.delete(_:)` | एक मॉडल हटाता है और सहेजता है |
| `$items.save()` | लंबित परिवर्तनों को स्थायी करता है |
| `$items.deleteAll()` | `FetchDescriptor` से मेल खाने वाले सभी मॉडलों को हटाता है और सहेजता है |

ये म्यूटेटर किसी भी अंतर्निहित SwiftData त्रुटि को लॉग करते हैं और निगल जाते हैं ताकि कॉल साइट संक्षिप्त रहें। जब आपको किसी विफल लेखन को सामने लाने या उससे उबरने की आवश्यकता हो, तो `strict` पर मौजूद थ्रोइंग समकक्षों का उपयोग करें:

```swift
do {
    try $items.strict.insert(item)
    try $items.strict.save()
} catch {
    // त्रुटि प्रस्तुत करें, रोलबैक करें, पुनः प्रयास करें…
}
```

`strict` सभी चार म्यूटेटरों (`insert`, `delete`, `save`, `deleteAll`) के थ्रोइंग संस्करणों को उसी संदर्भ द्वारा समर्थित करके उजागर करता है — जब लॉग की गई विफलता स्वीकार्य हो तो लेनिएंट API चुनें, और जब कॉलर को इसे संभालना ही हो तो `strict` चुनें।

## ModelContext तक पहुँचना

```swift
let context = Application.modelContext(\.modelContainer)
```

हल किए गए `ModelContainer` का `mainContext` लौटाता है — वही संदर्भ जो सभी पठन और लेखन द्वारा उपयोग किया जाता है।

## ModelState बनाम SwiftData @Query

`ModelState` बदलाव SwiftUI व्यू में स्वचालित रूप से प्रसारित **नहीं** होते। यह जानबूझकर किया गया है।

- **रिएक्टिव व्यू** — `@Query` का उपयोग करें। यह `ModelContext` का सीधे निरीक्षण करता है और डेटा बदलने पर व्यू को रिफ्रेश करता है। AppState द्वारा प्रदान किए गए कंटेनर को SwiftUI एनवायरनमेंट के साथ साझा करें ताकि व्यू और गैर-व्यू कोड एक ही स्टोर का उपयोग करें:

  ```swift
  @main
  struct MyApp: App {
      var body: some Scene {
          WindowGroup {
              ItemsView()
          }
          .modelContainer(Application.dependency(\.modelContainer))
      }
  }

  struct ItemsView: View {
      @Query(sort: \Item.title) private var items: [Item]

      var body: some View {
          List(items) { Text($0.title) }
      }
  }
  ```

- **व्यू मॉडल और सेवाएँ** — `@ModelState` / `Application.modelState` का उपयोग करें। आदर्श जब `@Environment` और `@Query` उपलब्ध न हों, या जब आपको व्यू कोड के बाहर मॉडल ऑपरेशन की आवश्यकता हो।

## नोट्स

- सभी पठन और लेखन कंटेनर के `mainContext` से होकर गुजरते हैं — उपयोग को मुख्य अभिनेता पर रखें।
- `ModelState` AppState के अपने कैश में परिणामों को कैश नहीं करता। SwiftData का `ModelContext` सत्य का स्रोत है।
- एक एकल `ModelContainer` निर्भरता पंजीकृत करें और इसे सभी मॉडल स्थितियों और SwiftUI एनवायरनमेंट से संदर्भित करें।
