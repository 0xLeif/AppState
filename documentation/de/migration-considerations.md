# Überlegungen zur Migration

Bei der Aktualisierung Ihres Datenmodells, insbesondere bei persistenten oder synchronisierten Daten, müssen Sie die Abwärtskompatibilität berücksichtigen, um potenzielle Probleme beim Laden älterer Daten zu vermeiden. Hier sind einige wichtige Punkte, die Sie beachten sollten:

## 1. Hinzufügen von nicht-optionalen Feldern
Wenn Sie Ihrem Modell neue, nicht-optionale Felder hinzufügen, kann die Dekodierung alter Daten (die diese Felder nicht enthalten) fehlschlagen. Um dies zu vermeiden:
- Erwägen Sie, neuen Feldern Standardwerte zu geben.
- Machen Sie die neuen Felder optional, um die Kompatibilität mit älteren Versionen Ihrer App zu gewährleisten.

### Beispiel:
```swift
struct Settings: Codable {
    var text: String
    var isDarkMode: Bool
    var newField: String? // Neues Feld ist optional
}
```

## 2. Änderungen am Datenformat
Wenn Sie die Struktur eines Modells ändern (z. B. einen Typ von `Int` in `String` ändern), kann der Dekodierungsprozess beim Lesen älterer Daten fehlschlagen. Planen Sie eine reibungslose Migration durch:
- Erstellen einer Migrationslogik, um alte Datenformate in die neue Struktur zu konvertieren.
- Verwendung des benutzerdefinierten Initialisierers von `Decodable`, um alte Daten zu verarbeiten und sie Ihrem neuen Modell zuzuordnen.

### Beispiel:
```swift
struct Settings: Codable {
    var text: String
    var isDarkMode: Bool
    var version: Int

    // Benutzerdefinierte Dekodierungslogik für ältere Versionen
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text)
        self.isDarkMode = try container.decode(Bool.self, forKey: .isDarkMode)
        self.version = (try? container.decode(Int.self, forKey: .version)) ?? 1 // Standard für ältere Daten
    }
}
```

## 3. Umgang mit gelöschten oder veralteten Feldern
Wenn Sie ein Feld aus dem Modell entfernen, stellen Sie sicher, dass alte Versionen der App die neuen Daten immer noch ohne Absturz dekodieren können. Sie können:
- Zusätzliche Felder beim Dekodieren ignorieren.
- Benutzerdefinierte Dekoder verwenden, um alte Daten zu verarbeiten und veraltete Felder ordnungsgemäß zu verwalten.

## 4. Versionierung Ihrer Modelle

Die Versionierung Ihrer Modelle ermöglicht es Ihnen, Änderungen an Ihrer Datenstruktur im Laufe der Zeit zu handhaben. Indem Sie eine Versionsnummer als Teil Ihres Modells beibehalten, können Sie einfach eine Migrationslogik implementieren, um ältere Datenformate in neuere zu konvertieren. Dieser Ansatz stellt sicher, dass Ihre App ältere Datenstrukturen verarbeiten und gleichzeitig reibungslos auf neue Versionen umsteigen kann.

- **Warum Versionierung wichtig ist**: Wenn Benutzer ihre App aktualisieren, haben sie möglicherweise noch ältere Daten auf ihren Geräten gespeichert. Die Versionierung hilft Ihrer App, das Datenformat zu erkennen und die richtige Migrationslogik anzuwenden.
- **Wie zu verwenden**: Fügen Sie Ihrem Modell ein `version`-Feld hinzu und überprüfen Sie es während des Dekodierungsprozesses, um festzustellen, ob eine Migration erforderlich ist.

### Beispiel:
```swift
struct Settings: Codable {
    var version: Int
    var text: String
    var isDarkMode: Bool

    // Handhaben der versionsspezifischen Dekodierungslogik
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(Int.self, forKey: .version)
        self.text = try container.decode(String.self, forKey: .text)
        self.isDarkMode = try container.decode(Bool.self, forKey: .isDarkMode)

        // Wenn von einer älteren Version migriert wird, wenden Sie hier die erforderlichen Transformationen an
        if version < 2 {
            // Migrieren Sie ältere Daten in das neuere Format
        }
    }
}
```

- **Beste Vorgehensweise**: Beginnen Sie von Anfang an mit einem `version`-Feld. Jedes Mal, wenn Sie Ihre Modellstruktur aktualisieren, erhöhen Sie die Version und behandeln die erforderliche Migrationslogik.

## 5. Testen der Migration
Testen Sie Ihre Migration immer gründlich, indem Sie das Laden alter Daten mit neuen Versionen Ihres Modells simulieren, um sicherzustellen, dass sich Ihre App wie erwartet verhält.

---
Dies wurde mit [Jules](https://jules.google) erstellt, es können Fehler auftreten. Bitte erstellen Sie einen Pull Request mit allen Korrekturen, die vorgenommen werden sollten, wenn Sie Muttersprachler sind.
