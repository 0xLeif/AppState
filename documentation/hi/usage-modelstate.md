# ModelState का उपयोग

🍎 `ModelState` **AppState** लाइब्रेरी का एक घटक है जो आपको एप्लिकेशन के दायरे के माध्यम से SwiftData `@Model` ऑब्जेक्ट्स का प्रबंधन करने देता है। यह एक साझा SwiftData `ModelContainer` को एक निर्भरता के रूप में इंजेक्ट करता है और उस कंटेनर के `ModelContext` से पढ़ता और लिखता है, जिससे व्यू मॉडल, सेवाओं और अन्य गैर-व्यू कोड को आपके मॉडलों तक साझा, निर्भरता-इंजेक्टेड पहुँच मिलती है।

> 🍎 `ModelState` और SwiftData `ModelContainer` निर्भरता Apple प्लेटफ़ॉर्म के लिए विशिष्ट हैं, क्योंकि वे Apple के SwiftData फ्रेमवर्क पर निर्भर करते हैं।

## मुख्य विशेषताएँ

- **निर्भरता-इंजेक्टेड मॉडल**: एक साझा `ModelContainer` को एक बार पंजीकृत करें और अपने ऐप में कहीं भी इसके मॉडलों तक पहुँचें।
- **मुख्य-अभिनेता `ModelContext`**: किसी भी कोड से कंटेनर का `mainContext` पुनर्प्राप्त करें, जिसमें वे व्यू मॉडल और सेवाएँ शामिल हैं जिनकी SwiftUI के `@Environment` तक कोई पहुँच नहीं है।
- **CRUD सुविधा**: एक छोटे, केंद्रित API के माध्यम से SwiftData मॉडलों को पढ़ें, सम्मिलित करें, हटाएँ, सहेजें और रीसेट करें।
- **सत्य के स्रोत के रूप में SwiftData**: `ModelState` AppState के कैश में परिणामों को कैश नहीं करता है — SwiftData का `ModelContext` एकमात्र सत्य का स्रोत बना रहता है।

## आवश्यकताएँ और उपलब्धता

SwiftData सुविधाओं के लिए AppState की आधार आवश्यकताओं की तुलना में नए प्लेटफ़ॉर्म संस्करणों की आवश्यकता होती है। सभी `ModelState` और `ModelContainer` API `#if canImport(SwiftData)` और निम्नलिखित उपलब्धता के पीछे गेट किए गए हैं:

- **iOS**: 17.0+
- **macOS**: 14.0+
- **tvOS**: 17.0+
- **watchOS**: 10.0+
- **visionOS**: 1.0+

उन प्लेटफ़ॉर्म या OS संस्करणों पर जहाँ SwiftData उपलब्ध नहीं है, ये API संकलित नहीं किए जाते हैं।

## ModelContainer निर्भरता को पंजीकृत करना

SwiftData का `ModelContainer` `Sendable` है, इसलिए इसे एक सामान्य AppState `Dependency` के रूप में संग्रहीत किया जा सकता है। `modelContainer(_:)` सुविधा का उपयोग करके एक `Application` एक्सटेंशन पर एक परिभाषित करें, जो कंटेनर को एक स्वचालित रूप से उत्पन्न पहचानकर्ता के साथ पंजीकृत करता है और ऑटोक्लोज़र का मूल्यांकन केवल एक बार करता है:

```swift
import AppState
import SwiftData

extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(
            try! ModelContainer(for: Item.self)
        )
    }
}
```

## ModelContext तक पहुँचना

एक बार `ModelContainer` निर्भरता परिभाषित हो जाने के बाद, आप अपने ऐप में कहीं भी साझा, मुख्य-अभिनेता से बंधे `ModelContext` तक पहुँच सकते हैं:

```swift
let context = Application.modelContext(\.modelContainer)
```

यह हल किए गए `ModelContainer` का `mainContext` लौटाता है, इसलिए आपके पूरे ऐप में एक ही संदर्भ साझा किया जाता है।

## एक ModelState को परिभाषित करना

`Application` ऑब्जेक्ट का विस्तार करके और इसे उस `ModelContainer` निर्भरता की ओर इंगित करके एक `ModelState` को परिभाषित करें जो इसका समर्थन करती है। बिना किसी `FetchDescriptor` के, स्थिति दिए गए प्रकार के सभी मॉडलों से मेल खाती है:

