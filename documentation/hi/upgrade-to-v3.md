# AppState 3.0 में अपग्रेड करना

AppState 3.0 लाइब्रेरी को Swift 6 और Apple के Observation फ्रेमवर्क के इर्द-गिर्द
आधुनिक बनाता है। यह मार्गदर्शिका ब्रेकिंग परिवर्तनों और उन्हें अनुकूलित करने के तरीके को कवर करती है।

## 1. बढ़ाई गई प्लेटफ़ॉर्म आवश्यकताएँ

आधुनिक Swift और SwiftData/Observation API का लाभ उठाने के लिए न्यूनतम परिनियोजन
लक्ष्य बढ़ा दिए गए थे:

| प्लेटफ़ॉर्म | 2.x | 3.0 |
| --- | --- | --- |
| iOS | 15.0 | **17.0** |
| macOS | 11.0 | **14.0** |
| tvOS | 15.0 | **17.0** |
| watchOS | 8.0 | **10.0** |
| visionOS | 1.0 | 1.0 |

Linux और Windows गैर-Apple फ़ीचर सेट के लिए समर्थित रहते हैं।

यदि आपको पुराने OS संस्करणों का समर्थन जारी रखना है, तो 2.x रिलीज़ लाइन पर बने रहें।

## 2. सख्त Swift 6

पैकेज अब Swift 6 भाषा मोड (`swiftLanguageModes: [.v6]`) और
`ExistentialAny` आगामी सुविधा को पिन करता है, और CI चेतावनियों को त्रुटियों के रूप में मानते हुए बिल्ड करता है।
अधिकांश ऐप्स के लिए इसके लिए किसी परिवर्तन की आवश्यकता नहीं है। यदि आपने AppState के
किसी सार्वजनिक प्रोटोकॉल को लागू किया है (उदाहरण के लिए एक कस्टम `FileManaging`, `UserDefaultsManaging`, या
`UbiquitousKeyValueStoreManaging`), तो आपको एक स्पष्ट `any` के साथ अस्तित्वगत प्रकार लिखने की
आवश्यकता हो सकती है (जैसे `any FileManaging`)।

## 3. Observation, ObservableObject का स्थान लेता है

`Application` अब `ObservableObject` के अनुरूप होने के बजाय [`@Observable`](https://developer.apple.com/documentation/observation)
मैक्रो का उपयोग करता है।

**सामान्य उपयोग के लिए किसी परिवर्तन की आवश्यकता नहीं है।** प्रॉपर्टी रैपर — `@AppState`,
`@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@Slice`,
`@OptionalSlice`, `@DependencySlice`, और `@ModelState` — SwiftUI दृश्यों के अंदर
काम करना जारी रखते हैं और दृश्य पहले की तरह अपडेट होते हैं। वे व्यू मॉडल जो
`ObservableObject` के अनुरूप हैं और इन रैपरों को होस्ट करते हैं, अभी भी समर्थित हैं।

क्या बदला:

- `Application` अब `ObservableObject` के अनुरूप नहीं है, इसलिए
  `Application.shared.objectWillChange` अब उपलब्ध नहीं है।
- एक नई विधि, `Application.notifyChange()`, पर्यवेक्षकों (SwiftUI दृश्यों) से
  अपडेट करने के लिए कहती है। AppState के अपने सेटर आपके लिए इसे कॉल करते हैं।

यदि आपने `Application` को उपवर्गित किया और मैन्युअल रूप से अपडेट ट्रिगर किए — उदाहरण के लिए एक
`didChangeExternally(notification:)` ओवरराइड से जो आने वाले iCloud परिवर्तनों पर प्रतिक्रिया करता है —
तो `objectWillChange.send()` को `notifyChange()` से बदलें:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            // पहले (2.x):
            // self.objectWillChange.send()

            // बाद में (3.0):
            self.notifyChange()
        }
    }
}
```

> ध्यान दें: `@ObservedDependency` अपरिवर्तित है। यह अभी भी उन निर्भरता मानों का निरीक्षण
> करता है जो `ObservableObject` के अनुरूप हैं।

## 4. नया: SwiftData समर्थन

3.0 प्रथम-श्रेणी SwiftData एकीकरण जोड़ता है: एक साझा `ModelContainer` को एक निर्भरता के रूप में
इंजेक्ट करें और `ModelState` के माध्यम से `@Model` ऑब्जेक्ट्स को पढ़ें/लिखें। देखें
[ModelState उपयोग मार्गदर्शिका](usage-modelstate.md)। यह योगात्मक और वैकल्पिक है।

---
यह अनुवाद स्वचालित रूप से उत्पन्न किया गया था और इसमें त्रुटियाँ हो सकती हैं। यदि आप एक देशी वक्ता हैं, तो हम एक पुल अनुरोध के माध्यम से सुधारों में आपके योगदान की सराहना करेंगे।
