# Sicherheitspruefung: IDOR, OWASP Top 10 und OWASP ZAP

Stand: 2026-08-13
Geprueftes Projekt: MultiApp (Zuhaus), Flutter-Client + Supabase-Backend
Pruefumfang: statische Analyse der Client-Requests, der SQL-Migrationen
(RLS-Policies und SECURITY-DEFINER-RPCs) und der beiden Edge Functions.
Keine Live-Tests gegen eine laufende Instanz.

## Stand der Umsetzung

| Befund | Schwere | Status |
| --- | --- | --- |
| F1 `push_record` Scope | Mittel-Hoch | **Behoben** in `supabase/migrations/0007_security_fixes.sql` |
| F2 `notify-fcm` | Mittel | **Behoben** in `supabase/functions/notify-fcm/index.ts` |
| F3 `upsert_device_token` | Niedrig-Mittel | **Behoben** in `supabase/migrations/0007_security_fixes.sql` |
| F6 `push_record` Datenblock | Mittel | **Behoben** in `supabase/migrations/0007_security_fixes.sql` |
| F4 Update-Signatur | Niedrig (Design) | Offen, Optionen siehe Abschnitt 4 |
| F5 Schwarz-API-Key | Info | Offen, Bewertung siehe Abschnitt 4 |

Ausrollen mit:

    ./tool/apply_security_fixes.ps1

Das Skript spielt die Migration ein, setzt das Webhook-Geheimnis und deployt
die Function neu. Der Client bleibt unveraendert; es ist ausschliesslich eine
Serveraenderung.

---

## 1. Ueberblick und Architektur

Die App ist offline-first. Die lokale Drift-Datenbank ist die Wahrheit fuer die
Oberflaeche; Supabase ist reiner Abgleichspartner und Rechte-Gate. Konto und
Haushalt sind optional. Der gesamte Server-Datenverkehr laeuft ueber vier Wege:

| Weg | Datei (Client) | Server | Zweck |
| --- | --- | --- | --- |
| PostgREST-Lesen | `sync_engine.dart`, `household_remote_service.dart` | Tabellen `sync_records`, `households`, `household_members`, `household_invites`, `household_events`, `device_tokens` | Lesen, durch RLS gefiltert |
| RPC (SECURITY DEFINER) | `sync_engine.dart`, `household_remote_service.dart`, `family_event_service.dart`, `fcm_service.dart` | `push_record`, `create_household`, `join_with_code`, `set_member_role`, `post_household_event`, `upsert_device_token`, ... | Alle Schreibvorgaenge |
| Edge Function | `auth_service.dart` | `delete-account` | Kontoloeschung (DSGVO) |
| Edge Function | (Datenbank-Webhook) | `notify-fcm` | FCM-Push an Familiengeraete |
| Fremd-APIs | `prospekte_providers.dart`, `open_food_facts_service.dart`, `update_service.dart` | Zippopotam, Open Food Facts, Schwarz-Filial-API, eigener Update-Bucket | Prospekte, Produktdaten, Updates |

**Grundmodell (gut umgesetzt):** RLS regelt das *Lesen* (nur eigene Bereiche),
alle *Schreibvorgaenge* laufen ueber SECURITY-DEFINER-RPCs, die die Rollenlogik
zentral durchsetzen. Direkte INSERT/UPDATE/DELETE vom Client sind per fehlender
Grants und fehlender Write-Policies gesperrt. Das ist genau die richtige Struktur
fuer Supabase.

---

## 2. IDOR-Pruefung (Broken Object Level Authorization)

Bei Supabase entscheidet nicht der Client, sondern die RLS-Policy bzw. die
RPC-Logik ueber den Objektzugriff. Geprueft wurde jeder Pfad, bei dem der Client
eine fremde ID (Haushalt, Datensatz, Nutzer, Token) mitschicken kann.

### 2.1 Lesen: sauber gegen IDOR abgesichert

