# Supabase einrichten (ab v0.7)

Die App laeuft ohne Konto vollstaendig im Gastmodus. Fuer Anmeldung, Familie und
Synchronisierung brauchst du ein kostenloses Supabase-Projekt.

## 1. Projekt anlegen

1. Auf https://supabase.com registrieren und einloggen.
2. **New project** anlegen.
3. Wichtig fuer DSGVO: als Region **Central EU (Frankfurt)** oder eine andere
   EU-Region waehlen.
4. Ein Datenbank-Passwort setzen (nur fuer den direkten DB-Zugriff, die App
   braucht es nicht).
5. Projekt erstellen und ein bis zwei Minuten warten, bis es bereit ist.

## 2. Zugangsdaten holen

Das Dashboard-Layout hat sich geaendert. Aktuell:

- **Project Settings -> API Keys -> Publishable key** (`sb_publishable_...`) ->
  das ist der oeffentliche Schluessel fuer die App (frueher "anon key").
- **Project Settings -> Data API -> API URL** -> die Projekt-URL.

**Achtung bei der URL:** Trage nur die Basis-URL ein, also
`https://<projekt>.supabase.co` **ohne** den Pfad `/rest/v1/`. Falls das
Dashboard die URL mit `/rest/v1/` am Ende zeigt, schneide diesen Teil ab. (Die
App entfernt einen solchen Pfad zur Sicherheit auch selbst.)

Der Publishable Key ist oeffentlich und darf in die App, gehoert aber trotzdem
nicht ins Git-Repo (deshalb `env.json` in `.gitignore`).

## 3. env.json anlegen

Kopiere `env.example.json` zu `env.json` und trage deine Werte ein:

```json
{
  "SUPABASE_URL": "https://abcdefgh.supabase.co",
  "SUPABASE_ANON_KEY": "dein-anon-key"
}
```

Starten mit:

```bash
flutter run -d windows --dart-define-from-file=env.json
```

Alternativ direkt (uebersteuert die Datei):

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## 4. Auth-Einstellungen im Dashboard

Unter **Authentication -> URL Configuration**:

- **Redirect URLs** ergaenzen: `de.lukas.multiapp://login-callback`

Unter **Authentication -> Providers -> Email**:

- **Confirm email** aktiviert lassen (Standard). Damit muss die E-Mail vor dem
  ersten Login bestaetigt werden.

## 5. Google-Login (optional)

1. In der **Google Cloud Console** ein Projekt anlegen.
2. **OAuth consent screen** konfigurieren (extern, App-Name, deine E-Mail).
3. Unter **Credentials -> Create credentials -> OAuth client ID**:
   - **Web application** anlegen. Als **Authorized redirect URI** die von
     Supabase angezeigte Callback-URL eintragen
     (`https://<projekt>.supabase.co/auth/v1/callback`).
   - Zusaetzlich fuer Android einen **Android**-OAuth-Client mit deinem
     Package-Namen `de.lukas.multiapp` und dem SHA-1-Fingerprint deines
     Signaturschluessels.
4. In Supabase unter **Authentication -> Providers -> Google** aktivieren und
   die **Client ID** und das **Client Secret** des Web-Clients eintragen.

Ohne diesen Schritt funktioniert E-Mail + Passwort trotzdem; der Google-Button
zeigt dann nur eine Fehlermeldung.

## Deep-Links auf dem Desktop (Windows)

Die E-Mail-Bestaetigung funktioniert immer: der Klick auf den Link bestaetigt
das Konto serverseitig, danach kannst du dich in der App mit E-Mail + Passwort
anmelden. Ein Ruecksprung in die App ist dafuer nicht noetig.

Google-Login und Passwort-Reset laufen ueber den Browser und muessen zurueck in
die App springen (`de.lukas.multiapp://login-callback`). Auf Android geschieht
das ueber den Intent-Filter automatisch. Auf **Windows** registriert die App das
URL-Schema beim ersten Start selbst in der Registry (HKEY_CURRENT_USER, keine
Admin-Rechte noetig) und leitet den Link an das laufende Fenster weiter. Der
Eintrag zeigt auf die gerade gestartete exe; startest du die App aus einem
anderen Pfad, wird er beim naechsten Start aktualisiert.