```swift
import AppState
import SwiftData

extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

आप एक कस्टम `FetchDescriptor` (फ़िल्टरिंग या सॉर्टिंग के लिए) और एक स्पष्ट `id` भी प्रदान कर सकते हैं:

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

## @ModelState प्रॉपर्टी रैपर

`@ModelState` प्रॉपर्टी रैपर `Application` के दायरे से मॉडलों के एक संग्रह को उजागर करता है:

```swift
import AppState
import SwiftData

@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func addItem(title: String) {
        // असाइन करने से नए (अभी तक संग्रहीत नहीं किए गए) मॉडल सम्मिलित होते हैं और सहेजे जाते हैं।
        items = items + [Item(title: title)]
    }
}
```

- रैप किए गए मान को **पढ़ना** स्थिति के `FetchDescriptor` का उपयोग करके एक फ़ेच करता है।
- रैप किए गए मान को **असाइन करना** नए मान में उन किसी भी मॉडल को सम्मिलित करता है जो अभी तक संग्रहीत नहीं हैं और समर्थक संदर्भ को सहेजता है। नए मान से अनुपस्थित मौजूदा मॉडल **नहीं** हटाए जाते हैं — हटाने के लिए `delete(_:)` या `reset()` का उपयोग करें।

### प्रोजेक्टेड मान के माध्यम से CRUD

प्रोजेक्टेड मान (`$items`) अंतर्निहित `Application.ModelState<Item>` को उजागर करता है, जो आपको सम्मिलन, विलोपन और सहेजने पर स्पष्ट नियंत्रण देता है:

```swift
@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func add(_ item: Item) {
        $items.insert(item)
    }

    func remove(_ item: Item) {
        $items.delete(item)
    }

    func persistPendingChanges() {
        $items.save()
    }
}
```

## Application.modelState के माध्यम से पढ़ना और बदलना

आप एक प्रॉपर्टी रैपर के बिना, `Application` प्रकार के माध्यम से सीधे `ModelState` के साथ भी काम कर सकते हैं। यह सेवाओं और अन्य गैर-व्यू कोड में सुविधाजनक है:

```swift
@MainActor
func loadAndAppend() {
    let state = Application.modelState(\.items)

    // वर्तमान मॉडल पढ़ें (एक फ़ेच करता है)।
    let current = state.value

    // यदि आवश्यक हो तो सीधे समर्थक ModelContext तक पहुँचें।
    let context = state.context

    // सम्मिलित करें, हटाएँ और सहेजें।
    state.insert(Item(title: "New item"))
    state.delete(current.first!)
    state.save()
}
```

लौटाया गया `ModelState` उजागर करता है:

- `value`: वर्तमान में स्थिति के `FetchDescriptor` से मेल खाने वाले मॉडल (प्राप्त करना फ़ेच करता है; सेट करना नए मॉडल सम्मिलित करता है और सहेजता है)।
- `context`: समर्थक मुख्य-अभिनेता `ModelContext`।
- `insert(_:)`: एक मॉडल सम्मिलित करता है और सहेजता है।
- `delete(_:)`: एक मॉडल हटाता है और सहेजता है।
- `save()`: संदर्भ में किसी भी लंबित परिवर्तन को संग्रहीत करता है।

## रीसेट करना

किसी `ModelState` द्वारा प्रबंधित हर मॉडल को हटाने के लिए, `Application.reset(modelState:)` का उपयोग करें:

```swift
Application.reset(modelState: \.items)
```

यह स्थिति के `FetchDescriptor` से मेल खाने वाले हर मॉडल को फ़ेच करता है, उसे हटाता है और संदर्भ को सहेजता है।

## ModelState बनाम SwiftData @Query का उपयोग कब करें

`ModelState` और `@ModelState` के माध्यम से किए गए परिवर्तन स्वचालित रूप से SwiftUI को प्रसारित **नहीं** किए जाते हैं। यह एक जानबूझकर किया गया डिज़ाइन विकल्प है:

- **प्रतिक्रियाशील दृश्यों के लिए SwiftData के अपने `@Query` का उपयोग करें।** `@Query` `ModelContext` का निरीक्षण करता है और अंतर्निहित डेटा बदलने पर स्वचालित रूप से आपके दृश्य को रीफ्रेश करता है। इसे AppState द्वारा प्रदान किए गए `ModelContainer` के साथ संयोजित करें ताकि आपके दृश्य और आपका गैर-व्यू कोड एक ही कंटेनर साझा करें:

  ```swift
  import SwiftData
  import SwiftUI

  struct ItemsView: View {
      @Query(sort: \Item.title) private var items: [Item]

      var body: some View {
          List(items) { item in
              Text(item.title)
          }
      }
  }

  // साझा कंटेनर को SwiftUI वातावरण में इंजेक्ट करें।
  @main
  struct MyApp: App {
      var body: some Scene {
          WindowGroup {
              ItemsView()
          }
          .modelContainer(Application.dependency(\.modelContainer))
      }
  }
  ```

- **व्यू मॉडल, सेवाओं और अन्य गैर-व्यू कोड के लिए `ModelState` / `@ModelState` का उपयोग करें** जिन्हें आपके मॉडलों तक साझा, निर्भरता-इंजेक्टेड पहुँच की आवश्यकता है। यह वहाँ आदर्श है जहाँ SwiftUI के `@Environment` और `@Query` उपलब्ध नहीं हैं, या जहाँ आप व्यू कोड के बाहर मॉडल संचालन करना चाहते हैं।

यह भी ध्यान दें कि `value` सेटर केवल अभी तक संग्रहीत नहीं किए गए मॉडलों को सम्मिलित करता है — यह उन मॉडलों को नहीं हटाता है जो नए मान से अनुपस्थित हैं। मॉडल हटाने के लिए `delete(_:)` या `reset(modelState:)` का उपयोग करें।

## एंड-टू-एंड उदाहरण

निम्नलिखित उदाहरण एक संपूर्ण प्रवाह दिखाता है: एक `@Model`, कंटेनर और मॉडल स्थिति को पंजीकृत करने वाले `Application` एक्सटेंशन, और एक व्यू मॉडल जो `@ModelState` का उपयोग करता है।

```swift
import AppState
import SwiftData
import SwiftUI

