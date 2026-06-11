# AppState 3.0 में अपग्रेड करना

AppState 3.0 Swift 6 और Apple के Observation फ्रेमवर्क के इर्द-गिर्द बनाया गया है। नीचे ब्रेकिंग परिवर्तन और उन्हें अनुकूलित करने का तरीका दिया गया है।

## ब्रेकिंग परिवर्तन एक नज़र में

- **प्लेटफ़ॉर्म न्यूनतम बढ़ाए गए** — iOS 17, macOS 14, tvOS 17, watchOS 10
- **Swift 6 सख्त समवर्तीता** — `ExistentialAny` सक्षम; प्रोटोकॉल एक्ज़िस्टेंशियल पर स्पष्ट `any` आवश्यक
- **`ObservableObject` हटाया गया** — `Application` अब `@Observable` का उपयोग करता है; `objectWillChange` समाप्त हो गया है, इसे `notifyChange()` से बदलें
- **नया (जोड़ा गया): SwiftData समर्थन** — `@Model` ऑब्जेक्ट्स के लिए `ModelState` / `@ModelState`

---

## 1. बढ़ाई गई प्लेटफ़ॉर्म आवश्यकताएँ

| प्लेटफ़ॉर्म | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

गैर-Apple फ़ीचर सेट के लिए Linux और Windows का समर्थन जारी है।

यदि आपको पुराने OS संस्करणों का समर्थन करने की आवश्यकता है तो 2.x रिलीज़ लाइन पर बने रहें।

## 2. सख्त Swift 6

पैकेज Swift 6 भाषा मोड (`swiftLanguageModes: [.v6]`) पिन करता है और `ExistentialAny` आगामी फ़ीचर सक्षम करता है। CI चेतावनियों को त्रुटियों के रूप में बिल्ड करता है।

अधिकांश ऐप्स को किसी परिवर्तन की आवश्यकता नहीं होती। यदि आपने AppState के किसी भी सार्वजनिक प्रोटोकॉल — `FileManaging`, `UserDefaultsManaging`, या `UbiquitousKeyValueStoreManaging` — को लागू किया है, तो आपको स्पष्ट `any` के साथ एक्ज़िस्टेंशियल प्रकार लिखने पड़ सकते हैं:

```swift
// Before (2.x)
var fileManager: FileManaging

// After (3.0)
var fileManager: any FileManaging
```

## 3. Observation, ObservableObject की जगह लेता है

`Application` अब `ObservableObject` के बजाय [`@Observable`](https://developer.apple.com/documentation/observation) का उपयोग करता है।

**प्रॉपर्टी रैपर अपरिवर्तित हैं।** `@AppState`, `@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`, `@OptionalSlice`, `@DependencySlice`, और `@ModelState` सभी SwiftUI व्यू के अंदर काम करना जारी रखते हैं। `ObservableObject` के अनुरूप व्यू मॉडल जो इन रैपर को होस्ट करते हैं, अभी भी समर्थित हैं।

क्या बदला:

- `Application.shared.objectWillChange` अब मौजूद नहीं है।
- `Application.notifyChange()` इसकी जगह लेता है। AppState के अपने सेटर इसे स्वचालित रूप से कॉल करते हैं।
- `Application.state(_:).value` को सीधे पढ़ना अब Observation में भाग लेता है — केवल `@AppState` रैपर ही नहीं। इसका मतलब है कि कोई भी कोड (केवल SwiftUI व्यू ही नहीं) स्थिति परिवर्तनों का निरीक्षण कर सकता है:

  ```swift
  withObservationTracking {
      _ = Application.state(\.counter).value
  } onChange: {
      // runs when the value changes — no SwiftUI required
  }
  ```

यदि आपने `Application` को सबक्लास किया और मैन्युअल रूप से `objectWillChange.send()` को कॉल किया (उदाहरण के लिए, `didChangeExternally` ओवरराइड से), तो इसे `notifyChange()` से बदलें:

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

> `@ObservedDependency` अपरिवर्तित है — यह अभी भी `ObservableObject` के अनुरूप निर्भरता मानों का निरीक्षण करता है।

## 4. नया: SwiftData समर्थन

3.0 SwiftData एकीकरण जोड़ता है। एक साझा `ModelContainer` को निर्भरता के रूप में इंजेक्ट करें और `ModelState` के माध्यम से `@Model` ऑब्जेक्ट्स को पढ़ें/लिखें। यह जोड़ा गया और वैकल्पिक है — देखें [ModelState उपयोग मार्गदर्शिका](usage-modelstate.md)।