## 6. Datenbank-Migration fuer Haushalte (ab v0.8)

Fuer Haushalte, Rollen und Einladungen braucht das Projekt Tabellen, Row-Level-
Security und einige Funktionen. Die liegen als SQL-Datei im Repo:

`supabase/migrations/0001_households.sql`

So einspielen:

1. Im Supabase-Dashboard **SQL Editor** oeffnen.
2. **New query**, den kompletten Inhalt der Datei einfuegen.
3. **Run** druecken. Die Datei ist idempotent, wiederholtes Ausfuehren schadet
   nicht.

Die Datei enthaelt neben Tabellen, RLS und Funktionen auch die noetigen
`GRANT`-Rechte fuer die Rolle `authenticated`. Ohne diese Rechte scheitert jede
Leseabfrage mit "permission denied ... code 42501". Falls du eine aeltere
Fassung ohne GRANTs eingespielt hattest, reicht das Nachziehen ueber
`supabase/migrations/0002_household_grants.sql`.

Danach kannst du in der App (angemeldet) ueber den Kontext-Umschalter einen
Haushalt **erstellen**, per Code/Link **einladen** und **beitreten**. Die
Verwaltung (Mitglieder, Rollen, Eigentuemer-Uebergabe) findest du in den
Einstellungen unter dem jeweiligen Haushalt.

Sicherheitsmodell: Lesen ist per RLS auf die eigenen Haushalte beschraenkt; alle
Aenderungen laufen ueber serverseitige Funktionen, die die Rollenrechte
durchsetzen. Ein Gast (nicht angemeldet) kann keine Haushalte anlegen; die App
fuehrt dann zur Anmeldung.

## 7. Sync der Modul-Inhalte (ab v0.9)

Damit Inventar, Einkauf, Notizen, Pillen und Tiere zwischen Geraeten und
Haushaltsmitgliedern abgeglichen werden, brauchst du eine weitere Migration:

`supabase/migrations/0003_sync.sql`

Genauso einspielen wie die anderen (SQL Editor -> New query -> Inhalt einfuegen
-> Run). Sie legt eine generische `sync_records`-Tabelle mit RLS an, dazu die
Merge-Funktion `push_record` (Last-Write-Wins, additive Zaehler) und aktiviert
Realtime.

Danach synchronisiert die App automatisch: beim Start, alle paar Minuten und
live ueber Realtime. Den Status siehst du in den Einstellungen unter
"Synchronisierung"; dort kannst du auch manuell abgleichen.

Zaehler (Vorratsmengen, Medikamenten-Vorrat) werden additiv zusammengefuehrt:
verbrauchen zwei Geraete offline vom selben Vorrat, summieren sich die Mengen
statt sich zu ueberschreiben. Alle anderen Felder folgen Last-Write-Wins.

## 8. Familien-Benachrichtigungen (ab v0.10)

Fuer Push an Familiengeraete (z.B. "Hund noch nicht gefuettert", verpasste
Pille) ohne Firebase - komplett ueber Supabase-Realtime:

`supabase/migrations/0004_family_events.sql`

Genauso einspielen. Sie legt die Tabelle `household_events` mit RLS an, dazu die
Funktion `post_household_event` (mit Doppel-Schutz) und aktiviert Realtime.

So funktioniert es: Ein laufendes Geraet erkennt eine Situation und legt ein
Ereignis an; alle verbundenen Geraete des Haushalts zeigen es als
Benachrichtigung. Einschraenkung des Realtime-Ansatzes: eine komplett
geschlossene App wird nicht geweckt - die Benachrichtigung erscheint, sobald die
App wieder laeuft. In den Einstellungen unter "Familie" laesst sich jeder Kanal
(Familien-Benachrichtigungen, Pillen-Eskalation, Fuetterung ueberfaellig)
einzeln an- und abschalten.