// 1. SwiftData मॉडल को परिभाषित करें।
@Model
final class TodoItem {
    var title: String
    var isComplete: Bool

    init(title: String, isComplete: Bool = false) {
        self.title = title
        self.isComplete = isComplete
    }
}

// 2. Application पर साझा ModelContainer और एक ModelState पंजीकृत करें।
extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(
            try! ModelContainer(for: TodoItem.self)
        )
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

// 3. एक व्यू मॉडल से @ModelState का उपयोग करें।
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
        Application.reset(modelState: \.todoItems)
    }
}
```

उसी डेटा से बंधी एक प्रतिक्रियाशील सूची के लिए, ऊपर [ModelState बनाम SwiftData @Query का उपयोग कब करें](#modelstate-बनाम-swiftdata-query-का-उपयोग-कब-करें) अनुभाग में दिखाए अनुसार, परिवर्तनों को व्यू मॉडल में रखते हुए दृश्य को SwiftData के `@Query` से संचालित करें।

## सर्वोत्तम प्रथाएं

- **प्रतिक्रियाशील दृश्य `@Query` का उपयोग करते हैं**: SwiftData के `@Query` को उन दृश्यों के लिए आरक्षित रखें जिन्हें स्वचालित रूप से अपडेट होने की आवश्यकता है, और उनके साथ AppState द्वारा प्रदान किए गए `ModelContainer` को साझा करें।
- **गैर-व्यू कोड `ModelState` का उपयोग करता है**: व्यू मॉडल, सेवाओं और पृष्ठभूमि तर्क में `@ModelState` और `Application.modelState` का उपयोग करें जिन्हें साझा मॉडल पहुँच की आवश्यकता है।
- **स्पष्ट विलोपन**: याद रखें कि `value` को असाइन करना केवल सम्मिलित करता है; मॉडल हटाने के लिए `delete(_:)` या `reset(modelState:)` का उपयोग करें।
- **एक साझा कंटेनर**: एक ही `ModelContainer` निर्भरता पंजीकृत करें और इसे अपनी मॉडल स्थितियों और SwiftUI वातावरण से संदर्भित करें ताकि सब कुछ एक ही स्टोर को पढ़े और लिखे।

## निष्कर्ष

`ModelState` SwiftData को **AppState** के निर्भरता-इंजेक्शन मॉडल में लाता है, जिससे आप अपने पूरे ऐप में एक ही `ModelContainer` साझा कर सकते हैं और व्यू मॉडल और सेवाओं से `@Model` ऑब्जेक्ट्स के साथ काम कर सकते हैं। प्रतिक्रियाशील UI के लिए, इसे SwiftData के `@Query` और उसी साझा कंटेनर के साथ जोड़ें।

---
यह अनुवाद स्वचालित रूप से उत्पन्न किया गया था और इसमें त्रुटियाँ हो सकती हैं। यदि आप एक देशी वक्ता हैं, तो हम एक पुल अनुरोध के माध्यम से सुधारों में आपके योगदान की सराहना करेंगे।
