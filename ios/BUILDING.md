# iPhone-Build von Stream Hub

Der Flutter-Dashboard-Code wird zwischen Windows und iPhone geteilt. Das iOS-Projekt ist unter `ios/` vorhanden; die App verwendet dort Apples WKWebView für die Anbieterseiten. Das Projekt ist aktuell auf iOS 15.0 als Mindestversion eingestellt.

## Auf einem Mac bauen und auf dem eigenen iPhone starten

1. Das Projekt auf einen Mac mit Xcode 15 oder neuer kopieren.
2. Flutter installieren und `flutter doctor` ausführen.
3. Im Projektordner `flutter pub get` ausführen.
4. `ios/Runner.xcworkspace` in Xcode öffnen.
5. Unter **Signing & Capabilities** eine persönliche Team-Signatur wählen und eine eigene, eindeutige Bundle-ID eintragen. Die aktuelle `com.example.streamHub` ist nur ein Platzhalter.
6. Ein iPhone verbinden, diesem Gerät vertrauen und in Xcode als Ziel auswählen.
7. Mit `flutter run` starten. Alternativ kann in Xcode **Product → Run** verwendet werden.

Xcode kann Apps mit einem kostenlosen Apple Account auf eigenen Geräten ausführen. Für TestFlight oder App-Store-Verteilung ist eine Mitgliedschaft im Apple Developer Program erforderlich.

## Grenzen dieses Prototyps

- Die Flutter-Oberfläche ist geteilt; die WebView und Medienwiedergabe sind plattformspezifisch. Jeder Anbieter muss auf einem echten iPhone separat geprüft werden.
- Streaming-Dienste können Login oder Wiedergabe in eingebetteten Browsern blockieren. DRM-Unterstützung der iOS-WebView bedeutet keine Freigabe oder Garantie der Anbieter.
- Die App ist derzeit ein Launcher mit eingebetteten Websites. Apple weist darauf hin, dass Websites in einer App oder eine Sammlung von Links allein keine hochwertige iOS-App ergeben. App-Store-Zulassung ist daher offen; dafür braucht die App zusätzlichen eigenständigen iOS-Nutzen.
- Für geschützte Namen, Logos und Inhalte kann Apple Autorisierungsnachweise verlangen. Vor einer öffentlichen Veröffentlichung müssen die erforderlichen Rechte geklärt sein.
- Vor einer Veröffentlichung sind App-Icon, eindeutige Bundle-ID, Support- und Datenschutzinformationen sowie Tests auf echten Geräten fertigzustellen.

## Release-Befehle

Auf dem Mac mit eingerichteter Signierung:

```sh
flutter build ios --release
flutter build ipa
```

`flutter build ipa` erzeugt das App-Archiv und ein `.ipa`-Paket zur Verteilung. Dieser Build muss auf macOS mit Xcode erstellt werden; Windows kann kein iOS-Installationspaket erzeugen.