- `sync_records`: Policy `sync_select` -> `can_access_scope(scope_kind, scope_id)`.
  Persoenlicher Scope nur bei `scope_id = auth.uid()`, Haushalts-Scope nur bei
  Mitgliedschaft. Der Pull in `sync_engine.dart:146` liest ohne eigenen Filter,
  bekommt aber nur die RLS-gefilterten Zeilen zurueck. **Kein IDOR.**
- `households` / `household_members`: sichtbar nur fuer Mitglieder desselben
  Haushalts (`is_household_member`). Der Client filtert in
  `fetchMyHouseholds()` zusaetzlich auf die eigene Mitgliedschaft. **Kein IDOR.**
- `household_invites`: nur Owner/Admin sehen die Liste (`my_role in ...`).
- `household_events`: Mitglied **und** (`target_user_id is null oder = auth.uid()`).
  Gezielte Ereignisse an eine Person sind fuer andere nicht lesbar. **Kein IDOR.**
- `device_tokens`: nur `user_id = auth.uid()`. **Kein IDOR.**

### 2.2 Schreiben ueber RPC: Rollen serverseitig geprueft

`set_member_role`, `remove_member`, `transfer_ownership`, `delete_household`,
`rename_household`, `create_invite`, `revoke_invite` pruefen jeweils
`my_role(_household)` und die Rangfolge (Owner > Admin > Member > Guest). Admins
koennen keine Admins ernennen, die Owner-Rolle ist geschuetzt, nur der Owner darf
uebergeben/aufloesen. Das ist konsistent und korrekt. **Kein IDOR.**

### 2.3 BEFUND F1 (Mittel bis Hoch): `push_record` prueft beim Update nur den mitgeschickten Scope, nicht den gespeicherten

Datei: `supabase/migrations/0003_sync.sql:80-150`

Beim Aktualisieren eines bereits existierenden Datensatzes lautet die
Berechtigungspruefung:

```sql
if not public.can_access_scope(_scope_kind, _scope_id) then   -- Zeile 101
  raise exception 'Kein Zugriff auf diesen Bereich';
end if;
...
update public.sync_records set data = _merged, ...
 where table_name = _table and id = _id;                      -- Zeile 146
```

Geprueft wird ausschliesslich der **vom Client uebergebene** Scope
(`_scope_kind`, `_scope_id`). Das UPDATE selbst trifft die Zeile nur ueber den
Primaerschluessel `(table_name, id)` und aendert den gespeicherten Scope nicht.
Der **tatsaechlich gespeicherte** Scope der Zielzeile wird nie mit dem Aufrufer
abgeglichen.

**Angriff:** Ein beliebiger angemeldeter Nutzer ruft `push_record` auf mit
`_scope_kind = 'personal'`, `_scope_id = <eigene uid>` (Pruefung besteht) sowie
`_table` und `_id` eines **fremden** Datensatzes und einem zukuenftigen
`_updated_at`. Per Last-Write-Wins wird `data` mit den Angreiferdaten
ueberschrieben; ueber `_deleted_at` laesst sich der Satz auch als geloescht
markieren. Die Funktion ist SECURITY DEFINER und umgeht dabei die RLS beim
internen `select`.

**Realistischer Pfad ohne UUID-Raten:** Datensatz-IDs sind zufaellige UUIDv4 und
fuer Fremde normalerweise nicht lesbar (RLS). Ein *ehemaliges* Haushaltsmitglied
hat die UUIDs aller Datensaetze aber lokal synchronisiert und behaelt sie nach
dem Entfernen/Verlassen. Es kann Inventar, Notizen, Pillenplaene oder
Tier-Eintraege des Haushalts dauerhaft manipulieren oder loeschen, obwohl seine
Lesezugriffe laengst durch RLS gesperrt sind.

**Auswirkung:** Integritaetsverletzung / tenant-uebergreifender Schreibzugriff.
Keine Vertraulichkeitsverletzung (Lesen bleibt dicht), aber Fremddaten koennen
verfaelscht oder getilgt werden.

**Empfehlung:** Bei existierendem Datensatz gegen den **gespeicherten** Scope
pruefen und Scope-Wechsel ablehnen:

