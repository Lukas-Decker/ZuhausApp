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

Im Projekt unter **Project Settings -> API**:

- **Project URL** (z.B. `https://abcdefgh.supabase.co`)
- **anon / publishable key** (langer oeffentlicher Schluessel)

Der anon-Key ist oeffentlich und darf in die App, gehoert aber trotzdem nicht
ins Git-Repo (deshalb `env.json` in `.gitignore`).

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

## Hinweis

Datenbank-Tabellen und Row-Level-Security fuer die Synchronisierung kommen in
v0.8 (Haushalte/Rollen) und v0.9 (Sync-Engine) dazu.
