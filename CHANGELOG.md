# Changelog

Alle nennenswerten Änderungen an Zuhaus, neueste zuerst. Beim Veröffentlichen
liest `tool/publish_update.ps1` den Abschnitt der jeweiligen Version aus und
zeigt ihn im Update-Hinweis der App an. Format je Version:

    ## <Version> - <Datum>

Einträge sind aus Nutzersicht geschrieben: was ist neu, was wurde behoben.

## 0.25.0 - 2026-08-11

- Der Update-Hinweis zeigt jetzt alle Änderungen seit der installierten
  Version, nicht nur die der neuesten. Wer mehrere Updates übersprungen
  hat, sieht sie über den Knopf "Änderungen ansehen" nach Versionen
  sortiert.

## 0.24.12 - 2026-08-11

- Kleinere Textkorrekturen (echte Umlaute in den Werkzeug-Ausgaben).

## 0.24.11 - 2026-08-11

- Update-Hinweise zeigen jetzt ein richtiges Changelog: die Änderungen
  werden beim Veröffentlichen automatisch aus CHANGELOG.md übernommen.

## 0.24.10 - 2026-08-11

- Neue Händler-Logos für IKEA, JYSK, KiK, MediaMarkt und Saturn.

## 0.24.9 - 2026-08-11

- Behoben: Die ALDI-Logos zeigten nur einen Bildausschnitt.

## 0.24.8 - 2026-08-11

- Die Logos der gängigen Ketten sind jetzt fest in die App eingebaut und
  damit gestochen scharf, auch ohne Internet.

## 0.24.7 - 2026-08-11

- Fehlt ein Logo, versucht die App weitere Quellen, bevor das neutrale
  Symbol erscheint.

## 0.24.6 - 2026-08-11

- Die Prospektübersicht ist jetzt ein kompaktes Grid der Märkte (Logo,
  Name, Anzahl). Ein Tipp auf einen Markt öffnet seine Prospekte.

## 0.24.5 - 2026-08-11

- Märkte werden mit ihrem Logo angezeigt.

## 0.24.4 - 2026-08-11

- Prospekte sind nach Markt gruppiert; gerade gültige tragen eine
  "Aktuell"-Marke und stehen zuerst.

## 0.24.3 - 2026-08-11

- Vorbereitung für die Lidl-Ortsauflösung: optionaler Schwarz-API-Schlüssel
  in der env.json.

## 0.24.2 - 2026-08-11

- Behoben: Ein Tipp auf ein Angebot öffnete den Prospekt eine Seite zu weit.

## 0.24.1 - 2026-08-11

- Prospekte und Angebote zeigen jetzt die nächstgelegene Filiale und den
  vollen Gültigkeitszeitraum (von - bis).
- Der Prospekt-Viewer lässt sich am PC blättern: Pfeil-Knöpfe, Pfeiltasten
  und Ziehen mit der Maus.

## 0.24.0 - 2026-08-11

- Neu: Prospekte und Angebote im Einkauf-Modul. Artikel suchen und die
  Angebote der Supermärkte vergleichen (günstigster Preis zuerst), Prospekte
  der Umgebung durchblättern.
- Standort per Postleitzahl, ohne Gerätestandort.
