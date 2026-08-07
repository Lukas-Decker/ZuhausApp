# MultiApp

Haushalts-App für Android und Desktop (Windows, Linux, macOS) mit fünf Modulen:
Inventar, Einkaufsliste, Notizen, Pillen-Tracker und Tier-Tracker.

Alles läuft offline; ein Konto und ein Haushalt sind optional und dienen dem
Abgleich zwischen Geräten und Personen.

## Festgelegte Rahmenbedingungen

| Thema | Entscheidung |
| --- | --- |
| Stack | Flutter, eine Codebasis für Android und Desktop |
| Backend | Supabase, EU-Region |
| Anmeldung | E-Mail + Passwort, Google, Apple, Passkeys |
| Barcode | Open Food Facts plus eigene Haushalts-Produktdatenbank |
| Kontext | Privat (blau) und Haushalt (grün), Dauerbanner und Umschalter |
| Rollen | Eigentümer, Admin, Mitglied, Kind/Gast |
| Gesundheitsdaten | Standardmäßig privat, Betreuer-Freigabe pro Plan |
| Datenschutz | Export und Kontolöschung, EU-Hosting, keine Telemetrie, Consent, Aufbewahrungsfristen, Audit-Log |
| Sync | Offline-first, Last-Write-Wins, Bestände werden additiv zusammengeführt |
| Erinnerungen | Lokal und Push, Eskalation und Snooze, pro Typ und pro Objekt abschaltbar |

## Kontextprinzip

Jeder Datensatz gehört genau einem Kontext: dem privaten Bereich einer Person
oder einem Haushalt. Der aktive Kontext färbt die gesamte Oberfläche und steht
in einer nicht ausblendbaren Leiste ganz oben. Aktionsbuttons nennen das Ziel im
Klartext, zum Beispiel "Hinzufügen zu Familie Müller".

## Projektstruktur

```
lib/
  app/          Theme, Router, Navigationsrahmen
  core/         Kontextlogik, Identität, Rollen, gemeinsame Widgets
  data/         Drift-Datenbank, Tabellen, Repositories
  features/     Die einzelnen Module
```

## Entwicklung

```bash
flutter pub get
```

Code-Generierung nach Änderungen an Drift-Tabellen:

```bash
dart run build_runner build
```

Analyse und Tests:

```bash
flutter analyze; flutter test
```

Starten:

```bash
flutter run -d windows
```

## Verpacken (dist/)

Fertige Artefakte landen im Ordner `dist/` im Projekt-Root. Das Skript liest
die Version aus `pubspec.yaml` und legt ab:

- `dist/Windows-<version>.zip` (gezippter Release-Ordner)
- `dist/Android-<version>-<abi>.apk` (je Prozessorart eine Release-APK:
  arm64-v8a, armeabi-v7a, x86_64)

Liegt eine `env.json` vor, wird sie in den Build uebernommen, sonst baut es im
Gastmodus (ohne Supabase).

```powershell
./tool/package.ps1
```

Nur eine Plattform bzw. nur neu zippen ohne Bauen:

```powershell
./tool/package.ps1 -Target windows
./tool/package.ps1 -Target android -SkipBuild
```

## Update-Kanal (Live-Updates)

Die App holt sich neue Versionen selbst vom eigenen Server (oeffentlicher
Supabase-Storage-Bucket `releases`): Hinweis beim Start, Download mit
Fortschritt, Installation per System-Installer (Android) bzw. Austausch nach
dem Beenden (Windows). Veroeffentlicht wird mit:

```powershell
./tool/publish_update.ps1 -Build -Notes "Was neu ist"
```

Einrichtung, Manifest-Format und Fehlersuche: [docs/updates.md](docs/updates.md).

## App-Icon

Das Icon (weisses Haus auf blauem, abgerundetem Grund) ist selbst gezeichnet und
damit frei verwendbar. Die Quellgrafiken liegen unter `assets/icon/`. Neu
erzeugen (z.B. nach einer Farb- oder Formaenderung in `tool/generate_icon.dart`):

```bash
dart run tool/generate_icon.dart
dart run flutter_launcher_icons
```

Der erste Befehl zeichnet die PNGs, der zweite verteilt sie auf Android
(Mipmaps + adaptive Icons) und Windows (`.ico`).

## Fahrplan

| Version | Inhalt |
| --- | --- |
| 0.1 | Gerüst, Design-System, Kontextumschaltung, lokale Datenbank |
| 0.2 | Inventar mit Barcode und Open Food Facts |
| 0.3 | Einkaufsliste mit Übernahme ins Inventar |
| 0.4 | Notizen und Checklisten |
| 0.5 | Pillen-Tracker mit lokalen Erinnerungen |
| 0.6 | Tier-Tracker |
| 0.7 | Anmeldung über Supabase |
| 0.8 | Haushalte, Rollen, Einladungen |
| 0.9 | Sync-Engine |
| 0.10 | Push an Familiengeräte und Eskalation |
| 0.11 | Biometrisches App-Schloss (Windows Hello, Fingerabdruck/Gesicht) |
| 0.12 | Datenschutzpaket (Export, Kontolöschung, Consent, Audit-Log) |
| 0.13 | FCM-Push (weckt geschlossene App) |