```sql
if _existing.id is not null then
  if not public.can_access_scope(_existing.scope_kind, _existing.scope_id) then
    raise exception 'Kein Zugriff auf diesen Datensatz';
  end if;
  if _existing.scope_kind <> _scope_kind or _existing.scope_id <> _scope_id then
    raise exception 'Scope-Wechsel nicht erlaubt';
  end if;
end if;
```

---

## 3. OWASP Top 10 (2021) im Durchgang

| # | Kategorie | Bewertung fuer diese App |
| --- | --- | --- |
| A01 | Broken Access Control | Grundmodell solide (RLS + RPC). **Ausnahme: F1** (`push_record`-Update) und **F2** (notify-fcm). |
| A02 | Cryptographic Failures | Aller Transport ueber HTTPS (Supabase, Zippopotam, OFF, FCM). Supabase-Session-Token liegt im plattformueblichen Secure-Store der Client-Bibliothek. Keine Eigenkrypto. Anmerkung: kein Client-seitiges Pinning (siehe A08/ZAP). |
| A03 | Injection | PostgREST parametrisiert; RPCs nutzen typisierte Parameter und `set search_path = public`. Keine dynamische SQL-Verkettung. Der Windows-Updater setzt Pfade als PowerShell-Literale und uebergibt sie als benannte Parameter (`update_installer.dart:232`). **Kein Injection-Befund.** |
| A04 | Insecure Design | Offline-first mit LWW ist bewusst gewaehlt; Rollen/Kontexte klar. Schwachpunkt im Design: selbst-aktualisierender Windows-Client ohne Code-Signatur (**F4**). |
| A05 | Security Misconfiguration | RLS auf allen Tabellen aktiv, `authenticated` hat nur SELECT. **F2** (Webhook-Secret optional + `--no-verify-jwt`) faellt hierunter. `releases`-Bucket ist bewusst oeffentlich lesbar, ohne Schreibrechte fuer anon/authenticated. |
| A06 | Vulnerable Components | `pubspec.lock` gepflegt, aktuelle Flutter/Supabase-Pakete. Regelmaessiges `flutter pub outdated` empfohlen; kein akuter Befund aus statischer Sicht. |
| A07 | Identification & Auth Failures | Auth ueber Supabase GoTrue (E-Mail+Passwort, OAuth, Passkeys). Kein Eigenbau. `delete-account` identifiziert den Aufrufer korrekt aus dem JWT (`delete-account/index.ts:48`), loescht nur eigene Daten und blockt Owner mit Restmitgliedern (409). |
| A08 | Software & Data Integrity Failures | Update-Kanal prueft SHA-256 **nur wenn** das Manifest eine Pruefsumme liefert, und Manifest wie Paket kommen aus demselben Bucket -> keine unabhaengige Vertrauensanker, **keine Code-Signatur** (**F4**). |
| A09 | Logging & Monitoring | Client-`DebugLog` vorhanden; serverseitig keine Audit-Spur ueber die RPCs hinaus. Fuer eine private Haushalts-App vertretbar. Der Fahrplan nennt ein Audit-Log als Ziel. |
| A10 | SSRF | Keine serverseitige Weiterleitung anhand von Nutzer-URLs. `notify-fcm` ruft feste Google-Endpunkte; die Ziel-URL ist nicht nutzergesteuert. **Kein SSRF-Befund.** |

---

## 4. Weitere Befunde

### F6 (Mittel, BEHOBEN): `push_record` prueft den JSON-Datenblock nicht

Nachtrag zur ersten Fassung dieses Berichts, gefunden beim Umsetzen von F1.

Dateien: `supabase/migrations/0003_sync.sql:80`, `lib/features/sync/local_sync_store.dart:76`

F1 betraf die Spalten `scope_kind`/`scope_id` der Tabelle. Der eigentliche
Nutzinhalt steckt aber in `data` (jsonb), und der wurde serverseitig **gar nicht**
geprueft. Entscheidend ist, was der Empfaenger damit macht:
`LocalSyncStore.applyRemote` schreibt **alle** Felder aus diesem Block in die
lokale Tabelle, also auch `id`, `scope_kind` und `scope_id`. Der Pull nutzt
ausschliesslich `map['data']` (`sync_engine.dart:163`), nie die Spalten.

