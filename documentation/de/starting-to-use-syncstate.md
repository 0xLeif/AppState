Um SyncState zu nutzen, müssen Sie zuerst die iCloud-Fähigkeiten und -Berechtigungen in Ihrem Xcode-Projekt einrichten. Hier ist eine Einführung, die Sie durch den Prozess führt:

### Einrichten der iCloud-Fähigkeiten:

1. Öffnen Sie Ihr Xcode-Projekt und passen Sie die Bundle-Identifikatoren für die macOS- und iOS-Ziele an Ihre eigenen an.
2. Als Nächstes müssen Sie die iCloud-Fähigkeit zu Ihrem Projekt hinzufügen. Wählen Sie dazu Ihr Projekt im Projektnavigator aus und wählen Sie dann Ihr Ziel aus. Klicken Sie in der Tab-Leiste oben im Editorbereich auf "Capabilities".
3. Aktivieren Sie im Bereich "Capabilities" iCloud, indem Sie auf den Schalter in der iCloud-Zeile klicken. Sie sollten sehen, wie sich der Schalter in die Ein-Position bewegt.
4. Sobald Sie iCloud aktiviert haben, müssen Sie den Schlüssel-Wert-Speicher aktivieren. Dies können Sie tun, indem Sie das Kontrollkästchen "Key-Value storage" aktivieren.

### Aktualisieren der Berechtigungen:

1. Sie müssen nun Ihre Berechtigungsdatei aktualisieren. Öffnen Sie die Berechtigungsdatei für Ihr Ziel.
2. Stellen Sie sicher, dass der Wert des iCloud-Schlüssel-Wert-Speichers mit Ihrer eindeutigen Schlüssel-Wert-Speicher-ID übereinstimmt. Ihre eindeutige ID sollte dem Format `$(TeamIdentifierPrefix)<Ihre Schlüssel-Wert-Speicher-ID>` folgen. Der Standardwert sollte etwa `$(TeamIdentifierPrefix)$(CFBundleIdentifier)` lauten. Dies ist für Einzelplattform-Apps in Ordnung, aber wenn Ihre App auf mehreren Apple-Betriebssystemen läuft, ist es wichtig, dass die Teile der Schlüssel-Wert-Speicher-ID für beide Ziele gleich sind.

### Konfigurieren der Geräte:

Zusätzlich zur Konfiguration des Projekts selbst müssen Sie auch die Geräte vorbereiten, auf denen das Projekt ausgeführt wird.

- Stellen Sie sicher, dass iCloud Drive sowohl auf iOS- als auch auf macOS-Geräten aktiviert ist.
- Melden Sie sich auf beiden Geräten mit demselben iCloud-Konto an.

Wenn Sie Fragen haben oder auf Probleme stoßen, können Sie sich gerne an uns wenden oder ein Problem melden.
