# SyncState का उपयोग

`SyncState` **AppState** लाइब्रेरी का एक घटक है जो आपको iCloud का उपयोग करके कई उपकरणों में ऐप की स्थिति को सिंक्रनाइज़ करने की अनुमति देता है। यह उपयोगकर्ता की वरीयताओं, सेटिंग्स, या अन्य महत्वपूर्ण डेटा को उपकरणों में सुसंगत रखने के लिए विशेष रूप से उपयोगी है।

## अवलोकन

`SyncState` iCloud के `NSUbiquitousKeyValueStore` का लाभ उठाता है ताकि उपकरणों में थोड़ी मात्रा में डेटा को सिंक में रखा जा सके। यह इसे वरीयताओं या उपयोगकर्ता सेटिंग्स जैसे हल्के एप्लिकेशन स्थिति को सिंक्रनाइज़ करने के लिए आदर्श बनाता है।

### मुख्य विशेषताएँ

- **iCloud सिंक्रनाइज़ेशन**: एक ही iCloud खाते में लॉग इन किए गए सभी उपकरणों में स्थिति को स्वचालित रूप से सिंक करें।
- **स्थायी भंडारण**: डेटा iCloud में स्थायी रूप से संग्रहीत होता है, जिसका अर्थ है कि ऐप के समाप्त होने या पुनरारंभ होने पर भी यह बना रहेगा।
- **लगभग वास्तविक समय सिंक**: स्थिति में परिवर्तन लगभग तुरंत अन्य उपकरणों में प्रचारित किए जाते हैं।

> **ध्यान दें**: `SyncState` watchOS 9.0 और बाद के संस्करणों पर समर्थित है।

## उपयोग का उदाहरण

### डेटा मॉडल

मान लें कि हमारे पास `Settings` नामक एक संरचना है जो `Codable` के अनुरूप है:

```swift
struct Settings: Codable {
    var text: String
    var isShowingSheet: Bool
    var isDarkMode: Bool
}
```

### एक SyncState को परिभाषित करना

आप `Application` ऑब्जेक्ट का विस्तार करके और उन स्थिति गुणों की घोषणा करके `SyncState` को परिभाषित कर सकते हैं जिन्हें सिंक किया जाना चाहिए:

```swift
extension Application {
    var settings: SyncState<Settings> {
        syncState(
            initial: Settings(
                text: "Hello, World!",
                isShowingSheet: false,
                isDarkMode: false
            ),
            id: "settings"
        )
    }
}
```

### बाहरी परिवर्तनों को संभालना

यह सुनिश्चित करने के लिए कि ऐप iCloud से बाहरी परिवर्तनों का जवाब देता है, एक कस्टम `Application` उपवर्ग बनाकर `didChangeExternally` फ़ंक्शन को ओवरराइड करें:

```swift
class CustomApplication: Application {
    override func didChangeExternally(notification: Notification) {
        super.didChangeExternally(notification: notification)

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
```

### स्थिति को संशोधित और सिंक करने के लिए दृश्य बनाना

निम्नलिखित उदाहरण में, हमारे पास दो दृश्य हैं: `ContentView` और `ContentViewInnerView`। ये दृश्य उनके बीच `Settings` स्थिति को साझा और सिंक करते हैं। `ContentView` उपयोगकर्ता को `text` को संशोधित करने और `isDarkMode` को टॉगल करने की अनुमति देता है, जबकि `ContentViewInnerView` वही पाठ प्रदर्शित करता है और टैप किए जाने पर इसे अपडेट करता है।

```swift
struct ContentView: View {
    @SyncState(\.settings) private var settings: Settings

    var body: some View {
        VStack {
            TextField("", text: $settings.text)

            Button(settings.isDarkMode ? "Light" : "Dark") {
                settings.isDarkMode.toggle()
            }

            Button("Show") { settings.isShowingSheet = true }
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        .sheet(isPresented: $settings.isShowingSheet, content: ContentViewInnerView.init)
    }
}

struct ContentViewInnerView: View {
    @Slice(\.settings, \.text) private var text: String

    var body: some View {
        Text("\(text)")
            .onTapGesture {
                text = Date().formatted()
            }
    }
}
```

### ऐप सेट करना

अंत में, `@main` संरचना में एप्लिकेशन सेट करें। इनिशियलाइज़ेशन में, कस्टम एप्लिकेशन को बढ़ावा दें, लॉगिंग सक्षम करें, और सिंक्रनाइज़ेशन के लिए iCloud स्टोर निर्भरता लोड करें:

