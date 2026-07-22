# MultiApp

Haushalts-App fuer Android und Desktop (Windows, Linux, macOS) mit fuenf Modulen:
Inventar, Einkaufsliste, Notizen, Pillen-Tracker und Tier-Tracker.

Alles laeuft offline; ein Konto und ein Haushalt sind optional und dienen dem
Abgleich zwischen Geraeten und Personen.

## Festgelegte Rahmenbedingungen

| Thema | Entscheidung |
| --- | --- |
| Stack | Flutter, eine Codebasis fuer Android und Desktop |
| Backend | Supabase, EU-Region |
| Anmeldung | E-Mail + Passwort, Google, Apple, Passkeys |
| Barcode | Open Food Facts plus eigene Haushalts-Produktdatenbank |
| Kontext | Privat (blau) und Haushalt (gruen), Dauerbanner und Umschalter |
| Rollen | Eigentuemer, Admin, Mitglied, Kind/Gast |
| Gesundheitsdaten | Standardmaessig privat, Betreuer-Freigabe pro Plan |
| Datenschutz | Export und Kontoloeschung, EU-Hosting, keine Telemetrie, Consent, Aufbewahrungsfristen, Audit-Log |
| Sync | Offline-first, Last-Write-Wins, Bestaende werden additiv zusammengefuehrt |
| Erinnerungen | Lokal und Push, Eskalation und Snooze, pro Typ und pro Objekt abschaltbar |

## Kontextprinzip

Jeder Datensatz gehoert genau einem Kontext: dem privaten Bereich einer Person
oder einem Haushalt. Der aktive Kontext faerbt die gesamte Oberflaeche und steht
in einer nicht ausblendbaren Leiste ganz oben. Aktionsbuttons nennen das Ziel im
Klartext, zum Beispiel "Hinzufuegen zu Familie Mueller".

## Projektstruktur

```
lib/
  app/          Theme, Router, Navigationsrahmen
  core/         Kontextlogik, Identitaet, Rollen, gemeinsame Widgets
  data/         Drift-Datenbank, Tabellen, Repositories
  features/     Die einzelnen Module
```

## Entwicklung

```bash
flutter pub get
```

Code-Generierung nach Aenderungen an Drift-Tabellen:

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

## Fahrplan

| Version | Inhalt |
| --- | --- |
| 0.1 | Geruest, Design-System, Kontextumschaltung, lokale Datenbank |
| 0.2 | Inventar mit Barcode und Open Food Facts |
| 0.3 | Einkaufsliste mit Uebernahme ins Inventar |
| 0.4 | Notizen und Checklisten |
| 0.5 | Pillen-Tracker mit lokalen Erinnerungen |
| 0.6 | Tier-Tracker |
| 0.7 | Anmeldung ueber Supabase |
| 0.8 | Haushalte, Rollen, Einladungen |
| 0.9 | Sync-Engine |
| 0.10 | Push an Familiengeraete und Eskalation |
| 0.11 | Passkeys |
| 1.0 | Datenschutzpaket und Release |