**Angriff:** Ein Haushaltsmitglied schickt einen Datensatz mit korrekten Spalten
(`household:X`, Pruefung besteht), im JSON-Block aber
`scope_kind: 'personal', scope_id: <fremde uid>`. Alle anderen Mitglieder ziehen
den Satz per Pull und legen ihn lokal im **privaten** Bereich ab. Auf dem Geraet
des Opfers taucht der Eintrag dann im Privatkontext auf, z.B. ein untergeschobener
Pillenplan oder eine Notiz. Analog laesst sich ueber ein abweichendes `id`-Feld
eine beliebige lokale Zeile des Empfaengers ueberschreiben.

**Auswirkung:** Einschleusen und Ueberschreiben von Inhalten auf fremden Geraeten
innerhalb desselben Haushalts. Kein Datenabfluss, aber ein Integritaets- und
Spoofing-Problem, das bei einem Pillen-Tracker unangenehm ist.

**Fix:** `push_record` weist Datenbloecke ab, deren `id`, `scope_kind` oder
`scope_id` von den Spaltenwerten abweichen, und akzeptiert nur bekannte
Tabellennamen. Fuer den echten Client aendert sich nichts: er befuellt
`_scope_id`, `_id` und `_data` aus derselben Zeile (`sync_engine.dart:118-130`),
die Werte stimmen dort bauartbedingt immer ueberein.

### F2 (Mittel, BEHOBEN): `notify-fcm` ist ohne verpflichtendes Geheimnis aufrufbar

Datei: `supabase/functions/notify-fcm/index.ts:84-89`, Deploy laut Kommentar mit
`--no-verify-jwt`. Der Webhook-Schutz ist **optional**: ist `FCM_WEBHOOK_SECRET`
nicht gesetzt, wird jeder Request akzeptiert. Wer die Function-URL kennt, kann
`{household_id, target_user_id, title, body}` frei setzen und einen Push mit
beliebigem Inhalt an die Geraete eines beliebigen Haushalts ausloesen
(Notification-Spoofing / Phishing-Text auf dem Sperrbildschirm), sofern die
Haushalts-UUID bekannt ist.

**Fix:** Das Geheimnis ist jetzt Pflicht. Fehlt `FCM_WEBHOOK_SECRET`, antwortet
die Function mit 500 und verschickt nichts; ein falscher oder fehlender Header
ergibt 403. Der Vergleich laeuft in konstanter Zeit, damit sich das Geheimnis
nicht ueber Laufzeitunterschiede zeichenweise erraten laesst.

**Achtung beim Ausrollen:** Der Webhook im Dashboard muss den Header
`x-webhook-secret` mitgeben, sonst geht kein Push mehr raus. Das Skript
`tool/apply_security_fixes.ps1` erzeugt das Geheimnis und zeigt es dafuer an.

### F3 (Niedrig bis Mittel, BEHOBEN): `upsert_device_token` uebernimmt fremde Token-Bindung

Datei: `supabase/migrations/0005_device_tokens.sql:46-52`. Bei `on conflict
(token)` wird `user_id = excluded.user_id` gesetzt. Wer einen fremden
FCM-Token kennt, kann ihn per RPC an das **eigene** Konto binden. Folge: Pushes
fuer den Angreifer landen auf dem Geraet des Opfers bzw. das Opfer verliert seine
Push-Zustellung (Fehlleitung/Denial). FCM-Tokens sind halb-geheim, daher
begrenztes Risiko.

**Fix:** Ein Token, der einem anderen Konto gehoert, wird nicht mehr uebernommen.
Der Normalfall "Geraet wechselt den Nutzer" kollidiert nicht, weil der Client
beim Abmelden `delete_device_token` aufruft **und** Firebase einen neuen Token
ausstellen laesst (`fcm_service.dart:84`). Nur eine verwaiste Bindung (Abmeldung
ohne Netz, Neuinstallation) wird nach 60 Tagen wieder freigegeben, damit sich
niemand dauerhaft aussperrt.