```swift
@main
struct SyncStateExampleApp: App {
    init() {
        Application
            .promote(to: CustomApplication.self)
            .logging(isEnabled: true)
            .load(dependency: \.icloudStore)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### iCloud की-वैल्यू स्टोर सक्षम करना

iCloud सिंक्रनाइज़ेशन को सक्षम करने के लिए, सुनिश्चित करें कि आप iCloud की-वैल्यू स्टोर क्षमता को सक्षम करने के लिए इस गाइड का पालन करते हैं: [SyncState का उपयोग शुरू करना](https://github.com/0xLeif/AppState/wiki/Starting-to-use-SyncState)।

### SyncState: iCloud संग्रहण पर नोट्स

जबकि `SyncState` आसान सिंक्रनाइज़ेशन की अनुमति देता है, `NSUbiquitousKeyValueStore` की सीमाओं को याद रखना महत्वपूर्ण है:

- **भंडारण सीमा**: आप `NSUbiquitousKeyValueStore` का उपयोग करके iCloud में 1 एमबी तक डेटा संग्रहीत कर सकते हैं, प्रति-कुंजी मान आकार सीमा 1 एमबी है।

### प्रवासन संबंधी विचार

अपने डेटा मॉडल को अपडेट करते समय, संभावित प्रवासन चुनौतियों का हिसाब रखना महत्वपूर्ण है, खासकर जब **StoredState**, **FileState**, या **SyncState** का उपयोग करके स्थायी डेटा के साथ काम कर रहे हों। उचित प्रवासन प्रबंधन के बिना, नए फ़ील्ड जोड़ने या डेटा प्रारूपों को संशोधित करने जैसे परिवर्तन पुराने डेटा लोड होने पर समस्याएँ पैदा कर सकते हैं।

यहाँ कुछ मुख्य बातें ध्यान में रखनी हैं:
- **नए गैर-वैकल्पिक फ़ील्ड जोड़ना**: सुनिश्चित करें कि नए फ़ील्ड या तो वैकल्पिक हैं या पश्चगामी संगतता बनाए रखने के लिए डिफ़ॉल्ट मान हैं।
- **डेटा प्रारूप परिवर्तनों को संभालना**: यदि आपके मॉडल की संरचना बदलती है, तो पुराने प्रारूपों का समर्थन करने के लिए कस्टम डीकोडिंग तर्क लागू करें।
- **अपने मॉडलों का संस्करण बनाना**: प्रवासन में मदद करने और डेटा के संस्करण के आधार पर तर्क लागू करने के लिए अपने मॉडलों में `version` फ़ील्ड का उपयोग करें।

प्रवासन का प्रबंधन करने और संभावित समस्याओं से बचने के तरीके के बारे में अधिक जानने के लिए, [प्रवासन संबंधी विचार मार्गदर्शिका](migration-considerations.md) देखें।

## SyncState कार्यान्वयन गाइड

iCloud को कॉन्फ़िगर करने और अपने प्रोजेक्ट में SyncState को सेट करने के बारे में विस्तृत निर्देशों के लिए, [SyncState कार्यान्वयन गाइड](syncstate-implementation.md) देखें।

## सर्वोत्तम प्रथाएं

- **छोटे, महत्वपूर्ण डेटा के लिए उपयोग करें**: `SyncState` उपयोगकर्ता वरीयताओं, सेटिंग्स, या सुविधा झंडे जैसे राज्य के छोटे, महत्वपूर्ण टुकड़ों को सिंक्रनाइज़ करने के लिए आदर्श है।
- **iCloud संग्रहण की निगरानी करें**: सुनिश्चित करें कि डेटा सिंक समस्याओं को रोकने के लिए `SyncState` का आपका उपयोग iCloud संग्रहण सीमाओं के भीतर रहता है।
- **बाहरी अपडेट को संभालें**: यदि आपके ऐप को किसी अन्य डिवाइस पर शुरू किए गए स्थिति परिवर्तनों का जवाब देने की आवश्यकता है, तो ऐप की स्थिति को वास्तविक समय में अपडेट करने के लिए `didChangeExternally` फ़ंक्शन को ओवरराइड करें।

## निष्कर्ष

`SyncState` iCloud के माध्यम से उपकरणों में थोड़ी मात्रा में एप्लिकेशन स्थिति को सिंक्रनाइज़ करने का एक शक्तिशाली तरीका प्रदान करता है। यह सुनिश्चित करने के लिए आदर्श है कि उपयोगकर्ता वरीयताएँ और अन्य प्रमुख डेटा एक ही iCloud खाते में लॉग इन किए गए सभी उपकरणों में सुसंगत रहें। अधिक उन्नत उपयोग के मामलों के लिए, **AppState** की अन्य विशेषताओं, जैसे [SecureState](usage-securestate.md) और [FileState](usage-filestate.md) का अन्वेषण करें।

---
यह जूल्स का उपयोग करके उत्पन्न किया गया था, गलतियाँ हो सकती हैं। कृपया किसी भी सुधार के साथ एक पुल अनुरोध करें जो आपके मूल वक्ता होने पर होना चाहिए।
