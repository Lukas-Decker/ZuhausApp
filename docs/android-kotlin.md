# Android: eingebautes Kotlin (AGP 9)

Beim Android-Build erscheint diese Warnung:

> Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP):
> flutter_timezone, mobile_scanner. Future versions of Flutter will fail to
> build if your app uses plugins that apply KGP.

Kurzfassung: **Das ist bekannt, die App ist ihrerseits fertig umgestellt, und
abstellen lässt sich die Warnung erst, wenn die betroffenen Fremd-Plugins
nachziehen.** Der Build funktioniert bis dahin normal.

## Worum es geht

Ab dem Android-Gradle-Plugin 9 bringt AGP Kotlin-Unterstützung selbst mit; das
separate Kotlin-Gradle-Plugin (KGP) entfällt. Flutter macht diesen Wechsel über
zwei Schalter in `android/gradle.properties` mit:

| Schalter | Bedeutung |
| --- | --- |
| `android.builtInKotlin` | `true` = eingebautes Kotlin von AGP, KGP verschwindet vom Klassenpfad |
| `android.newDsl` | `true` = neue Gradle-DSL von AGP 9 |

Beide stehen bei uns bewusst auf `false`.

## Was an der App bereits erledigt ist

Die App-Seite der Migration ist vollständig:

- `android/app/build.gradle.kts` wendet **kein** `kotlin-android` an,
- die Java-/Kotlin-Zielversion steht im neuen `kotlin { compilerOptions { … } }`
  statt im alten `kotlinOptions`-Block,
- die beiden Schalter sind gesetzt (auf `false`, siehe unten).

Die Warnung nennt deshalb ausschließlich fremde Plugins, nicht unseren Code.

## Warum die Schalter noch auf `false` stehen

Mit `android.builtInKotlin=true` bricht der Build ab:

```
Applying the Kotlin Android Plugin (KGP) was unsuccessful.
KGP was not found on the classpath.
Build file '…/app_links-7.2.1/android/build.gradle.kts' line: 22
> The 'org.jetbrains.kotlin.android' plugin is no longer required for Kotlin
  support since AGP 9.0.
```

Bemerkenswert daran: `app_links` enthält ausschließlich Java-Quellen und
deklariert KGP nirgends. Der Flutter-Gradle-Loader richtet Kotlin für **jedes**
Plugin-Modul ein, und ohne KGP auf dem Klassenpfad scheitert das am ersten
Modul in der Reihe. Die Namen in der Warnung (`flutter_timezone`,
`mobile_scanner`) und der Name im Abbruch (`app_links`) sind daher
verschiedene Dinge, und eine Suche in den Plugin-Dateien führt in die Irre.

Ein Umstieg auf neuere Plugin-Versionen hilft aktuell nicht: `flutter_timezone`
(5.1.0) und `mobile_scanner` (7.4.0) sind bereits die neuesten
Veröffentlichungen und haben die Migration noch nicht vollzogen. `mobile_scanner`
hat immerhin vorgearbeitet und wendet KGP seit 7.2.1 nur noch unterhalb von
AGP 9 an.

## Wann kann umgestellt werden

Das beantwortet ein Probebau:

```bash
powershell -File tool/check_kgp.ps1
```

Das Skript schaltet `android.builtInKotlin` vorübergehend auf `true`, baut ein
Debug-APK und setzt die Datei danach in jedem Fall zurück. Exit-Code `0` heißt
"geht jetzt", `2` heißt "noch nicht". Läuft der Bau durch, sind drei Schritte
fällig:

1. In `android/gradle.properties` beide Schalter auf `true` setzen.
2. In `android/settings.gradle.kts` die Zeile mit
   `org.jetbrains.kotlin.android` entfernen.
3. Android-Release bauen und die App auf einem Gerät gegenprüfen (Scanner,
   Erinnerungen, App-Schloss und Teilen sind die Funktionen, die an den
   betroffenen Plugins hängen).

## Hintergrund

- [Migration zu Built-in Kotlin, App-Seite](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers)
- [Migration zu Built-in Kotlin, Plugin-Seite](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors)
