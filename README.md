# Stream Hub

Ein unabhängiger Flutter-Prototyp, der offizielle Streaming-Webseiten in einer gemeinsamen Oberfläche bündelt. Stream Hub hostet keine Videos und verwendet keine Anbieter-API-Schlüssel.

## Downloads

Die Windows-Version und die Android-APK erscheinen als Anlagen auf der GitHub-Seite **Releases**, sobald ein Versionstag gebaut wurde. Diese Downloads sind Prototypen; die Geräte- und Wiedergabeprüfung ist noch offen.

## Plattformstatus

| Plattform | Stand |
| --- | --- |
| Windows-PC | Windows-x64-Prototyp vorhanden; GitHub-Workflow baut ein ZIP für Releases |
| Android | Flutter-Projekt vorhanden; GitHub-Workflow baut eine APK |
| Android TV / Fire TV | Android-APK mit Leanback-Launcher-Eintrag; Geräte- und Fernbedienungstest steht aus |
| Samsung Tizen / LG webOS | Nicht enthalten; dafür wären eigene Plattform-Apps nötig |
| iOS / Apple TV | In diesem Download-Projekt nicht enthalten |

Android TV und Fire TV erhalten dieselbe APK. Der Leanback-Launcher-Eintrag ist eingerichtet; Fernbedienungsnavigation, Anbieter-Webseiten und Videowiedergabe müssen noch auf Zielgeräten geprüft werden. Streaming-Dienste können eingebettete Browser, Anmeldung oder Wiedergabe einschränken; DRM-Wiedergabe ist nicht garantiert.

## Selbst bauen

Benötigt werden Flutter 3.47.7, Dart aus dem Flutter SDK und für Android ein Android SDK mit Java 17.

```sh
flutter pub get
flutter build windows --release
flutter build apk --release
```

Der Android-Release-Build ist derzeit mit dem Debug-Zertifikat signiert und nur als Prototyp/Sideload-Test gedacht. Für Play Store oder eine dauerhafte öffentliche Verteilung muss der Betreiber ein eigenes Signierzertifikat und eine eindeutige App-ID einrichten. Keine privaten Signierschlüssel in dieses Repository legen.

## GitHub-Releases

Ein Push eines Versions-Tags wie `v0.2.0` startet `.github/workflows/release.yml`. Der Workflow baut ein Windows-ZIP und eine Android-APK und hängt sie an einen GitHub-Release. Der APK-Download ist zugleich für Android-TV-/Fire-TV-Testgeräte vorgesehen.

## Datenschutz und Marken

Stream Hub fragt keine Zugangsdaten ab und überträgt keine Nutzerkonten an einen eigenen Server. Anmeldung, Websites, Werbung und Wiedergabe bleiben beim jeweiligen Anbieter. Die Namen und Marken der Anbieter gehören ihren jeweiligen Rechteinhabern; diese sind nicht mit Stream Hub verbunden.

## Nutzungsrechte

Diesem Repository ist keine Open-Source-Lizenz beigefügt. Die Projektdateien dürfen angesehen werden; daraus entsteht keine Erlaubnis, die App oder veränderte Fassungen weiterzuverbreiten oder kommerziell zu nutzen. Ein öffentliches Repository kann trotzdem kopiert oder geforkt werden; GitHub-Zugriffsrechte und eine Lizenz sind kein technischer Kopierschutz.
