# AppState

[![macOS बिल्ड](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/macOS.yml?label=macOS&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/macOS.yml)
[![Ubuntu बिल्ड](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/ubuntu.yml?label=Ubuntu&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/ubuntu.yml)
[![Windows बिल्ड](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/windows.yml?label=Windows&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/windows.yml)
[![लाइसेंस](https://img.shields.io/github/license/0xLeif/AppState)](https://github.com/0xLeif/AppState/blob/main/LICENSE)
[![संस्करण](https://img.shields.io/github/v/release/0xLeif/AppState)](https://github.com/0xLeif/AppState/releases)

इसे अन्य भाषाओं में पढ़ें: [French](README.fr.md) | [German](README.de.md) | [Hindi](README.hi.md) | [Portuguese](README.pt.md) | [Russian](README.ru.md) | [Simplified Chinese](README.zh-CN.md) | [Spanish](README.es.md)

**AppState** एप्लिकेशन स्थिति को थ्रेड-सुरक्षित, प्रकार-सुरक्षित और SwiftUI-अनुकूल तरीके से प्रबंधित करने के लिए एक Swift 6 लाइब्रेरी है। अपने ऐप में स्थिति को केंद्रीकृत और सिंक्रनाइज़ करें; कहीं भी निर्भरताएँ इंजेक्ट करें।

## आवश्यकताएँ

- **iOS**: 17.0+
- **watchOS**: 10.0+
- **macOS**: 14.0+
- **tvOS**: 17.0+
- **visionOS**: 1.0+
- **स्विफ्ट**: 6.0+
- **Xcode**: 16.0+

**गैर-Apple प्लेटफ़ॉर्म समर्थन**: लिनक्स और विंडोज

> 🍎 इस प्रतीक के साथ चिह्नित सुविधाएँ Apple प्लेटफ़ॉर्म के लिए विशिष्ट हैं, क्योंकि वे iCloud और कीचेन जैसी Apple तकनीकों पर निर्भर करती हैं।

## मुख्य विशेषताएँ

**AppState** में शामिल हैं:

- **State**: केंद्रीकृत स्थिति प्रबंधन जो आपको पूरे ऐप में परिवर्तनों को एनकैप्सुलेट और प्रसारित करने की अनुमति देता है।
- **StoredState**: `UserDefaults` का उपयोग करके स्थायी स्थिति, ऐप लॉन्च के बीच थोड़ी मात्रा में डेटा सहेजने के लिए आदर्श।
- **FileState**: `FileManager` का उपयोग करके संग्रहीत स्थायी स्थिति, डिस्क पर बड़ी मात्रा में डेटा को सुरक्षित रूप से संग्रहीत करने के लिए उपयोगी।
- 🍎 **SwiftData (ModelState)**: एक साझा `ModelContainer` को इंजेक्ट करके और `ModelState` के साथ मॉडलों को पढ़कर/लिखकर AppState के माध्यम से SwiftData `@Model` ऑब्जेक्ट्स का प्रबंधन करें।
- 🍎 **SyncState**: iCloud का उपयोग करके कई उपकरणों में स्थिति को सिंक्रनाइज़ करें, उपयोगकर्ता की प्राथमिकताओं और सेटिंग्स में स्थिरता सुनिश्चित करता है।
- 🍎 **SecureState**: कीचेन का उपयोग करके संवेदनशील डेटा को सुरक्षित रूप से संग्रहीत करें, उपयोगकर्ता की जानकारी जैसे टोकन या पासवर्ड की सुरक्षा करता है।
- **निर्भरता प्रबंधन**: बेहतर मॉड्यूलरिटी और परीक्षण के लिए अपने ऐप में नेटवर्क सेवाओं या डेटाबेस क्लाइंट जैसी निर्भरताएँ इंजेक्ट करें।
- **Slicing**: संपूर्ण एप्लिकेशन स्थिति को प्रबंधित करने की आवश्यकता के बिना दानेदार नियंत्रण के लिए किसी स्थिति या निर्भरता के विशिष्ट भागों तक पहुँचें।
- **Constants**: जब आपको अपरिवर्तनीय मानों की आवश्यकता हो तो अपनी स्थिति के केवल-पढ़ने के लिए स्लाइस तक पहुँचें।
- **Observed Dependencies**: `ObservableObject` निर्भरताओं का निरीक्षण करें ताकि जब वे बदलें तो आपके विचार अपडेट हों।

## शुरुआत कैसे करें

Swift Package Manager के माध्यम से **AppState** जोड़ें — देखें [स्थापना मार्गदर्शिका](en/installation.md)। फिर त्वरित परिचय के लिए [उपयोग अवलोकन](en/usage-overview.md) देखें।

## त्वरित उदाहरण

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

## दस्तावेज़ीकरण

यहाँ **AppState** के दस्तावेज़ीकरण का विस्तृत विवरण दिया गया है:

- [स्थापना मार्गदर्शिका](en/installation.md): Swift Package Manager का उपयोग करके अपने प्रोजेक्ट में **AppState** कैसे जोड़ें।
- [उपयोग अवलोकन](en/usage-overview.md): उदाहरण कार्यान्वयन के साथ मुख्य विशेषताओं का अवलोकन।

### विस्तृत उपयोग मार्गदर्शिकाएँ:

- [स्थिति और निर्भरता प्रबंधन](en/usage-state-dependency.md): स्थिति को केंद्रीकृत करें और अपने पूरे ऐप में निर्भरताएँ इंजेक्ट करें।
- [स्लाइसिंग स्थिति](en/usage-slice.md): स्थिति के विशिष्ट भागों तक पहुँचें और संशोधित करें।
- [StoredState उपयोग मार्गदर्शिका](en/usage-storedstate.md): `StoredState` का उपयोग करके हल्के डेटा को कैसे बनाए रखें।
- [FileState उपयोग मार्गदर्शिका](en/usage-filestate.md): डिस्क पर बड़ी मात्रा में डेटा को सुरक्षित रूप से कैसे बनाए रखें, जानें।
- 🍎 [ModelState उपयोग मार्गदर्शिका](en/usage-modelstate.md): एक साझा `ModelContainer` के माध्यम से SwiftData `@Model` ऑब्जेक्ट्स का प्रबंधन करें।
- [कीचेन SecureState उपयोग](en/usage-securestate.md): कीचेन का उपयोग करके संवेदनशील डेटा को सुरक्षित रूप से संग्रहीत करें।
- [SyncState के साथ iCloud सिंकिंग](en/usage-syncstate.md): iCloud का उपयोग करके उपकरणों में स्थिति को सिंक्रनाइज़ रखें।
- [AppState 3.0 में अपग्रेड करना](en/upgrade-to-v3.md): ब्रेकिंग परिवर्तन और 2.x रिलीज़ लाइन से माइग्रेट कैसे करें।
- [अक्सर पूछे जाने वाले प्रश्न](en/faq.md): **AppState** का उपयोग करते समय सामान्य प्रश्नों के उत्तर।
- [स्थिरांक उपयोग मार्गदर्शिका](en/usage-constant.md): अपनी स्थिति से केवल-पढ़ने के लिए मानों तक पहुँचें।
- [ObservedDependency उपयोग मार्गदर्शिका](en/usage-observeddependency.md): अपने विचारों में `ObservableObject` निर्भरताओं के साथ काम करें।
- [उन्नत उपयोग](en/advanced-usage.md): जस्ट-इन-टाइम निर्माण और निर्भरताओं को प्रीलोड करने जैसी तकनीकें।
- [सर्वोत्तम प्रथाएँ](en/best-practices.md): अपने ऐप की स्थिति को प्रभावी ढंग से संरचित करने के लिए युक्तियाँ।
- [माइग्रेशन विचार](en/migration-considerations.md): स्थायी मॉडल अपडेट करते समय मार्गदर्शन।

## योगदान

हम योगदान का स्वागत करते हैं! कृपया शामिल होने के तरीके के लिए हमारी [योगदान मार्गदर्शिका](en/contributing.md) देखें।

## अगले चरण

[उपयोग अवलोकन](en/usage-overview.md) से शुरुआत करें। जस्ट-इन-टाइम निर्माण और प्रीलोडिंग के लिए, [उन्नत उपयोग मार्गदर्शिका](en/advanced-usage.md) देखें। [स्थिरांक](en/usage-constant.md) और [ObservedDependency](en/usage-observeddependency.md) मार्गदर्शिकाएँ अतिरिक्त सुविधाओं को कवर करती हैं।