### F4 (Niedrig, Design/Lieferkette): Windows-Update ohne Code-Signatur

Dateien: `update_installer.dart:180-229`, `release_manifest.dart:150-155`. Die
Integritaet des heruntergeladenen Pakets haengt an TLS plus einer **optionalen**
SHA-256 aus demselben Bucket. Wird der Storage-Bucket oder der Service-Role-Key
kompromittiert, laesst sich ein manipuliertes Windows-ZIP ausliefern, das der
Client entpackt und per Skript ueber die Programmdateien kopiert (stille
Codeausfuehrung). Android ist durch die APK-Signaturpruefung des Systems teilweise
geschuetzt, Windows nicht.

#### Recherche: Signieroptionen fuer eine Privatperson in DE/EU

Ausgangsfrage war, ob es einen kostenfreien Signierweg gibt oder ob nur der
Microsoft Store bleibt. Kurz: einen kostenlosen kommerziellen Weg fuer ein
geschlossenes Privatprojekt gibt es nicht, aber der teure Weg wird hier auch
gar nicht gebraucht.

| Weg | Kosten | Fuer dich nutzbar? |
| --- | --- | --- |
| Azure Trusted Signing (jetzt Azure Artifact Signing) | 9,99 USD/Monat | **Nein.** Fuer Einzelentwickler bislang nur USA/Kanada. Organisationen in der EU koennen es nutzen, Privatpersonen in DE nicht, ohne Termin fuer weitere Laender. |
| SignPath Foundation | kostenlos | **Nur bei Open Source.** Setzt ein oeffentliches Repository und einen Review voraus. Zuhaus ist derzeit ein privates Repo, also aktuell nicht anwendbar. |
| Certum Open Source Code Signing (PL, EU-CA) | ca. 50 bis 120 USD/Jahr | **Ja.** Der guenstigste regulaere Weg fuer Privatpersonen in der EU, Signieren per SimplySign in der Cloud (kein Hardware-Token noetig). Identitaetspruefung per Ausweis. Seit 27.02.2026 max. 459 Tage Laufzeit, laengere Laufzeiten brauchen Reissues. |
| EV-Zertifikat | ab ca. 400 USD/Jahr | Nicht noetig. OV-Zertifikate bekommen inzwischen vergleichbare SmartScreen-Reputation. |
| Microsoft Store | kostenlos (Signatur durch Microsoft) | **Moeglich, aber mit Haken.** Microsoft signiert das Paket, dafuer entfaellt der eigene Update-Kanal. Datenschutzseitig der genannte Punkt: Wer nach DSA als "Trader" gilt, dessen Kontaktdaten (Anschrift, Telefon, E-Mail) werden auf der Produktseite veroeffentlicht. Fuer ein privates Hobbyprojekt ist die Trader-Einstufung nicht zwingend, die Verifizierung verlangt Microsoft aber trotzdem. |

#### Empfehlung: eigenes Manifest signieren statt Zertifikat kaufen

Fuer die tatsaechliche Bedrohung hier (kompromittierter Storage-Bucket liefert
ein manipuliertes ZIP) braucht es **kein CA-Zertifikat**. Ein CA-Zertifikat
loest ein anderes Problem: dass ein fremder Nutzer einem Download aus dem Netz
vertrauen kann (SmartScreen). Deine Nutzer sind aber eine Handvoll bekannter
Geraete, die die App bereits installiert haben.

Der wirksame und kostenlose Fix ist ein eigener Vertrauensanker:

1. `sha256` im Manifest **verpflichtend** machen (heute wird ohne Pruefsumme
   kommentarlos akzeptiert, `update_installer.dart:150-155`).
2. `manifest.json` beim Veroeffentlichen mit einem privaten Schluessel
   signieren (z.B. Ed25519), der ausschliesslich auf deinem Rechner liegt.
3. Den **oeffentlichen** Schluessel fest in die App kompilieren und die
   Manifest-Signatur vor dem Download pruefen.

