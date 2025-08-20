# AppState

[![macOS बिल्ड](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/macOS.yml?label=macOS&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/macOS.yml)
[![Ubuntu बिल्ड](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/ubuntu.yml?label=Ubuntu&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/ubuntu.yml)
[![Windows बिल्ड](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/windows.yml?label=Windows&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/windows.yml)
[![लाइसेंस](https://img.shields.io/github/license/0xLeif/AppState)](https://github.com/0xLeif/AppState/blob/main/LICENSE)
[![संस्करण](https://img.shields.io/github/v/release/0xLeif/AppState)](https://github.com/0xLeif/AppState/releases)

**AppState** एक स्विफ्ट 6 लाइब्रेरी है जिसे एप्लिकेशन स्थिति के प्रबंधन को थ्रेड-सुरक्षित, प्रकार-सुरक्षित और SwiftUI-अनुकूल तरीके से सरल बनाने के लिए डिज़ाइन किया गया है। यह आपके एप्लिकेशन में स्थिति को केंद्रीकृत और सिंक्रनाइज़ करने के लिए उपकरणों का एक सेट प्रदान करता है, साथ ही आपके ऐप के विभिन्न हिस्सों में निर्भरताएँ इंजेक्ट करता है।

## आवश्यकताएँ

- **iOS**: 15.0+
- **watchOS**: 8.0+
- **macOS**: 11.0+
- **tvOS**: 15.0+
- **visionOS**: 1.0+
- **स्विफ्ट**: 6.0+
- **Xcode**: 16.0+

**गैर-Apple प्लेटफ़ॉर्म समर्थन**: लिनक्स और विंडोज

> 🍎 इस प्रतीक के साथ चिह्नित सुविधाएँ Apple प्लेटफ़ॉर्म के लिए विशिष्ट हैं, क्योंकि वे iCloud और कीचेन जैसी Apple तकनीकों पर निर्भर करती हैं।

## मुख्य विशेषताएँ

**AppState** में स्थिति और निर्भरताओं के प्रबंधन में मदद करने के लिए कई शक्तिशाली सुविधाएँ शामिल हैं:

- **State**: केंद्रीकृत स्थिति प्रबंधन जो आपको पूरे ऐप में परिवर्तनों को एनकैप्सुलेट और प्रसारित करने की अनुमति देता है।
- **StoredState**: `UserDefaults` का उपयोग करके स्थायी स्थिति, ऐप लॉन्च के बीच थोड़ी मात्रा में डेटा सहेजने के लिए आदर्श।
- **FileState**: `FileManager` का उपयोग करके संग्रहीत स्थायी स्थिति, डिस्क पर बड़ी मात्रा में डेटा को सुरक्षित रूप से संग्रहीत करने के लिए उपयोगी।
- 🍎 **SyncState**: iCloud का उपयोग करके कई उपकरणों में स्थिति को सिंक्रनाइज़ करें, उपयोगकर्ता की प्राथमिकताओं और सेटिंग्स में स्थिरता सुनिश्चित करता है।
- 🍎 **SecureState**: कीचेन का उपयोग करके संवेदनशील डेटा को सुरक्षित रूप से संग्रहीत करें, उपयोगकर्ता की जानकारी जैसे टोकन या पासवर्ड की सुरक्षा करता है।
- **निर्भरता प्रबंधन**: बेहतर मॉड्यूलरिटी और परीक्षण के लिए अपने ऐप में नेटवर्क सेवाओं या डेटाबेस क्लाइंट जैसी निर्भरताएँ इंजेक्ट करें।
- **Slicing**: संपूर्ण एप्लिकेशन स्थिति को प्रबंधित करने की आवश्यकता के बिना दानेदार नियंत्रण के लिए किसी स्थिति या निर्भरता के विशिष्ट भागों तक पहुँचें।
- **Constants**: जब आपको अपरिवर्तनीय मानों की आवश्यकता हो तो अपनी स्थिति के केवल-पढ़ने के लिए स्लाइस तक पहुँचें।
- **Observed Dependencies**: `ObservableObject` निर्भरताओं का निरीक्षण करें ताकि जब वे बदलें तो आपके विचार अपडेट हों।

## शुरुआत कैसे करें

**AppState** को अपने स्विफ्ट प्रोजेक्ट में एकीकृत करने के लिए, आपको स्विफ्ट पैकेज मैनेजर का उपयोग करना होगा। **AppState** स्थापित करने के बारे में विस्तृत निर्देशों के लिए [स्थापना मार्गदर्शिका](documentation/hi/installation.md) का पालन करें।

स्थापना के बाद, अपने प्रोजेक्ट में स्थिति को प्रबंधित करने और निर्भरताएँ इंजेक्ट करने के तरीके के बारे में त्वरित परिचय के लिए [उपयोग अवलोकन](documentation/hi/usage-overview.md) देखें।

## त्वरित उदाहरण

नीचे एक न्यूनतम उदाहरण दिया गया है जो दिखाता है कि स्थिति का एक टुकड़ा कैसे परिभाषित करें और इसे SwiftUI दृश्य से कैसे एक्सेस करें:

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
            Text("गणना: \(counter)")
            Button("बढ़ाएँ") { counter += 1 }
        }
    }
}
```

यह स्निपेट एक `Application` एक्सटेंशन में एक स्थिति मान को परिभाषित करने और इसे एक दृश्य के अंदर बाँधने के लिए `@AppState` प्रॉपर्टी रैपर का उपयोग करने का प्रदर्शन करता है।

## दस्तावेज़ीकरण

यहाँ **AppState** के दस्तावेज़ीकरण का विस्तृत विवरण दिया गया है:

- [स्थापना मार्गदर्शिका](documentation/hi/installation.md): स्विफ्ट पैकेज मैनेजर का उपयोग करके अपने प्रोजेक्ट में **AppState** कैसे जोड़ें।
- [उपयोग अवलोकन](documentation/hi/usage-overview.md): उदाहरण कार्यान्वयन के साथ मुख्य विशेषताओं का अवलोकन।

### विस्तृत उपयोग मार्गदर्शिकाएँ:

- [स्थिति और निर्भरता प्रबंधन](documentation/hi/usage-state-dependency.md): स्थिति को केंद्रीकृत करें और अपने पूरे ऐप में निर्भरताएँ इंजेक्ट करें।
- [स्लाइसिंग स्थिति](documentation/hi/usage-slice.md): स्थिति के विशिष्ट भागों तक पहुँचें और संशोधित करें।
- [StoredState उपयोग मार्गदर्शिका](documentation/hi/usage-storedstate.md): `StoredState` का उपयोग करके हल्के डेटा को कैसे बनाए रखें।
- [FileState उपयोग मार्गदर्शिका](documentation/hi/usage-filestate.md): डिस्क पर बड़ी मात्रा में डेटा को सुरक्षित रूप से कैसे बनाए रखें, जानें।
- [कीचेन SecureState उपयोग](documentation/hi/usage-securestate.md): कीचेन का उपयोग करके संवेदनशील डेटा को सुरक्षित रूप से संग्रहीत करें।
- [SyncState के साथ iCloud सिंकिंग](documentation/hi/usage-syncstate.md): iCloud का उपयोग करके उपकरणों में स्थिति को सिंक्रनाइज़ रखें।
- [अक्सर पूछे जाने वाले प्रश्न](documentation/hi/faq.md): **AppState** का उपयोग करते समय सामान्य प्रश्नों के उत्तर।
- [स्थिरांक उपयोग मार्गदर्शिका](documentation/hi/usage-constant.md): अपनी स्थिति से केवल-पढ़ने के लिए मानों तक पहुँचें।
- [ObservedDependency उपयोग मार्गदर्शिका](documentation/hi/usage-observeddependency.md): अपने विचारों में `ObservableObject` निर्भरताओं के साथ काम करें।
- [उन्नत उपयोग](documentation/hi/advanced-usage.md): जस्ट-इन-टाइम निर्माण और निर्भरताओं को प्रीलोड करने जैसी तकनीकें।
- [सर्वोत्तम प्रथाएँ](documentation/hi/best-practices.md): अपने ऐप की स्थिति को प्रभावी ढंग से संरचित करने के लिए युक्तियाँ।
- [माइग्रेशन विचार](documentation/hi/migration-considerations.md): स्थायी मॉडल अपडेट करते समय मार्गदर्शन।

## योगदान

हम योगदान का स्वागत करते हैं! कृपया शामिल होने के तरीके के लिए हमारी [योगदान मार्गदर्शिका](documentation/hi/contributing.md) देखें।

## अगले चरण

**AppState** स्थापित होने के साथ, आप [उपयोग अवलोकन](documentation/hi/usage-overview.md) और अधिक विस्तृत मार्गदर्शिकाओं को देखकर इसकी मुख्य विशेषताओं की खोज शुरू कर सकते हैं। अपने स्विफ्ट प्रोजेक्ट्स में स्थिति और निर्भरताओं का प्रभावी ढंग से प्रबंधन शुरू करें! अधिक उन्नत उपयोग तकनीकों के लिए, जैसे जस्ट-इन-टाइम निर्माण और निर्भरताओं को प्रीलोड करना, [उन्नत उपयोग मार्गदर्शिका](documentation/hi/advanced-usage.md) देखें। आप अतिरिक्त सुविधाओं के लिए [स्थिरांक](documentation/hi/usage-constant.md) और [ObservedDependency](documentation/hi/usage-observeddependency.md) मार्गदर्शिकाओं की भी समीक्षा कर सकते हैं।
