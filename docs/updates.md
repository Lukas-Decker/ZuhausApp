# Eigener Update-Kanal

Die App prüft beim Start (und danach alle sechs Stunden) auf dem eigenen
Server, ob eine neuere Version bereitliegt, zeigt die Änderungen an und
installiert das Update auf Wunsch selbst. Kein Store, keine Fremdanbieter.

- **Android:** die APK wird geladen und dem System-Installer übergeben.
- **Windows:** das ZIP wird geladen, daneben entpackt und nach dem Beenden der
  App eingespielt; danach startet die App neu.

Alles liegt im eigenen Supabase-Projekt (EU) im öffentlichen Storage-Bucket
`releases`.

## 1. Einmalig einrichten

1. Migration `supabase/migrations/0006_releases.sql` im SQL-Editor ausführen.
   Sie legt den Bucket `releases` an und macht ihn öffentlich lesbar.
2. Service-Role-Key holen: Dashboard -> Project Settings -> API ->
   `service_role`. Der Schlüssel darf **nie** in die App, in `env.json` oder
   ins Repo: er umgeht alle Zugriffsregeln.

```bash
$env:SUPABASE_SERVICE_KEY = 'eyJ...'
```

Am besten dauerhaft als Benutzer-Umgebungsvariable setzen, dann muss man ihn
nie wieder eintippen.

## 2. Version veröffentlichen

```bash
./tool/publish_update.ps1 -Build -Notes "Was neu ist"
```

Das Skript

1. baut (mit `-Build`) über `tool/package.ps1` nach `dist/`,
2. berechnet Größe und SHA-256 beider Pakete,
3. lädt `Android-<version>.apk` und `Windows-<version>.zip` hoch,
4. schreibt zuletzt `manifest.json`.

Das Manifest kommt bewusst zum Schluss: so wird nie eine Version angekündigt,
deren Datei noch fehlt.

Nützliche Schalter:

| Schalter | Wirkung |
| --- | --- |
| `-Build` | vorher `package.ps1` laufen lassen |
| `-Notes "..."` | Änderungstext; ohne Angabe wird `dist/notes-<version>.txt` gelesen |
| `-MinVersion 0.20.0` | Pflicht-Update für alles darunter; ohne Angabe bleibt der bisherige Wert |
| `-ServiceKey ...` | Schlüssel direkt statt aus der Umgebungsvariable |

Die Version kommt immer aus `pubspec.yaml`. Vor dem Veröffentlichen also
`version:` in `pubspec.yaml` **und** `appVersion` in `lib/core/app_info.dart`
hochzählen.

## 3. Aufbau des Manifests

`manifest.json` im Bucket:

```json
{
  "latestVersion": "0.21.0",
  "minVersion": "0.20.0",
  "publishedAt": "2026-08-07T10:00:00Z",
  "notes": "- Live-Updates\n- Kleinkram",
  "android": {
    "url": "https://<projekt>.supabase.co/storage/v1/object/public/releases/Android-0.21.0.apk",
    "file": "Android-0.21.0.apk",
    "size": 31457280,
    "sha256": "a1b2..."
  },
  "windows": { "...": "wie oben, nur Windows-0.21.0.zip" }
}
```

- `latestVersion` – neueste Version. Ist sie größer als die laufende, kommt der
  Hinweis.
- `minVersion` – optional. Wer darunter liegt, bekommt ein Pflicht-Update, das
  sich nicht wegklicken lässt.
- `sha256` – wird nach dem Download geprüft; passt sie nicht, wird die Datei
  verworfen.
- Fehlt ein Plattform-Block, bekommt diese Plattform kein Update angeboten.

## 4. Was der Nutzer sieht

- Neue Version: Blatt von unten mit Version, Größe, Datum und Änderungen.
  "Später" blendet genau diese Version aus, "Jetzt aktualisieren" lädt mit
  Fortschrittsbalken und installiert.
- Pflicht-Update: derselbe Inhalt als Dialog ohne "Später".
- Einstellungen -> Updates: Zustand, Knopf zum sofortigen Nachsehen und ein
  Schalter für die automatische Prüfung.

Android fragt beim ersten Mal nach der Erlaubnis "Unbekannte Apps
installieren". Das Blatt bietet dann direkt den Weg in die Systemeinstellung
an; danach genügt ein erneuter Tipp auf "Jetzt aktualisieren" (die geladene
Datei wird wiederverwendet).

## 5. Anderer Server statt Supabase

Der Kanal ist nicht an Supabase gebunden. Ein beliebiger Webserver, der
`manifest.json` und die Pakete statisch ausliefert, genügt:

```bash
flutter build apk --release --dart-define=UPDATE_BASE_URL=https://updates.example.org
```

Die App hängt an die Basis-URL nur noch `/manifest.json` an; die Paket-Adressen
stehen vollständig im Manifest.

## 6. Fehlersuche

- **"Noch keine Version veröffentlicht"** – `manifest.json` fehlt im Bucket.
- **Prüfsummenfehler** – Datei wurde nach dem Hochladen ersetzt, ohne das
  Manifest neu zu schreiben. Einfach `publish_update.ps1` erneut laufen lassen.
- **Windows-Update passiert nicht** – das Update-Skript protokolliert nach
  `%TEMP%\...\updates\update.log`. Läuft die App aus einem geschützten Ordner
  (z. B. `C:\Program Files`), fehlen die Schreibrechte; dann öffnet das Skript
  den entpackten Ordner zum Kopieren von Hand.
- Fehler landen zusätzlich im App-Protokoll (Einstellungen -> Diagnose ->
  Protokoll), Quelle `update`.