Damit ist die Pruefsumme nicht mehr aus derselben Quelle wie die Datei, und wer
den Bucket uebernimmt, kann kein gueltiges Manifest mehr erzeugen. Kosten: null,
keine Identitaetspruefung, keine DSGVO-Offenlegung, kein Store.

Ein Certum-Zertifikat lohnt erst, wenn die App oeffentlich verteilt werden soll
und die SmartScreen-Warnung fuer Fremde stoert.

### F5 (Niedrig, Info): Drittanbieter-Schluessel im Client

`SCHWARZ_STORES_API_KEY` (`app_config.dart:77`, `env.json`) wird per
`--dart-define` in das Binary kompiliert und ist damit aus dem Release
extrahierbar. Der Supabase-Publishable/Anon-Key darf oeffentlich sein (dafuer ist
er gedacht, RLS schuetzt dahinter), der Schwarz-Key jedoch nicht wirklich.
**Positiv:** `env.json` ist per `.gitignore` ausgeschlossen und war nie im
Git-Verlauf (geprueft), der echte Schluessel ist nicht in der Historie.

#### "Wie soll ich den Schluessel sonst einbetten?"

Gar nicht, und das ist der Punkt: **ein Geheimnis laesst sich in einer
Client-App grundsaetzlich nicht sicher unterbringen.** Alles, was das Binary
zum Laufen braucht, kann auch ein Angreifer daraus lesen. `--dart-define`,
Verschleierung oder Aufteilen auf mehrere Konstanten aendern daran nichts, sie
erhoehen nur den Aufwand um Minuten. Es gibt deshalb nur drei ehrliche Wege:

1. **Serverseitig proxen (technisch sauber).** Eine kleine Edge Function haelt
   den Schluessel als Supabase-Secret und reicht die Filialabfrage durch. Die
   App ruft nur noch deine Function. Kosten: ein zusaetzlicher Netzweg und die
   Funktion haengt an deinem Backend statt direkt an der Schwarz-API.
2. **Restriktiv ausstellen.** Falls die Schwarz-API es anbietet: Kontingent,
   Referrer- oder IP-Bindung setzen, damit ein abgegriffener Schluessel wenig
   wert ist.
3. **Bewusst akzeptieren und dokumentieren.** Das ist hier vertretbar, und
   zwar aus einem konkreten Grund: Der Schluessel oeffnet eine
   **Filial-Suche**, keine Nutzerdaten. Der Schaden bei Missbrauch ist fremdes
   Kontingent bzw. eine Sperre deines Schluessels, kein Datenschutzvorfall.
   Die Funktion ist ausserdem optional (`prospekte_providers.dart:118-123`):
   ohne Schluessel faellt nur die Lidl-Ortsaufloesung aus.

Zum Vergleich: Der Supabase-Publishable-Key **darf** im Binary stehen, dafuer
ist er gemacht. Er ist keine Berechtigung, sondern nur eine Projektkennung,
die Rechte liegen dahinter in RLS. Beim Schwarz-Key ist das anders, er *ist*
die Berechtigung.

**Einschaetzung:** Wenn die Prospekt-Funktion dauerhaft bleiben soll, ist
Variante 1 die richtige Loesung. Solange es beim Testbetrieb bleibt, ist
Variante 3 mit diesem Absatz als Dokumentation vertretbar. Wichtig ist nur,
den Key rotieren zu koennen, falls er auffaellt.

### Positiv hervorzuheben

- Konsequentes RLS-plus-RPC-Muster, keine direkten Client-Writes.
- `delete-account` streng auf den JWT-Aufrufer begrenzt, mit Owner-Schutz.
- Pfad-Bereinigung gegen Path-Traversal beim Dateinamen (`_safeFileName`).
- Datensparsame Standortaufloesung: nur PLZ, kein Geraetestandort
  (`prospekte_providers.dart:12-34`).
- Keine Secrets im Git-Verlauf.

---

## 5. Ist OWASP ZAP hier sinnvoll?

Kurzfassung: **nur eingeschraenkt, und nicht als automatischer Scanner.** ZAP ist
ein DAST-Werkzeug fuer Web-Apps. Hier stehen dem zwei strukturelle Huerden
gegenueber.

