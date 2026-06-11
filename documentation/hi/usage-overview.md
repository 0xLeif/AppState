# उपयोग का अवलोकन

यह अवलोकन SwiftUI `View` के भीतर **AppState** लाइब्रेरी के प्रमुख घटकों का उपयोग करने का एक त्वरित परिचय प्रदान करता है। प्रत्येक अनुभाग में सरल उदाहरण शामिल हैं जो SwiftUI दृश्य संरचना के दायरे में फिट होते हैं।

## एप्लिकेशन एक्सटेंशन में मान परिभाषित करना

एप्लिकेशन-व्यापी स्थिति या निर्भरताओं को परिभाषित करने के लिए, आपको `Application` ऑब्जेक्ट का विस्तार करना चाहिए। यह आपको अपने ऐप की सभी स्थिति को एक ही स्थान पर केंद्रीकृत करने की अनुमति देता है। यहाँ विभिन्न स्थितियों और निर्भरताओं को बनाने के लिए `Application` का विस्तार करने का एक उदाहरण दिया गया है:

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

`State` आपको एप्लिकेशन-व्यापी स्थिति परिभाषित करने की अनुमति देता है जिसे आपके ऐप में कहीं भी एक्सेस और संशोधित किया जा सकता है।

### उदाहरण

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("Hello, \(user.name)!")
            Button("Log in") {
                user.isLoggedIn.toggle()
            }
        }
    }
}
```

## StoredState

`StoredState` `UserDefaults` का उपयोग करके स्थिति को स्थायी बनाता है ताकि यह सुनिश्चित हो सके कि मान ऐप लॉन्च के बीच सहेजे जाएँ।

### उदाहरण

```swift
import AppState
import SwiftUI

struct PreferencesView: View {
    @StoredState(\.userPreferences) var userPreferences: String

    var body: some View {
        VStack {
            Text("Preferences: \(userPreferences)")
            Button("Update Preferences") {
                userPreferences = "Updated Preferences"
            }
        }
    }
}
```

## SyncState

`SyncState` iCloud का उपयोग करके कई उपकरणों में ऐप स्थिति को सिंक्रनाइज़ करता है।

### उदाहरण

```swift
import AppState
import SwiftUI

struct SyncSettingsView: View {
    @SyncState(\.darkModeEnabled) var isDarkModeEnabled: Bool

    var body: some View {
        VStack {
            Toggle("Dark Mode", isOn: $isDarkModeEnabled)
        }
    }
}
```

## FileState

`FileState` का उपयोग फ़ाइल सिस्टम का उपयोग करके बड़े या अधिक जटिल डेटा को स्थायी रूप से संग्रहीत करने के लिए किया जाता है, जो इसे कैशिंग या ऐसे डेटा को सहेजने के लिए आदर्श बनाता है जो `UserDefaults` की सीमाओं में फिट नहीं होता।

### उदाहरण

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

## ModelState

🍎 `ModelState` एक साझा `ModelContainer` को इंजेक्ट करके AppState के माध्यम से SwiftData `@Model` ऑब्जेक्ट्स का प्रबंधन करता है। यह व्यू मॉडल, सेवाओं और अन्य गैर-व्यू कोड के लिए अभिप्रेत है; रिएक्टिव व्यू के लिए, AppState द्वारा प्रदान किए गए `ModelContainer` के साथ SwiftData के `@Query` का उपयोग करें। SwiftData फ़ीचर्स के लिए iOS 17+ / macOS 14+ आवश्यक है।

### उदाहरण

```swift
import AppState
import SwiftData

private func makeItemContainer() -> ModelContainer {
    do {
        return try ModelContainer(for: Item.self)
    } catch {
        fatalError("Failed to create ModelContainer: \(error)")
    }
}

extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeItemContainer())
    }

    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}

@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func add(_ item: Item) {
        $items.insert(item)
    }
}
```

अधिक विवरण के लिए, देखें [ModelState उपयोग मार्गदर्शिका](usage-modelstate.md)।

## SecureState

`SecureState` संवेदनशील डेटा को कीचेन में सुरक्षित रूप से संग्रहीत करता है।

### उदाहरण

```swift
import AppState
import SwiftUI

