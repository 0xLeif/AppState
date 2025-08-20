# ObservedDependency का उपयोग

`ObservedDependency` **AppState** लाइब्रेरी का एक घटक है जो आपको `ObservableObject` के अनुरूप निर्भरताओं का उपयोग करने की अनुमति देता है। यह तब उपयोगी होता है जब आप चाहते हैं कि निर्भरता आपके SwiftUI दृश्यों को परिवर्तनों के बारे में सूचित करे, जिससे आपके दृश्य प्रतिक्रियाशील और गतिशील हो जाते हैं।

## मुख्य विशेषताएँ

- **अवलोकन योग्य निर्भरताएँ**: `ObservableObject` के अनुरूप निर्भरताओं का उपयोग करें, जिससे निर्भरता को अपनी स्थिति बदलने पर स्वचालित रूप से आपके दृश्यों को अपडेट करने की अनुमति मिलती है।
- **प्रतिक्रियाशील यूआई अपडेट**: जब देखे गए निर्भरता द्वारा परिवर्तन प्रकाशित किए जाते हैं तो SwiftUI दृश्य स्वचालित रूप से अपडेट हो जाते हैं।
- **थ्रेड-सेफ**: अन्य AppState घटकों की तरह, `ObservedDependency` देखी गई निर्भरता तक थ्रेड-सुरक्षित पहुँच सुनिश्चित करता है।

## उपयोग का उदाहरण

### एक अवलोकन योग्य निर्भरता को परिभाषित करना

यहाँ बताया गया है कि `Application` एक्सटेंशन में एक अवलोकन योग्य सेवा को निर्भरता के रूप में कैसे परिभाषित करें:

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

### SwiftUI व्यू में देखी गई निर्भरता का उपयोग करना

अपने SwiftUI व्यू में, आप `@ObservedDependency` प्रॉपर्टी रैपर का उपयोग करके अवलोकन योग्य निर्भरता तक पहुँच सकते हैं। देखा गया ऑब्जेक्ट अपनी स्थिति बदलने पर स्वचालित रूप से दृश्य को अपडेट करता है।

```swift
import AppState
import SwiftUI

struct ObservedDependencyExampleView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        VStack {
            Text("गणना: \(service.count)")
            Button("गणना बढ़ाएँ") {
                service.count += 1
            }
        }
    }
}
```

### परीक्षण मामला

निम्नलिखित परीक्षण मामला `ObservedDependency` के साथ सहभागिता को प्रदर्शित करता है:

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

### प्रतिक्रियाशील यूआई अपडेट

चूंकि निर्भरता `ObservableObject` के अनुरूप है, इसलिए इसकी स्थिति में कोई भी परिवर्तन SwiftUI दृश्य में एक यूआई अपडेट को ट्रिगर करेगा। आप स्थिति को सीधे `Picker` जैसे यूआई तत्वों से बाँध सकते हैं:

```swift
import AppState
import SwiftUI

struct ReactiveView: View {
    @ObservedDependency(\.observableService) var service: ObservableService

    var body: some View {
        Picker("गणना चुनें", selection: $service.count) {
            ForEach(0..<10) { count in
                Text("\(count)").tag(count)
            }
        }
    }
}
```

## सर्वोत्तम प्रथाएं

- **अवलोकन योग्य सेवाओं के लिए उपयोग करें**: `ObservedDependency` तब आदर्श है जब आपकी निर्भरता को दृश्यों को परिवर्तनों के बारे में सूचित करने की आवश्यकता होती है, खासकर उन सेवाओं के लिए जो डेटा या स्थिति अपडेट प्रदान करती हैं।
- **प्रकाशित गुणों का लाभ उठाएं**: सुनिश्चित करें कि आपकी निर्भरता आपके SwiftUI दृश्यों में अपडेट को ट्रिगर करने के लिए `@Published` गुणों का उपयोग करती है।
- **थ्रेड-सेफ**: अन्य AppState घटकों की तरह, `ObservedDependency` अवलोकन योग्य सेवा तक थ्रेड-सुरक्षित पहुँच और संशोधनों को सुनिश्चित करता है।

## निष्कर्ष

`ObservedDependency` आपके ऐप के भीतर अवलोकन योग्य निर्भरताओं के प्रबंधन के लिए एक शक्तिशाली उपकरण है। स्विफ्ट के `ObservableObject` प्रोटोकॉल का लाभ उठाकर, यह सुनिश्चित करता है कि आपके SwiftUI दृश्य प्रतिक्रियाशील और सेवा या संसाधन में परिवर्तनों के साथ अद्यतित रहें।

---
यह जूल्स का उपयोग करके उत्पन्न किया गया था, गलतियाँ हो सकती हैं। कृपया किसी भी सुधार के साथ एक पुल अनुरोध करें जो आपके मूल वक्ता होने पर होना चाहिए।
