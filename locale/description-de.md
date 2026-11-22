# Custom Skirmish Trails

**1.4.1**

Diese Erweiterung ermöglicht eigene Kreuzzugsmärsche, die in `.csv`-Dateien definiert werden.

## Möglichkeiten
Die ZIP-Datei dieser Erweiterung enthält eine `template.csv`-Datei, die beschreibt, was angepasst werden kann.

Du kannst auch den ersten Marsch [hier](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-First-Edition-Trail.csv), den Warchest-Marsch [hier](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Warchest-Trail.csv) und den Extreme-Marsch [hier](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Extreme-Trail.csv) herunterladen.

Ein einfacher Online-Editor findet sich hier: https://edit-csv.net/

Hier die Liste der Spalten:
- map_name
- fairness
- start_levels
- num_players
- player1
- player2
- player3
- player4
- player5
- player6
- player7
- player8
- start_position1
- start_position2
- start_position3
- start_position4
- start_position5
- start_position6
- start_position7
- start_position8
- team1
- team2
- team3
- team4
- team5
- team6
- team7
- team8
- aiv_type1
- aiv_type2
- aiv_type3
- aiv_type4
- aiv_type5
- aiv_type6
- aiv_type7
- aiv_type8
- mission_name
- gold
- producible_bows
- producible_crossbows
- producible_maces
- producible_pikes
- producible_spears
- producible_swords
- recruitable_archers
- recruitable_spearmen
- recruitable_macemen
- recruitable_crossbowmen
- recruitable_pikemen
- recruitable_swordsmen
- recruitable_knights
- recruitable_arabian_bows
- recruitable_slaves
- recruitable_slingers
- recruitable_assassins
- recruitable_horse_archers
- recruitable_arabian_swordsmen
- recruitable_fire_throwers
- resource_wood
- resource_hops
- resource_stone
- resource_iron
- resource_pitch
- resource_wheat
- resource_bread
- resource_cheese
- resource_meat
- resource_apple
- resource_ale
- resource_gold
- resource_flour
- resource_bow
- resource_crossbow
- resource_spear
- resource_pike
- resource_mace
- resource_sword
- resource_leatherarmor
- resource_ironarmor
- text_dexcription_line_01 - 08: Verwende `""`, um Text für das Startmenü der Gefechtsmission einzutragen
- trade_: Verwende z. B. `trade_spear` (Einzahl!), um den Handel mit dieser Ware ein- oder auszuschalten

## Neu in 1.4 (Fork von Monsterfish)

### Spielernamen und Lord des menschlichen Spielers
Optionale CSV-Spalten, am besten am Ende eingefügt:
- `player1_name` bis `player8_name`: der Name eines Spielers in dieser Mission, in der Einsatzbesprechung und im Spiel. Leer übernimmt den üblichen Spieler- oder KI-Namen.
- `player1_lord`: `Arab` oder `Europ` gibt dem menschlichen Spieler für diese Mission den arabischen oder europäischen Lord samt dessen Starttruppen. Leer belässt die eigene Wahl des Spielers.
- `player1_skip_start_units`: `1` gibt dem menschlichen Spieler keine Starttruppen in dieser Mission (der Lord erscheint weiterhin). Leer oder `0` behält sie.

### Marsch-Einstellungsdatei
Jeder Marsch kann eine Marsch-Einstellungsdatei (eine `.json`-Datei, eingestellt in der GUI) mit sämtlichen Angaben zum Marsch haben. `resources/trail-settings.schema.json` beschreibt sie, und `resources/trails/template-*-settings.json` enthalten die Werte des Spiels. Jeder Eintrag ist optional:
- `trail_type`: `First`, `Warchest` oder `Extreme`.
- `trail_missions`: die Missionsdaten des Marschs, siehe unten.
- `trail_text_files`: die Sprachdateien des Marschs, siehe unten.
- `trail_title`, `trail_summary`: die Texte unter der Marsch-Schaltfläche im Gefechtsmenü. Eine Kurzbeschreibung breiter als 540 Pixel bricht in eine zweite Zeile um; beide Texte rücken dann 10 Pixel höher.
- `starting_year`: das Jahr, in dem die erste Mission beginnt.
- `trail_visuals`: `trail_button_idle` und `trail_button_highlighted` (Bilder, z. B. `.png`, für die Marsch-Schaltfläche im Gefechtsmenü) sowie `trail_background` (Hintergrund des Marsch-Bildschirms: eine `.tgx`-Datei oder ein `.png`/`.jpg`/`.bmp`, das das Spiel einmalig in `.tgx` umwandelt und in `ucp/.cache` speichert; die Größe der Spieldatei beibehalten).
- `trail_mission_positions`: eine Liste von `{ "x": .., "y": .. }`-Punkten auf dem 800×600-Marsch-Bildschirm, einer pro Mission. Ihre Anzahl bestimmt die Missionszahl des Marschs (höchstens 50 für den ersten Marsch, 30 für Warchest und Extreme).
- `ai_character_mapping`: eigene Namen für die KI-Schlüssel (`"SK_RICHARD": "Alfonso"`). Missionsdateien nutzen sie, und die CSV-Datei darf sie in `player1` bis `player8` verwenden.

