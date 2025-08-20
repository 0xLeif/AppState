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

`State` आपको एप्लिकेशन-व्यापी स्थिति को परिभाषित करने की अनुमति देता है जिसे आपके ऐप में कहीं भी एक्सेस और संशोधित किया जा सकता है।

### उदाहरण

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("नमस्ते, \(user.name)!")
            Button("लॉग इन करें") {
                user.isLoggedIn.toggle()
            }
        }
    }
}
```

## StoredState

`StoredState` `UserDefaults` का उपयोग करके स्थिति को बनाए रखता है ताकि यह सुनिश्चित हो सके कि मान ऐप लॉन्च के बीच सहेजे गए हैं।

### उदाहरण

```swift
import AppState
import SwiftUI

struct PreferencesView: View {
    @StoredState(\.userPreferences) var userPreferences: String

    var body: some View {
        VStack {
            Text("वरीयताएँ: \(userPreferences)")
            Button("वरीयताएँ अपडेट करें") {
                userPreferences = "Updated Preferences"
            }
        }
    }
}
```

## SyncState

`SyncState` iCloud का उपयोग करके कई उपकरणों में ऐप की स्थिति को सिंक्रनाइज़ करता है।

### उदाहरण

```swift
import AppState
import SwiftUI

struct SyncSettingsView: View {
    @SyncState(\.darkModeEnabled) var isDarkModeEnabled: Bool

    var body: some View {
        VStack {
            Toggle("डार्क मोड", isOn: $isDarkModeEnabled)
        }
    }
}
```

## FileState

`FileState` का उपयोग फ़ाइल सिस्टम का उपयोग करके बड़े या अधिक जटिल डेटा को स्थायी रूप से संग्रहीत करने के लिए किया जाता है, जो इसे कैशिंग या उन डेटा को सहेजने के लिए आदर्श बनाता है जो `UserDefaults` की सीमाओं के भीतर फिट नहीं होते हैं।

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

## SecureState

`SecureState` संवेदनशील डेटा को किचेन में सुरक्षित रूप से संग्रहीत करता है।

### उदाहरण

```swift
import AppState
import SwiftUI

struct SecureView: View {
    @SecureState(\.userToken) var userToken: String?

    var body: some View {
        VStack {
            if let token = userToken {
                Text("उपयोगकर्ता टोकन: \(token)")
            } else {
                Text("कोई टोकन नहीं मिला।")
            }
            Button("टोकन सेट करें") {
                userToken = "secure_token_value"
            }
        }
    }
}
```

## Constant

`Constant` आपके एप्लिकेशन की स्थिति के भीतर मानों तक अपरिवर्तनीय, केवल-पढ़ने के लिए पहुँच प्रदान करता है, उन मानों तक पहुँचते समय सुरक्षा सुनिश्चित करता है जिन्हें संशोधित नहीं किया जाना चाहिए।

### उदाहरण

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.user, \.name) var name: String

    var body: some View {
        Text("उपयोगकर्ता नाम: \(name)")
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
            Text("उपयोगकर्ता नाम: \(name)")
            Button("उपयोगकर्ता नाम अपडेट करें") {
                name = "NewUsername"
            }
        }
    }
}
```

## सर्वोत्तम प्रथाएं

- **SwiftUI दृश्यों में `AppState` का उपयोग करें**: `@AppState`, `@StoredState`, `@FileState`, `@SecureState`, और अन्य जैसे संपत्ति रैपर SwiftUI दृश्यों के दायरे में उपयोग किए जाने के लिए डिज़ाइन किए गए हैं।
- **एप्लिकेशन एक्सटेंशन में स्थिति को परिभाषित करें**: अपने ऐप की स्थिति और निर्भरताओं को परिभाषित करने के लिए `Application` का विस्तार करके स्थिति प्रबंधन को केंद्रीकृत करें।
- **प्रतिक्रियाशील अपडेट**: जब स्थिति बदलती है तो SwiftUI स्वचालित रूप से दृश्यों को अपडेट करता है, इसलिए आपको UI को मैन्युअल रूप से रीफ्रेश करने की आवश्यकता नहीं है।
- **[सर्वोत्तम प्रथाओं के लिए गाइड](best-practices.md)**: AppState का उपयोग करते समय सर्वोत्तम प्रथाओं के विस्तृत विवरण के लिए।

## अगले चरण

बुनियादी उपयोग से परिचित होने के बाद, आप अधिक उन्नत विषयों का पता लगा सकते हैं:

- [FileState उपयोग गाइड](usage-filestate.md) में फ़ाइलों में बड़ी मात्रा में डेटा को बनाए रखने के लिए **FileState** का उपयोग करने का अन्वेषण करें।
- [स्थिरांक उपयोग गाइड](usage-constant.md) में **स्थिरांक** के बारे में जानें और अपने ऐप की स्थिति में अपरिवर्तनीय मानों के लिए उनका उपयोग कैसे करें।
- [राज्य निर्भरता उपयोग गाइड](usage-state-dependency.md) में साझा सेवाओं को संभालने के लिए AppState में **निर्भरता** का उपयोग कैसे किया जाता है, इसकी जांच करें और उदाहरण देखें।
- [देखे गए निर्भरता उपयोग गाइड](usage-observeddependency.md) में दृश्यों में अवलोकन योग्य निर्भरताओं के प्रबंधन के लिए `ObservedDependency` का उपयोग करने जैसी **उन्नत SwiftUI** तकनीकों में गहराई से उतरें।
- अधिक उन्नत उपयोग तकनीकों के लिए, जैसे जस्ट-इन-टाइम निर्माण और निर्भरताओं को प्रीलोड करना, [उन्नत उपयोग गाइड](advanced-usage.md) देखें।

---
यह जूल्स का उपयोग करके उत्पन्न किया गया था, गलतियाँ हो सकती हैं। कृपया किसी भी सुधार के साथ एक पुल अनुरोध करें जो आपके मूल वक्ता होने पर होना चाहिए।
