# स्थिति और निर्भरता का उपयोग

**AppState** एप्लिकेशन-व्यापी स्थिति के प्रबंधन और SwiftUI दृश्यों में निर्भरता को इंजेक्ट करने के लिए शक्तिशाली उपकरण प्रदान करता है। अपनी स्थिति और निर्भरताओं को केंद्रीकृत करके, आप यह सुनिश्चित कर सकते हैं कि आपका एप्लिकेशन सुसंगत और बनाए रखने योग्य बना रहे।

## अवलोकन

- **स्थिति**: एक मान का प्रतिनिधित्व करता है जिसे पूरे ऐप में साझा किया जा सकता है। स्थिति मानों को आपके SwiftUI दृश्यों के भीतर संशोधित और देखा जा सकता है।
- **निर्भरता**: एक साझा संसाधन या सेवा का प्रतिनिधित्व करता है जिसे SwiftUI दृश्यों के भीतर इंजेक्ट और एक्सेस किया जा सकता है।

### मुख्य विशेषताएँ

- **केंद्रीकृत स्थिति**: एप्लिकेशन-व्यापी स्थिति को एक ही स्थान पर परिभाषित और प्रबंधित करें।
- **निर्भरता इंजेक्शन**: अपने एप्लिकेशन के विभिन्न घटकों में साझा सेवाओं और संसाधनों को इंजेक्ट और एक्सेस करें।

## उपयोग का उदाहरण

### एप्लिकेशन स्थिति को परिभाषित करना

एप्लिकेशन-व्यापी स्थिति को परिभाषित करने के लिए, `Application` ऑब्जेक्ट का विस्तार करें और स्थिति गुणों की घोषणा करें।

```swift
import AppState

struct User {
    var name: String
    var isLoggedIn: Bool
}

extension Application {
    var user: State<User> {
        state(initial: User(name: "Guest", isLoggedIn: false))
    }
}
```

### एक दृश्य में स्थिति तक पहुँचना और उसे संशोधित करना

आप `@AppState` प्रॉपर्टी रैपर का उपयोग करके सीधे SwiftUI दृश्य के भीतर स्थिति मानों तक पहुँच और उन्हें संशोधित कर सकते हैं।

```swift
import AppState
import SwiftUI

struct ContentView: View {
    @AppState(\.user) var user: User

    var body: some View {
        VStack {
            Text("नमस्ते, \(user.name)!")
            Button("लॉग इन करें") {
                user.name = "John Doe"
                user.isLoggedIn = true
            }
        }
    }
}
```

### निर्भरताओं को परिभाषित करना

आप साझा संसाधनों, जैसे कि नेटवर्क सेवा, को `Application` ऑब्जेक्ट में निर्भरता के रूप में परिभाषित कर सकते हैं। इन निर्भरताओं को SwiftUI दृश्यों में इंजेक्ट किया जा सकता है।

```swift
import AppState

protocol NetworkServiceType {
    func fetchData() -> String
}

class NetworkService: NetworkServiceType {
    func fetchData() -> String {
        return "Data from network"
    }
}

extension Application {
    var networkService: Dependency<NetworkServiceType> {
        dependency(NetworkService())
    }
}
```

### एक दृश्य में निर्भरताओं तक पहुँचना

`@AppDependency` प्रॉपर्टी रैपर का उपयोग करके SwiftUI दृश्य के भीतर निर्भरताओं तक पहुँचें। यह आपको अपनी दृश्य में नेटवर्क सेवा जैसी सेवाओं को इंजेक्ट करने की अनुमति देता है।

```swift
import AppState
import SwiftUI

struct NetworkView: View {
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("डेटा: \(networkService.fetchData())")
        }
    }
}
```

### एक दृश्य में स्थिति और निर्भरताओं का संयोजन

स्थिति और निर्भरताएँ अधिक जटिल एप्लिकेशन तर्क बनाने के लिए एक साथ काम कर सकती हैं। उदाहरण के लिए, आप किसी सेवा से डेटा प्राप्त कर सकते हैं और स्थिति को अपडेट कर सकते हैं:

```swift
import AppState
import SwiftUI

struct CombinedView: View {
    @AppState(\.user) var user: User
    @AppDependency(\.networkService) var networkService: NetworkServiceType

    var body: some View {
        VStack {
            Text("उपयोगकर्ता: \(user.name)")
            Button("डेटा प्राप्त करें") {
                user.name = networkService.fetchData()
                user.isLoggedIn = true
            }
        }
    }
}
```

### सर्वोत्तम प्रथाएं

- **स्थिति को केंद्रीकृत करें**: दोहराव से बचने और स्थिरता सुनिश्चित करने के लिए अपनी एप्लिकेशन-व्यापी स्थिति को एक ही स्थान पर रखें।
- **साझा सेवाओं के लिए निर्भरताओं का उपयोग करें**: घटकों के बीच तंग युग्मन से बचने के लिए नेटवर्क सेवाओं, डेटाबेस या अन्य साझा संसाधनों जैसी निर्भरताओं को इंजेक्ट करें।

## निष्कर्ष

**AppState** के साथ, आप एप्लिकेशन-व्यापी स्थिति का प्रबंधन कर सकते हैं और साझा निर्भरताओं को सीधे अपने SwiftUI दृश्यों में इंजेक्ट कर सकते हैं। यह पैटर्न आपके ऐप को मॉड्यूलर और बनाए रखने योग्य रखने में मदद करता है। अपने ऐप की स्थिति प्रबंधन को और बढ़ाने के लिए **AppState** लाइब्रेरी की अन्य विशेषताओं, जैसे [SecureState](usage-securestate.md) और [SyncState](usage-syncstate.md) का अन्वेषण करें।
