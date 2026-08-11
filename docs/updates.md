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
2. Geheimen Schlüssel holen: Dashboard -> **Settings -> API Keys**. Dort gibt
   es zwei Sorten, beide funktionieren:
   - Tab **Legacy API keys** -> `service_role` (JWT, beginnt mit `eyJ`)
   - **Secret keys** -> `sb_secret_...` (neue Art, muss ggf. erst angelegt
     werden)

   Der Schlüssel darf **nie** in die App, in `env.json` oder ins Repo: er
   umgeht alle Zugriffsregeln.

```bash
$env:SUPABASE_SECRET_KEY = 'eyJ...'
```

Das Skript schickt den Schlüssel in `apikey` **und** `Authorization`. Der alte
`service_role`-JWT braucht `Authorization`, die neuen `sb_secret_`-Schlüssel
den `apikey`-Header und dulden `Authorization` nur mit exakt demselben Wert.

Am besten dauerhaft als Benutzer-Umgebungsvariable setzen, dann muss man ihn
nie wieder eintippen.

## 2. Version veröffentlichen

```bash
./tool/publish_update.ps1 -Build
```

Die Änderungen kommen automatisch aus `CHANGELOG.md`: Vor jedem Release dort
einen Abschnitt `## <Version> - <Datum>` mit Stichpunkten aus Nutzersicht
ergänzen. Das Skript legt **alle** Abschnitte als `changelog` ins Manifest,
und die App zeigt hinter dem Knopf "Änderungen ansehen" genau die, die neuer
sind als die installierte Version. Wer drei Updates übersprungen hat, sieht
also alle drei. `-Notes "..."` bleibt als Ausnahme-Override und füllt nur
das Feld `notes` (das ältere App-Versionen lesen).

Das Skript

1. baut (mit `-Build`) über `tool/package.ps1` nach `dist/`,
2. berechnet Größe und SHA-256 aller Pakete,
3. lädt `Android-<version>-<abi>.apk` (drei Stück) und
   `Windows-<version>.zip` hoch,
4. schreibt zuletzt `manifest.json`.

**Warum drei APKs:** eine APK für alle Prozessorarten ist über 80 MB, und
Supabase Storage nimmt im Free-Plan höchstens 50 MB je Datei. `package.ps1`
baut deshalb mit `--split-per-abi` je eine APK für `arm64-v8a`,
`armeabi-v7a` und `x86_64` (jeweils rund 30 MB). Das Manifest führt alle auf,
und das Gerät sucht sich beim Update die passende: die App fragt über den
Kanal `de.lukas.multiapp/installer` ihre `Build.SUPPORTED_ABIS` ab und nimmt
den ersten Eintrag, für den es ein Paket gibt. Vor dem Hochladen prüft das
Skript die Dateigrößen und bricht mit klarer Meldung ab, falls doch etwas
über 50 MB liegt.

**Einmal geteilt, immer geteilt:** Flutter gibt jeder Split-APK einen eigenen
`versionCode` (Build 39 wird zu 2039 für arm64-v8a, 1039 für armeabi-v7a,
4039 für x86_64). Eine spätere universelle APK hätte den viel kleineren Code
40 und ließe sich nicht mehr darüber installieren, Android verweigert
Rückschritte beim `versionCode`. Das ginge nur mit Deinstallation, und damit
wären die lokalen Daten weg. Also bei den geteilten APKs bleiben.

Das Manifest kommt bewusst zum Schluss: so wird nie eine Version angekündigt,
deren Datei noch fehlt.

Nützliche Schalter:

| Schalter | Wirkung |
| --- | --- |
| `-Build` | vorher `package.ps1` laufen lassen |
| `-Notes "..."` | Änderungstext-Override; ohne Angabe zählt `dist/notes-<version>.txt`, sonst der Versionsabschnitt aus `CHANGELOG.md` |
| `-MinVersion 0.20.0` | Pflicht-Update für alles darunter; ohne Angabe bleibt der bisherige Wert |
| `-ServiceKey ...` | Schlüssel direkt statt aus `SUPABASE_SECRET_KEY` / `SUPABASE_SERVICE_KEY` |

Die Version kommt immer aus `pubspec.yaml`. Vor dem Veröffentlichen also
`version:` in `pubspec.yaml` **und** `appVersion` in `lib/core/app_info.dart`
hochzählen sowie den passenden Abschnitt in `CHANGELOG.md` schreiben.

## 3. Aufbau des Manifests

`manifest.json` im Bucket:

```json
{
  "latestVersion": "0.21.0",
  "minVersion": "0.20.0",
  "publishedAt": "2026-08-07T10:00:00Z",
  "notes": "- Live-Updates\n- Kleinkram",
  "changelog": [
    { "version": "0.21.0", "date": "2026-08-07", "notes": "- Live-Updates\n- Kleinkram" },
    { "version": "0.20.0", "date": "2026-08-05", "notes": "- Vorherige Version" }
  ],
  "android": {
    "arm64-v8a": {
      "url": "https://<projekt>.supabase.co/storage/v1/object/public/releases/Android-0.21.0-arm64-v8a.apk",
      "file": "Android-0.21.0-arm64-v8a.apk",
      "size": 31457280,
      "sha256": "a1b2..."
    },
    "armeabi-v7a": { "...": "gleiche Felder" },
    "x86_64": { "...": "gleiche Felder" }
  },
  "windows": {
    "url": ".../Windows-0.21.0.zip",
    "file": "Windows-0.21.0.zip",
    "size": 16252928,
    "sha256": "c3d4..."
  }
}
```

- `latestVersion` – neueste Version. Ist sie größer als die laufende, kommt der
  Hinweis.
- `minVersion` – optional. Wer darunter liegt, bekommt ein Pflicht-Update, das
  sich nicht wegklicken lässt.
- `sha256` – wird nach dem Download geprüft; passt sie nicht, wird die Datei
  verworfen.
- Fehlt ein Plattform-Block, bekommt diese Plattform kein Update angeboten.
  Gleiches gilt für eine Prozessorart, die unter `android` nicht auftaucht.
- Ein einzelner Android-Block mit `url` (also ohne ABI-Ebene) wird weiterhin
  verstanden, falls du doch mal eine universelle APK ausliefern willst.

Alte Versionen bleiben im Bucket liegen (praktisch, um notfalls
zurückzugehen). Pro Veröffentlichung kommen rund 100 MB dazu, der Free-Plan
hat 1 GB: ab und zu die ältesten Dateien im Dashboard unter Storage löschen.

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
