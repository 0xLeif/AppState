# AppState

[![macOS Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/macOS.yml?label=macOS&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/macOS.yml)
[![Ubuntu Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/ubuntu.yml?label=Ubuntu&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/ubuntu.yml)
[![Windows Build](https://img.shields.io/github/actions/workflow/status/0xLeif/AppState/windows.yml?label=Windows&branch=main)](https://github.com/0xLeif/AppState/actions/workflows/windows.yml)
[![License](https://img.shields.io/github/license/0xLeif/AppState)](https://github.com/0xLeif/AppState/blob/main/LICENSE)
[![Version](https://img.shields.io/github/v/release/0xLeif/AppState)](https://github.com/0xLeif/AppState/releases)

**AppState** ist eine Swift 6-Bibliothek, die entwickelt wurde, um die Verwaltung des Anwendungszustands auf eine threadsichere, typsichere und SwiftUI-freundliche Weise zu vereinfachen. Sie bietet eine Reihe von Werkzeugen, um den Zustand in Ihrer gesamten Anwendung zu zentralisieren und zu synchronisieren sowie Abhängigkeiten in verschiedene Teile Ihrer App zu injizieren.

## Anforderungen

- **iOS**: 15.0+
- **watchOS**: 8.0+
- **macOS**: 11.0+
- **tvOS**: 15.0+
- **visionOS**: 1.0+
- **Swift**: 6.0+
- **Xcode**: 16.0+

**Unterstützung für Nicht-Apple-Plattformen**: Linux & Windows

> 🍎 Mit diesem Symbol gekennzeichnete Funktionen sind spezifisch für Apple-Plattformen, da sie auf Apple-Technologien wie iCloud und dem Schlüsselbund basieren.

## Hauptmerkmale

**AppState** enthält mehrere leistungsstarke Funktionen zur Verwaltung von Zustand und Abhängigkeiten:

- **State**: Zentralisierte Zustandsverwaltung, die es Ihnen ermöglicht, Änderungen in der gesamten App zu kapseln und zu übertragen.
- **StoredState**: Persistenter Zustand mit `UserDefaults`, ideal zum Speichern kleiner Datenmengen zwischen App-Starts.
- **FileState**: Persistenter Zustand, der mit `FileManager` gespeichert wird und nützlich ist, um größere Datenmengen sicher auf der Festplatte zu speichern.
- 🍎 **SyncState**: Synchronisieren Sie den Zustand über mehrere Geräte mit iCloud und stellen Sie die Konsistenz der Benutzereinstellungen sicher.
- 🍎 **SecureState**: Speichern Sie sensible Daten sicher mit dem Schlüsselbund und schützen Sie Benutzerinformationen wie Token oder Passwörter.
- **Abhängigkeitsmanagement**: Injizieren Sie Abhängigkeiten wie Netzwerkdienste oder Datenbankclients in Ihre gesamte App für eine bessere Modularität und Testbarkeit.
- **Slicing**: Greifen Sie auf bestimmte Teile eines Zustands oder einer Abhängigkeit zu, um eine granulare Kontrolle zu erhalten, ohne den gesamten Anwendungszustand verwalten zu müssen.
- **Constants**: Greifen Sie auf schreibgeschützte Teile Ihres Zustands zu, wenn Sie unveränderliche Werte benötigen.
- **Observed Dependencies**: Beobachten Sie `ObservableObject`-Abhängigkeiten, damit Ihre Ansichten aktualisiert werden, wenn sie sich ändern.

## Erste Schritte

Um **AppState** in Ihr Swift-Projekt zu integrieren, müssen Sie den Swift Package Manager verwenden. Befolgen Sie die [Installationsanleitung](documentation/de/installation.md) für detaillierte Anweisungen zur Einrichtung von **AppState**.

Nach der Installation finden Sie in der [Verwendungsübersicht](documentation/de/usage-overview.md) eine kurze Einführung in die Verwaltung des Zustands und die Injektion von Abhängigkeiten in Ihr Projekt.

## Schnelles Beispiel

Unten sehen Sie ein minimales Beispiel, das zeigt, wie man einen Zustandsausschnitt definiert und von einer SwiftUI-Ansicht darauf zugreift:

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
            Text("Zähler: \(counter)")
            Button("Inkrementieren") { counter += 1 }
        }
    }
}
```

Dieser Ausschnitt zeigt, wie man einen Zustandswert in einer `Application`-Erweiterung definiert und den `@AppState`-Property-Wrapper verwendet, um ihn in einer Ansicht zu binden.

## Dokumentation

Hier ist eine detaillierte Aufschlüsselung der Dokumentation von **AppState**:

- [Installationsanleitung](documentation/de/installation.md): So fügen Sie **AppState** mit dem Swift Package Manager zu Ihrem Projekt hinzu.
- [Verwendungsübersicht](documentation/de/usage-overview.md): Eine Übersicht über die wichtigsten Funktionen mit Beispielimplementierungen.

### Detaillierte Verwendungsanleitungen:

- [Zustands- und Abhängigkeitsmanagement](documentation/de/usage-state-dependency.md): Zentralisieren Sie den Zustand und injizieren Sie Abhängigkeiten in Ihrer gesamten App.
- [Zustand slicen](documentation/de/usage-slice.md): Greifen Sie auf bestimmte Teile des Zustands zu und ändern Sie sie.
- [StoredState-Verwendungsanleitung](documentation/de/usage-storedstate.md): So persistieren Sie leichtgewichtige Daten mit `StoredState`.
- [FileState-Verwendungsanleitung](documentation/de/usage-filestate.md): Erfahren Sie, wie Sie größere Datenmengen sicher auf der Festplatte persistieren.
- [SecureState mit Schlüsselbund verwenden](documentation/de/usage-securestate.md): Speichern Sie sensible Daten sicher mit dem Schlüsselbund.
- [iCloud-Synchronisierung mit SyncState](documentation/de/usage-syncstate.md): Halten Sie den Zustand über Geräte hinweg mit iCloud synchron.
- [FAQ](documentation/de/faq.md): Antworten auf häufig gestellte Fragen zur Verwendung von **AppState**.
- [Konstanten-Verwendungsanleitung](documentation/de/usage-constant.md): Greifen Sie auf schreibgeschützte Werte aus Ihrem Zustand zu.
- [ObservedDependency-Verwendungsanleitung](documentation/de/usage-observeddependency.md): Arbeiten Sie mit `ObservableObject`-Abhängigkeiten in Ihren Ansichten.
- [Erweiterte Verwendung](documentation/de/advanced-usage.md): Techniken wie Just-in-Time-Erstellung und Vorabladen von Abhängigkeiten.
- [Beste Praktiken](documentation/de/best-practices.md): Tipps zur effektiven Strukturierung des Zustands Ihrer App.
- [Überlegungen zur Migration](documentation/de/migration-considerations.md): Anleitung zur Aktualisierung persistierter Modelle.

## Mitwirken

Wir freuen uns über Beiträge! Bitte lesen Sie unsere [Anleitung für Mitwirkende](documentation/de/contributing.md), um zu erfahren, wie Sie sich beteiligen können.

## Nächste Schritte

Nach der Installation von **AppState** können Sie die wichtigsten Funktionen erkunden, indem Sie sich die [Verwendungsübersicht](documentation/de/usage-overview.md) und detailliertere Anleitungen ansehen. Beginnen Sie mit der effektiven Verwaltung von Zustand und Abhängigkeiten in Ihren Swift-Projekten! Für fortgeschrittenere Verwendungstechniken wie die Just-In-Time-Erstellung und das Vorabladen von Abhängigkeiten siehe die [Anleitung zur erweiterten Verwendung](documentation/de/advanced-usage.md). Sie können auch die Anleitungen zu [Konstanten](documentation/de/usage-constant.md) und [ObservedDependency](documentation/de/usage-observeddependency.md) für zusätzliche Funktionen einsehen.