### 5.1 Huerde 1: Flutter ist nicht proxy-aware

Dart/Flutter nutzt einen eigenen TLS-Stack mit eingebautem Zertifikatsspeicher,
ignoriert die System-Proxy-Einstellung und ein systemweit installiertes
ZAP-CA-Zertifikat. Um Traffic ueberhaupt durch ZAP zu leiten, muss man:

- den Verkehr aktiv umbiegen (z. B. `reFlutter`, auf Android das Frida-Skript
  `disable-flutter-tls.js`), und
- die TLS-Verifikation der App aushebeln.

Auf Desktop (Windows/Linux/macOS) muesste man dem `HttpClient` einen Proxy und
das ZAP-CA ueber `SecurityContext`/`badCertificateCallback` unterschieben, also
einen Debug-Build bauen. Fuer eine reine Blackbox-Pruefung ist das viel Aufwand.

### 5.2 Huerde 2: Generische Scanner verstehen PostgREST/RLS nicht

Das Sicherheitsmodell liegt in der Datenbank (RLS-Policies, SECURITY-DEFINER-RPCs),
nicht in klassischer serverseitiger Web-Logik. ZAPs aktive Scanner (SQLi, XSS,
Command Injection) laufen praktisch ins Leere: PostgREST parametrisiert, es gibt
kein server-gerendertes HTML. Die eigentlichen Risiken hier (BOLA/IDOR wie **F1**,
fehlende Authentifizierung an einer Function wie **F2**, RLS-Luecken) findet ZAP
automatisch nicht, weil ihm das PostgREST-/RLS-Wissen fehlt. Genau dafuer gibt es
spezialisierte Werkzeuge (z. B. Supabomb/SupaSec) und PostgREST-typische Tricks
wie `?id=gt.0` zum Abgreifen ganzer Tabellen.

### 5.3 Wo ZAP trotzdem hilft

Als **manueller Intercepting-Proxy** (nicht als Auto-Scanner) ist ZAP nuetzlich,
um aufgezeichnete Requests gezielt umzuschreiben und erneut zu senden:

- `push_record` mit fremder `_id` und eigenem Scope wiederspielen (**F1** verifizieren).
- `notify-fcm` ohne/mit falschem `x-webhook-secret` aufrufen (**F2** verifizieren).
- RPC-Parameter fuzzen, Rollenpruefungen mit einem Zweit-Account gegentesten.
- TLS/Antwort-Header pruefen.

Fuer diese Ziele reicht aber auch `curl`/Postman mit zwei echten Nutzer-JWTs, und
das ist ohne TLS-Bypass am Flutter-Client deutlich schneller aufgesetzt.

### 5.4 Empfehlung Test-Ansatz

1. **Manuelle BOLA/Multi-Tenant-Tests** mit zwei Konten direkt gegen die
   PostgREST-/RPC-Endpunkte (curl/Postman) - deckt F1/F2/F3 ab.
2. **RLS-Regressionstests** in der Datenbank via **pgTAP** (jede Policy als Test),
   damit kuenftige Migrationen keine Luecke aufreissen.
3. **Supabase-spezifische Scanner** (Supabomb o. ae.) fuer die typischen
   Fehlkonfigurationen.
4. **ZAP optional** als Intercepting-Proxy fuer Ad-hoc-Replays; der automatische
   Active-Scan bringt gegen dieses Backend wenig und lohnt den Flutter-TLS-Aufwand
   kaum.

---

## 6. Zusammenfassung und Aussicht

Die App hat ein durchdachtes Grundgeruest: Lesen ueber RLS, Schreiben nur ueber
rollenpruefende SECURITY-DEFINER-RPCs, DSGVO-konforme Kontoloeschung, datensparsame
Standortnutzung, keine Secrets im Repository. Klassische Injection- und
Lese-IDOR-Wege greifen nicht.

Stand nach der Umsetzung:

