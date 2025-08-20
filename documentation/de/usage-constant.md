# Verwendung von Konstanten

`Constant` in der **AppState**-Bibliothek bietet schreibgeschützten Zugriff auf Werte im Zustand Ihrer Anwendung. Es funktioniert ähnlich wie `Slice`, stellt jedoch sicher, dass die zugegriffenen Werte unveränderlich sind. Dies macht `Constant` ideal für den Zugriff auf Werte, die andernfalls veränderbar sein könnten, aber in bestimmten Kontexten schreibgeschützt bleiben sollen.

## Hauptmerkmale

- **Schreibgeschützter Zugriff**: Konstanten bieten Zugriff auf veränderbare Zustände, aber die Werte können nicht geändert werden.
- **Auf die Anwendung beschränkt**: Wie `Slice` wird `Constant` innerhalb der `Application`-Erweiterung definiert und ist auf den Zugriff auf bestimmte Teile des Zustands beschränkt.
- **Threadsicher**: `Constant` gewährleistet einen sicheren Zugriff auf den Zustand in nebenläufigen Umgebungen.

## Anwendungsbeispiel

### Definieren einer Konstante in der Anwendung

So definieren Sie eine `Constant` in der `Application`-Erweiterung, um auf einen schreibgeschützten Wert zuzugreifen:

```swift
import AppState
import SwiftUI

struct ExampleValue {
    var username: String?
    var isLoading: Bool
    let value: String
    var mutableValue: String
}

extension Application {
    var exampleValue: State<ExampleValue> {
        state(
            initial: ExampleValue(
                username: "Leif",
                isLoading: false,
                value: "value",
                mutableValue: ""
            )
        )
    }
}
```

### Zugriff auf die Konstante in einer SwiftUI-Ansicht

In einer SwiftUI-Ansicht können Sie den `@Constant`-Property-Wrapper verwenden, um auf den konstanten Zustand schreibgeschützt zuzugreifen:

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.exampleValue, \.value) var constantValue: String

    var body: some View {
        Text("Konstanter Wert: \(constantValue)")
    }
}
```

### Schreibgeschützter Zugriff auf veränderbaren Zustand

Auch wenn der Wert an anderer Stelle veränderbar ist, wird der Wert bei Zugriff über `@Constant` unveränderlich:

```swift
import AppState
import SwiftUI

struct ExampleView: View {
    @Constant(\.exampleValue, \.mutableValue) var constantMutableValue: String

    var body: some View {
        Text("Schreibgeschützter veränderbarer Wert: \(constantMutableValue)")
    }
}
```

## Bewährte Praktiken

- **Verwendung für schreibgeschützten Zugriff**: Verwenden Sie `Constant`, um auf Teile des Zustands zuzugreifen, die in bestimmten Kontexten nicht geändert werden sollen, auch wenn sie an anderer Stelle veränderbar sind.
- **Threadsicher**: Wie andere AppState-Komponenten gewährleistet `Constant` einen threadsicheren Zugriff auf den Zustand.
- **Verwenden Sie `OptionalConstant` für optionale Werte**: Wenn der Teil des Zustands, auf den Sie zugreifen, `nil` sein kann, verwenden Sie `OptionalConstant`, um das Fehlen eines Werts sicher zu behandeln.

## Fazit

`Constant` und `OptionalConstant` bieten eine effiziente Möglichkeit, auf bestimmte Teile des Zustands Ihrer App schreibgeschützt zuzugreifen. Sie stellen sicher, dass Werte, die andernfalls veränderbar sein könnten, bei Zugriff innerhalb einer Ansicht als unveränderlich behandelt werden, was Sicherheit und Klarheit in Ihrem Code gewährleistet.

---
Dies wurde mit Jules erstellt, es können Fehler auftreten. Bitte erstellen Sie einen Pull Request mit allen Korrekturen, die vorgenommen werden sollten, wenn Sie Muttersprachler sind.
