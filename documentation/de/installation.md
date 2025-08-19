# Installationsanleitung

Diese Anleitung führt Sie durch den Prozess der Installation von **AppState** in Ihr Swift-Projekt mit dem Swift Package Manager.

## Swift Package Manager

**AppState** kann einfach mit dem Swift Package Manager in Ihr Projekt integriert werden. Befolgen Sie die folgenden Schritte, um **AppState** als Abhängigkeit hinzuzufügen.

### Schritt 1: Aktualisieren Sie Ihre `Package.swift`-Datei

Fügen Sie **AppState** zum `dependencies`-Abschnitt Ihrer `Package.swift`-Datei hinzu:

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/AppState.git", from: "2.2.0")
]
```

### Schritt 2: Fügen Sie AppState zu Ihrem Ziel hinzu

Schließen Sie AppState in die Abhängigkeiten Ihres Ziels ein:

```swift
.target(
    name: "YourTarget",
    dependencies: ["AppState"]
)
```

### Schritt 3: Erstellen Sie Ihr Projekt

Nachdem Sie AppState zu Ihrer `Package.swift`-Datei hinzugefügt haben, erstellen Sie Ihr Projekt, um die Abhängigkeit abzurufen und in Ihre Codebasis zu integrieren.

```
swift build
```

### Schritt 4: Importieren Sie AppState in Ihren Code

Jetzt können Sie AppState in Ihrem Projekt verwenden, indem Sie es am Anfang Ihrer Swift-Dateien importieren:

```swift
import AppState
```

## Xcode

Wenn Sie **AppState** lieber direkt über Xcode hinzufügen möchten, befolgen Sie diese Schritte:

### Schritt 1: Öffnen Sie Ihr Xcode-Projekt

Öffnen Sie Ihr Xcode-Projekt oder Ihren Arbeitsbereich.

### Schritt 2: Fügen Sie eine Swift-Paketabhängigkeit hinzu

1. Navigieren Sie zum Projektnavigator und wählen Sie Ihre Projektdatei aus.
2. Wählen Sie im Projekteditor Ihr Ziel aus und gehen Sie dann zum Tab "Swift Packages".
3. Klicken Sie auf die Schaltfläche "+", um eine Paketabhängigkeit hinzuzufügen.

### Schritt 3: Geben Sie die Repository-URL ein

Geben Sie im Dialogfeld "Choose Package Repository" die folgende URL ein: `https://github.com/0xLeif/AppState.git`

Klicken Sie dann auf "Weiter".

### Schritt 4: Geben Sie die Version an

Wählen Sie die Version aus, die Sie verwenden möchten. Es wird empfohlen, die Option "Bis zur nächsten Hauptversion" auszuwählen und `2.0.0` als Untergrenze anzugeben. Klicken Sie dann auf "Weiter".

### Schritt 5: Fügen Sie das Paket hinzu

Xcode ruft das Paket ab und bietet Ihnen Optionen zum Hinzufügen von **AppState** zu Ihrem Ziel an. Stellen Sie sicher, dass Sie das richtige Ziel auswählen, und klicken Sie auf "Fertig stellen".

### Schritt 6: Importieren Sie `AppState` in Ihren Code

Sie können **AppState** jetzt am Anfang Ihrer Swift-Dateien importieren:

```swift
import AppState
```

## Nächste Schritte

Nach der Installation von AppState können Sie zur [Verwendungsübersicht](usage-overview.md) übergehen, um zu sehen, wie Sie die wichtigsten Funktionen in Ihrem Projekt implementieren.
