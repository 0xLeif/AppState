# Häufig gestellte Fragen

Diese kurze FAQ beantwortet häufig gestellte Fragen, die Entwickler bei der Verwendung von **AppState** haben können.

## Wie setze ich einen Zustandswert zurück?

Für persistente Zustände wie `StoredState`, `FileState` und `SyncState` können Sie sie auf ihre Anfangswerte zurücksetzen, indem Sie die statischen `reset`-Funktionen für den `Application`-Typ verwenden.

Um beispielsweise einen `StoredState<Bool>` zurückzusetzen:
```swift
extension Application {
    var hasCompletedOnboarding: StoredState<Bool> { storedState(initial: false, id: "onboarding_complete") }
}

// Irgendwo in Ihrem Code
Application.reset(storedState: \.hasCompletedOnboarding)
```
Dadurch wird der Wert in `UserDefaults` auf `false` zurückgesetzt. Ähnliche `reset`-Funktionen gibt es für `FileState`, `SyncState` und `SecureState`.

Für einen nicht-persistenten `State` können Sie ihn auf die gleiche Weise wie persistente Zustände zurücksetzen:
```swift
extension Application {
    var counter: State<Int> { state(initial: 0) }
}

// Irgendwo in Ihrem Code
Application.reset(\.counter)
```

## Kann ich AppState mit asynchronen Aufgaben verwenden?

Ja. `State`- und Abhängigkeitswerte sind threadsicher und funktionieren nahtlos mit Swift Concurrency. Sie können sie innerhalb von `async`-Funktionen ohne zusätzliche Sperren aufrufen und ändern.

## Wo sollte ich Zustände und Abhängigkeiten definieren?

Bewahren Sie alle Ihre Zustände und Abhängigkeiten in `Application`-Erweiterungen auf. Dies gewährleistet eine einzige Quelle der Wahrheit und erleichtert das Auffinden aller verfügbaren Werte.

## Ist AppState mit Combine kompatibel?

Sie können AppState zusammen mit Combine verwenden, indem Sie `State`-Änderungen an Publisher überbrücken. Beobachten Sie einen `State`-Wert und senden Sie bei Bedarf Aktualisierungen über einen `PassthroughSubject` oder einen anderen Combine-Publisher.

---
Diese Übersetzung wurde automatisch generiert und kann Fehler enthalten. Wenn Sie Muttersprachler sind, freuen wir uns über Ihre Korrekturvorschläge per Pull Request.