| ID | Schwere | Kurz | Status |
| --- | --- | --- | --- |
| F1 | Mittel-Hoch | `push_record` prueft beim Update nur den mitgeschickten Scope | Behoben (0007) |
| F6 | Mittel | `push_record` prueft den JSON-Datenblock gar nicht | Behoben (0007) |
| F2 | Mittel | `notify-fcm` ohne Pflicht-Secret aufrufbar | Behoben (Function) |
| F3 | Niedrig-Mittel | `upsert_device_token` uebernimmt fremde Token-Bindung | Behoben (0007) |
| F4 | Niedrig (Design) | Windows-Update ohne unabhaengigen Vertrauensanker | Offen, Empfehlung: Manifest selbst signieren |
| F5 | Niedrig (Info) | Schwarz-API-Key steckt im Client-Binary | Offen, bewusst tragbar |

**Zu OWASP ZAP:** fuer dieses Flutter-plus-Supabase-Setup nur als manueller
Proxy punktuell sinnvoll, nicht als automatischer Scanner. Der groessere Nutzen
liegt in manuellen Multi-Tenant-Tests mit zwei JWTs, pgTAP-RLS-Tests und
Supabase-spezifischen Werkzeugen.

### Braucht das Sync-Modell einen Umbau?

Kurz: **nein.** Die Architektur ist nicht die Ursache der Befunde.

Das Muster (offline-first, eine generische `sync_records`-Tabelle, RLS zum Lesen,
SECURITY-DEFINER-RPCs zum Schreiben, LWW plus additive Zaehler) ist fuer diese
App angemessen und gaengig. Alle vier behobenen Befunde hatten dieselbe Ursache,
und es war keine strukturelle: **an der Vertrauensgrenze wurde zu wenig
validiert.** Der Server hat entgegengenommen, was der Client behauptet hat, statt
es gegen den gespeicherten Zustand zu pruefen. Das ist eine Luecke in der
Eingangspruefung, kein falscher Aufbau. Ein Neubau wuerde viel Arbeit kosten und
mit hoher Wahrscheinlichkeit dieselbe Form annehmen, nur mit neuen Fehlern.

Was ich stattdessen empfehle, in dieser Reihenfolge:

1. **pgTAP-Tests** fuer RLS und RPCs. Das ist der wichtigste Punkt: die
   Sicherheitslogik liegt komplett in SQL und ist derzeit ungetestet. Genau so
   ist F1 entstanden und genau so entsteht der naechste Befund bei der naechsten
   Migration.
2. **Groessenbegrenzung fuer `data`**, z.B. per Check-Constraint. Aktuell kann
   ein Mitglied beliebig grosse JSON-Bloecke ablegen.
3. **Zeitstempel eingrenzen.** `updated_at` ist Client-Zeit. Ein Wert weit in
   der Zukunft gewinnt bei LWW dauerhaft jeden Konflikt. Ein Riegel wie
   "nicht mehr als 24 Stunden voraus" reicht.
4. **F4 umsetzen** (Manifest signieren), siehe Abschnitt 4.

Punkt 2 und 3 sind Haertung gegen ein *boeswilliges Haushaltsmitglied*. Wie weit
das getrieben werden muss, haengt vom Vertrauensmodell ab: Bei einem
Familienhaushalt ist ein Angreifer im eigenen Haushalt ein anderes Szenario als
bei einer oeffentlichen Mehrmandantenanwendung. F1 und F6 waren trotzdem
wichtig, weil sie auch **ehemalige** Mitglieder betreffen.

---

*Hinweis: Diese Pruefung ist eine statische Code- und Konfigurationsanalyse ohne
Live-Penetrationstest. Die genannten Angriffspfade wurden aus dem Quellcode
abgeleitet, nicht praktisch gegen eine laufende Instanz ausgefuehrt.*

*Zum Stand der Korrekturen: Die SQL-Migration 0007 konnte lokal nicht ausgefuehrt
werden (kein Postgres/Docker auf dem Entwicklungsrechner). Sie ist gegen die
bestehenden Funktionen gegengelesen, aber nicht ausgefuehrt getestet. Nach dem
Einspielen bitte einmal praktisch pruefen: Abgleich laeuft durch, ein
Familien-Ereignis kommt an, und ein Aufruf ohne `x-webhook-secret` ergibt 403.*