struct SecureView: View {
    @SecureState(\.userToken) var userToken: String?

    var body: some View {
        VStack {
            if let token = userToken {
                Text("User token: \(token)")
            } else {
                Text("No token found.")
            }
            Button("Set Token") {
                userToken = "secure_token_value"
            }
        }
    }
}
```

## Constant

`Constant` आपके एप्लिकेशन की स्थिति के भीतर मानों तक अपरिवर्तनीय, केवल-पढ़ने योग्य पहुँच प्रदान करता है, जो उन मानों तक पहुँचते समय सुरक्षा सुनिश्चित करता है जिन्हें संशोधित नहीं किया जाना चाहिए।

### उदाहरण

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.user, \.name) var name: String

    var body: some View {
        Text("Username: \(name)")
    }
}
```

## स्लाइसिंग स्थिति

`Slice` और `OptionalSlice` आपको अपने एप्लिकेशन की स्थिति के विशिष्ट भागों तक पहुँचने की अनुमति देते हैं।

### उदाहरण

```swift
import AppState
import SwiftUI

struct SlicingView: View {
    @Slice(\.user, \.name) var name: String

    var body: some View {
        VStack {
            Text("Username: \(name)")
            Button("Update Username") {
                name = "NewUsername"
            }
        }
    }
}
```

## सर्वोत्तम प्रथाएँ

- **SwiftUI व्यू में `AppState` का उपयोग करें**: `@AppState`, `@StoredState`, `@FileState`, `@SecureState`, और अन्य जैसे प्रॉपर्टी रैपर SwiftUI व्यू के दायरे में उपयोग के लिए डिज़ाइन किए गए हैं।
- **एप्लिकेशन एक्सटेंशन में स्थिति परिभाषित करें**: अपने ऐप की स्थिति और निर्भरताओं को परिभाषित करने के लिए `Application` का विस्तार करके स्थिति प्रबंधन को केंद्रीकृत करें।
- **रिएक्टिव अपडेट**: स्थिति बदलने पर SwiftUI स्वचालित रूप से व्यू अपडेट करता है, इसलिए आपको UI को मैन्युअल रूप से रिफ्रेश करने की आवश्यकता नहीं है।
- **[सर्वोत्तम प्रथाएँ मार्गदर्शिका](best-practices.md)**: AppState का उपयोग करते समय सर्वोत्तम प्रथाओं के विस्तृत विवरण के लिए।

## अगले चरण

बुनियादी उपयोग से परिचित होने के बाद, आप अधिक उन्नत विषयों का पता लगा सकते हैं:

- [FileState उपयोग मार्गदर्शिका](usage-filestate.md) में फ़ाइलों में बड़ी मात्रा में डेटा को स्थायी बनाने के लिए **FileState** का उपयोग करना देखें।
- 🍎 [ModelState उपयोग मार्गदर्शिका](usage-modelstate.md) में AppState के माध्यम से **SwiftData** मॉडलों का प्रबंधन करना सीखें।
- [स्थिरांक उपयोग मार्गदर्शिका](usage-constant.md) में **Constants** के बारे में और अपने ऐप की स्थिति में अपरिवर्तनीय मानों के लिए उनका उपयोग कैसे करें, सीखें।
- AppState में साझा सेवाओं को संभालने के लिए **Dependency** का उपयोग कैसे किया जाता है, इसकी जाँच करें, और [स्टेट निर्भरता उपयोग मार्गदर्शिका](usage-state-dependency.md) में उदाहरण देखें।
- [ObservedDependency उपयोग मार्गदर्शिका](usage-observeddependency.md) में व्यू में अवलोकनीय निर्भरताओं के प्रबंधन के लिए `ObservedDependency` का उपयोग करने जैसी **उन्नत SwiftUI** तकनीकों में गहराई से उतरें।
- अधिक उन्नत उपयोग तकनीकों के लिए, जैसे जस्ट-इन-टाइम निर्माण और निर्भरताओं को प्रीलोड करना, [उन्नत उपयोग मार्गदर्शिका](advanced-usage.md) देखें।