Relative Pfade in der Datei beziehen sich auf den Ordner der Datei selbst.

### Missionsdaten: CSV-Datei und Missionsdateien
`"trail_missions": { "base_name": "missions/reconquista", "data_mode": "csv" }` benennt sowohl die CSV-Datei (`missions/reconquista.csv`) als auch einen Ordner mit Missionsdateien (`missions/reconquista/reconquista_mission_01.json`, …). Eine Missionsdatei (Format 1, `resources/mission.schema.json`) enthält dieselben Daten wie eine CSV-Zeile, übersichtlich zum Lesen und Bearbeiten gegliedert:
- `mission_name` und `text_description` (eine Liste der 8 Zeilen) ganz oben;
- `advantage` (`human_large`, `human_small`, `neutral`, `ai_small`, `ai_large`; entspricht `fairness` 1–5 in der CSV) und `start_mode` (`normal`, `crusader`, `deathmatch`; entspricht `start_levels` 1–3). Zahlen funktionieren ebenfalls;
- `players`: ein Eintrag pro Spieler, sodass ihre Anzahl die Spielerzahl der Mission ergibt. `players[0]` ist der menschliche Spieler: darf `lord` und `skip_start_units` enthalten, niemals `ai`. Die übrigen haben stets `ai`, niemals `lord`. Alle besitzen bei Bedarf `name`, `start_position`, `team`, `aiv_type` und `gold`;
- `producible`, `recruitable`, `resources`, `tradeable`: die Spalten mit Präfix aus der CSV als Objekte;
- `extra`: jeder CSV-Wert ohne eigenen Platz oben, damit nichts verloren geht.

`data_mode` legt fest, welche Quelle maßgeblich ist, und wird bei jedem Spielstart angewendet:
- `csv`: das Spiel lädt die CSV-Datei und erzeugt daraus die Missionsdateien.
- `json_folder`: das Spiel erzeugt die CSV-Datei aus den Missionsdateien und lädt sie dann.
- `automatic`: pro Mission gewinnt die zuletzt bearbeitete Datei – neuere Missionsdateien fließen in die CSV ein, neuere CSV-Zeilen in die Missionsdateien.

Vor Änderungen wird die vorherige CSV als `<csv>.bak` und die vorherigen Missionsdateien in `<ordner>/.bak` gesichert (je eine Vorversion). Wurde seit dem letzten Start nichts geändert, wird nichts gelesen oder geschrieben. Ohne Marsch-Einstellungsdatei wird wie bisher die in der GUI gewählte CSV-Datei genutzt.

### Sprachdateien
Die Missionsdaten enthalten einen Textbestand, die Standardsprache. Jede weitere Sprache ist eine kleine JSON-Datei mit nur ihren Texten: `"trail_text_files": "texts/"` verweist auf einen Ordner mit `english.json`, `german.json` usw. (oder ein Objekt, das Sprachen auf Dateien abbildet). Aufbau einer Sprachdatei:

```json
{
  "trail_title": "Die Reconquista",
  "trail_summary": "...",
  "missions": {
    "1": { "mission_name": "Die Küste", "text_description_line_01": "...", "player2_name": "..." }
  }
}
```

Missionen werden über ihre Nummer zugeordnet. Ein Text, der in einer Sprachdatei fehlt, zeigt den Text aus den Missionsdaten; der strikte Modus listet diese Lücken auf. Mit `trail_missions` wird `texts/_template.json` mit allen Texten der Missionsdaten als Vorlage für Übersetzer erstellt.

### Dateipfade
Das Fenster „Dateipfade“ jedes Marschs listet die dafür gesetzten Dateien auf und löscht sie (das Zurücksetzen der GUI selbst funktioniert nur unmittelbar nach dem Setzen eines Pfads).

### Strikter Modus
Entwicklereinstellung: protokolliert jedes Problem in CSV-, Missions-, Sprach- und Einstellungsdateien, jede auf den Spielwert zurückfallende Einstellung und jeden fehlenden Text einer Sprachdatei. Ohne diese Option erscheint eine Warnung pro fehlerhafter Datei.

### CSV-Daten exportieren und importieren
Das Fenster „CSV-Daten“ jedes Marschs in der GUI bietet Schaltflächen zum Exportieren und Importieren per Hand (`trail_missions` erledigt das bei jedem Start automatisch). Export schreibt jede CSV-Zeile in eine Missionsdatei; Import setzt die Missionsdateien wieder zur CSV-Datei zusammen. Da die GUI selbst keine Dateien schreiben kann, merkt sich der Klick die Anfrage und das Spiel führt sie beim nächsten Start aus; das Fenster zeigt danach das Ergebnis an.

## Unterstützung
Jede Unterstützung ist willkommen!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

Falls du PayPal nutzt:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
